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

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('api_communication.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("API_COMMUNICATION")

app = FastAPI(
    title="카탈로그 API",
    description="수집가를 위한 카탈로그 및 아이템 관리 API",
    version="1.0.0"
)

# 통신 로깅 미들웨어
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # 요청 로깅
    body = b""
    if request.method in ["POST", "PUT", "PATCH"]:
        body = await request.body()
    
    logger.info(f"🔵 REQUEST: {request.method} {request.url}")
    logger.info(f"   Headers: {dict(request.headers)}")
    if body:
        try:
            body_json = json.loads(body.decode())
            logger.info(f"   Body: {json.dumps(body_json, ensure_ascii=False, indent=2)}")
        except:
            logger.info(f"   Body: {body.decode()}")
    
    # 요청 처리
    response = await call_next(request)
    
    # 응답 로깅
    process_time = time.time() - start_time
    logger.info(f"🔴 RESPONSE: {response.status_code} ({process_time:.3f}s)")
    
    return response

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 개발 환경용, 프로덕션에서는 특정 도메인으로 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정적 파일 서빙 (업로드된 이미지)
if os.path.exists(settings.UPLOAD_DIR):
    app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# 라우터 등록
app.include_router(catalogs.router, prefix="/api/catalogs", tags=["catalogs"])
app.include_router(items.router, prefix="/api/items", tags=["items"])
app.include_router(upload.router, prefix="/api/upload", tags=["upload"])

@app.on_event("startup")
async def startup_event():
    """앱 시작 시 DynamoDB 테이블 초기화"""
    await init_db()

@app.get("/")
async def root():
    return {"message": "카탈로그 API 서버가 실행 중입니다"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)