"""
카탈로그 CRUD 작업
"""
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import List, Optional
import uuid

from app.models.database import CatalogDB, ItemDB, UserItemStatusDB, UserCatalogDB
from app.schemas.catalog import CatalogCreate, CatalogUpdate
from app.core.config import get_kst_now


def get_catalog(db: Session, catalog_id: str) -> Optional[CatalogDB]:
    """카탈로그 조회"""
    return db.query(CatalogDB).filter(CatalogDB.catalog_id == catalog_id).first()


def get_catalogs_by_user(
    db: Session, 
    user_id: str, 
    category: Optional[str] = None,
    visibility: Optional[str] = None
) -> List[CatalogDB]:
    """사용자의 카탈로그 목록 조회"""
    query = db.query(CatalogDB).filter(CatalogDB.user_id == user_id)
    
    if category:
        query = query.filter(CatalogDB.category == category)
    if visibility:
        query = query.filter(CatalogDB.visibility == visibility)
    
    return query.all()


def get_public_catalogs(
    db: Session,
    category: Optional[str] = None,
    exclude_user_id: Optional[str] = None
) -> List[CatalogDB]:
    """공개 카탈로그 목록 조회"""
    query = db.query(CatalogDB).filter(CatalogDB.visibility == "public")
    
    if exclude_user_id:
        query = query.filter(CatalogDB.user_id != exclude_user_id)
    if category:
        query = query.filter(CatalogDB.category == category)
    
    return query.order_by(CatalogDB.created_at.desc()).all()


def create_catalog(db: Session, catalog: CatalogCreate, user_id: str) -> CatalogDB:
    """카탈로그 생성"""
    catalog_id = str(uuid.uuid4())
    
    db_catalog = CatalogDB(
        catalog_id=catalog_id,
        user_id=user_id,
        title=catalog.title,
        description=catalog.description,
        category=catalog.category,
        tags=catalog.tags,
        visibility=catalog.visibility,
        thumbnail_url=catalog.thumbnail_url
    )
    
    db.add(db_catalog)
    db.commit()
    db.refresh(db_catalog)
    
    return db_catalog


def update_catalog(
    db: Session, 
    catalog_id: str, 
    catalog_update: CatalogUpdate
) -> Optional[CatalogDB]:
    """카탈로그 수정"""
    db_catalog = get_catalog(db, catalog_id)
    
    if not db_catalog:
        return None
    
    update_data = catalog_update.dict(exclude_unset=True)
    if update_data:
        for key, value in update_data.items():
            setattr(db_catalog, key, value)
        
        db_catalog.updated_at = get_kst_now()
        db.commit()
        db.refresh(db_catalog)
    
    return db_catalog


def delete_catalog(db: Session, catalog_id: str, user_id: str) -> bool:
    """카탈로그 삭제 (연관된 아이템 및 참조 포함)"""
    db_catalog = get_catalog(db, catalog_id)
    
    if not db_catalog:
        return False
    
    # 연관된 아이템들과 사용자 아이템 상태 삭제
    items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).all()
    for item in items:
        db.query(UserItemStatusDB).filter(UserItemStatusDB.item_id == item.item_id).delete()
        db.delete(item)
    
    # 저장된 카탈로그(복사본)인 경우 원본 참조 기록도 삭제
    user_catalog_ref = db.query(UserCatalogDB).filter(
        and_(
            UserCatalogDB.user_id == user_id,
            UserCatalogDB.copied_catalog_id == catalog_id
        )
    ).first()
    
    if user_catalog_ref:
        db.delete(user_catalog_ref)
    
    db.delete(db_catalog)
    db.commit()
    
    return True


def calculate_catalog_stats(db: Session, catalog_id: str, user_id: str) -> dict:
    """카탈로그 통계 계산 (아이템 수, 보유 수, 수집률)"""
    items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).all()
    item_count = len(items)
    
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
    
    return {
        "item_count": item_count,
        "owned_count": owned_count,
        "completion_rate": round(completion_rate, 2)
    }


def build_catalog_response(
    catalog_record: CatalogDB, 
    stats: dict, 
    original_catalog_id: str = None,
    creator_nickname: str = None,
    is_saved: bool = False
) -> dict:
    """카탈로그 응답 데이터 구성"""
    return {
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
        "item_count": stats["item_count"],
        "owned_count": stats["owned_count"],
        "completion_rate": stats["completion_rate"],
        "original_catalog_id": original_catalog_id,
        "creator_nickname": creator_nickname,
        "is_saved": is_saved
    }
