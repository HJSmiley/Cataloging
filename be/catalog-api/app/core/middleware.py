"""
Catalog-API 미들웨어
- HTTP 요청/응답 로깅
"""
import time
import json
import logging
from fastapi import Request

logger = logging.getLogger("API_COMMUNICATION")

async def log_requests_middleware(request: Request, call_next):
    """HTTP 요청/응답 로깅 미들웨어 - 모든 API 호출을 자동으로 기록"""
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
