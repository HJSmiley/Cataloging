"""
Catalog-API 유틸리티 함수들
- JWT 토큰 검증 및 사용자 인증
- user-api(Spring Boot)에서 발급한 JWT 토큰 호환성 보장
- Authorization 헤더에서 Bearer 토큰 추출 및 검증
"""
from fastapi import HTTPException, Depends, Header
from typing import Optional
import jwt
from app.config import settings

async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    """
    JWT 토큰에서 사용자 ID 추출 (필수 인증)
    - Flutter ApiService에서 전송한 Authorization 헤더 처리
    - user-api에서 발급한 JWT 토큰을 동일한 시크릿 키로 검증
    - 인증 실패 시 401 에러 반환
    """
    
    print(f"🔍 Authorization 헤더: {authorization}")
    
    # 1단계: Authorization 헤더 존재 여부 확인
    if not authorization:
        print("❌ Authorization 헤더가 없음")
        raise HTTPException(status_code=401, detail="Authorization 헤더가 필요합니다")
    
    # 2단계: Bearer 토큰 형식 확인
    if not authorization.startswith("Bearer "):
        print(f"❌ 잘못된 Authorization 형식: {authorization}")
        raise HTTPException(status_code=401, detail="Bearer 토큰이 필요합니다")
    
    # 3단계: 토큰 추출
    token = authorization.split(" ")[1]
    print(f"🔑 JWT 토큰: {token[:50]}...")
    
    # 4단계: JWT 토큰 검증 및 사용자 ID 추출
    try:
        print(f"🔧 JWT 시크릿: {settings.JWT_SECRET_KEY[:20]}...")
        print(f"🔧 JWT 알고리즘: {settings.JWT_ALGORITHM}")
        
        # user-api와 동일한 시크릿 키와 알고리즘으로 토큰 디코딩
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET_KEY, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        print(f"✅ JWT 페이로드: {payload}")
        
        # 5단계: 사용자 ID 추출 (JWT의 "sub" 클레임)
        user_id = payload.get("sub")
        if user_id is None:
            print("❌ JWT에 sub 필드가 없음")
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
        
        print(f"👤 추출된 사용자 ID: {user_id} (타입: {type(user_id)})")
        
        # 6단계: 사용자 ID를 문자열로 변환하여 반환
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
    """
    JWT 액세스 토큰 생성 (개발/테스트용)
    - user-api와 동일한 형식으로 토큰 생성
    - 실제 운영에서는 user-api에서만 토큰 발급
    - 한국 시간(KST) 기준으로 토큰 생성
    """
    from datetime import timedelta
    from app.config import get_kst_now
    
    now = get_kst_now()
    expire = now + timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
    payload = {
        "sub": user_id,        # 사용자 ID (Subject)
        "exp": expire,         # 만료 시간 (Expiration)
        "iat": now             # 발급 시간 (Issued At)
    }
    
    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token

async def get_optional_user_id(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """
    JWT 토큰에서 사용자 ID 추출 (선택적 인증)
    - 공개 카탈로그 조회 시 사용 (로그인 선택사항)
    - 토큰이 없거나 유효하지 않아도 None 반환 (에러 발생 안함)
    - 토큰이 유효하면 사용자별 맞춤 정보 제공
    """
    
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        
        try:
            payload = jwt.decode(
                token, 
                settings.JWT_SECRET_KEY, 
                algorithms=[settings.JWT_ALGORITHM]
            )
            user_id = payload.get("sub")
            return str(user_id) if user_id else None
        except jwt.PyJWTError:
            return None  # 토큰 오류 시 None 반환 (에러 발생 안함)
    
    return None

def verify_token(token: str) -> str:
    """
    JWT 토큰 검증 및 사용자 ID 반환 (직접 토큰 검증용)
    - 토큰 문자열을 직접 받아서 검증
    - 내부적으로 사용하는 헬퍼 함수
    """
    try:
        # 디버깅을 위한 로그 추가
        print(f"🔍 토큰 검증 시도: {token[:50]}...")
        print(f"🔑 사용 중인 시크릿: {settings.JWT_SECRET_KEY[:20]}...")
        print(f"🔧 알고리즘: {settings.JWT_ALGORITHM}")
        
        # user-api와 동일한 설정으로 토큰 디코딩
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET_KEY, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        print(f"✅ 토큰 디코딩 성공: {payload}")
        
        # 사용자 ID 추출
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
        return str(user_id)
        
    except jwt.ExpiredSignatureError as e:
        print(f"❌ 토큰 만료: {e}")
        raise HTTPException(status_code=401, detail="토큰이 만료되었습니다")
    except jwt.PyJWTError as e:
        print(f"❌ JWT 오류: {e}")
        raise HTTPException(status_code=401, detail=f"토큰 검증에 실패했습니다: {str(e)}")