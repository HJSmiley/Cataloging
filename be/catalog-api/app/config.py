"""
Catalog-API 설정 파일
- 환경변수 기반 설정 관리
- JWT 토큰 설정 (user-api와 동일한 시크릿 키 사용)
- 데이터베이스 및 파일 업로드 경로 설정
- CORS, 로깅, 정적 파일 서빙 설정
"""
import os
import logging
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
    
    # CORS 설정 - Flutter 앱에서 API 호출 허용
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")  # 쉼표로 구분된 도메인 목록
    CORS_CREDENTIALS = os.getenv("CORS_CREDENTIALS", "true").lower() == "true"
    CORS_METHODS = os.getenv("CORS_METHODS", "*").split(",")
    CORS_HEADERS = os.getenv("CORS_HEADERS", "*").split(",")
    
    # 로깅 설정 - API 통신 로깅
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE = os.getenv("LOG_FILE", "api_communication.log")
    LOG_FORMAT = os.getenv("LOG_FORMAT", "%(asctime)s - %(name)s - %(levelname)s - %(message)s")

# 전역 설정 인스턴스 - 다른 모듈에서 import하여 사용
settings = Settings()

def setup_logging():
    """로깅 설정 초기화"""
    logging.basicConfig(
        level=getattr(logging, settings.LOG_LEVEL),
        format=settings.LOG_FORMAT,
        handlers=[
            logging.FileHandler(settings.LOG_FILE),  # 파일 로깅
            logging.StreamHandler()                   # 콘솔 로깅
        ]
    )
    return logging.getLogger("API_COMMUNICATION")