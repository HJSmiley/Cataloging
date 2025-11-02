import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # 데이터베이스 설정
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./catalog.db")
    
    # JWT 설정
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
    JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_EXPIRE_MINUTES = 60 * 24 * 7  # 7일
    
    # 파일 업로드 설정
    UPLOAD_DIR = os.getenv("UPLOAD_DIR", "./uploads")

settings = Settings()