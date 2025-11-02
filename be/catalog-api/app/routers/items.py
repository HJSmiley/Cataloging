from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime
import uuid
from sqlalchemy.orm import Session

from app.models import Item, ItemCreate, ItemUpdate, ErrorResponse
from app.database import get_db, CatalogDB, ItemDB
from app.utils import get_current_user_id

router = APIRouter()

@router.get("/catalog/{catalog_id}", response_model=List[Item])
async def get_items_by_catalog(
    catalog_id: str,
    user_id: str = Depends(get_current_user_id),
    owned: Optional[bool] = Query(None, description="보유 여부 필터"),
    db: Session = Depends(get_db)
):
    """카탈로그의 아이템 목록 조회"""
    try:
        # 카탈로그 소유자 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 아이템 조회
        query = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id)
        
        # 보유 여부 필터 적용
        if owned is not None:
            query = query.filter(ItemDB.owned == owned)
        
        item_records = query.all()
        
        items = []
        for item_record in item_records:
            item_data = {
                "item_id": item_record.item_id,
                "catalog_id": item_record.catalog_id,
                "name": item_record.name,
                "description": item_record.description,
                "image_url": item_record.image_url,
                "owned": item_record.owned,
                "user_fields": item_record.user_fields or {},
                "created_at": item_record.created_at.isoformat(),
                "updated_at": item_record.updated_at.isoformat()
            }
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
        # 아이템 조회
        item_record = db.query(ItemDB).filter(ItemDB.item_id == item_id).first()
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        # 카탈로그 소유자 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == item_record.catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="연관된 카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        item_data = {
            "item_id": item_record.item_id,
            "catalog_id": item_record.catalog_id,
            "name": item_record.name,
            "description": item_record.description,
            "image_url": item_record.image_url,
            "owned": item_record.owned,
            "user_fields": item_record.user_fields or {},
            "created_at": item_record.created_at.isoformat(),
            "updated_at": item_record.updated_at.isoformat()
        }
        
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
        # 카탈로그 소유자 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == item.catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 아이템 생성
        item_id = str(uuid.uuid4())
        
        item_record = ItemDB(
            item_id=item_id,
            catalog_id=item.catalog_id,
            name=item.name,
            description=item.description,
            image_url=item.image_url,
            owned=item.owned,
            user_fields=item.user_fields
        )
        
        db.add(item_record)
        db.commit()
        db.refresh(item_record)
        
        item_data = {
            "item_id": item_record.item_id,
            "catalog_id": item_record.catalog_id,
            "name": item_record.name,
            "description": item_record.description,
            "image_url": item_record.image_url,
            "owned": item_record.owned,
            "user_fields": item_record.user_fields or {},
            "created_at": item_record.created_at.isoformat(),
            "updated_at": item_record.updated_at.isoformat()
        }
        
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
        # 기존 아이템 조회
        item_record = db.query(ItemDB).filter(ItemDB.item_id == item_id).first()
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        # 카탈로그 소유자 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == item_record.catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="연관된 카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 업데이트할 필드만 수정
        update_data = item_update.dict(exclude_unset=True)
        if update_data:
            for key, value in update_data.items():
                setattr(item_record, key, value)
            
            item_record.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(item_record)
        
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
    """아이템 보유 여부 토글"""
    try:
        # 기존 아이템 조회
        item_record = db.query(ItemDB).filter(ItemDB.item_id == item_id).first()
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        # 카탈로그 소유자 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == item_record.catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="연관된 카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 보유 여부 토글
        item_record.owned = not item_record.owned
        item_record.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(item_record)
        
        # 업데이트된 아이템 조회
        return await get_item(item_id, user_id, db)
        
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
        # 아이템 존재 확인
        item_record = db.query(ItemDB).filter(ItemDB.item_id == item_id).first()
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        # 카탈로그 소유자 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == item_record.catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="연관된 카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 아이템 삭제
        db.delete(item_record)
        db.commit()
        
        return {"message": "아이템이 성공적으로 삭제되었습니다"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")