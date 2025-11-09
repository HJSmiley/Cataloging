from pydantic import BaseModel, Field
from typing import List, Optional

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
    creator_nickname: Optional[str] = Field(default=None, description="생성자 닉네임 (공개 카탈로그 조회 시)")
    is_saved: Optional[bool] = Field(default=False, description="저장 여부 (공개 카탈로그 조회 시)")

    class Config:
        from_attributes = True
