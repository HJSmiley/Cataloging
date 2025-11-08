from pydantic import BaseModel, Field
from typing import Optional

class UploadResponse(BaseModel):
    upload_url: str = Field(..., description="S3 업로드 URL")
    file_url: str = Field(..., description="업로드 후 파일 접근 URL")

class ErrorResponse(BaseModel):
    error: str = Field(..., description="오류 메시지")
    detail: Optional[str] = Field(default=None, description="상세 오류 정보")
