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
from app.config import get_kst_now
from sqlalchemy import and_

from app.models import Item, ItemCreate, ItemUpdate, ErrorResponse
from app.database import get_db, CatalogDB, ItemDB, UserItemStatusDB
from app.utils import get_current_user_id, get_optional_user_id

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
        # 카탈로그 존재 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        # 공개 카탈로그가 아니면 소유자 확인 필요
        if catalog_record.visibility != "public":
            if not user_id:
                raise HTTPException(status_code=401, detail="인증이 필요합니다")
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
            # 사용자별 보유 상태 조회 (로그인한 경우만)
            owned = False
            if user_id:
                user_status = db.query(UserItemStatusDB).filter(
                    and_(
                        UserItemStatusDB.user_id == user_id,
                        UserItemStatusDB.item_id == item_record.item_id
                    )
                ).first()
                owned = user_status.owned if user_status else False
            
            item_data = {
                "item_id": item_record.item_id,
                "catalog_id": item_record.catalog_id,
                "name": item_record.name,
                "description": item_record.description,
                "image_url": item_record.image_url,
                "owned": owned,  # 사용자별 보유 상태
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
        
        # 사용자별 보유 상태 조회
        user_status = db.query(UserItemStatusDB).filter(
            and_(
                UserItemStatusDB.user_id == user_id,
                UserItemStatusDB.item_id == item_id
            )
        ).first()
        owned = user_status.owned if user_status else False
        
        item_data = {
            "item_id": item_record.item_id,
            "catalog_id": item_record.catalog_id,
            "name": item_record.name,
            "description": item_record.description,
            "image_url": item_record.image_url,
            "owned": owned,  # 사용자별 보유 상태
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
            user_fields=item.user_fields
        )
        
        db.add(item_record)
        db.flush()  # item_id 생성을 위해 flush
        
        # 아이템 생성 시 생성자에게 기본 상태(미보유) 부여
        user_item_status = UserItemStatusDB(
            user_id=user_id,
            item_id=item_id,
            owned=False  # 기본값: 미보유
        )
        db.add(user_item_status)
        db.commit()
        db.refresh(item_record)
        db.refresh(user_item_status)
        
        item_data = {
            "item_id": item_record.item_id,
            "catalog_id": item_record.catalog_id,
            "name": item_record.name,
            "description": item_record.description,
            "image_url": item_record.image_url,
            "owned": user_item_status.owned,  # 생성자의 보유 상태
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
            
            item_record.updated_at = get_kst_now()
            db.commit()
            db.refresh(item_record)
        
        # 업데이트된 아이템 조회
        return await get_item(item_id, user_id, db)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.patch("/{item_id}/toggle-owned", response_model=Item)
async def toggle_item_owned(
    item_id: str,
    user_id: str = Depends(get_current_user_id),  # JWT 토큰에서 user_id 추출
    db: Session = Depends(get_db)
):
    """
    아이템 보유 여부 토글
    - Flutter ApiService.toggleItemOwned()에서 호출
    - 체크박스 클릭 시 owned 상태를 True ↔ False로 변경
    - 변경 후 카탈로그 수집률 자동 업데이트 트리거
    """
    try:
        # 1단계: 아이템 존재 여부 확인
        item_record = db.query(ItemDB).filter(ItemDB.item_id == item_id).first()
        
        if not item_record:
            raise HTTPException(status_code=404, detail="아이템을 찾을 수 없습니다")
        
        # 2단계: 사용자의 아이템 상태 조회 또는 생성
        user_status = db.query(UserItemStatusDB).filter(
            and_(
                UserItemStatusDB.user_id == user_id,
                UserItemStatusDB.item_id == item_id
            )
        ).first()
        
        if not user_status:
            # 상태가 없으면 새로 생성 (기본값: False)
            user_status = UserItemStatusDB(
                user_id=user_id,
                item_id=item_id,
                owned=False
            )
            db.add(user_status)
            db.flush()  # ID 생성을 위해 flush
        
        # 3단계: 보유 상태 토글
        user_status.owned = not user_status.owned
        user_status.updated_at = get_kst_now()
        
        # 4단계: 데이터베이스에 변경사항 저장
        db.commit()
        db.refresh(user_status)
        
        # 5단계: 업데이트된 아이템 정보 반환
        item_data = {
            "item_id": item_record.item_id,
            "catalog_id": item_record.catalog_id,
            "name": item_record.name,
            "description": item_record.description,
            "image_url": item_record.image_url,
            "owned": user_status.owned,  # 업데이트된 사용자별 보유 상태
            "user_fields": item_record.user_fields or {},
            "created_at": item_record.created_at.isoformat(),
            "updated_at": item_record.updated_at.isoformat()
        }
        
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