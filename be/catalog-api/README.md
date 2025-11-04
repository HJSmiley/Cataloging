# 카탈로그 API (FastAPI + SQLite)

수집가를 위한 카탈로그 및 아이템 관리 API 서버입니다.

## 기능

- 카탈로그 CRUD (생성, 조회, 수정, 삭제)
- 아이템 CRUD (생성, 조회, 수정, 삭제)
- 아이템 보유 여부 토글
- 로컬 파일 시스템 이미지 업로드
- 수집률 자동 계산

## 기술 스택

- **FastAPI**: 고성능 Python 웹 프레임워크
- **SQLite**: 로컬 데이터베이스 (개발용)
- **SQLAlchemy**: ORM
- **로컬 파일 시스템**: 이미지 파일 저장
- **JWT**: 인증 토큰
- **Docker**: 컨테이너화 및 배포

## 설치 및 실행

### 방법 1: Docker 사용 (권장)

#### 1. Docker 이미지 빌드

```bash
# catalog-api 디렉토리로 이동
cd be/catalog-api

# Docker 이미지 빌드
docker build -t catalog-api .
```

#### 2. Docker 컨테이너 실행

```bash
# 컨테이너 실행 (백그라운드)
docker run -d -p 8000:8000 --name catalog-api-container catalog-api

# 또는 포그라운드에서 실행 (로그 확인 가능)
docker run -p 8000:8000 --name catalog-api-container catalog-api
```

#### 3. 컨테이너 관리

```bash
# 컨테이너 상태 확인
docker ps

# 컨테이너 로그 확인
docker logs catalog-api-container

# 컨테이너 중지
docker stop catalog-api-container

# 컨테이너 삭제
docker rm catalog-api-container

# 이미지 삭제
docker rmi catalog-api
```

### 방법 2: 로컬 Python 환경

#### 1. 가상환경 설정 및 의존성 설치

```bash
# 가상환경 생성
python3 -m venv venv

# 가상환경 활성화 (macOS/Linux)
source venv/bin/activate

# 가상환경 활성화 (Windows)
# venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt
```

#### 2. 환경 변수 설정 (선택사항)

`.env.example`을 참고하여 `.env` 파일을 생성할 수 있습니다. 기본 설정으로도 실행 가능합니다.

```bash
cp .env.example .env
```

#### 3. 서버 실행

```bash
# 가상환경 활성화 후 개발 서버 실행
source venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 또는 Python으로 직접 실행
source venv/bin/activate
python main.py
```

## API 문서 확인

서버 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API 엔드포인트

### 카탈로그 API

- `GET /api/catalogs/` - 카탈로그 목록 조회
- `GET /api/catalogs/{catalog_id}` - 특정 카탈로그 조회
- `POST /api/catalogs/` - 카탈로그 생성
- `PUT /api/catalogs/{catalog_id}` - 카탈로그 수정
- `DELETE /api/catalogs/{catalog_id}` - 카탈로그 삭제

### 아이템 API

- `GET /api/items/catalog/{catalog_id}` - 카탈로그의 아이템 목록 조회
- `GET /api/items/{item_id}` - 특정 아이템 조회
- `POST /api/items/` - 아이템 생성
- `PUT /api/items/{item_id}` - 아이템 수정
- `PATCH /api/items/{item_id}/toggle-owned` - 아이템 보유 여부 토글
- `DELETE /api/items/{item_id}` - 아이템 삭제

### 업로드 API

- `POST /api/upload/file` - 파일 업로드 (로컬 파일 시스템)
- `DELETE /api/upload/file` - 파일 삭제
- `GET /uploads/images/{user_id}/{year}/{month}/{day}/{filename}` - 이미지 파일 서빙

## 인증

현재 개발 단계에서는 다음 두 가지 방식으로 인증을 지원합니다:

1. **JWT 토큰** (권장): `Authorization: Bearer <token>`
2. **개발용 사용자 ID**: `Authorization: <user_id>`

## 데이터 구조

### 카탈로그 (Catalog)

```json
{
  "catalog_id": "uuid",
  "user_id": "string",
  "title": "string",
  "description": "string",
  "category": "string",
  "tags": ["string"],
  "visibility": "public|private",
  "thumbnail_url": "string",
  "created_at": "ISO datetime",
  "updated_at": "ISO datetime",
  "item_count": 0,
  "owned_count": 0,
  "completion_rate": 0.0
}
```

### 아이템 (Item)

```json
{
  "item_id": "uuid",
  "catalog_id": "uuid",
  "name": "string",
  "description": "string",
  "image_url": "string",
  "owned": false,
  "user_fields": {
    "key": "value"
  },
  "created_at": "ISO datetime",
  "updated_at": "ISO datetime"
}
```

## Docker 구성

### Dockerfile 특징

- **베이스 이미지**: `python:3.13-slim` (경량화된 Python 이미지)
- **시스템 의존성**: gcc (Python 패키지 컴파일용)
- **포트**: 8000번 포트 노출
- **개발 모드**: `--reload` 옵션으로 코드 변경 시 자동 재시작
- **볼륨**: 업로드 디렉토리 자동 생성

### 프로덕션 배포 시 고려사항

```bash
# 프로덕션용 실행 (reload 옵션 제거)
docker run -d -p 8000:8000 \
  -v $(pwd)/uploads:/app/uploads \
  -v $(pwd)/catalog.db:/app/catalog.db \
  --name catalog-api-prod \
  catalog-api
```

- 데이터베이스와 업로드 파일을 호스트에 마운트하여 데이터 영속성 보장
- 환경 변수로 설정 값 주입 가능

## 개발 참고사항

- SQLite 데이터베이스는 앱 시작 시 자동으로 생성됩니다 (`catalog.db`)
- 이미지는 로컬 파일 시스템에 저장됩니다 (`./uploads/` 디렉토리)
- 수집률은 카탈로그 조회 시 실시간으로 계산됩니다
- 모든 API는 사용자별로 데이터가 격리됩니다
- 개발 환경에서는 `Authorization` 헤더에 사용자 ID를 직접 전달할 수 있습니다
- Docker 컨테이너 내에서도 동일한 기능이 제공됩니다