"""
Catalog-API 메인 서버 파일 (Python FastAPI)
- 카탈로그 및 아이템 관리 API 서버
- Flutter 앱에서 데이터 CRUD 요청을 처리
- JWT 토큰 기반 인증으로 사용자별 데이터 관리
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.routers import catalogs, items, upload
from app.database import init_db
from app.config import settings, setup_logging
from app.middleware import log_requests_middleware
import os

# API 통신 로깅 설정
logger = setup_logging()

# FastAPI 앱 인스턴스 생성
app = FastAPI(
    title="카탈로그 API",
    description="수집가를 위한 카탈로그 및 아이템 관리 API",
    version="1.0.0"
)

# HTTP 요청/응답 로깅 미들웨어 - 모든 API 호출을 자동으로 기록
app.middleware("http")(log_requests_middleware)

# CORS 미들웨어 설정 - Flutter 앱에서 API 호출 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=settings.CORS_CREDENTIALS,
    allow_methods=settings.CORS_METHODS,
    allow_headers=settings.CORS_HEADERS,
)

# 정적 파일 서빙 설정 - 업로드된 이미지 파일 제공
if os.path.exists(settings.UPLOAD_DIR):
    app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# API 라우터 등록 - 각 기능별로 분리된 라우터들을 메인 앱에 연결
app.include_router(catalogs.router, prefix="/api/catalogs", tags=["catalogs"])  # 카탈로그 CRUD
app.include_router(items.router, prefix="/api/items", tags=["items"])           # 아이템 CRUD
app.include_router(upload.router, prefix="/api/upload", tags=["upload"])        # 파일 업로드

# 사용자 카탈로그 관리 라우터 추가
from app.routers import user_catalogs
app.include_router(user_catalogs.router, prefix="/api/user-catalogs", tags=["user-catalogs"])  # 사용자 카탈로그 관리

# 서버 시작 시 실행되는 이벤트 핸들러
@app.on_event("startup")
async def startup_event():
    """앱 시작 시 SQLite 데이터베이스 테이블 초기화"""
    await init_db()  # database.py의 init_db() 함수 호출

# 기본 엔드포인트들
@app.get("/")
async def root():
    """서버 상태 확인용 루트 엔드포인트"""
    return {"message": "카탈로그 API 서버가 실행 중입니다"}

@app.get("/health")
async def health_check():
    """헬스체크 엔드포인트 - Flutter 앱에서 서버 연결 테스트용"""
    return {"status": "healthy"}

# 서버 실행 설정 - 개발 환경에서 직접 실행 시
if __name__ == "__main__":
    import uvicorn
    # uvicorn ASGI 서버로 FastAPI 앱 실행
    # host="0.0.0.0": 모든 네트워크 인터페이스에서 접근 허용
    # port=8000: 포트 8000에서 서비스 (Flutter에서 localhost:8000으로 접근)
    uvicorn.run(app, host="0.0.0.0", port=8002)