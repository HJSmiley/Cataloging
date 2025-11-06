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

from app.models import Catalog, UserCatalogSave, UserCatalog
from app.database import get_db, CatalogDB, UserCatalogDB, UserItemStatusDB, ItemDB
from app.utils import get_current_user_id

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
        print(f"=== my-catalogs 호출됨: 사용자 {user_id} ===")
        
        # 내가 소유한 모든 카탈로그 조회 (원본 + 복사본)
        # UserCatalogDB와 조인하여 원본 카탈로그 ID 정보도 함께 가져오기
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
        
        print(f"사용자 {user_id}의 소유 카탈로그 수: {len(catalog_query)}")
        
        # 각 카탈로그의 수집률 계산 (사용자별)
        result_catalogs = []
        for catalog_record, original_catalog_id in catalog_query:
            # 카탈로그의 모든 아이템 조회
            items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_record.catalog_id).all()
            item_count = len(items)
            
            # 현재 사용자의 보유 아이템 수 계산
            owned_count = 0
            if items:
                item_ids = [item.item_id for item in items]
                user_statuses = db.query(UserItemStatusDB).filter(
                    and_(
                        UserItemStatusDB.user_id == user_id,
                        UserItemStatusDB.item_id.in_(item_ids),
                        UserItemStatusDB.owned == True
                    )
                ).all()
                owned_count = len(user_statuses)
            
            completion_rate = (owned_count / item_count * 100) if item_count > 0 else 0
            
            catalog_data = {
                "catalog_id": catalog_record.catalog_id,
                "user_id": catalog_record.user_id,
                "title": catalog_record.title,
                "description": catalog_record.description,
                "category": catalog_record.category,
                "tags": catalog_record.tags or [],
                "visibility": catalog_record.visibility,
                "thumbnail_url": catalog_record.thumbnail_url,
                "created_at": catalog_record.created_at.isoformat(),
                "updated_at": catalog_record.updated_at.isoformat(),
                "item_count": item_count,
                "owned_count": owned_count,
                "completion_rate": round(completion_rate, 2),
                "original_catalog_id": original_catalog_id  # 원본 카탈로그 ID (복사본인 경우에만 값이 있음)
            }
            
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
        print(f"=== 카탈로그 저장 요청 시작: 사용자 {user_id}, 카탈로그 {request.catalog_id} ===")
        logger.info(f"사용자 {user_id}가 카탈로그 {request.catalog_id} 저장 요청")
        
        # 1. 원본 카탈로그 존재 확인
        original_catalog = db.query(CatalogDB).filter(CatalogDB.catalog_id == request.catalog_id).first()
        if not original_catalog:
            print(f"카탈로그 {request.catalog_id}를 찾을 수 없음")
            logger.error(f"카탈로그 {request.catalog_id}를 찾을 수 없음")
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        logger.info(f"원본 카탈로그 찾음: {original_catalog.title} (소유자: {original_catalog.user_id})")
        
        # 2. 자신의 카탈로그인지 확인
        if original_catalog.user_id == user_id:
            logger.error(f"자신의 카탈로그 저장 시도: {user_id}")
            raise HTTPException(status_code=400, detail="자신의 카탈로그는 저장할 수 없습니다")
        
        # 3. 이미 저장했는지 확인 (원본 ID 기준)
        existing = db.query(UserCatalogDB).filter(
            and_(
                UserCatalogDB.user_id == user_id,
                UserCatalogDB.original_catalog_id == request.catalog_id
            )
        ).first()
        
        if existing:
            logger.error(f"이미 저장된 카탈로그: {user_id} -> {request.catalog_id}")
            raise HTTPException(status_code=400, detail="이미 저장된 카탈로그입니다")
        
        # 4. 카탈로그 완전 복사본 생성
        new_catalog_id = str(uuid.uuid4())
        logger.info(f"새 카탈로그 ID 생성: {new_catalog_id}")
        
        copied_catalog = CatalogDB(
            catalog_id=new_catalog_id,
            user_id=user_id,  # 현재 사용자가 소유자가 됨
            title=original_catalog.title,  # 원본 제목 그대로 사용 (복사본 표시 제거)
            description=original_catalog.description,
            category=original_catalog.category,
            tags=original_catalog.tags,
            visibility="private",  # 복사본은 기본적으로 비공개
            thumbnail_url=original_catalog.thumbnail_url
        )
        
        logger.info(f"복사본 카탈로그 생성: {copied_catalog.title}")
        db.add(copied_catalog)
        db.flush()  # catalog_id 생성을 위해 flush
        logger.info("카탈로그 복사본 DB에 추가 완료")
        
        # 5. 원본 카탈로그의 모든 아이템도 완전 복사
        original_items = db.query(ItemDB).filter(ItemDB.catalog_id == request.catalog_id).all()
        logger.info(f"복사할 아이템 수: {len(original_items)}")
        
        for original_item in original_items:
            new_item_id = str(uuid.uuid4())
            
            copied_item = ItemDB(
                item_id=new_item_id,
                catalog_id=new_catalog_id,  # 새로운 카탈로그 ID
                name=original_item.name,
                description=original_item.description,
                image_url=original_item.image_url,
                user_fields=original_item.user_fields
            )
            
            db.add(copied_item)
            logger.info(f"아이템 복사: {original_item.name} -> {new_item_id}")
            
            # 복사된 아이템에 대한 사용자 상태 생성 (기본값: 미보유)
            user_item_status = UserItemStatusDB(
                user_id=user_id,
                item_id=new_item_id,
                owned=False  # 기본값: 미보유
            )
            db.add(user_item_status)
        
        # 6. 원본-복사본 관계 저장 (추적 목적 - 중복 저장 방지용)
        user_catalog = UserCatalogDB(
            user_id=user_id,
            original_catalog_id=request.catalog_id,  # 원본 카탈로그 ID
            copied_catalog_id=new_catalog_id         # 복사본 카탈로그 ID
        )
        
        db.add(user_catalog)
        db.commit()
        
        logger.info(f"사용자 {user_id}가 카탈로그 {request.catalog_id}를 {new_catalog_id}로 복사 완료")
        
        return {
            "message": "카탈로그가 성공적으로 저장되었습니다",
            "copied_catalog_id": new_catalog_id,
            "original_catalog_id": request.catalog_id
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
        print(f"=== 카탈로그 제거 요청: 사용자 {user_id}, 카탈로그 {catalog_id} ===")
        
        # 1. 카탈로그 소유자 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == catalog_id).first()
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        # 2. 소유자 확인 (자신이 소유한 카탈로그만 삭제 가능)
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="삭제 권한이 없습니다")
        
        print(f"카탈로그 삭제: {catalog_record.title}")
        
        # 3. 카탈로그의 모든 아이템과 관련 데이터 삭제
        items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).all()
        for item in items:
            # 아이템 상태 삭제
            db.query(UserItemStatusDB).filter(UserItemStatusDB.item_id == item.item_id).delete()
            # 아이템 삭제
            db.delete(item)
        
        # 4. 카탈로그 삭제
        db.delete(catalog_record)
        
        # 5. 원본 참조 삭제 (저장한 카탈로그인 경우)
        # 이 카탈로그가 다른 카탈로그의 복사본이었다면 참조 기록 삭제
        user_catalog_ref = db.query(UserCatalogDB).filter(
            and_(
                UserCatalogDB.user_id == user_id,
                UserCatalogDB.copied_catalog_id == catalog_id
            )
        ).first()
        
        if user_catalog_ref:
            db.delete(user_catalog_ref)
        
        db.commit()
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
        # 원본 카탈로그 ID로 저장 기록 확인
        user_catalog = db.query(UserCatalogDB).filter(
            and_(
                UserCatalogDB.user_id == user_id,
                UserCatalogDB.original_catalog_id == original_catalog_id
            )
        ).first()
        
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