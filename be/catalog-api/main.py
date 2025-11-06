"""
Catalog-API 메인 서버 파일 (Python FastAPI)
- 카탈로그 및 아이템 관리 API 서버
- Flutter 앱에서 데이터 CRUD 요청을 처리
- JWT 토큰 기반 인증으로 사용자별 데이터 관리
"""
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.routers import catalogs, items, upload
from app.database import init_db
from app.config import settings
import os
import time
import json
import logging

# API 통신 로깅 설정 - 모든 요청/응답을 파일과 콘솔에 기록
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('api_communication.log'),  # 파일 로깅
        logging.StreamHandler()                        # 콘솔 로깅
    ]
)
logger = logging.getLogger("API_COMMUNICATION")

# FastAPI 앱 인스턴스 생성
app = FastAPI(
    title="카탈로그 API",
    description="수집가를 위한 카탈로그 및 아이템 관리 API",
    version="1.0.0"
)

# HTTP 요청/응답 로깅 미들웨어 - 모든 API 호출을 자동으로 기록
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()  # 요청 처리 시간 측정 시작
    
    # 1단계: 들어오는 요청 정보 로깅
    body = b""
    if request.method in ["POST", "PUT", "PATCH"]:
        body = await request.body()  # 요청 바디 읽기 (GET은 바디 없음)
    
    logger.info(f"🔵 REQUEST: {request.method} {request.url}")
    logger.info(f"   Headers: {dict(request.headers)}")  # JWT 토큰 등 헤더 정보
    if body:
        # Content-Type 확인
        content_type = request.headers.get("content-type", "")
        
        if "multipart/form-data" in content_type:
            # 파일 업로드의 경우 바이너리 데이터가 포함되므로 크기만 로깅
            logger.info(f"   Body: [Multipart form data, size: {len(body)} bytes]")
        else:
            try:
                # JSON 바디를 예쁘게 포맷팅하여 로깅
                body_json = json.loads(body.decode('utf-8'))
                logger.info(f"   Body: {json.dumps(body_json, ensure_ascii=False, indent=2)}")
            except UnicodeDecodeError:
                # 바이너리 데이터인 경우
                logger.info(f"   Body: [Binary data, size: {len(body)} bytes]")
            except json.JSONDecodeError:
                # JSON이 아닌 텍스트 데이터인 경우
                try:
                    logger.info(f"   Body: {body.decode('utf-8')}")
                except UnicodeDecodeError:
                    logger.info(f"   Body: [Non-UTF8 data, size: {len(body)} bytes]")
    
    # 2단계: 실제 요청 처리 (라우터 함수 호출)
    response = await call_next(request)
    
    # 3단계: 응답 정보 로깅
    process_time = time.time() - start_time  # 처리 시간 계산
    logger.info(f"🔴 RESPONSE: {response.status_code} ({process_time:.3f}s)")
    
    return response

# CORS 미들웨어 설정 - Flutter 앱에서 API 호출 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # 개발 환경용 모든 도메인 허용 (프로덕션에서는 특정 도메인만)
    allow_credentials=True,   # 쿠키, Authorization 헤더 허용
    allow_methods=["*"],      # 모든 HTTP 메서드 허용 (GET, POST, PUT, DELETE 등)
    allow_headers=["*"],      # 모든 헤더 허용 (JWT Authorization 헤더 포함)
)

# 정적 파일 서빙 설정 - 업로드된 이미지 파일 제공
if os.path.exists(settings.UPLOAD_DIR):
    # /uploads 경로로 업로드된 파일들에 접근 가능
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