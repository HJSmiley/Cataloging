"""
사용자 관련 API 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models.database import get_db
from app.core.security import get_current_user_id
from app.crud import user as user_crud

router = APIRouter()


@router.delete("/me")
async def delete_user_data(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    현재 사용자의 모든 카탈로그 데이터 삭제 (회원 탈퇴 시)
    - JWT 토큰으로 사용자 인증
    - 사용자가 생성한 모든 카탈로그 및 아이템 삭제
    - 사용자가 저장한 카탈로그 참조 삭제
    """
    try:
        deleted_counts = user_crud.delete_user_data(db, user_id)
        
        return {
            "message": "사용자 데이터가 성공적으로 삭제되었습니다",
            "deleted": deleted_counts
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터 삭제 실패: {str(e)}")
