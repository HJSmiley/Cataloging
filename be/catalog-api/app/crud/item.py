"""
아이템 CRUD 작업
"""
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import List, Optional
import uuid

from app.models.database import ItemDB, UserItemStatusDB
from app.schemas.item import ItemCreate, ItemUpdate
from app.core.config import get_kst_now


def get_item(db: Session, item_id: str) -> Optional[ItemDB]:
    """아이템 조회"""
    return db.query(ItemDB).filter(ItemDB.item_id == item_id).first()


def get_items_by_catalog(db: Session, catalog_id: str) -> List[ItemDB]:
    """카탈로그의 아이템 목록 조회"""
    return db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).all()


def create_item(db: Session, item: ItemCreate, user_id: str) -> ItemDB:
    """아이템 생성"""
    item_id = str(uuid.uuid4())
    
    db_item = ItemDB(
        item_id=item_id,
        catalog_id=item.catalog_id,
        name=item.name,
        description=item.description,
        image_url=item.image_url,
        user_fields=item.user_fields
    )
    
    db.add(db_item)
    db.flush()
    
    # 아이템 생성 시 생성자에게 기본 상태(미보유) 부여
    user_item_status = UserItemStatusDB(
        user_id=user_id,
        item_id=item_id,
        owned=False
    )
    db.add(user_item_status)
    db.commit()
    db.refresh(db_item)
    
    return db_item


def update_item(db: Session, item_id: str, item_update: ItemUpdate) -> Optional[ItemDB]:
    """아이템 수정"""
    db_item = get_item(db, item_id)
    
    if not db_item:
        return None
    
    update_data = item_update.dict(exclude_unset=True)
    if update_data:
        for key, value in update_data.items():
            setattr(db_item, key, value)
        
        db_item.updated_at = get_kst_now()
        db.commit()
        db.refresh(db_item)
    
    return db_item


def delete_item(db: Session, item_id: str) -> bool:
    """아이템 삭제"""
    db_item = get_item(db, item_id)
    
    if not db_item:
        return False
    
    # 아이템 상태 삭제
    db.query(UserItemStatusDB).filter(UserItemStatusDB.item_id == item_id).delete()
    
    db.delete(db_item)
    db.commit()
    
    return True


def get_user_item_status(db: Session, user_id: str, item_id: str) -> Optional[UserItemStatusDB]:
    """사용자의 아이템 보유 상태 조회"""
    return db.query(UserItemStatusDB).filter(
        and_(
            UserItemStatusDB.user_id == user_id,
            UserItemStatusDB.item_id == item_id
        )
    ).first()


def toggle_item_owned(db: Session, user_id: str, item_id: str) -> UserItemStatusDB:
    """아이템 보유 여부 토글"""
    user_status = get_user_item_status(db, user_id, item_id)
    
    if not user_status:
        # 상태가 없으면 새로 생성
        user_status = UserItemStatusDB(
            user_id=user_id,
            item_id=item_id,
            owned=False
        )
        db.add(user_status)
        db.flush()
    
    # 보유 상태 토글
    user_status.owned = not user_status.owned
    user_status.updated_at = get_kst_now()
    
    db.commit()
    db.refresh(user_status)
    
    return user_status


def build_item_response(item_record: ItemDB, owned: bool) -> dict:
    """아이템 응답 데이터 구성"""
    return {
        "item_id": item_record.item_id,
        "catalog_id": item_record.catalog_id,
        "name": item_record.name,
        "description": item_record.description,
        "image_url": item_record.image_url,
        "owned": owned,
        "user_fields": item_record.user_fields or {},
        "created_at": item_record.created_at.isoformat(),
        "updated_at": item_record.updated_at.isoformat()
    }
