"""
아이템 관련 API 라우터
- 아이템 CRUD 작업 처리
- 아이템 보유 상태 토글 기능
- Flutter ItemProvider에서 호출하는 엔드포인트들
"""
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime
import uuid
from sqlalchemy.orm import Session
from app.core.config import get_kst_now
from sqlalchemy import and_

from app.schemas import Item, ItemCreate, ItemUpdate, ErrorResponse
from app.models import get_db, CatalogDB, ItemDB, UserItemStatusDB
from app.core.security import get_current_user_id, get_optional_user_id
from app.crud import item as item_crud
from app.crud import catalog as catalog_crud

# 아이템 라우터 생성 - main.py에서 /api/items 경로에 마운트
router = APIRouter()

@router.get("/catalog/{catalog_id}", response_model=List[Item])
async def get_items_by_catalog(
    catalog_id: str,
    owned: Optional[bool] = Query(None, description="보유 여부 필터"),
    db: Session = Depends(get_db),
    user_id: Optional[str] = Depends(get_optional_user_id)  # 선택적 사용자 ID (JWT 토큰이 있으면 추출)
):
    """카탈로그의 아이템 목록 조회 (공개 카탈로그는 인증 불필요)"""
    try:
        catalog_record = catalog_crud.get_catalog(db, catalog_id)
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        # 공개 카탈로그가 아니면 소유자 확인 필요
        if catalog_record.visibility != "public":
            if not user_id:
                raise HTTPException(status_code=401, detail="인증이 필요합니다")
            if catalog_record.user_id != user_id:
                raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        item_records = item_crud.get_items_by_catalog(db, catalog_id)
        
        items = []
        for item_record in item_records:
            # 사용자별 보유 상태 조회 (로그인한 경우만)
            owned_status = False
            if user_id:
                user_status = item_crud.get_user_item_status(db, user_id, item_record.item_id)
                owned_status = user_status.owned if user_status else False
            
            # 보유 여부 필터 적용
            if owned is not None and owned_status != owned:
                continue
            
            item_data = item_crud.build_item_response(item_record, owned_status)
            items.append(Item(**item_data))
        
        return items
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.get("/{item_id}", response_model=Item)
async def get_item(
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """특정 아이템 상세 조회"""
    try:
        item_record = item_crud.get_item(db, item_id)
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        catalog_record = catalog_crud.get_catalog(db, item_record.catalog_id)
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="연관된 카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        user_status = item_crud.get_user_item_status(db, user_id, item_id)
        owned = user_status.owned if user_status else False
        
        item_data = item_crud.build_item_response(item_record, owned)
        
        return Item(**item_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.post("/", response_model=Item, status_code=201)
async def create_item(
    item: ItemCreate,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """새 아이템 생성"""
    try:
        catalog_record = catalog_crud.get_catalog(db, item.catalog_id)
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        item_record = item_crud.create_item(db, item, user_id)
        
        item_data = item_crud.build_item_response(item_record, False)
        
        return Item(**item_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.put("/{item_id}", response_model=Item)
async def update_item(
    item_id: str,
    item_update: ItemUpdate,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """아이템 수정"""
    try:
        item_record = item_crud.get_item(db, item_id)
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        catalog_record = catalog_crud.get_catalog(db, item_record.catalog_id)
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="연관된 카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        item_record = item_crud.update_item(db, item_id, item_update)
        
        # 업데이트된 아이템 조회
        return await get_item(item_id, user_id, db)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.patch("/{item_id}/toggle-owned", response_model=Item)
async def toggle_item_owned(
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    아이템 보유 여부 토글
    - Flutter ApiService.toggleItemOwned()에서 호출
    - 체크박스 클릭 시 owned 상태를 True ↔ False로 변경
    """
    try:
        item_record = item_crud.get_item(db, item_id)
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        user_status = item_crud.toggle_item_owned(db, user_id, item_id)
        
        item_data = item_crud.build_item_response(item_record, user_status.owned)
        
        return Item(**item_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.delete("/{item_id}")
async def delete_item(
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """아이템 삭제"""
    try:
        item_record = item_crud.get_item(db, item_id)
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        catalog_record = catalog_crud.get_catalog(db, item_record.catalog_id)
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="연관된 카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        success = item_crud.delete_item(db, item_id)
        
        if not success:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        return {"message": "아이템이 성공적으로 삭제되었습니다"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")