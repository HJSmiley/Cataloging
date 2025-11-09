"""
Catalog-API 미들웨어
- HTTP 요청/응답 로깅
- Flutter 클라이언트와의 통신 내역을 명확하게 기록
"""
import time
import json
import logging
from fastapi import Request
from starlette.responses import StreamingResponse, Response

# Settings에서 설정한 API 전용 로거 사용
logger = logging.getLogger("API_COMMUNICATION")


async def log_requests_middleware(request: Request, call_next):
    """HTTP 요청/응답 로깅 미들웨어 - 모든 API 호출을 자동으로 기록합니다."""
    start_time = time.time()  # 요청 처리 시간 측정 시작

    # 구분선 출력
    logger.warning("=" * 80)

    # -------------------------------------------------------------------------
    # 1) HTTP REQUEST LOGGING
    # -------------------------------------------------------------------------
    body = b""
    if request.method in ["POST", "PUT", "PATCH"]:
        # 요청 바디 읽기 (GET은 바디 없음)
        body = await request.body()

    # 요청 헤더에서 중요 정보만 추출
    important_headers = {}
    if "authorization" in request.headers:
        auth_header = request.headers["authorization"]
        # JWT 토큰의 앞부분만 표시
        if auth_header.startswith("Bearer "):
            token_preview = auth_header[:37] + "..." if len(auth_header) > 40 else auth_header
            important_headers["Authorization"] = token_preview
    if "content-type" in request.headers:
        important_headers["Content-Type"] = request.headers["content-type"]

    logger.warning("📤 [CLIENT → CATALOG-API] REQUEST")
    logger.warning(f"   Method: {request.method}")
    logger.warning(f"   URL: {request.url.path}")

    if request.url.query:
        logger.warning(f"   Query: {request.url.query}")

    if important_headers:
        logger.warning(f"   Headers: {json.dumps(important_headers, ensure_ascii=False)}")

    # 요청 바디 출력
    if body:
        content_type = request.headers.get("content-type", "")

        if "multipart/form-data" in content_type:
            # 파일 업로드의 경우 바이너리 데이터가 포함되므로 크기만 기록
            logger.warning(f"   [Multipart form data, size: {len(body)} bytes]")
        else:
            try:
                # JSON 바디를 예쁘게 포맷팅하여 로깅
                body_json = json.loads(body.decode("utf-8"))
                body_str = json.dumps(body_json, ensure_ascii=False)
                logger.warning(f"   {body_str}")
            except UnicodeDecodeError:
                logger.warning(f"   [Binary data, size: {len(body)} bytes]")
            except json.JSONDecodeError:
                try:
                    logger.warning(f"   {body.decode('utf-8')}")
                except UnicodeDecodeError:
                    logger.warning(f"   [Non-UTF8 data, size: {len(body)} bytes]")

    # -------------------------------------------------------------------------
    # 2) ROUTER 실행 (실제 API 처리)
    # -------------------------------------------------------------------------
    response = await call_next(request)

    # -------------------------------------------------------------------------
    # 3) HTTP RESPONSE LOGGING
    # -------------------------------------------------------------------------
    process_time = time.time() - start_time  # 처리 시간 계산

    # 응답 본문 로깅 준비
    response_body = b""
    if isinstance(response, StreamingResponse):
        response_body_parts = []
        async for chunk in response.body_iterator:
            response_body_parts.append(chunk)
        response_body = b"".join(response_body_parts)

        # 새로운 Response 생성 (원본 응답의 속성 유지)
        response = Response(
            content=response_body,
            status_code=response.status_code,
            headers=dict(response.headers),
            media_type=response.media_type,
        )

    logger.warning("📥 [CATALOG-API → CLIENT] RESPONSE")
    logger.warning(f"   Status: {response.status_code}")

    # 응답 본문 로깅 (JSON인 경우)
    if response_body:
        try:
            response_json = json.loads(response_body.decode("utf-8"))
            body_str = json.dumps(response_json, ensure_ascii=False)
            logger.warning(f"   {body_str}")
        except (UnicodeDecodeError, json.JSONDecodeError):
            logger.warning(f"   [Non-JSON data, size: {len(response_body)} bytes]")

    logger.warning("=" * 80 + "\n")

    return response
