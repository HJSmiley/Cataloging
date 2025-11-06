import os
from sqlalchemy import create_engine, Column, String, Boolean, Text, DateTime, Integer, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.sql import func
from datetime import datetime
from app.config import settings

# SQLAlchemy 설정
engine = create_engine(settings.DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 데이터베이스 모델
class CatalogDB(Base):
    __tablename__ = "catalogs"
    
    catalog_id = Column(String, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    category = Column(String, default="미분류")
    tags = Column(JSON, default=list)
    visibility = Column(String, default="public")
    thumbnail_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

class ItemDB(Base):
    __tablename__ = "items"
    
    item_id = Column(String, primary_key=True, index=True)
    catalog_id = Column(String, index=True, nullable=False)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    image_url = Column(String, nullable=True)
    user_fields = Column(JSON, default=dict)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

class UserCatalogDB(Base):
    """사용자가 저장한 카탈로그 추적 (중복 저장 방지용)"""
    __tablename__ = "user_catalogs"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, index=True, nullable=False)
    original_catalog_id = Column(String, index=True, nullable=False)  # 원본 카탈로그 ID
    copied_catalog_id = Column(String, index=True, nullable=True)     # 복사본 카탈로그 ID
    saved_at = Column(DateTime, default=func.now())
    
    # 복합 인덱스: 한 사용자가 같은 원본 카탈로그를 중복 저장하지 않도록
    __table_args__ = (
        {'sqlite_autoincrement': True}
    )

class UserItemStatusDB(Base):
    """사용자별 아이템 보유 상태"""
    __tablename__ = "user_item_status"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, index=True, nullable=False)
    item_id = Column(String, index=True, nullable=False)
    owned = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # 복합 인덱스: 한 사용자의 한 아이템에 대해 하나의 상태만
    __table_args__ = (
        {'sqlite_autoincrement': True}
    )

async def init_db():
    """데이터베이스 테이블 생성"""
    try:
        Base.metadata.create_all(bind=engine)
        
        # 업로드 디렉토리 생성
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        
        print("SQLite 데이터베이스 초기화 완료")
    except Exception as e:
        print(f"데이터베이스 초기화 오류: {e}")

def get_db():
    """데이터베이스 세션 의존성"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()