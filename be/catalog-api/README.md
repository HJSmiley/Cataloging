# Catalog API

카탈로그 및 아이템 관리를 위한 FastAPI 기반 백엔드 서비스

## 프로젝트 구조

```
catalog-api/
├── app/
│   ├── main.py              # FastAPI 엔트리포인트
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
├── main.py                  # 하위 호환성을 위한 엔트리포인트
├── requirements.txt         # Python 의존성
├── Dockerfile               # Docker 이미지 빌드
└── README.md                # 프로젝트 문서

```

## 주요 기능

- **카탈로그 관리**: 수집 카탈로그 생성, 조회, 수정, 삭제
- **아이템 관리**: 카탈로그 내 아이템 CRUD 및 보유 상태 관리
- **사용자 인증**: JWT 토큰 기반 인증 (user-api와 연동)
- **파일 업로드**: 이미지 파일 업로드 및 서빙
- **공개/비공개**: 카탈로그 공개 설정 및 다른 사용자 카탈로그 저장

## 설치 및 실행

### 1. 의존성 설치

```bash
pip install -r requirements.txt
```

### 2. 환경 변수 설정

`.env` 파일을 생성하고 다음 내용을 설정:

```env
DATABASE_URL=sqlite:///./catalog.db
JWT_SECRET_KEY=mySecretKey1234567890123456789012345678901234567890
JWT_ALGORITHM=HS256
UPLOAD_DIR=./uploads

CORS_ORIGINS=*
CORS_CREDENTIALS=true
CORS_METHODS=*
CORS_HEADERS=*

LOG_LEVEL=INFO
LOG_FILE=api_communication.log
```

### 3. 서버 실행

```bash
# 개발 서버 실행
python main.py

# 또는 uvicorn 직접 실행
uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload
```

서버는 `http://localhost:8002`에서 실행됩니다.

### 4. API 문서 확인

- Swagger UI: `http://localhost:8002/docs`
- ReDoc: `http://localhost:8002/redoc`

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
4. `app/main.py`에 라우터 등록

## Docker

```bash
# 이미지 빌드
docker build -t catalog-api .

# 컨테이너 실행
docker run -p 8002:8002 catalog-api
```

## 라이선스

MIT License
