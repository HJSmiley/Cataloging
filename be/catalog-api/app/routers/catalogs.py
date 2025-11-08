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
from app.config import get_kst_now
from sqlalchemy import func, and_

from app.models import Catalog, CatalogCreate, CatalogUpdate, ErrorResponse
from app.database import get_db, CatalogDB, ItemDB, UserItemStatusDB
from app.utils import get_current_user_id

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
        # 1단계: 현재 사용자의 카탈로그만 조회하는 기본 쿼리
        query = db.query(CatalogDB).filter(CatalogDB.user_id == user_id)
        
        # 2단계: 선택적 필터 적용
        if category:
            query = query.filter(CatalogDB.category == category)
        if visibility:
            query = query.filter(CatalogDB.visibility == visibility)
        
        catalog_records = query.all()  # SQLite에서 카탈로그 레코드들 조회
        
        catalogs = []
        for catalog_record in catalog_records:
            # 3단계: 각 카탈로그의 아이템 통계 계산 (사용자별 수집률)
            items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_record.catalog_id).all()
            item_count = len(items)                                    # 총 아이템 수
            
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
            
            completion_rate = (owned_count / item_count * 100) if item_count > 0 else 0  # 사용자별 수집률
            
            # 4단계: 응답용 카탈로그 데이터 구성
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
                "completion_rate": round(completion_rate, 2)  # 소수점 2자리까지
            }
            
            catalogs.append(Catalog(**catalog_data))
        
        return catalogs  # Flutter CatalogProvider로 카탈로그 목록 반환
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")

@router.get("/public", response_model=List[Catalog])
async def get_public_catalogs(
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
        # 1단계: 공개 카탈로그만 조회하는 기본 쿼리
        query = db.query(CatalogDB).filter(
            CatalogDB.visibility == "public"  # 공개 카탈로그만
        )
        
        # 로그인한 사용자가 있으면 자신의 카탈로그 제외
        if user_id:
            query = query.filter(CatalogDB.user_id != user_id)
        
        # 2단계: 선택적 필터 적용
        if category:
            query = query.filter(CatalogDB.category == category)
        
        # 3단계: 시간순 정렬 (최신순)
        catalog_records = query.order_by(CatalogDB.created_at.desc()).all()
        
        catalogs = []
        for catalog_record in catalog_records:
            # 4단계: 각 카탈로그의 아이템 통계 계산 (공개 카탈로그는 원작자 기준)
            items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_record.catalog_id).all()
            item_count = len(items)                                    # 총 아이템 수
            
            # 원작자의 보유 아이템 수 계산 (공개 카탈로그 표시용)
            owned_count = 0
            if items:
                item_ids = [item.item_id for item in items]
                user_statuses = db.query(UserItemStatusDB).filter(
                    and_(
                        UserItemStatusDB.user_id == catalog_record.user_id,  # 원작자 기준
                        UserItemStatusDB.item_id.in_(item_ids),
                        UserItemStatusDB.owned == True
                    )
                ).all()
                owned_count = len(user_statuses)
            
            completion_rate = (owned_count / item_count * 100) if item_count > 0 else 0  # 원작자 기준 수집률
            
            # 5단계: 응답용 카탈로그 데이터 구성
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
                "completion_rate": round(completion_rate, 2)  # 소수점 2자리까지
            }
            
            catalogs.append(Catalog(**catalog_data))
        
        return catalogs  # Flutter ExploreScreen으로 공개 카탈로그 목록 반환 (인증 불필요)
        
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
        # 1단계: 카탈로그 존재 여부 확인
        catalog_record = db.query(CatalogDB).filter(CatalogDB.catalog_id == catalog_id).first()
        
        if not catalog_record:
            raise HTTPException(status_code=404, detail="카탈로그를 찾을 수 없습니다")
        
        # 2단계: 접근 권한 확인 (공개 카탈로그는 누구나 접근 가능)
        if catalog_record.visibility != "public" and catalog_record.user_id != user_id:
            raise HTTPException(status_code=403, detail="접근 권한이 없습니다")
        
        # 3단계: 실시간 아이템 통계 계산 (사용자별 최신 수집률 반영)
        items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).all()
        item_count = len(items)                                    # 총 아이템 수
        
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
        
        completion_rate = (owned_count / item_count * 100) if item_count > 0 else 0  # 사용자별 수집률
        
        # 4단계: 최신 정보로 카탈로그 데이터 구성
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
            "completion_rate": round(completion_rate, 2)  # 업데이트된 수집률
        }
        
        return Catalog(**catalog_data)  # Flutter로 최신 카탈로그 정보 반환
        
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
            
            catalog_record.updated_at = get_kst_now()
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
        
        # 연관된 아이템들과 사용자 아이템 상태 삭제
        items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).all()
        for item in items:
            # 아이템 상태 삭제
            db.query(UserItemStatusDB).filter(UserItemStatusDB.item_id == item.item_id).delete()
            # 아이템 삭제
            db.delete(item)
        
        # 저장된 카탈로그(복사본)인 경우 원본 참조 기록도 삭제
        from app.database import UserCatalogDB
        user_catalog_ref = db.query(UserCatalogDB).filter(
            and_(
                UserCatalogDB.user_id == user_id,
                UserCatalogDB.copied_catalog_id == catalog_id
            )
        ).first()
        
        if user_catalog_ref:
            db.delete(user_catalog_ref)
        
        # 카탈로그 삭제
        db.delete(catalog_record)
        db.commit()
        
        return {"message": "카탈로그가 성공적으로 삭제되었습니다"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 오류: {e}")