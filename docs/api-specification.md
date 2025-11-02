# 카탈로깅 API 명세서

## 개요

카탈로깅 앱의 RESTful API 명세서입니다. 클라이언트와 서버 간 통신에 사용되는 모든 엔드포인트와 데이터 구조를 정의합니다.

## 기본 정보

- **Base URL**: `http://localhost:8000`
- **API Version**: v1
- **Content-Type**: `application/json`
- **Authentication**: Authorization 헤더 (개발 단계에서는 사용자 ID 직접 전송)

## 인증

모든 API 요청에는 Authorization 헤더가 필요합니다.

```http
Authorization: {user_id}
```

예시:
```http
Authorization: flutter-user-1
```

---

## 엔드포인트

### 1. 서버 상태

#### GET /health
서버 상태를 확인합니다.

**Request**
```http
GET /health
```

**Response**
```json
{
  "status": "healthy"
}
```

---

### 2. 카탈로그 API

#### GET /api/catalogs/
사용자의 카탈로그 목록을 조회합니다.

**Request**
```http
GET /api/catalogs/
Authorization: {user_id}
```

**Query Parameters**
- `category` (optional): 카테고리 필터
- `visibility` (optional): 공개 여부 필터 (`public` | `private`)

**Response**
```json
[
  {
    "catalog_id": "uuid",
    "user_id": "string",
    "title": "string",
    "description": "string",
    "category": "string",
    "tags": ["string"],
    "visibility": "public",
    "thumbnail_url": "string | null",
    "created_at": "2025-11-02T13:31:38",
    "updated_at": "2025-11-02T13:31:38",
    "item_count": 0,
    "owned_count": 0,
    "completion_rate": 0.0
  }
]
```

#### GET /api/catalogs/{catalog_id}
특정 카탈로그의 상세 정보를 조회합니다.

**Request**
```http
GET /api/catalogs/{catalog_id}
Authorization: {user_id}
```

**Response**
```json
{
  "catalog_id": "uuid",
  "user_id": "string",
  "title": "string",
  "description": "string",
  "category": "string",
  "tags": ["string"],
  "visibility": "public",
  "thumbnail_url": "string | null",
  "created_at": "2025-11-02T13:31:38",
  "updated_at": "2025-11-02T13:31:38",
  "item_count": 1,
  "owned_count": 1,
  "completion_rate": 100.0
}
```

#### POST /api/catalogs/
새 카탈로그를 생성합니다.

**Request**
```http
POST /api/catalogs/
Authorization: {user_id}
Content-Type: application/json

{
  "title": "string",           // 필수
  "description": "string",     // 필수
  "category": "string",        // 선택 (기본값: "미분류")
  "tags": ["string"],          // 선택 (기본값: [])
  "visibility": "public",      // 선택 (기본값: "public")
  "thumbnail_url": "string"    // 선택
}
```

**Response**
```json
{
  "catalog_id": "uuid",
  "user_id": "string",
  "title": "string",
  "description": "string",
  "category": "string",
  "tags": ["string"],
  "visibility": "public",
  "thumbnail_url": "string | null",
  "created_at": "2025-11-02T13:31:38",
  "updated_at": "2025-11-02T13:31:38",
  "item_count": 0,
  "owned_count": 0,
  "completion_rate": 0.0
}
```

#### DELETE /api/catalogs/{catalog_id}
카탈로그를 삭제합니다. (연관된 아이템도 함께 삭제)

**Request**
```http
DELETE /api/catalogs/{catalog_id}
Authorization: {user_id}
```

**Response**
```json
{
  "message": "카탈로그가 성공적으로 삭제되었습니다"
}
```

---

### 3. 아이템 API

#### GET /api/items/catalog/{catalog_id}
특정 카탈로그의 아이템 목록을 조회합니다.

**Request**
```http
GET /api/items/catalog/{catalog_id}
Authorization: {user_id}
```

**Query Parameters**
- `owned` (optional): 보유 여부 필터 (`true` | `false`)

**Response**
```json
[
  {
    "item_id": "uuid",
    "catalog_id": "uuid",
    "name": "string",
    "description": "string",
    "image_url": "string | null",
    "owned": false,
    "user_fields": {
      "key": "value"
    },
    "created_at": "2025-11-02T13:31:52",
    "updated_at": "2025-11-02T13:31:52"
  }
]
```

#### GET /api/items/{item_id}
특정 아이템의 상세 정보를 조회합니다.

**Request**
```http
GET /api/items/{item_id}
Authorization: {user_id}
```

**Response**
```json
{
  "item_id": "uuid",
  "catalog_id": "uuid",
  "name": "string",
  "description": "string",
  "image_url": "string | null",
  "owned": false,
  "user_fields": {
    "key": "value"
  },
  "created_at": "2025-11-02T13:31:52",
  "updated_at": "2025-11-02T13:31:52"
}
```

#### POST /api/items/
새 아이템을 생성합니다.

**Request**
```http
POST /api/items/
Authorization: {user_id}
Content-Type: application/json

{
  "catalog_id": "uuid",       // 필수
  "name": "string",           // 필수
  "description": "string",    // 필수
  "image_url": "string",      // 선택
  "owned": false,             // 선택 (기본값: false)
  "user_fields": {            // 선택 (기본값: {})
    "key": "value"
  }
}
```

**Response**
```json
{
  "item_id": "uuid",
  "catalog_id": "uuid",
  "name": "string",
  "description": "string",
  "image_url": "string | null",
  "owned": false,
  "user_fields": {
    "key": "value"
  },
  "created_at": "2025-11-02T13:31:52",
  "updated_at": "2025-11-02T13:31:52"
}
```

#### PUT /api/items/{item_id}
아이템 정보를 수정합니다.

**Request**
```http
PUT /api/items/{item_id}
Authorization: {user_id}
Content-Type: application/json

{
  "name": "string",           // 선택
  "description": "string",    // 선택
  "image_url": "string",      // 선택
  "owned": true,              // 선택
  "user_fields": {            // 선택
    "key": "value"
  }
}
```

**Response**
```json
{
  "item_id": "uuid",
  "catalog_id": "uuid",
  "name": "string",
  "description": "string",
  "image_url": "string | null",
  "owned": true,
  "user_fields": {
    "key": "value"
  },
  "created_at": "2025-11-02T13:31:52",
  "updated_at": "2025-11-02T13:32:15"
}
```

#### PATCH /api/items/{item_id}/toggle-owned
아이템의 보유 여부를 토글합니다.

**Request**
```http
PATCH /api/items/{item_id}/toggle-owned
Authorization: {user_id}
```

**Response**
```json
{
  "item_id": "uuid",
  "catalog_id": "uuid",
  "name": "string",
  "description": "string",
  "image_url": "string | null",
  "owned": true,              // 토글된 값
  "user_fields": {
    "key": "value"
  },
  "created_at": "2025-11-02T13:31:52",
  "updated_at": "2025-11-02T13:32:20"  // 업데이트 시간 갱신
}
```

#### DELETE /api/items/{item_id}
아이템을 삭제합니다.

**Request**
```http
DELETE /api/items/{item_id}
Authorization: {user_id}
```

**Response**
```json
{
  "message": "아이템이 성공적으로 삭제되었습니다"
}
```

---

### 4. 파일 업로드 API

#### POST /api/upload/file
파일을 업로드합니다.

**Request**
```http
POST /api/upload/file
Authorization: {user_id}
Content-Type: multipart/form-data

file: [binary data]
```

**Response**
```json
{
  "upload_url": "",
  "file_url": "/uploads/images/{user_id}/{year}/{month}/{day}/{filename}"
}
```

#### DELETE /api/upload/file
업로드된 파일을 삭제합니다.

**Request**
```http
DELETE /api/upload/file
Authorization: {user_id}
Content-Type: application/json

{
  "file_url": "/uploads/images/{user_id}/{year}/{month}/{day}/{filename}"
}
```

**Response**
```json
{
  "message": "파일이 성공적으로 삭제되었습니다"
}
```

---

## 데이터 모델

### Catalog
```typescript
interface Catalog {
  catalog_id: string;        // UUID
  user_id: string;          // 사용자 ID
  title: string;            // 카탈로그 제목
  description: string;      // 카탈로그 설명
  category: string;         // 카테고리 (기본값: "미분류")
  tags: string[];           // 태그 배열
  visibility: "public" | "private";  // 공개 여부
  thumbnail_url?: string;   // 썸네일 URL (선택)
  created_at: string;       // 생성일 (ISO 8601)
  updated_at: string;       // 수정일 (ISO 8601)
  item_count: number;       // 아이템 개수 (계산됨)
  owned_count: number;      // 보유 아이템 개수 (계산됨)
  completion_rate: number;  // 수집률 (계산됨, 0-100)
}
```

### Item
```typescript
interface Item {
  item_id: string;          // UUID
  catalog_id: string;       // 카탈로그 ID (FK)
  name: string;             // 아이템명
  description: string;      // 아이템 설명
  image_url?: string;       // 이미지 URL (선택)
  owned: boolean;           // 보유 여부
  user_fields: Record<string, string>;  // 사용자 정의 필드
  created_at: string;       // 생성일 (ISO 8601)
  updated_at: string;       // 수정일 (ISO 8601)
}
```

---

## HTTP 상태 코드

| 코드 | 의미 | 사용 상황 |
|------|------|-----------|
| 200 | OK | 성공적인 GET, PUT, PATCH, DELETE |
| 201 | Created | 성공적인 POST (리소스 생성) |
| 400 | Bad Request | 잘못된 요청 데이터 |
| 401 | Unauthorized | 인증 실패 |
| 403 | Forbidden | 권한 없음 |
| 404 | Not Found | 리소스를 찾을 수 없음 |
| 500 | Internal Server Error | 서버 내부 오류 |

---

## 에러 응답 형식

```json
{
  "error": "오류 메시지",
  "detail": "상세 오류 정보 (선택)"
}
```

예시:
```json
{
  "error": "카탈로그를 찾을 수 없습니다",
  "detail": "catalog_id: invalid-uuid"
}
```

---

## 특별한 기능

### 1. 실시간 수집률 계산
카탈로그 조회 시 `completion_rate`가 실시간으로 계산됩니다:
```
completion_rate = (owned_count / item_count) * 100
```

### 2. 사용자 정의 필드
아이템에 임의의 키-값 쌍을 저장할 수 있습니다:
```json
{
  "user_fields": {
    "제조사": "굿스마일컴퍼니",
    "시리즈": "하츠네 미쿠",
    "스케일": "1/8",
    "희귀도": "SSR"
  }
}
```

### 3. 자동 타임스탬프
모든 리소스의 `created_at`과 `updated_at`은 서버에서 자동 관리됩니다.

### 4. UUID 자동 생성
모든 ID는 서버에서 UUID v4 형식으로 자동 생성됩니다.