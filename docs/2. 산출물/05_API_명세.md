# API 명세 (API Spec)

## 1. API 개요

카탈로깅 시스템은 두 개의 독립적인 API 서버로 구성됩니다:
- **User API** (Spring Boot): 회원 관리 및 JWT 토큰 발급
- **Catalog API** (FastAPI): 카탈로그 및 아이템 관리

## 2. 공통 사항

### 2.1 기본 정보

| 항목 | User API | Catalog API |
|------|----------|-------------|
| Base URL | http://localhost:{PORT} (기본: 8080) | http://localhost:{PORT} (기본: 8000) |
| 포트 설정 | PORT 환경 변수 | .env 파일의 PORT |
| Protocol | HTTP/1.1 | HTTP/1.1 |
| Data Format | JSON (UTF-8) | JSON (UTF-8) |
| Authentication | JWT Bearer Token | JWT Bearer Token |

### 2.2 인증 방식

모든 보호된 API는 JWT 토큰을 요구합니다.

**요청 헤더**:
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json; charset=utf-8
```

**JWT 토큰 구조**:
- Algorithm: HS256
- Expiration: 24시간
- Payload: `{ "sub": "user_id" }`

### 2.3 HTTP 상태 코드

| 코드 | 의미 | 사용 상황 |
|------|------|-----------|
| 200 | OK | 성공적인 GET, PUT, PATCH, DELETE |
| 201 | Created | 성공적인 POST (리소스 생성) |
| 400 | Bad Request | 잘못된 요청 데이터 |
| 401 | Unauthorized | 인증 실패 (토큰 없음/만료/유효하지 않음) |
| 403 | Forbidden | 권한 없음 (소유자가 아님) |
| 404 | Not Found | 리소스를 찾을 수 없음 |
| 500 | Internal Server Error | 서버 내부 오류 |

### 2.4 에러 응답 형식

```json
{
  "detail": "에러 메시지"
}
```

**예시**:
```json
{
  "detail": "인증 토큰이 필요합니다"
}
```

## 3. User API (Spring Boot)

**포트**: 환경 변수 `PORT`로 설정 (기본값: 8080)

### 3.1 시스템 API

#### GET /api/test/health
서버 상태 확인 (Health Check)

**요청**:
```http
GET /api/test/health
```

**응답** (200 OK):
```json
{
  "status": "UP",
  "message": "User API is running",
  "timestamp": "2025-11-08T10:00:00.000Z"
}
```

### 3.2 인증 API

#### POST /api/auth/dev-login
개발용 간편 로그인 (JWT 토큰 발급)

**요청**:
```http
POST /api/auth/dev-login
Content-Type: application/json

{
  "email": "user@example.com",
  "nickname": "사용자"
}
```

**응답** (200 OK):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "nickname": "사용자",
    "introduction": null,
    "profileImage": null,
    "createdAt": "2025-11-08T10:00:00",
    "updatedAt": "2025-11-08T10:00:00"
  }
}
```

#### GET /api/auth/login/{provider}
OAuth2 로그인 URL 조회

**요청**:
```http
GET /api/auth/login/google
```

**응답** (200 OK):
```json
{
  "loginUrl": "https://accounts.google.com/o/oauth2/v2/auth?..."
}
```

#### POST /api/auth/logout
로그아웃

**요청**:
```http
POST /api/auth/logout
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "message": "로그아웃 성공"
}
```

### 3.3 사용자 API

#### GET /api/users/me
현재 사용자 정보 조회

**요청**:
```http
GET /api/users/me
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "id": 1,
  "email": "user@example.com",
  "nickname": "사용자",
  "introduction": "안녕하세요",
  "profileImage": "/uploads/profile.jpg",
  "createdAt": "2025-11-08T10:00:00",
  "updatedAt": "2025-11-08T10:00:00"
}
```

#### PUT /api/users/me
사용자 정보 수정

**요청**:
```http
PUT /api/users/me
Authorization: Bearer {JWT}
Content-Type: application/json

{
  "nickname": "새닉네임",
  "introduction": "새 자기소개",
  "profileImage": "/uploads/new-profile.jpg"
}
```

**응답** (200 OK):
```json
{
  "id": 1,
  "email": "user@example.com",
  "nickname": "새닉네임",
  "introduction": "새 자기소개",
  "profileImage": "/uploads/new-profile.jpg",
  "createdAt": "2025-11-08T10:00:00",
  "updatedAt": "2025-11-08T11:00:00"
}
```

#### DELETE /api/users/me
회원 탈퇴

**요청**:
```http
DELETE /api/users/me
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "message": "회원 탈퇴가 완료되었습니다"
}
```

#### GET /api/users/{userId}
특정 사용자 공개 프로필 조회 (인증 불필요)

**요청**:
```http
GET /api/users/1
```

**응답** (200 OK):
```json
{
  "id": 1,
  "email": "user@example.com",
  "nickname": "사용자",
  "introduction": "안녕하세요",
  "profileImage": "/uploads/profile.jpg",
  "createdAt": "2025-11-08T10:00:00",
  "updatedAt": "2025-11-08T10:00:00"
}
```

**참고**:
- 인증 없이 접근 가능 (공개 프로필)
- Catalog API에서 생성자 닉네임 조회 시 사용

## 4. Catalog API (FastAPI)

**포트**: `.env` 파일의 `PORT` 설정 (기본값: 8000)

### 4.1 시스템 API

#### GET /health
서버 상태 확인 (Health Check)

**요청**:
```http
GET /health
```

**응답** (200 OK):
```json
{
  "status": "healthy"
}
```

#### GET /
루트 엔드포인트

**요청**:
```http
GET /
```

**응답** (200 OK):
```json
{
  "message": "카탈로그 API 서버가 실행 중입니다"
}
```

### 4.2 사용자 카탈로그 API

#### GET /api/user-catalogs/my-catalogs
내 카탈로그 목록 조회 (생성+저장)

**요청**:
```http
GET /api/user-catalogs/my-catalogs
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
[
  {
    "catalog_id": "uuid-1",
    "user_id": "1",
    "title": "내 피규어 컬렉션",
    "description": "애니메이션 피규어 모음",
    "category": "피규어",
    "tags": ["애니메이션", "수집"],
    "visibility": "public",
    "thumbnail_url": "/uploads/thumb.jpg",
    "created_at": "2025-11-08T10:00:00",
    "updated_at": "2025-11-08T10:00:00",
    "item_count": 10,
    "owned_count": 7,
    "completion_rate": 70.0,
    "original_catalog_id": null
  }
]
```

#### POST /api/user-catalogs/save-catalog
카탈로그 저장 (복사)

**요청**:
```http
POST /api/user-catalogs/save-catalog
Authorization: Bearer {JWT}
Content-Type: application/json

{
  "catalog_id": "uuid-original"
}
```

**응답** (200 OK):
```json
{
  "message": "카탈로그가 성공적으로 저장되었습니다",
  "copied_catalog_id": "uuid-copied",
  "original_catalog_id": "uuid-original"
}
```

**에러** (400 Bad Request):
```json
{
  "detail": "자신의 카탈로그는 저장할 수 없습니다"
}
```

#### DELETE /api/user-catalogs/unsave-catalog/{catalog_id}
저장한 카탈로그 제거

**요청**:
```http
DELETE /api/user-catalogs/unsave-catalog/uuid-copied
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "message": "카탈로그가 성공적으로 삭제되었습니다"
}
```

#### GET /api/user-catalogs/check-ownership/{catalog_id}
카탈로그 소유권 확인

**요청**:
```http
GET /api/user-catalogs/check-ownership/uuid-1
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "catalog_id": "uuid-1",
  "is_owned": true,
  "user_id": "1"
}
```

#### GET /api/user-catalogs/check-saved/{original_catalog_id}
카탈로그 저장 여부 확인

**요청**:
```http
GET /api/user-catalogs/check-saved/uuid-original
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "original_catalog_id": "uuid-original",
  "is_saved": true,
  "copied_catalog_id": "uuid-copied",
  "user_id": "1"
}
```

### 4.3 카탈로그 API

#### GET /api/catalogs/public
공개 카탈로그 목록 조회 (인증 선택)

**요청**:
```http
GET /api/catalogs/public?category=피규어&user_id=1
Authorization: Bearer {JWT} (선택)
```

**쿼리 파라미터**:
- `category` (optional): 카테고리 필터
- `user_id` (optional): 현재 사용자 ID (자신의 카탈로그 제외용)

**응답** (200 OK):
```json
[
  {
    "catalog_id": "uuid-1",
    "user_id": "2",
    "title": "공개 피규어 컬렉션",
    "description": "다른 사용자의 공개 카탈로그",
    "category": "피규어",
    "tags": ["애니메이션"],
    "visibility": "public",
    "thumbnail_url": "/uploads/thumb.jpg",
    "created_at": "2025-11-08T10:00:00",
    "updated_at": "2025-11-08T10:00:00",
    "item_count": 15,
    "owned_count": 0,
    "completion_rate": 0.0,
    "creator_nickname": "수집왕",
    "is_saved": false
  }
]
```

**새로운 필드**:
- `creator_nickname`: 카탈로그 생성자 닉네임 (User API에서 조회)
- `is_saved`: 현재 사용자가 이 카탈로그를 저장했는지 여부 (로그인 시에만)

#### GET /api/catalogs/{catalog_id}
카탈로그 상세 조회

**요청**:
```http
GET /api/catalogs/uuid-1
Authorization: Bearer {JWT} (선택)
```

**응답** (200 OK):
```json
{
  "catalog_id": "uuid-1",
  "user_id": "1",
  "title": "내 피규어 컬렉션",
  "description": "애니메이션 피규어 모음",
  "category": "피규어",
  "tags": ["애니메이션", "수집"],
  "visibility": "public",
  "thumbnail_url": "/uploads/thumb.jpg",
  "created_at": "2025-11-08T10:00:00",
  "updated_at": "2025-11-08T10:00:00",
  "item_count": 10,
  "owned_count": 7,
  "completion_rate": 70.0
}
```

#### POST /api/catalogs/
카탈로그 생성

**요청**:
```http
POST /api/catalogs/
Authorization: Bearer {JWT}
Content-Type: application/json

{
  "title": "새 카탈로그",
  "description": "카탈로그 설명",
  "category": "피규어",
  "tags": ["애니메이션", "수집"],
  "visibility": "public",
  "thumbnail_url": "/uploads/thumb.jpg"
}
```

**응답** (201 Created):
```json
{
  "catalog_id": "uuid-new",
  "user_id": "1",
  "title": "새 카탈로그",
  "description": "카탈로그 설명",
  "category": "피규어",
  "tags": ["애니메이션", "수집"],
  "visibility": "public",
  "thumbnail_url": "/uploads/thumb.jpg",
  "created_at": "2025-11-08T12:00:00",
  "updated_at": "2025-11-08T12:00:00",
  "item_count": 0,
  "owned_count": 0,
  "completion_rate": 0.0
}
```

#### PUT /api/catalogs/{catalog_id}
카탈로그 수정

**요청**:
```http
PUT /api/catalogs/uuid-1
Authorization: Bearer {JWT}
Content-Type: application/json

{
  "title": "수정된 제목",
  "description": "수정된 설명",
  "category": "레고",
  "tags": ["레고", "빌딩"],
  "visibility": "private",
  "thumbnail_url": "/uploads/new-thumb.jpg"
}
```

**응답** (200 OK):
```json
{
  "catalog_id": "uuid-1",
  "user_id": "1",
  "title": "수정된 제목",
  "description": "수정된 설명",
  "category": "레고",
  "tags": ["레고", "빌딩"],
  "visibility": "private",
  "thumbnail_url": "/uploads/new-thumb.jpg",
  "created_at": "2025-11-08T10:00:00",
  "updated_at": "2025-11-08T13:00:00",
  "item_count": 10,
  "owned_count": 7,
  "completion_rate": 70.0
}
```

#### DELETE /api/catalogs/{catalog_id}
카탈로그 삭제

**요청**:
```http
DELETE /api/catalogs/uuid-1
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "message": "카탈로그가 삭제되었습니다"
}
```

### 4.4 아이템 API

#### GET /api/items/catalog/{catalog_id}
카탈로그의 아이템 목록 조회

**요청**:
```http
GET /api/items/catalog/uuid-1?owned=true
Authorization: Bearer {JWT}
```

**쿼리 파라미터**:
- `owned` (optional): 보유 여부 필터 (true/false)

**응답** (200 OK):
```json
[
  {
    "item_id": "uuid-item-1",
    "catalog_id": "uuid-1",
    "name": "피규어 A",
    "description": "피규어 설명",
    "image_url": "/uploads/item1.jpg",
    "owned": true,
    "user_fields": {
      "구매일": "2025-01-01",
      "가격": "50000"
    },
    "created_at": "2025-11-08T10:00:00",
    "updated_at": "2025-11-08T10:00:00"
  }
]
```

#### GET /api/items/{item_id}
아이템 상세 조회

**요청**:
```http
GET /api/items/uuid-item-1
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "item_id": "uuid-item-1",
  "catalog_id": "uuid-1",
  "name": "피규어 A",
  "description": "피규어 설명",
  "image_url": "/uploads/item1.jpg",
  "owned": true,
  "user_fields": {
    "구매일": "2025-01-01",
    "가격": "50000"
  },
  "created_at": "2025-11-08T10:00:00",
  "updated_at": "2025-11-08T10:00:00"
}
```

#### POST /api/items/
아이템 생성

**요청**:
```http
POST /api/items/
Authorization: Bearer {JWT}
Content-Type: application/json

{
  "catalog_id": "uuid-1",
  "name": "새 아이템",
  "description": "아이템 설명",
  "image_url": "/uploads/new-item.jpg",
  "user_fields": {
    "구매일": "2025-11-08",
    "가격": "30000"
  }
}
```

**응답** (201 Created):
```json
{
  "item_id": "uuid-new-item",
  "catalog_id": "uuid-1",
  "name": "새 아이템",
  "description": "아이템 설명",
  "image_url": "/uploads/new-item.jpg",
  "owned": false,
  "user_fields": {
    "구매일": "2025-11-08",
    "가격": "30000"
  },
  "created_at": "2025-11-08T12:00:00",
  "updated_at": "2025-11-08T12:00:00"
}
```

#### PUT /api/items/{item_id}
아이템 수정

**요청**:
```http
PUT /api/items/uuid-item-1
Authorization: Bearer {JWT}
Content-Type: application/json

{
  "name": "수정된 아이템",
  "description": "수정된 설명",
  "image_url": "/uploads/updated-item.jpg",
  "user_fields": {
    "구매일": "2025-11-09",
    "가격": "35000"
  }
}
```

**응답** (200 OK):
```json
{
  "item_id": "uuid-item-1",
  "catalog_id": "uuid-1",
  "name": "수정된 아이템",
  "description": "수정된 설명",
  "image_url": "/uploads/updated-item.jpg",
  "owned": true,
  "user_fields": {
    "구매일": "2025-11-09",
    "가격": "35000"
  },
  "created_at": "2025-11-08T10:00:00",
  "updated_at": "2025-11-08T13:00:00"
}
```

#### PATCH /api/items/{item_id}/toggle-owned
아이템 보유 상태 토글 (핵심 기능)

**요청**:
```http
PATCH /api/items/uuid-item-1/toggle-owned
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "item_id": "uuid-item-1",
  "catalog_id": "uuid-1",
  "name": "피규어 A",
  "description": "피규어 설명",
  "image_url": "/uploads/item1.jpg",
  "owned": true,
  "user_fields": {
    "구매일": "2025-01-01",
    "가격": "50000"
  },
  "created_at": "2025-11-08T10:00:00",
  "updated_at": "2025-11-08T14:00:00"
}
```

#### DELETE /api/items/{item_id}
아이템 삭제

**요청**:
```http
DELETE /api/items/uuid-item-1
Authorization: Bearer {JWT}
```

**응답** (200 OK):
```json
{
  "message": "아이템이 삭제되었습니다"
}
```

### 4.5 파일 업로드 API

#### POST /api/upload/file
이미지 파일 업로드

**요청**:
```http
POST /api/upload/file
Authorization: Bearer {JWT}
Content-Type: multipart/form-data

file: (binary) 이미지 파일
```

**응답** (200 OK):
```json
{
  "file_url": "/uploads/1/2025/11/08/uuid-filename.jpg",
  "filename": "uuid-filename.jpg"
}
```

#### DELETE /api/upload/file
파일 삭제

**요청**:
```http
DELETE /api/upload/file
Authorization: Bearer {JWT}
Content-Type: application/json

{
  "file_url": "/uploads/1/2025/11/08/uuid-filename.jpg"
}
```

**응답** (200 OK):
```json
{
  "message": "파일이 삭제되었습니다"
}
```

## 5. JWT 인증 흐름

### 5.1 로그인 및 토큰 발급

```
1. Flutter → User API: POST /api/auth/dev-login
   { email, nickname }

2. User API → Flutter: 
   { accessToken, user }

3. Flutter: SharedPreferences에 토큰 저장
```

### 5.2 인증된 API 호출

```
1. Flutter → Catalog API: GET /api/user-catalogs/my-catalogs
   Authorization: Bearer {JWT}

2. Catalog API: JWT 검증
   - jwt.decode(token, SECRET_KEY, HS256)
   - user_id = payload['sub']

3. Catalog API → Flutter:
   [{ catalog_id, title, ... }]
```

### 5.3 토큰 만료 처리

```
1. Flutter → Catalog API: API 호출
   Authorization: Bearer {expired_token}

2. Catalog API → Flutter: 401 Unauthorized
   { "detail": "토큰이 만료되었습니다" }

3. Flutter: 로그아웃 처리, LoginScreen으로 이동
```

## 6. API 테스트

### 6.1 Swagger UI

- **User API**: http://localhost:8080/swagger-ui.html (향후 추가)
- **Catalog API**: http://localhost:8000/docs

### 6.2 Postman Collection

주요 API 테스트 시나리오:
1. 개발용 로그인 → JWT 토큰 획득
2. 내 카탈로그 목록 조회
3. 카탈로그 생성
4. 아이템 추가
5. 아이템 보유 상태 토글
6. 수집률 확인

## 7. API 버전 관리

- **현재 버전**: v1 (암묵적)
- **향후 계획**: URL에 버전 명시 (/api/v1/catalogs)
- **하위 호환성**: 기존 API 유지하면서 새 버전 추가
