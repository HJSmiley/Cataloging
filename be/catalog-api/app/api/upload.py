from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from datetime import datetime
import uuid
import os
from app.core.config import get_kst_now, settings
import shutil
from pathlib import Path

from app.schemas import UploadResponse, ErrorResponse
from app.core.security import get_current_user_id

router = APIRouter()

@router.post("/file", response_model=UploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id)
):
    """파일 업로드 (로컬 파일 시스템)"""
    try:
        # 파일 확장자 검증
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
        file_extension = Path(file.filename).suffix.lower()
        
        if file_extension not in allowed_extensions:
            raise HTTPException(
                status_code=400, 
                detail=f"지원하지 않는 파일 형식입니다. 허용된 형식: {', '.join(allowed_extensions)}"
            )
        
        # 파일명 생성 (사용자ID/년월일/UUID.확장자) - 한국 시간 기준
        now = get_kst_now()
        date_prefix = now.strftime("%Y/%m/%d")
        file_id = str(uuid.uuid4())
        
        # 저장 경로 생성
        upload_dir = Path(settings.UPLOAD_DIR) / "images" / user_id / date_prefix
        upload_dir.mkdir(parents=True, exist_ok=True)
        
        # 파일 저장
        filename = f"{file_id}{file_extension}"
        file_path = upload_dir / filename
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # 파일 URL 생성 (상대 경로)
        file_url = f"/uploads/images/{user_id}/{date_prefix}/{filename}"
        
        return UploadResponse(
            upload_url="",  # 로컬 업로드에서는 사용하지 않음
            file_url=file_url
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"파일 업로드 오류: {e}")

@router.delete("/file")
async def delete_file(
    file_url: str,
    user_id: str = Depends(get_current_user_id)
):
    """로컬 파일 삭제"""
    try:
        # URL 검증
        if not file_url.startswith(f"/uploads/images/{user_id}/"):
            raise HTTPException(status_code=403, detail="파일 삭제 권한이 없습니다")
        
        # 파일 경로 생성
        file_path = Path(settings.UPLOAD_DIR) / file_url.lstrip("/uploads/")
        
        # 파일 존재 확인 및 삭제
        if file_path.exists():
            file_path.unlink()
            return {"message": "파일이 성공적으로 삭제되었습니다"}
        else:
            raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"파일 삭제 오류: {e}")

# 정적 파일 서빙을 위한 엔드포인트 (개발용)
@router.get("/images/{user_id}/{year}/{month}/{day}/{filename}")
async def serve_image(
    user_id: str,
    year: str,
    month: str,
    day: str,
    filename: str
):
    """업로드된 이미지 파일 서빙"""
    try:
        file_path = Path(settings.UPLOAD_DIR) / "images" / user_id / year / month / day / filename
        
        if not file_path.exists():
            raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다")
        
        from fastapi.responses import FileResponse
        return FileResponse(file_path)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"파일 서빙 오류: {e}")