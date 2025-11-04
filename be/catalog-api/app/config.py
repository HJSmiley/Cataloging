import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # 데이터베이스 설정
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./catalog.db")
    
    # JWT 설정 (Spring Boot와 동일한 설정 사용)
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "mySecretKey1234567890123456789012345678901234567890")
    JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_EXPIRE_MINUTES = 60 * 24  # 24시간 (Spring Boot와 동일)
    
    # 파일 업로드 설정
    UPLOAD_DIR = os.getenv("UPLOAD_DIR", "./uploads")

settings = Settings()