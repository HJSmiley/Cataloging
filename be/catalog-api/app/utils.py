from fastapi import HTTPException, Depends, Header
from typing import Optional
import jwt
from app.config import settings

async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    """JWT 토큰에서 사용자 ID 추출"""
    
    print(f"🔍 Authorization 헤더: {authorization}")
    
    if not authorization:
        print("❌ Authorization 헤더가 없음")
        raise HTTPException(status_code=401, detail="Authorization 헤더가 필요합니다")
    
    if not authorization.startswith("Bearer "):
        print(f"❌ 잘못된 Authorization 형식: {authorization}")
        raise HTTPException(status_code=401, detail="Bearer 토큰이 필요합니다")
    
    token = authorization.split(" ")[1]
    print(f"🔑 JWT 토큰: {token[:50]}...")
    
    # JWT 토큰 검증
    try:
        print(f"🔧 JWT 시크릿: {settings.JWT_SECRET_KEY[:20]}...")
        print(f"🔧 JWT 알고리즘: {settings.JWT_ALGORITHM}")
        
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET_KEY, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        print(f"✅ JWT 페이로드: {payload}")
        
        user_id = payload.get("sub")
        if user_id is None:
            print("❌ JWT에 sub 필드가 없음")
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
        
        print(f"👤 추출된 사용자 ID: {user_id} (타입: {type(user_id)})")
        
        # 사용자 ID를 문자열로 변환
        user_id_str = str(user_id)
        print(f"👤 최종 사용자 ID: {user_id_str}")
        
        return user_id_str
        
    except jwt.ExpiredSignatureError as e:
        print(f"❌ JWT 토큰 만료: {e}")
        raise HTTPException(status_code=401, detail="토큰이 만료되었습니다")
    except jwt.InvalidTokenError as e:
        print(f"❌ JWT 토큰 무효: {e}")
        raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
    except Exception as e:
        print(f"❌ JWT 처리 오류: {e}")
        raise HTTPException(status_code=401, detail="토큰 처리 중 오류가 발생했습니다")

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

async def get_optional_user_id(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """JWT 토큰에서 사용자 ID 추출 (선택적, 인증 실패 시 None 반환)"""
    
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        
        try:
            payload = jwt.decode(
                token, 
                settings.JWT_SECRET_KEY, 
                algorithms=[settings.JWT_ALGORITHM]
            )
            user_id = payload.get("sub")
            return user_id
        except jwt.PyJWTError:
            return None
    
    return None

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