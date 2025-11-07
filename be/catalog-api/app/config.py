"""
Catalog-API 설정 파일
- 환경변수 기반 설정 관리
- JWT 토큰 설정 (user-api와 동일한 시크릿 키 사용)
- 데이터베이스 및 파일 업로드 경로 설정
"""
import os
from dotenv import load_dotenv

# .env 파일에서 환경변수 로드
load_dotenv()

class Settings:
    """애플리케이션 설정 클래스"""
    
    # SQLite 데이터베이스 설정 - 로컬 파일 기반 DB
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./catalog.db")
    
    # JWT 토큰 설정 - user-api(Spring Boot)와 동일한 설정으로 토큰 호환성 보장
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "mySecretKey1234567890123456789012345678901234567890")
    JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")  # HMAC SHA-256 알고리즘
    JWT_EXPIRE_MINUTES = 60 * 24  # 24시간 토큰 유효기간 (Spring Boot와 동일)
    
    # 파일 업로드 설정 - 이미지 파일 저장 경로
    UPLOAD_DIR = os.getenv("UPLOAD_DIR", "./uploads")

# 전역 설정 인스턴스 - 다른 모듈에서 import하여 사용
settings = Settings()