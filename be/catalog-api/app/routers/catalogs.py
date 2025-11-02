from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime
import uuid
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models import Catalog, CatalogCreate, CatalogUpdate, ErrorResponse
from app.database import get_db, CatalogDB, ItemDB
from app.utils import get_current_user_id

router = APIRouter()

@router.get("/", response_model=List[Catalog])
async def get_catalogs(
    user_id: str = Depends(get_current_user_id),
    category: Optional[str] = Query(None, description="카테고리 필터"),
    visibility: Optional[str] = Query(None, description="공개 여부 필터"),
    db: Session = Depends(get_db)
):
    """사용자의 카탈로그 목록 조회"""
    try:
        # 기본 쿼리
        query = db.query(CatalogDB).filter(CatalogDB.user_id == user_id)
        
        # 필터 적용
        if category:
            query = query.filter(CatalogDB.category == category)
        if visibility:
            query = query.filter(CatalogDB.visibility == visibility)
        
        catalog_records = query.all()
        
        catalogs = []
        for catalog_record in catalog_records:
            # 각 카탈로그의 아이템 통계 계산
            items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_record.catalog_id).all()
            item_count = len(items)
            owned_count = sum(1 for item in items if item.owned)
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
                "completion_rate": round(completion_rate, 2)
            }
            
            catalogs.append(Catalog(**catalog_data))
        
        return catalogs
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.get("/{catalog_id}", response_model=Catalog)
async def get_catalog(
    catalog_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """특정 카탈로그 상세 조회"""
    try:
        # 카탈로그 조회
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        # 소유자 확인
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 아이템 통계 계산
        items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).all()
        item_count = len(items)
        owned_count = sum(1 for item in items if item.owned)
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
            "completion_rate": round(completion_rate, 2)
        }
        
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
        catalog_id = str(uuid.uuid4())
        
        catalog_record = CatalogDB(
            catalog_id=catalog_id,
            user_id=user_id,
            title=catalog.title,
            description=catalog.description,
            category=catalog.category,
            tags=catalog.tags,
            visibility=catalog.visibility,
            thumbnail_url=catalog.thumbnail_url
        )
        
        db.add(catalog_record)
        db.commit()
        db.refresh(catalog_record)
        
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
            "item_count": 0,
            "owned_count": 0,
            "completion_rate": 0.0
        }
        
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
        # 기존 카탈로그 조회
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        # 소유자 확인
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 업데이트할 필드만 수정
        update_data = catalog_update.dict(exclude_unset=True)
        if update_data:
            for key, value in update_data.items():
                setattr(catalog_record, key, value)
            
            catalog_record.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(catalog_record)
        
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
        # 카탈로그 존재 및 소유자 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        if catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 연관된 아이템들 삭제
        db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).delete()
        
        # 카탈로그 삭제
        db.delete(catalog_record)
        db.commit()
        
        return {"message": "카탈로그가 성공적으로 삭제되었습니다"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")