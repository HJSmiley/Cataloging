from fastapi import HTTPException, Depends, Header
from typing import Optional
import jwt
from app.config import settings

async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    """JWT 토큰에서 사용자 ID 추출 (임시 구현)"""
    
    # 개발 단계에서는 헤더에서 직접 user_id를 받음
    # 실제 운영에서는 JWT 토큰을 검증해야 함
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        
        # JWT 토큰 검증 (실제 구현)
        try:
            payload = jwt.decode(
                token, 
                settings.JWT_SECRET_KEY, 
                algorithms=[settings.JWT_ALGORITHM]
            )
            user_id = payload.get("sub")
            if user_id is None:
                raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
            return user_id
        except jwt.PyJWTError:
            raise HTTPException(status_code=401, detail="토큰 검증에 실패했습니다")
    
    # 개발용 임시 처리: X-User-ID 헤더 사용
    user_id_header = None
    if authorization and not authorization.startswith("Bearer "):
        user_id_header = authorization
    
    if user_id_header:
        return user_id_header
    
    # 토큰이 없는 경우
    raise HTTPException(
        status_code=401, 
        detail="인증이 필요합니다. Authorization 헤더에 JWT 토큰 또는 개발용 사용자 ID를 포함해주세요."
    )

def create_access_token(user_id: str) -> str:
    """JWT 액세스 토큰 생성"""
    from datetime import datetime, timedelta
    
    expire = datetime.utcnow() + timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
    payload = {
        "sub": user_id,
        "exp": expire,
        "iat": datetime.utcnow()
    }
    
    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token

def verify_token(token: str) -> str:
    """JWT 토큰 검증 및 사용자 ID 반환"""
    try:
        # 디버깅을 위한 로그 추가
        print(f"🔍 토큰 검증 시도: {token[:50]}...")
        print(f"🔑 사용 중인 시크릿: {settings.JWT_SECRET_KEY[:20]}...")
        print(f"🔧 알고리즘: {settings.JWT_ALGORITHM}")
        
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET_KEY, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        print(f"✅ 토큰 디코딩 성공: {payload}")
        
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
        return user_id
    except jwt.ExpiredSignatureError as e:
        print(f"❌ 토큰 만료: {e}")
        raise HTTPException(status_code=401, detail="토큰이 만료되었습니다")
    except jwt.PyJWTError as e:
        print(f"❌ JWT 오류: {e}")
        raise HTTPException(status_code=401, detail=f"토큰 검증에 실패했습니다: {str(e)}")