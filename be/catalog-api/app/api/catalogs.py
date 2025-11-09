"""
카탈로그 관련 API 라우터
- 카탈로그 CRUD 작업 처리
- JWT 토큰으로 사용자 인증
- Flutter CatalogProvider에서 호출하는 엔드포인트들
"""
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime
import uuid
from sqlalchemy.orm import Session
from app.core.config import get_kst_now
from sqlalchemy import func, and_

from app.schemas import Catalog, CatalogCreate, CatalogUpdate, ErrorResponse
from app.models import get_db, CatalogDB, ItemDB, UserItemStatusDB
from app.core.security import get_current_user_id
from app.crud import catalog as catalog_crud

# 카탈로그 라우터 생성 - main.py에서 /api/catalogs 경로에 마운트
router = APIRouter()

@router.get("/", response_model=List[Catalog])
async def get_catalogs(
    user_id: str = Depends(get_current_user_id),  # JWT 토큰에서 user_id 추출
    category: Optional[str] = Query(None, description="카테고리 필터"),
    visibility: Optional[str] = Query(None, description="공개 여부 필터"),
    db: Session = Depends(get_db)  # SQLite 데이터베이스 세션
):
    """
    사용자의 카탈로그 목록 조회 (홈 화면용)
    - Flutter ApiService.getCatalogs()에서 호출
    - JWT 토큰으로 사용자 인증 후 해당 사용자의 카탈로그만 반환
    """
    try:
        catalog_records = catalog_crud.get_catalogs_by_user(db, user_id, category, visibility)
        
        catalogs = []
        for catalog_record in catalog_records:
            stats = catalog_crud.calculate_catalog_stats(db, catalog_record.catalog_id, user_id)
            catalog_data = catalog_crud.build_catalog_response(catalog_record, stats)
            catalogs.append(Catalog(**catalog_data))
        
        return catalogs
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.get("/public", response_model=List[Catalog])
def get_public_catalogs(
    category: Optional[str] = Query(None, description="카테고리 필터"),
    user_id: Optional[str] = Query(None, description="현재 사용자 ID (자신의 카탈로그 제외용)"),
    db: Session = Depends(get_db)  # SQLite 데이터베이스 세션
):
    """
    공개 카탈로그 목록 조회 (탐색 화면용)
    - Flutter ApiService.getPublicCatalogs()에서 호출
    - 모든 공개 카탈로그를 시간순으로 반환 (로그인 불필요)
    """
    try:
        import requests
        from app.crud.user_catalog import check_catalog_saved
        
        catalog_records = catalog_crud.get_public_catalogs(db, category, user_id)
        
        # User API에서 사용자 정보 가져오기
        user_api_url = "http://localhost:8080/api/users"
        user_nicknames = {}
        
        catalogs = []
        for catalog_record in catalog_records:
            # 생성자 닉네임 가져오기
            creator_nickname = None
            if catalog_record.user_id not in user_nicknames:
                try:
                    url = f"{user_api_url}/{catalog_record.user_id}"
                    response = requests.get(url, timeout=2)
                    
                    if response.status_code == 200:
                        if response.text:
                            user_data = response.json()
                            user_nicknames[catalog_record.user_id] = user_data.get("nickname", "알 수 없음")
                        else:
                            user_nicknames[catalog_record.user_id] = "알 수 없음"
                    else:
                        user_nicknames[catalog_record.user_id] = "알 수 없음"
                except Exception as e:
                    user_nicknames[catalog_record.user_id] = "알 수 없음"
            
            creator_nickname = user_nicknames.get(catalog_record.user_id)
            
            # 저장 여부 확인
            is_saved = False
            if user_id:
                is_saved = check_catalog_saved(db, user_id, catalog_record.catalog_id)
            
            # 공개 카탈로그는 원작자 기준으로 통계 계산
            stats = catalog_crud.calculate_catalog_stats(db, catalog_record.catalog_id, catalog_record.user_id)
            catalog_data = catalog_crud.build_catalog_response(
                catalog_record, 
                stats,
                creator_nickname=creator_nickname,
                is_saved=is_saved
            )
            catalogs.append(Catalog(**catalog_data))
        
        return catalogs
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.get("/{catalog_id}", response_model=Catalog)
async def get_catalog(
    catalog_id: str,
    user_id: str = Depends(get_current_user_id),  # JWT 토큰에서 user_id 추출
    db: Session = Depends(get_db)
):
    """
    특정 카탈로그 상세 조회
    - 공개 카탈로그는 누구나 조회 가능
    - 비공개 카탈로그는 소유자만 조회 가능
    """
    try:
        catalog_record = catalog_crud.get_catalog(db, catalog_id)
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        # 접근 권한 확인 (공개 카탈로그는 누구나 접근 가능)
        if catalog_record.visibility != "public" and catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        stats = catalog_crud.calculate_catalog_stats(db, catalog_id, user_id)
        catalog_data = catalog_crud.build_catalog_response(catalog_record, stats)
        
        return Catalog(**catalog_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.post("/", response_model=Catalog, status_code=201)
async def create_catalog(
    catalog: CatalogCreate,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """새 카탈로그 생성"""
    try:
        catalog_record = catalog_crud.create_catalog(db, catalog, user_id)
        
        stats = {
            "item_count": 0,
            "owned_count": 0,
            "completion_rate": 0.0
        }
        catalog_data = catalog_crud.build_catalog_response(catalog_record, stats)
        
        return Catalog(**catalog_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.put("/{catalog_id}", response_model=Catalog)
async def update_catalog(
    catalog_id: str,
    catalog_update: CatalogUpdate,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """카탈로그 수정"""
    try:
        catalog_record = catalog_crud.get_catalog(db, catalog_id)
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        catalog_record = catalog_crud.update_catalog(db, catalog_id, catalog_update)
        
        # 업데이트된 카탈로그 조회
        return await get_catalog(catalog_id, user_id, db)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.delete("/{catalog_id}")
async def delete_catalog(
    catalog_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """카탈로그 삭제 (연관된 아이템도 함께 삭제)"""
    try:
        catalog_record = catalog_crud.get_catalog(db, catalog_id)
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        success = catalog_crud.delete_catalog(db, catalog_id, user_id)
        
        if not success:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        return {"message": "카탈로그가 성공적으로 삭제되었습니다"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")