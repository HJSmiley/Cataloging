# Catalog API

카탈로그 및 아이템 관리를 위한 FastAPI 기반 백엔드 서비스

## 프로젝트 구조

```
catalog-api/
├── app/
│   ├── core/                # 설정 및 유틸리티
│   │   ├── __init__.py
│   │   ├── config.py        # 환경 설정
│   │   ├── security.py      # JWT 인증
│   │   └── middleware.py    # HTTP 미들웨어
│   ├── api/                 # 라우터/엔드포인트
│   │   ├── __init__.py
│   │   ├── catalogs.py      # 카탈로그 API
│   │   ├── items.py         # 아이템 API
│   │   ├── upload.py        # 파일 업로드 API
│   │   └── user_catalogs.py # 사용자 카탈로그 API
│   ├── models/              # DB 모델 (SQLAlchemy)
│   │   ├── __init__.py
│   │   └── database.py      # 데이터베이스 모델
│   ├── schemas/             # Pydantic 스키마
│   │   ├── __init__.py
│   │   ├── catalog.py       # 카탈로그 스키마
│   │   ├── item.py          # 아이템 스키마
│   │   ├── user_catalog.py  # 사용자 카탈로그 스키마
│   │   ├── user_item.py     # 사용자 아이템 스키마
│   │   └── common.py        # 공통 스키마
│   └── crud/                # DB CRUD 로직
│       ├── __init__.py
│       ├── catalog.py       # 카탈로그 CRUD
│       ├── item.py          # 아이템 CRUD
│       └── user_catalog.py  # 사용자 카탈로그 CRUD
├── .env                     # 환경 변수 파일
├── .env.example             # 환경 변수 예시
├── main.py                  # FastAPI 엔트리포인트
├── requirements.txt         # Python 의존성
└── README.md                # 프로젝트 문서

```

## 주요 기능

- **카탈로그 관리**: 수집 카탈로그 생성, 조회, 수정, 삭제
- **아이템 관리**: 카탈로그 내 아이템 CRUD 및 보유 상태 관리
- **사용자 인증**: JWT 토큰 기반 인증 (user-api와 연동)
- **파일 업로드**: 이미지 파일 업로드 및 서빙
- **공개/비공개**: 카탈로그 공개 설정 및 다른 사용자 카탈로그 저장

## 설치 및 실행

### 1. 가상환경 생성 및 활성화

```bash
# 가상환경 생성 (최초 1회)
python3 -m venv .venv

# 가상환경 활성화
source .venv/bin/activate  # macOS/Linux
# 또는
.venv\Scripts\activate     # Windows
```

### 2. 의존성 설치

```bash
pip install -r requirements.txt
```

### 3. 환경 변수 설정

`.env.example` 파일을 참고하여 `.env` 파일을 생성:

```bash
cp .env.example .env
```

`.env` 파일 내용:

```env
# 서버 설정
PORT=8000
HOST=0.0.0.0

DATABASE_URL=sqlite:///./catalog.db
JWT_SECRET_KEY=your-jwt-secret-key
JWT_ALGORITHM=HS256
UPLOAD_DIR=./uploads

CORS_ORIGINS=*
CORS_CREDENTIALS=true
CORS_METHODS=*
CORS_HEADERS=*

LOG_LEVEL=INFO
LOG_FILE=api_communication.log
```

### 4. 서버 실행

```bash
# .env 파일에서 포트 설정 확인/수정
# PORT=8000 (기본값)

# 개발 서버 실행 (환경 변수에서 포트 설정 사용)
python main.py

# 또는 uvicorn 직접 실행 (포트 지정)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# 또는 환경 변수로 포트 임시 변경
PORT=8003 python main.py
```

서버는 `.env` 파일의 `PORT` 설정에 따라 실행됩니다 (기본값: 8000).

### 5. API 문서 확인

- Swagger UI: `http://localhost:{PORT}/docs` (기본: http://localhost:8000/docs)
- ReDoc: `http://localhost:{PORT}/redoc` (기본: http://localhost:8000/redoc)
- Health Check: `http://localhost:{PORT}/health`

포트는 `.env` 파일의 `PORT` 설정을 따릅니다.

## API 엔드포인트

### 카탈로그 API (`/api/catalogs`)

- `GET /` - 내 카탈로그 목록 조회
- `GET /public` - 공개 카탈로그 목록 조회
- `GET /{catalog_id}` - 카탈로그 상세 조회
- `POST /` - 카탈로그 생성
- `PUT /{catalog_id}` - 카탈로그 수정
- `DELETE /{catalog_id}` - 카탈로그 삭제

### 아이템 API (`/api/items`)

- `GET /catalog/{catalog_id}` - 카탈로그의 아이템 목록 조회
- `GET /{item_id}` - 아이템 상세 조회
- `POST /` - 아이템 생성
- `PUT /{item_id}` - 아이템 수정
- `PATCH /{item_id}/toggle-owned` - 아이템 보유 상태 토글
- `DELETE /{item_id}` - 아이템 삭제

### 사용자 카탈로그 API (`/api/user-catalogs`)

- `GET /my-catalogs` - 내가 소유한 카탈로그 목록
- `POST /save-catalog` - 다른 사용자의 카탈로그 저장
- `DELETE /unsave-catalog/{catalog_id}` - 저장한 카탈로그 제거
- `GET /check-ownership/{catalog_id}` - 카탈로그 소유권 확인
- `GET /check-saved/{original_catalog_id}` - 카탈로그 저장 여부 확인

### 파일 업로드 API (`/api/upload`)

- `POST /file` - 파일 업로드
- `DELETE /file` - 파일 삭제

## 인증

모든 API는 JWT 토큰 기반 인증을 사용합니다. 요청 헤더에 다음과 같이 토큰을 포함해야 합니다:

```
Authorization: Bearer <JWT_TOKEN>
```

JWT 토큰은 user-api에서 발급받아야 합니다.

## 데이터베이스

SQLite를 사용하며, 다음 테이블들이 자동으로 생성됩니다:

- `catalogs` - 카탈로그 정보
- `items` - 아이템 정보
- `user_catalogs` - 사용자 카탈로그 저장 관계
- `user_item_status` - 사용자별 아이템 보유 상태

## 개발

### 코드 구조

- **app/core**: 설정, 보안, 미들웨어 등 핵심 기능
- **app/api**: FastAPI 라우터 (엔드포인트 정의)
- **app/models**: SQLAlchemy 데이터베이스 모델
- **app/schemas**: Pydantic 스키마 (요청/응답 검증)
- **app/crud**: 데이터베이스 CRUD 작업 로직

### 새로운 API 추가

1. `app/schemas/`에 Pydantic 스키마 정의
2. `app/crud/`에 CRUD 함수 작성
3. `app/api/`에 라우터 생성
4. `main.py`에 라우터 등록

## 라이선스

MIT License
