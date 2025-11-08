from pydantic import BaseModel, Field
from app.schemas.catalog import Catalog

class UserCatalogSave(BaseModel):
    catalog_id: str = Field(..., description="저장할 카탈로그 ID")

class UserCatalog(BaseModel):
    user_id: str = Field(..., description="사용자 ID")
    catalog_id: str = Field(..., description="카탈로그 ID")
    saved_at: str = Field(..., description="저장일")
    catalog: Catalog = Field(..., description="카탈로그 정보")

    class Config:
        from_attributes = True
