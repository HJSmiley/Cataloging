"""
사용자 카탈로그 CRUD 작업
"""
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import List, Optional
import uuid

from app.models.database import UserCatalogDB, CatalogDB, ItemDB, UserItemStatusDB


def get_user_catalog(db: Session, user_id: str, original_catalog_id: str) -> Optional[UserCatalogDB]:
    """사용자 카탈로그 저장 기록 조회"""
    return db.query(UserCatalogDB).filter(
        and_(
            UserCatalogDB.user_id == user_id,
            UserCatalogDB.original_catalog_id == original_catalog_id
        )
    ).first()


def check_catalog_saved(db: Session, user_id: str, catalog_id: str) -> bool:
    """카탈로그 저장 여부 확인"""
    # catalog_id가 원본 카탈로그 ID인 경우
    saved = db.query(UserCatalogDB).filter(
        and_(
            UserCatalogDB.user_id == user_id,
            UserCatalogDB.original_catalog_id == catalog_id
        )
    ).first()
    
    return saved is not None


def save_catalog(db: Session, user_id: str, original_catalog_id: str) -> dict:
    """카탈로그 복사 및 저장"""
    # 원본 카탈로그 조회
    original_catalog = db.query(CatalogDB).filter(CatalogDB.catalog_id == original_catalog_id).first()
    
    if not original_catalog:
        return None
    
    # 카탈로그 복사본 생성
    new_catalog_id = str(uuid.uuid4())
    
    copied_catalog = CatalogDB(
        catalog_id=new_catalog_id,
        user_id=user_id,
        title=original_catalog.title,
        description=original_catalog.description,
        category=original_catalog.category,
        tags=original_catalog.tags,
        visibility="private",
        thumbnail_url=original_catalog.thumbnail_url
    )
    
    db.add(copied_catalog)
    db.flush()
    
    # 아이템 복사
    original_items = db.query(ItemDB).filter(ItemDB.catalog_id == original_catalog_id).all()
    
    for original_item in original_items:
        new_item_id = str(uuid.uuid4())
        
        copied_item = ItemDB(
            item_id=new_item_id,
            catalog_id=new_catalog_id,
            name=original_item.name,
            description=original_item.description,
            image_url=original_item.image_url,
            user_fields=original_item.user_fields
        )
        
        db.add(copied_item)
        
        # 사용자 아이템 상태 생성
        user_item_status = UserItemStatusDB(
            user_id=user_id,
            item_id=new_item_id,
            owned=False
        )
        db.add(user_item_status)
    
    # 원본-복사본 관계 저장
    user_catalog = UserCatalogDB(
        user_id=user_id,
        original_catalog_id=original_catalog_id,
        copied_catalog_id=new_catalog_id
    )
    
    db.add(user_catalog)
    db.commit()
    
    return {
        "copied_catalog_id": new_catalog_id,
        "original_catalog_id": original_catalog_id
    }


def unsave_catalog(db: Session, user_id: str, copied_catalog_id: str) -> bool:
    """저장한 카탈로그 제거"""
    # 카탈로그 조회
    catalog = db.query(CatalogDB).filter(CatalogDB.catalog_id == copied_catalog_id).first()
    
    if not catalog or catalog.user_id != user_id:
        return False
    
    # 아이템 및 상태 삭제
    items = db.query(ItemDB).filter(ItemDB.catalog_id == copied_catalog_id).all()
    for item in items:
        db.query(UserItemStatusDB).filter(UserItemStatusDB.item_id == item.item_id).delete()
        db.delete(item)
    
    # 카탈로그 삭제
    db.delete(catalog)
    
    # 원본 참조 삭제
    user_catalog_ref = db.query(UserCatalogDB).filter(
        and_(
            UserCatalogDB.user_id == user_id,
            UserCatalogDB.copied_catalog_id == copied_catalog_id
        )
    ).first()
    
    if user_catalog_ref:
        db.delete(user_catalog_ref)
    
    db.commit()
    
    return True
