from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from datetime import datetime
import uuid

class CatalogBase(BaseModel):
    title: str = Field(..., description="카탈로그 제목")
    description: str = Field(..., description="카탈로그 설명")
    category: str = Field(default="미분류", description="카테고리")
    tags: List[str] = Field(default_factory=list, description="태그 리스트")
    visibility: str = Field(default="public", description="공개 여부 (public/private)")
    thumbnail_url: Optional[str] = Field(default=None, description="썸네일 이미지 URL")

class CatalogCreate(CatalogBase):
    pass

class CatalogUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    tags: Optional[List[str]] = None
    visibility: Optional[str] = None
    thumbnail_url: Optional[str] = None

class Catalog(CatalogBase):
    catalog_id: str = Field(..., description="카탈로그 고유 ID")
    user_id: str = Field(..., description="소유자 ID")
    created_at: str = Field(..., description="생성일")
    updated_at: str = Field(..., description="수정일")
    item_count: Optional[int] = Field(default=0, description="아이템 개수")
    owned_count: Optional[int] = Field(default=0, description="보유 아이템 개수")
    completion_rate: Optional[float] = Field(default=0.0, description="수집률")
    original_catalog_id: Optional[str] = Field(default=None, description="원본 카탈로그 ID (복사본인 경우)")

    class Config:
        from_attributes = True

class ItemBase(BaseModel):
    name: str = Field(..., description="아이템명")
    description: str = Field(..., description="아이템 설명")
    image_url: Optional[str] = Field(default=None, description="이미지 URL")
    user_fields: Dict[str, str] = Field(default_factory=dict, description="사용자 정의 필드")

class ItemCreate(ItemBase):
    catalog_id: str = Field(..., description="카탈로그 ID")

class ItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    user_fields: Optional[Dict[str, str]] = None

class Item(ItemBase):
    item_id: str = Field(..., description="아이템 고유 ID")
    catalog_id: str = Field(..., description="카탈로그 ID")
    owned: bool = Field(default=False, description="현재 사용자의 보유 여부")
    created_at: str = Field(..., description="생성일")
    updated_at: str = Field(..., description="수정일")

    class Config:
        from_attributes = True

# 새로운 모델들
class UserCatalogSave(BaseModel):
    catalog_id: str = Field(..., description="저장할 카탈로그 ID")

class UserCatalog(BaseModel):
    user_id: str = Field(..., description="사용자 ID")
    catalog_id: str = Field(..., description="카탈로그 ID")
    saved_at: str = Field(..., description="저장일")
    catalog: Catalog = Field(..., description="카탈로그 정보")

    class Config:
        from_attributes = True

class UserItemStatus(BaseModel):
    user_id: str = Field(..., description="사용자 ID")
    item_id: str = Field(..., description="아이템 ID")
    owned: bool = Field(..., description="보유 여부")
    created_at: str = Field(..., description="생성일")
    updated_at: str = Field(..., description="수정일")

    class Config:
        from_attributes = True

class UploadResponse(BaseModel):
    upload_url: str = Field(..., description="S3 업로드 URL")
    file_url: str = Field(..., description="업로드 후 파일 접근 URL")

class ErrorResponse(BaseModel):
    error: str = Field(..., description="오류 메시지")
    detail: Optional[str] = Field(default=None, description="상세 오류 정보")