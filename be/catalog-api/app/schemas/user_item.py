from pydantic import BaseModel, Field

class UserItemStatus(BaseModel):
    user_id: str = Field(..., description="사용자 ID")
    item_id: str = Field(..., description="아이템 ID")
    owned: bool = Field(..., description="보유 여부")
    created_at: str = Field(..., description="생성일")
    updated_at: str = Field(..., description="수정일")

    class Config:
        from_attributes = True
