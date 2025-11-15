"""
사용자 관련 CRUD 작업
"""
from sqlalchemy.orm import Session
from app.models.database import CatalogDB, ItemDB, UserItemStatusDB, UserCatalogDB


def delete_user_data(db: Session, user_id: str) -> dict:
    """
    사용자의 모든 데이터 삭제 (회원 탈퇴 시)
    - 사용자가 생성한 모든 카탈로그
    - 카탈로그에 속한 모든 아이템
    - 사용자의 아이템 보유 상태
    - 사용자가 저장한 카탈로그 참조
    """
    deleted_counts = {
        "catalogs": 0,
        "items": 0,
        "item_statuses": 0,
        "saved_catalogs": 0
    }
    
    # 1. 사용자가 생성한 카탈로그 및 아이템 삭제
    user_catalogs = db.query(CatalogDB).filter(CatalogDB.user_id == user_id).all()
    
    for catalog in user_catalogs:
        # 카탈로그의 아이템들 삭제
        items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog.catalog_id).all()
        for item in items:
            # 아이템 보유 상태 삭제 (모든 사용자의)
            deleted_statuses = db.query(UserItemStatusDB).filter(
                UserItemStatusDB.item_id == item.item_id
            ).delete()
            deleted_counts["item_statuses"] += deleted_statuses
            
            db.delete(item)
            deleted_counts["items"] += 1
        
        # 다른 사용자가 저장한 참조 기록 삭제
        db.query(UserCatalogDB).filter(
            UserCatalogDB.original_catalog_id == catalog.catalog_id
        ).delete()
        
        db.delete(catalog)
        deleted_counts["catalogs"] += 1
    
    # 2. 사용자가 저장한 다른 사람의 카탈로그 참조 삭제
    saved_refs = db.query(UserCatalogDB).filter(
        UserCatalogDB.user_id == user_id
    ).all()
    
    for ref in saved_refs:
        # 복사본 카탈로그가 있으면 삭제
        if ref.copied_catalog_id:
            copied_catalog = db.query(CatalogDB).filter(
                CatalogDB.catalog_id == ref.copied_catalog_id
            ).first()
            
            if copied_catalog:
                # 복사본의 아이템들 삭제
                copied_items = db.query(ItemDB).filter(
                    ItemDB.catalog_id == ref.copied_catalog_id
                ).all()
                
                for item in copied_items:
                    db.query(UserItemStatusDB).filter(
                        UserItemStatusDB.item_id == item.item_id
                    ).delete()
                    db.delete(item)
                
                db.delete(copied_catalog)
        
        db.delete(ref)
        deleted_counts["saved_catalogs"] += 1
    
    # 3. 사용자의 모든 아이템 보유 상태 삭제
    remaining_statuses = db.query(UserItemStatusDB).filter(
        UserItemStatusDB.user_id == user_id
    ).delete()
    deleted_counts["item_statuses"] += remaining_statuses
    
    db.commit()
    
    return deleted_counts
