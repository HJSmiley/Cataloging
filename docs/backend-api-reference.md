# 백엔드 API 레퍼런스

## 디렉토리 구조

### be/catalog-api (FastAPI - Python)
```
be/catalog-api/
├── main.py                          # 하위 호환성을 위한 엔트리포인트
├── .env                             # 환경 변수 설정
├── .env.example                     # 환경 변수 예시
├── Dockerfile                       # Docker 컨테이너 설정
├── requirements.txt                 # Python 의존성
├── catalog.db                       # SQLite 데이터베이스
├── api_communication.log            # API 통신 로그
├── README.md                        # 프로젝트 문서
├── MIGRATION_GUIDE.md               # 마이그레이션 가이드
├── STRUCTURE.md                     # 구조 다이어그램
├── app/
│   ├── __init__.py
│   ├── main.py                      # FastAPI 애플리케이션 엔트리포인트
│   ├── core/                        # 핵심 기능 (설정, 보안, 미들웨어)
│   │   ├── __init__.py
│   │   ├── config.py                # 환경 설정 및 로깅
│   │   ├── security.py              # JWT 인증 및 사용자 검증
│   │   └── middleware.py            # HTTP 요청/응답 로깅
│   ├── api/                         # API 라우터 (엔드포인트)
│   │   ├── __init__.py
│   │   ├── catalogs.py              # 카탈로그 CRUD API
│   │   ├── items.py                 # 아이템 CRUD API
│   │   ├── upload.py                # 파일 업로드 API
│   │   └── user_catalogs.py         # 사용자 카탈로그 관리 API
│   ├── models/                      # 데이터베이스 모델 (SQLAlchemy)
│   │   ├── __init__.py
│   │   └── database.py              # DB 모델 및 세션 관리
│   ├── schemas/                     # Pydantic 스키마 (요청/응답 검증)
│   │   ├── __init__.py
│   │   ├── catalog.py               # 카탈로그 스키마
│   │   ├── item.py                  # 아이템 스키마
│   │   ├── user_catalog.py          # 사용자 카탈로그 스키마
│   │   ├── user_item.py             # 사용자 아이템 스키마
│   │   └── common.py                # 공통 스키마
│   └── crud/                        # CRUD 작업 로직
│       ├── __init__.py
│       ├── catalog.py               # 카탈로그 CRUD
│       ├── item.py                  # 아이템 CRUD
│       └── user_catalog.py          # 사용자 카탈로그 CRUD
└── uploads/                         # 업로드된 이미지 파일
```

### be/user-api (Spring Boot - Java)
```
be/user-api/
├── build.gradle                     # Gradle 빌드 설정
├── gradlew                          # Gradle 래퍼 (Unix)
├── gradlew.bat                      # Gradle 래퍼 (Windows)
├── README.md
├── gradle/
│   └── wrapper/
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
└── src/main/
    ├── java/com/cataloging/userapi/
    │   ├── UserApiApplication.java  # Spring Boot 메인 클래스
    │   ├── config/
    │   │   ├── SecurityConfig.java  # Spring Security 설정
    │   │   └── WebConfig.java       # CORS 설정
    │   ├── controller/
    │   │   ├── AuthController.java  # 인증 API
    │   │   ├── UserController.java  # 사용자 관리 API
    │   │   ├── DevController.java   # 개발용 API
    │   │   └── TestController.java  # 테스트용 API
    │   ├── dto/
    │   │   └── UserDto.java         # 데이터 전송 객체
    │   ├── entity/
    │   │   └── User.java            # JPA 엔티티
    │   ├── repository/
    │   │   └── UserRepository.java  # JPA 리포지토리
    │   ├── security/
    │   │   ├── JwtTokenProvider.java       # JWT 토큰 생성/검증
    │   │   ├── JwtAuthenticationFilter.java # JWT 인증 필터
    │   │   └── OAuth2SuccessHandler.java    # OAuth2 성공 핸들러
    │   └── service/
    │       └── UserService.java     # 비즈니스 로직
    └── resources/
        └── application.yml          # 애플리케이션 설정
```

---

## API 엔드포인트

### user-api (Spring Boot) - 포트 8081

#### 인증 API (`/api/auth`)

**개발용 간편 로그인**
```
POST /api/auth/dev-login
Content-Type: application/json

요청:
{
  "email": "user@example.com",
  "nickname": "사용자"
}

응답: 200 OK
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "userId": "1",
    "email": "user@example.com",
    "nickname": "사용자",
    "introduction": null,
    "profileImage": null,
    "createdAt": "2025-11-08T10:00:00",
    "updatedAt": "2025-11-08T10:00:00"
  }
}
```

**OAuth2 로그인 URL 조회**
```
GET /api/auth/login/{provider}
Path: provider = google | naver

응답: 200 OK
{
  "loginUrl": "https://accounts.google.com/o/oauth2/v2/auth?..."
}
```

**로그아웃**
```
POST /api/auth/logout

응답: 200 OK
{
  "message": "로그아웃 성공"
}
```

#### 사용자 API (`/api/users`)

**현재 사용자 정보 조회**
```
GET /api/users/me
Authorization: Bearer {JWT}

응답: 200 OK
{
  "userId": "1",
  "email": "user@example.com",
  "nickname": "사용자",
  "introduction": "안녕하세요",
  "profileImage": "/uploads/profile.jpg",
  "createdAt": "2025-11-08T10:00:00",
  "updatedAt": "2025-11-08T10:00:00"
}
```

**사용자 정보 수정**
```
PUT /api/users/me
Authorization: Bearer {JWT}
Content-Type: application/json

요청:
{
  "nickname": "새닉네임",
  "introduction": "새 자기소개",
  "profileImage": "/uploads/new-profile.jpg"
}

응답: 200 OK
{
  "userId": "1",
  "email": "user@example.com",
  "nickname": "새닉네임",
  "introduction": "새 자기소개",
  "profileImage": "/uploads/new-profile.jpg",
  "createdAt": "2025-11-08T10:00:00",
  "updatedAt": "2025-11-08T11:00:00"
}
```

**회원 탈퇴**
```
DELETE /api/users/me
Authorization: Bearer {JWT}

응답: 200 OK
{
  "message": "회원 탈퇴가 완료되었습니다"
}
```

**특정 사용자 조회**
```
GET /api/users/{userId}
Path: userId = 사용자 ID

응답: 200 OK
{
  "userId": "1",
  "email": "user@example.com",
  "nickname": "사용자",
  "introduction": "안녕하세요",
  "profileImage": "/uploads/profile.jpg",
  "createdAt": "2025-11-08T10:00:00",
  "updatedAt": "2025-11-08T10:00:00"
}
```

#### 개발용 API (`/api/dev`)

**개발용 사용자 생성**
```
POST /api/dev/create-user
Content-Type: application/json

요청:
{
  "email": "test@example.com",
  "nickname": "테스트사용자"
}

응답: 200 OK
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "user": { ... }
}
```

**모든 사용자 조회**
```
GET /api/dev/users

응답: 200 OK
[
  {
    "userId": "1",
    "email": "user1@example.com",
    "nickname": "사용자1",
    ...
  },
  {
    "userId": "2",
    "email": "user2@example.com",
    "nickname": "사용자2",
    ...
  }
]
```

**사용자 삭제**
```
DELETE /api/dev/users/{userId}
Path: userId = 사용자 ID

응답: 200 OK
{
  "message": "사용자가 삭제되었습니다"
}
```

#### 테스트 API (`/api/test`)

**서버 상태 확인**
```
GET /api/test/health

응답: 200 OK
{
  "status": "healthy",
  "timestamp": "2025-11-08T10:00:00"
}
```

**테스트용 JWT 토큰 생성**
```
POST /api/test/create-token
Content-Type: application/json

요청:
{
  "email": "test@example.com",
  "nickname": "테스트"
}

응답: 200 OK
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "user": { ... }
}
```

**JWT 토큰 검증**
```
POST /api/test/validate-token
Content-Type: application/json

요청:
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}

응답: 200 OK
{
  "valid": true,
  "userId": "1",
  "email": "user@example.com"
}
```

---

### catalog-api (FastAPI) - 포트 8002

#### 사용자 카탈로그 API (`/api/user-catalogs`)

**내 카탈로그 목록 조회**
```
GET /api/user-catalogs/my-catalogs
Authorization: Bearer {JWT}

응답: 200 OK
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
  },
  {
    "catalog_id": "uuid-2",
    "user_id": "1",
    "title": "레고 세트 컬렉션",
    "description": "저장한 카탈로그",
    "category": "레고",
    "tags": ["레고", "빌딩"],
    "visibility": "private",
    "thumbnail_url": null,
    "created_at": "2025-11-08T11:00:00",
    "updated_at": "2025-11-08T11:00:00",
    "item_count": 20,
    "owned_count": 5,
    "completion_rate": 25.0,
    "original_catalog_id": "uuid-original"
  }
]
```

**카탈로그 저장 (복사)**
```
POST /api/user-catalogs/save-catalog
Authorization: Bearer {JWT}
Content-Type: application/json

요청:
{
  "catalog_id": "uuid-original"
}

응답: 200 OK
{
  "message": "카탈로그가 성공적으로 저장되었습니다",
  "copied_catalog_id": "uuid-copied",
  "original_catalog_id": "uuid-original"
}

에러: 400 Bad Request
{
  "detail": "자신의 카탈로그는 저장할 수 없습니다"
}

에러: 400 Bad Request
{
  "detail": "이미 저장된 카탈로그입니다"
}
```

**카탈로그 제거 (복사본 삭제)**
```
DELETE /api/user-catalogs/unsave-catalog/{catalog_id}
Authorization: Bearer {JWT}
Path: catalog_id = 삭제할 복사본 카탈로그 ID

응답: 200 OK
{
  "message": "카탈로그가 성공적으로 삭제되었습니다"
}
```

**카탈로그 소유권 확인**
```
GET /api/user-catalogs/check-ownership/{catalog_id}
Authorization: Bearer {JWT}
Path: catalog_id = 카탈로그 ID

응답: 200 OK
{
  "catalog_id": "uuid-1",
  "is_owned": true,
  "user_id": "1"
}
```

**카탈로그 저장 여부 확인**
```
GET /api/user-catalogs/check-saved/{original_catalog_id}
Authorization: Bearer {JWT}
Path: original_catalog_id = 원본 카탈로그 ID

응답: 200 OK
{
  "original_catalog_id": "uuid-original",
  "is_saved": true,
  "copied_catalog_id": "uuid-copied",
  "user_id": "1"
}
```

**디버그: 사용자 정보 확인**
```
GET /api/user-catalogs/debug/user-info
Authorization: Bearer {JWT}

응답: 200 OK
{
  "user_id": "1",
  "catalog_count": 5,
  "catalogs": [
    { "id": "uuid-1", "title": "...", "user_id": "1" }
  ],
  "all_catalogs": [
    { "id": "uuid-1", "title": "...", "user_id": "1" },
    { "id": "uuid-2", "title": "...", "user_id": "2" }
  ]
}
```

#### 카탈로그 API (`/api/catalogs`)

**내 카탈로그 목록 조회 (구버전)**
```
GET /api/catalogs/
Authorization: Bearer {JWT}

응답: 200 OK
[
  {
    "catalog_id": "uuid-1",
    "user_id": "1",
    "title": "내 피규어 컬렉션",
    ...
  }
]
```

**공개 카탈로그 목록 조회**
```
GET /api/catalogs/public
Query: ?category=피규어&user_id=1

응답: 200 OK
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
    "completion_rate": 0.0
  }
]
```

**카탈로그 상세 조회**
```
GET /api/catalogs/{catalog_id}
Path: catalog_id = 카탈로그 ID
Authorization: Bearer {JWT} (선택)

응답: 200 OK
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

**카탈로그 생성**
```
POST /api/catalogs/
Authorization: Bearer {JWT}
Content-Type: application/json

요청:
{
  "title": "새 카탈로그",
  "description": "카탈로그 설명",
  "category": "피규어",
  "tags": ["애니메이션", "수집"],
  "visibility": "public",
  "thumbnail_url": "/uploads/thumb.jpg"
}

응답: 201 Created
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

**카탈로그 수정**
```
PUT /api/catalogs/{catalog_id}
Authorization: Bearer {JWT}
Path: catalog_id = 카탈로그 ID
Content-Type: application/json

요청:
{
  "title": "수정된 제목",
  "description": "수정된 설명",
  "category": "레고",
  "tags": ["레고", "빌딩"],
  "visibility": "private",
  "thumbnail_url": "/uploads/new-thumb.jpg"
}

응답: 200 OK
{
  "catalog_id": "uuid-1",
  "user_id": "1",
  "title": "수정된 제목",
  ...
  "updated_at": "2025-11-08T13:00:00"
}
```

**카탈로그 삭제**
```
DELETE /api/catalogs/{catalog_id}
Authorization: Bearer {JWT}
Path: catalog_id = 카탈로그 ID

응답: 200 OK
{
  "message": "카탈로그가 삭제되었습니다"
}
```

#### 아이템 API (`/api/items`)

**카탈로그의 아이템 목록 조회**
```
GET /api/items/catalog/{catalog_id}
Authorization: Bearer {JWT}
Path: catalog_id = 카탈로그 ID
Query: ?owned=true (보유 아이템만 조회)

응답: 200 OK
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
  },
  {
    "item_id": "uuid-item-2",
    "catalog_id": "uuid-1",
    "name": "피규어 B",
    "description": "피규어 설명",
    "image_url": "/uploads/item2.jpg",
    "owned": false,
    "user_fields": {},
    "created_at": "2025-11-08T10:00:00",
    "updated_at": "2025-11-08T10:00:00"
  }
]
```

**아이템 상세 조회**
```
GET /api/items/{item_id}
Authorization: Bearer {JWT}
Path: item_id = 아이템 ID

응답: 200 OK
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

**아이템 생성**
```
POST /api/items/
Authorization: Bearer {JWT}
Content-Type: application/json

요청:
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

응답: 201 Created
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

**아이템 수정**
```
PUT /api/items/{item_id}
Authorization: Bearer {JWT}
Path: item_id = 아이템 ID
Content-Type: application/json

요청:
{
  "name": "수정된 아이템",
  "description": "수정된 설명",
  "image_url": "/uploads/updated-item.jpg",
  "user_fields": {
    "구매일": "2025-11-09",
    "가격": "35000"
  }
}

응답: 200 OK
{
  "item_id": "uuid-item-1",
  "catalog_id": "uuid-1",
  "name": "수정된 아이템",
  ...
  "updated_at": "2025-11-08T13:00:00"
}
```

**아이템 보유 상태 토글 (핵심 기능)**
```
PATCH /api/items/{item_id}/toggle-owned
Authorization: Bearer {JWT}
Path: item_id = 아이템 ID

응답: 200 OK
{
  "item_id": "uuid-item-1",
  "catalog_id": "uuid-1",
  "name": "피규어 A",
  "description": "피규어 설명",
  "image_url": "/uploads/item1.jpg",
  "owned": true,  // false → true로 토글됨
  "user_fields": { ... },
  "created_at": "2025-11-08T10:00:00",
  "updated_at": "2025-11-08T14:00:00"
}
```

**아이템 삭제**
```
DELETE /api/items/{item_id}
Authorization: Bearer {JWT}
Path: item_id = 아이템 ID

응답: 200 OK
{
  "message": "아이템이 삭제되었습니다"
}
```

#### 파일 업로드 API (`/api/upload`)

**이미지 파일 업로드**
```
POST /api/upload/file
Authorization: Bearer {JWT}
Content-Type: multipart/form-data

요청:
- file: (binary) 이미지 파일

응답: 200 OK
{
  "file_url": "/uploads/1/2025/11/08/uuid-filename.jpg",
  "filename": "uuid-filename.jpg"
}
```

**파일 삭제**
```
DELETE /api/upload/file
Authorization: Bearer {JWT}
Content-Type: application/json

요청:
{
  "file_url": "/uploads/1/2025/11/08/uuid-filename.jpg"
}

응답: 200 OK
{
  "message": "파일이 삭제되었습니다"
}
```

**이미지 서빙 (정적 파일)**
```
GET /api/upload/images/{user_id}/{year}/{month}/{day}/{filename}

응답: 200 OK
Content-Type: image/jpeg
(이미지 바이너리 데이터)
```

---

## 공통 사항

### 인증
- 모든 보호된 엔드포인트는 JWT 토큰 필요
- 헤더: `Authorization: Bearer {JWT}`
- 토큰 만료 시간: 24시간
- 토큰 알고리즘: HS256

### 에러 응답
```json
{
  "detail": "에러 메시지"
}
```

### HTTP 상태 코드
- 200: 성공
- 201: 생성 성공
- 400: 잘못된 요청
- 401: 인증 실패
- 403: 권한 없음
- 404: 리소스 없음
- 500: 서버 오류

### CORS
- 개발 환경: 모든 Origin 허용
- 프로덕션: 특정 도메인만 허용

### 로깅
- catalog-api: 모든 요청/응답 자동 로깅 (`api_communication.log`)
- user-api: Spring Boot 기본 로깅
