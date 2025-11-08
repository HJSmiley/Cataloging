"""
Catalog-API 메인 서버 파일 (Python FastAPI)
- 이 파일은 하위 호환성을 위해 유지됩니다
- 실제 애플리케이션은 app/main.py에 있습니다
"""
from app.main import app

# 서버 실행 설정 - 개발 환경에서 직접 실행 시
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)