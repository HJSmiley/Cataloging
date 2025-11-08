from pydantic import BaseModel, Field
from typing import Dict, Optional

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
