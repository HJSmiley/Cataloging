"""
사용자 카탈로그 관리 API 라우터
- 사용자가 저장한 카탈로그 목록 관리
- 다른 사용자의 카탈로그를 내 카탈로그로 저장
- 사용자별 아이템 보유 상태 관리
"""
from fastapi import APIRouter, HTTPException, Depends
from typing import List
from datetime import datetime
import uuid
import logging
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.schemas import Catalog, UserCatalogSave, UserCatalog
from app.models import get_db, CatalogDB, UserCatalogDB, UserItemStatusDB, ItemDB
from app.core.security import get_current_user_id
from app.crud import catalog as catalog_crud
from app.crud import user_catalog as user_catalog_crud

# 로거 설정
logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/my-catalogs", response_model=List[Catalog])
async def get_my_catalogs(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    내가 소유한 카탈로그 목록 조회 (홈 화면용)
    - 내가 생성한 카탈로그 + 저장한 카탈로그 (복사본)
    - 추가/저장 시간순으로 정렬
    """
    try:
        # 내가 소유한 모든 카탈로그 조회 (원본 + 복사본)
        catalog_query = db.query(
            CatalogDB,
            UserCatalogDB.original_catalog_id
        ).outerjoin(
            UserCatalogDB,
            and_(
                UserCatalogDB.copied_catalog_id == CatalogDB.catalog_id,
                UserCatalogDB.user_id == user_id
            )
        ).filter(
            CatalogDB.user_id == user_id
        ).order_by(CatalogDB.created_at.desc()).all()
        
        result_catalogs = []
        for catalog_record, original_catalog_id in catalog_query:
            stats = catalog_crud.calculate_catalog_stats(db, catalog_record.catalog_id, user_id)
            catalog_data = catalog_crud.build_catalog_response(catalog_record, stats, original_catalog_id)
            result_catalogs.append(Catalog(**catalog_data))
        
        return result_catalogs
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.post("/save-catalog")
async def save_catalog(
    request: UserCatalogSave,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    다른 사용자의 카탈로그를 복사하여 내 카탈로그로 저장
    """
    try:
        logger.info(f"사용자 {user_id}가 카탈로그 {request.catalog_id} 저장 요청")
        
        # 원본 카탈로그 존재 확인
        original_catalog = catalog_crud.get_catalog(db, request.catalog_id)
        if not original_catalog:
            logger.error(f"카탈로그 {request.catalog_id}를 찾을 수 없음")
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        logger.info(f"원본 카탈로그 찾음: {original_catalog.title} (소유자: {original_catalog.user_id})")
        
        # 자신의 카탈로그인지 확인
        if original_catalog.user_id == user_id:
            logger.error(f"자신의 카탈로그 저장 시도: {user_id}")
            raise HTTPException(status_code=400, detail="자신의 카탈로그는 저장할 수 없습니다")
        
        # 이미 저장했는지 확인
        existing = user_catalog_crud.get_user_catalog(db, user_id, request.catalog_id)
        if existing:
            logger.error(f"이미 저장된 카탈로그: {user_id} -> {request.catalog_id}")
            raise HTTPException(status_code=400, detail="이미 저장된 카탈로그입니다")
        
        # 카탈로그 복사
        result = user_catalog_crud.save_catalog(db, user_id, request.catalog_id)
        
        logger.info(f"사용자 {user_id}가 카탈로그 {request.catalog_id}를 {result['copied_catalog_id']}로 복사 완료")
        
        return {
            "message": "카탈로그가 성공적으로 저장되었습니다",
            "copied_catalog_id": result["copied_catalog_id"],
            "original_catalog_id": result["original_catalog_id"]
        }
        
    except Exception as e:
        db.rollback()
        logger.error(f"카탈로그 저장 실패: {str(e)}")
        raise HTTPException(status_code=500, detail=f"카탈로그 저장 실패: {str(e)}")

@router.delete("/unsave-catalog/{catalog_id}")
async def unsave_catalog(
    catalog_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    저장한 카탈로그 제거 (복사본 삭제)
    - catalog_id는 삭제할 복사본의 ID
    """
    try:
        catalog_record = catalog_crud.get_catalog(db, catalog_id)
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="삭제 권한이 없습니다")
        
        success = user_catalog_crud.unsave_catalog(db, user_id, catalog_id)
        
        if not success:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        return {"message": "카탈로그가 성공적으로 삭제되었습니다"}
        
    except Exception as e:
        db.rollback()
        logger.error(f"카탈로그 삭제 실패: {str(e)}")
        raise HTTPException(status_code=500, detail=f"카탈로그 삭제 실패: {str(e)}")

@router.get("/check-ownership/{catalog_id}")
async def check_catalog_ownership(
    catalog_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    카탈로그 소유권 확인
    - 사용자가 해당 카탈로그를 소유하고 있는지 확인
    """
    try:
        catalog = db.query(CatalogDB).filter(
            and_(
                CatalogDB.catalog_id == catalog_id,
                CatalogDB.user_id == user_id
            )
        ).first()
        
        return {
            "catalog_id": catalog_id,
            "is_owned": catalog is not None,
            "user_id": user_id
        }
        
    except Exception as e:
        logger.error(f"소유권 확인 실패: {str(e)}")
        raise HTTPException(status_code=500, detail=f"소유권 확인 실패: {str(e)}")

@router.get("/check-saved/{original_catalog_id}")
async def check_catalog_saved(
    original_catalog_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    카탈로그 저장 여부 확인 (원본 카탈로그 ID 기준)
    - 사용자가 해당 원본 카탈로그를 저장했는지 확인
    """
    try:
        user_catalog = user_catalog_crud.get_user_catalog(db, user_id, original_catalog_id)
        
        return {
            "original_catalog_id": original_catalog_id,
            "is_saved": user_catalog is not None,
            "copied_catalog_id": user_catalog.copied_catalog_id if user_catalog else None,
            "user_id": user_id
        }
        
    except Exception as e:
        logger.error(f"저장 여부 확인 실패: {str(e)}")
        raise HTTPException(status_code=500, detail=f"저장 여부 확인 실패: {str(e)}")



@router.get("/debug/user-info")
async def debug_user_info(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    디버깅용: 현재 사용자 정보 확인
    """
    catalogs = db.query(CatalogDB).filter(CatalogDB.user_id == user_id).all()
    all_catalogs = db.query(CatalogDB).all()
    return {
        "user_id": user_id,
        "catalog_count": len(catalogs),
        "catalogs": [{"id": c.catalog_id, "title": c.title, "user_id": c.user_id} for c in catalogs],
        "all_catalogs": [{"id": c.catalog_id, "title": c.title, "user_id": c.user_id} for c in all_catalogs]
    }