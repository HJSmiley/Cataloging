"""
Catalog-API 데이터베이스 설정 및 모델 정의
- SQLite 데이터베이스 연결 및 세션 관리
- 카탈로그, 아이템, 사용자 관련 테이블 정의
- 데이터베이스 초기화 및 의존성 주입 함수 제공
"""
import os
from sqlalchemy import create_engine, Column, String, Boolean, Text, DateTime, Integer, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.sql import func
from datetime import datetime
from app.config import settings

# SQLAlchemy 데이터베이스 엔진 설정
# SQLite 사용, 멀티스레드 환경에서 안전하게 동작하도록 설정
engine = create_engine(settings.DATABASE_URL, connect_args={"check_same_thread": False})

# 데이터베이스 세션 팩토리 생성
# autocommit=False: 명시적 커밋 필요 (트랜잭션 안전성)
# autoflush=False: 자동 플러시 비활성화 (성능 최적화)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# SQLAlchemy ORM 베이스 클래스
Base = declarative_base()

# 데이터베이스 테이블 모델 정의

class CatalogDB(Base):
    """카탈로그 테이블 - 사용자가 생성한 수집 카탈로그 정보"""
    __tablename__ = "catalogs"
    
    catalog_id = Column(String, primary_key=True, index=True)  # UUID 기반 고유 ID
    user_id = Column(String, index=True, nullable=False)      # 카탈로그 소유자 ID (JWT에서 추출)
    title = Column(String, nullable=False)                    # 카탈로그 제목
    description = Column(Text, nullable=False)                # 카탈로그 설명
    category = Column(String, default="미분류")                # 카테고리 분류
    tags = Column(JSON, default=list)                         # 태그 배열 (JSON 형태)
    visibility = Column(String, default="public")             # 공개 설정 (public/private)
    thumbnail_url = Column(String, nullable=True)             # 썸네일 이미지 URL
    created_at = Column(DateTime, default=func.now())         # 생성 시간
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())  # 수정 시간

class ItemDB(Base):
    """아이템 테이블 - 카탈로그에 속한 개별 수집품 정보"""
    __tablename__ = "items"
    
    item_id = Column(String, primary_key=True, index=True)    # UUID 기반 고유 ID
    catalog_id = Column(String, index=True, nullable=False)   # 소속 카탈로그 ID (외래키 역할)
    name = Column(String, nullable=False)                     # 아이템명
    description = Column(Text, nullable=False)                # 아이템 설명
    image_url = Column(String, nullable=True)                 # 아이템 이미지 URL
    user_fields = Column(JSON, default=dict)                  # 사용자 정의 필드 (JSON 형태)
    created_at = Column(DateTime, default=func.now())         # 생성 시간
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())  # 수정 시간

class UserCatalogDB(Base):
    """사용자 카탈로그 저장 테이블 - 다른 사용자의 카탈로그를 내 컬렉션에 저장"""
    __tablename__ = "user_catalogs"
    
    id = Column(Integer, primary_key=True, autoincrement=True)        # 자동 증가 ID
    user_id = Column(String, index=True, nullable=False)              # 저장한 사용자 ID
    original_catalog_id = Column(String, index=True, nullable=False)  # 원본 카탈로그 ID
    copied_catalog_id = Column(String, index=True, nullable=True)     # 복사본 카탈로그 ID (내 컬렉션용)
    saved_at = Column(DateTime, default=func.now())                   # 저장 시간
    
    # 복합 인덱스: 한 사용자가 같은 원본 카탈로그를 중복 저장하지 않도록 제약
    __table_args__ = (
        {'sqlite_autoincrement': True}
    )

class UserItemStatusDB(Base):
    """사용자 아이템 보유 상태 테이블 - 각 아이템의 수집 여부 추적"""
    __tablename__ = "user_item_status"
    
    id = Column(Integer, primary_key=True, autoincrement=True)        # 자동 증가 ID
    user_id = Column(String, index=True, nullable=False)              # 사용자 ID
    item_id = Column(String, index=True, nullable=False)              # 아이템 ID
    owned = Column(Boolean, default=False)                            # 보유 여부 (True: 보유, False: 미보유)
    created_at = Column(DateTime, default=func.now())                 # 생성 시간
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())  # 수정 시간
    
    # 복합 인덱스: 한 사용자의 한 아이템에 대해 하나의 상태만 존재하도록 제약
    __table_args__ = (
        {'sqlite_autoincrement': True}
    )

async def init_db():
    """
    데이터베이스 초기화 함수
    - 서버 시작 시 호출되어 모든 테이블 생성
    - 파일 업로드 디렉토리도 함께 생성
    """
    try:
        # SQLAlchemy 메타데이터를 기반으로 모든 테이블 생성
        Base.metadata.create_all(bind=engine)
        
        # 이미지 업로드용 디렉토리 생성 (존재하지 않는 경우)
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        
        print("✅ SQLite 데이터베이스 초기화 완료")
    except Exception as e:
        print(f"❌ 데이터베이스 초기화 오류: {e}")

def get_db():
    """
    데이터베이스 세션 의존성 주입 함수
    - FastAPI의 Depends()와 함께 사용
    - 요청 처리 후 자동으로 세션 종료하여 리소스 관리
    """
    db = SessionLocal()  # 새 데이터베이스 세션 생성
    try:
        yield db  # 라우터 함수에 세션 전달
    finally:
        db.close()  # 요청 완료 후 세션 정리