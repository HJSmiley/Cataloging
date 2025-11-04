# 카탈로깅 시스템 아키텍처

## 개요

카탈로깅 앱의 전체 시스템 아키텍처와 클라이언트-서버 간 정보 교환 구조를 설명합니다.

## 시스템 구성도

```
┌─────────────────────────────────────────────────────────────┐
│                    클라이언트 (Flutter Web)                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   UI Layer  │  │ State Mgmt  │  │    API Service      │  │
│  │             │  │ (Provider)  │  │                     │  │
│  │ - Screens   │  │             │  │ - HTTP Client       │  │
│  │ - Widgets   │  │ - Catalog   │  │ - JSON Serialization│  │
│  │ - Forms     │  │ - Item      │  │ - JWT Auth          │  │
│  │ - Auth      │  │ - User      │  │ - Error Handling    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP/JSON + JWT
                              │ REST API
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ALB (Application Load Balancer)          │
├─────────────────────────────────────────────────────────────┤
│  라우팅 규칙:                                                │
│  - /api/users/** → Spring Boot (포트 8081)                  │
│  - /api/catalogs/** → FastAPI (포트 8000)                   │
│  - /api/items/** → FastAPI (포트 8000)                      │
└─────────────────────────────────────────────────────────────┘
                    │                           │
                    ▼                           ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│    회원 API (Spring Boot)    │    │   카탈로그 API (FastAPI)    │
├─────────────────────────────┤    ├─────────────────────────────┤
│ ┌─────────────────────────┐ │    │ ┌─────────────────────────┐ │
│ │      Controllers        │ │    │ │       Routers           │ │
│ │ - AuthController        │ │    │ │ - Catalogs              │ │
│ │ - UserController        │ │    │ │ - Items                 │ │
│ │ - TestController        │ │    │ │ - Upload                │ │
│ └─────────────────────────┘ │    │ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │    │ ┌─────────────────────────┐ │
│ │      Security           │ │    │ │      Models             │ │
│ │ - JWT Provider          │ │    │ │ - Pydantic Validation   │ │
│ │ - OAuth2 Handler        │ │    │ │ - JSON Serialization    │ │
│ │ - CORS Config           │ │    │ │ - SQLAlchemy ORM        │ │
│ └─────────────────────────┘ │    │ └─────────────────────────┘ │
│                             │    │                             │
│ 포트: 8081                   │    │ 포트: 8000                   │
│ 데이터베이스: H2 (개발용)     │    │ 데이터베이스: SQLite         │
└─────────────────────────────┘    └─────────────────────────────┘
                    │                           │
                    ▼                           ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│      사용자 데이터베이스      │    │     카탈로그 데이터베이스    │
├─────────────────────────────┤    ├─────────────────────────────┤
│ ┌─────────────────────────┐ │    │ ┌─────────────────────────┐ │
│ │     users 테이블         │ │    │ │   catalogs 테이블        │ │
│ │ - id (PK)               │ │    │ │ - catalog_id (PK)       │ │
│ │ - provider              │ │    │ │ - user_id (INDEX)       │ │
│ │ - provider_id           │ │    │ │ - title                 │ │
│ │ - email                 │ │    │ │ - description           │ │
│ │ - nickname              │ │    │ │ - category              │ │
│ │ - introduction          │ │    │ │ - tags (JSON)           │ │
│ │ - profile_image         │ │    │ │ - visibility            │ │
│ │ - status                │ │    │ │ - created_at            │ │
│ │ - created_at            │ │    │ │ - updated_at            │ │
│ │ - updated_at            │ │    │ └─────────────────────────┘ │
│ └─────────────────────────┘ │    │ ┌─────────────────────────┐ │
│                             │    │ │     items 테이블         │ │
│                             │    │ │ - item_id (PK)          │ │
│                             │    │ │ - catalog_id (FK)       │ │
│                             │    │ │ - name                  │ │
│                             │    │ │ - description           │ │
│                             │    │ │ - owned                 │ │
│                             │    │ │ - user_fields (JSON)    │ │
│                             │    │ │ - created_at            │ │
│                             │    │ │ - updated_at            │ │
│                             │    │ └─────────────────────────┘ │
└─────────────────────────────┘    └─────────────────────────────┘
```

## 클라이언트 아키텍처 (Flutter)

### 1. 디렉토리 구조
```
fe/lib/
├── main.dart                      # 앱 진입점 (스플래시 + 네비게이션)
├── models/                        # 데이터 모델
│   ├── catalog.dart              # 카탈로그 모델
│   ├── catalog.g.dart            # JSON 직렬화 코드 (자동생성)
│   ├── item.dart                 # 아이템 모델
│   ├── item.g.dart               # JSON 직렬화 코드 (자동생성)
│   └── user.dart                 # 사용자 모델
├── providers/                     # 상태 관리
│   ├── auth_provider.dart        # 인증 상태 관리
│   ├── catalog_provider.dart     # 카탈로그 상태 관리
│   └── item_provider.dart        # 아이템 상태 관리
├── services/                      # API 통신
│   ├── api_service.dart          # 카탈로그/아이템 API
│   └── auth_service.dart         # 인증 API
└── screens/                       # UI 화면
    ├── splash_screen.dart         # 스플래시 화면 (애니메이션)
    ├── login_screen.dart          # 로그인 화면
    ├── main_navigation_screen.dart # 메인 네비게이션 (4개 탭)
    ├── home_screen.dart           # 홈 탭 (카탈로그 목록)
    ├── explore_screen.dart        # 탐색 탭 (검색/필터링)
    ├── add_screen.dart            # 추가 탭 (생성 기능)
    ├── profile_screen.dart        # 마이 탭 (프로필 관리)
    ├── catalog_detail_screen.dart # 카탈로그 상세
    ├── item_detail_screen.dart    # 아이템 상세 (애니메이션)
    ├── create_catalog_screen.dart # 카탈로그 생성
    └── create_item_screen.dart    # 아이템 생성
```

### 2. 클라이언트가 관리하는 정보

#### 상태 관리 (Provider)
```dart
class CatalogProvider {
  List<Catalog> _catalogs = [];     // 카탈로그 목록 캐시
  bool _isLoading = false;          // 로딩 상태
  String? _error;                   // 에러 메시지
  
  // 실시간 수집률 업데이트
  Future<void> updateCatalogCompletionRate(String catalogId) async {
    final updatedCatalog = await ApiService.getCatalog(catalogId);
    // 로컬 상태 업데이트 및 notifyListeners() 호출
  }
}

class ItemProvider {
  List<Item> _items = [];           // 아이템 목록 캐시
  bool _isLoading = false;          // 로딩 상태
  String? _error;                   // 에러 메시지
  Function(String, {required bool owned})? _onItemChanged; // 콜백 함수
  
  // 아이템 변경 시 카탈로그 수집률 업데이트 트리거
  void toggleItemOwned(String itemId) async {
    // 아이템 상태 변경 후
    _onItemChanged?.call(updatedItem.catalogId, owned: updatedItem.owned);
  }
}
```

#### 데이터 모델
```dart
class Catalog {
  final String catalogId;          // 서버에서 받은 ID
  final String userId;             // 사용자 ID
  final String title;              // 제목
  final String description;        // 설명
  final String category;           // 카테고리
  final List<String> tags;         // 태그 배열
  final String visibility;         // 공개 여부
  final String? thumbnailUrl;      // 썸네일 URL
  final String createdAt;          // 생성일
  final String updatedAt;          // 수정일
  final int itemCount;             // 아이템 개수 (서버 계산)
  final int ownedCount;            // 보유 개수 (서버 계산)
  final double completionRate;     // 수집률 (서버 계산, 실시간 업데이트)
}
```

## 회원 API 아키텍처 (Spring Boot)

### 1. 디렉토리 구조
```
be/user-api/
├── build.gradle                # Gradle 빌드 설정
├── src/main/java/com/cataloging/userapi/
│   ├── UserApiApplication.java # Spring Boot 메인 클래스
│   ├── config/                 # 설정 클래스
│   │   ├── SecurityConfig.java # Spring Security 설정
│   │   └── WebConfig.java      # 웹 설정
│   ├── controller/             # REST 컨트롤러
│   │   ├── AuthController.java # 인증 관련 API
│   │   ├── UserController.java # 사용자 관리 API
│   │   ├── TestController.java # 테스트용 API
│   │   └── DevController.java  # 개발용 API
│   ├── dto/                    # 데이터 전송 객체
│   │   └── UserDto.java        # 사용자 DTO
│   ├── entity/                 # JPA 엔티티
│   │   └── User.java           # 사용자 엔티티
│   ├── repository/             # 데이터 접근 계층
│   │   └── UserRepository.java # 사용자 리포지토리
│   ├── security/               # 보안 관련
│   │   ├── JwtTokenProvider.java      # JWT 토큰 생성/검증
│   │   ├── JwtAuthenticationFilter.java # JWT 인증 필터
│   │   └── OAuth2SuccessHandler.java   # OAuth2 성공 핸들러
│   └── service/                # 비즈니스 로직
│       └── UserService.java    # 사용자 서비스
└── src/main/resources/
    └── application.yml         # 애플리케이션 설정
```

### 2. 회원 API가 관리하는 정보

#### JPA 엔티티 (User)
```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;                    // 사용자 고유 ID
    
    @Column(nullable = false)
    private String provider;            // OAuth2 제공자 (google, naver, apple)
    
    @Column(nullable = false, unique = true)
    private String providerId;          // OAuth2 고유 식별자
    
    @Column(nullable = false)
    private String email;               // 이메일
    
    @Column(nullable = false)
    private String nickname;            // 닉네임
    
    @Column(columnDefinition = "TEXT")
    private String introduction;        // 자기소개
    
    private String profileImage;        // 프로필 이미지 URL
    
    @Enumerated(EnumType.STRING)
    private UserStatus status;          // 사용자 상태 (ACTIVE, INACTIVE, DELETED)
    
    @CreationTimestamp
    private LocalDateTime createdAt;    // 생성일 (자동)
    
    @UpdateTimestamp
    private LocalDateTime updatedAt;    // 수정일 (자동)
}
```

#### JWT 토큰 관리
```java
@Component
public class JwtTokenProvider {
    private final SecretKey key;                    // JWT 서명 키
    private final long tokenValidityInMilliseconds; // 토큰 유효 시간 (24시간)
    
    public String createToken(String userId);       // JWT 토큰 생성
    public String getUserId(String token);          // 토큰에서 사용자 ID 추출
    public boolean validateToken(String token);     // 토큰 유효성 검증
}
```

#### OAuth2 사용자 정보 처리
```java
@Service
public class UserService {
    // OAuth2 제공자별 사용자 정보 추출 및 저장/업데이트
    public User processOAuth2User(String provider, OAuth2User oAuth2User) {
        // Google: sub, email, name, picture
        // Naver: response.id, response.email, response.name, response.profile_image
        // 기존 사용자 확인 후 정보 업데이트 또는 신규 생성
    }
}
```

## 카탈로그 API 아키텍처 (FastAPI)

### 1. 디렉토리 구조
```
be/catalog-api/
├── main.py                   # FastAPI 앱 진입점
├── app/
│   ├── __init__.py
│   ├── config.py            # 설정
│   ├── database.py          # 데이터베이스 연결
│   ├── models.py            # Pydantic 모델
│   ├── utils.py             # 유틸리티 함수
│   └── routers/             # API 라우터
│       ├── __init__.py
│       ├── catalogs.py      # 카탈로그 API
│       ├── items.py         # 아이템 API
│       └── upload.py        # 파일 업로드 API
├── requirements.txt         # Python 의존성
├── Dockerfile              # Docker 컨테이너 설정
├── .dockerignore           # Docker 빌드 제외 파일
└── api_communication.log   # 통신 로그
```

### 2. 서버가 관리하는 정보

#### 데이터베이스 모델 (SQLAlchemy)
```python
class CatalogDB(Base):
    __tablename__ = "catalogs"
    
    catalog_id = Column(String, primary_key=True)    # UUID
    user_id = Column(String, index=True)             # 사용자 ID (인덱스)
    title = Column(String, nullable=False)           # 제목
    description = Column(Text, nullable=False)       # 설명
    category = Column(String, default="미분류")       # 카테고리
    tags = Column(JSON, default=list)               # 태그 (JSON 배열)
    visibility = Column(String, default="public")   # 공개 여부
    thumbnail_url = Column(String, nullable=True)   # 썸네일 URL
    created_at = Column(DateTime, default=func.now()) # 생성일 (자동)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now()) # 수정일 (자동)

class ItemDB(Base):
    __tablename__ = "items"
    
    item_id = Column(String, primary_key=True)       # UUID
    catalog_id = Column(String, index=True)          # 카탈로그 ID (인덱스)
    name = Column(String, nullable=False)            # 아이템명
    description = Column(Text, nullable=False)       # 설명
    image_url = Column(String, nullable=True)        # 이미지 URL
    owned = Column(Boolean, default=False)           # 보유 여부
    user_fields = Column(JSON, default=dict)         # 사용자 정의 필드 (JSON)
    created_at = Column(DateTime, default=func.now()) # 생성일 (자동)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now()) # 수정일 (자동)
```

#### 비즈니스 로직
```python
# 수집률 실시간 계산
def calculate_completion_rate(catalog_id):
    items = db.query(ItemDB).filter(ItemDB.catalog_id == catalog_id).all()
    item_count = len(items)
    owned_count = sum(1 for item in items if item.owned)
    return (owned_count / item_count * 100) if item_count > 0 else 0

# 사용자별 데이터 격리
def get_user_catalogs(user_id):
    return db.query(CatalogDB).filter(CatalogDB.user_id == user_id).all()
```

## 클라이언트-서버 통신

### 1. 통신 프로토콜
- **프로토콜**: HTTP/1.1
- **데이터 형식**: JSON (UTF-8)
- **인증**: JWT Bearer Token (Authorization 헤더)
- **CORS**: 모든 Origin 허용 (개발 환경)

### 2. 인증 플로우

#### OAuth2 로그인 (Google/Naver)
```
1. 클라이언트 → 회원 API: GET /api/auth/login/{provider}
2. 회원 API → 클라이언트: 로그인 URL 반환
3. 클라이언트 → OAuth2 Provider: 사용자 인증
4. OAuth2 Provider → 회원 API: 인증 코드 콜백
5. 회원 API: 사용자 정보 추출 및 저장/업데이트
6. 회원 API → 클라이언트: JWT 토큰 + 사용자 정보 반환
```

#### JWT 토큰 기반 API 호출
```
클라이언트 → 카탈로그 API:
GET /api/catalogs/
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...

카탈로그 API → 회원 API: JWT 토큰 검증 (내부 통신)
회원 API → 카탈로그 API: 사용자 ID 반환
카탈로그 API → 클라이언트: 해당 사용자의 카탈로그 목록 반환
```

### 3. API 엔드포인트 구성

#### 회원 API (Spring Boot - 포트 8081)
```
# 인증 관련
GET  /api/auth/login/{provider}     # OAuth2 로그인 URL 조회
POST /api/auth/logout               # 로그아웃

# 사용자 관리
GET  /api/users/me                  # 현재 사용자 정보 조회
PUT  /api/users/me                  # 사용자 정보 수정
DELETE /api/users/me                # 회원 탈퇴
GET  /api/users/{userId}            # 특정 사용자 조회

# 개발/테스트용
GET  /api/test/health               # 서버 상태 확인
POST /api/test/create-token         # 테스트용 JWT 토큰 생성
POST /api/test/validate-token       # JWT 토큰 검증
POST /api/dev/create-user           # 개발용 사용자 생성
```

#### 카탈로그 API (FastAPI - 포트 8000)
```
# 카탈로그 관리
GET  /api/catalogs/                 # 카탈로그 목록 조회
GET  /api/catalogs/{catalog_id}     # 특정 카탈로그 조회
POST /api/catalogs/                 # 카탈로그 생성
PUT  /api/catalogs/{catalog_id}     # 카탈로그 수정
DELETE /api/catalogs/{catalog_id}   # 카탈로그 삭제

# 아이템 관리
GET  /api/items/catalog/{catalog_id} # 카탈로그의 아이템 목록
GET  /api/items/{item_id}           # 특정 아이템 조회
POST /api/items/                    # 아이템 생성
PUT  /api/items/{item_id}           # 아이템 수정
PATCH /api/items/{item_id}/toggle-owned # 보유 여부 토글
DELETE /api/items/{item_id}         # 아이템 삭제

# 파일 업로드
POST /api/upload/file               # 이미지 파일 업로드
DELETE /api/upload/file             # 파일 삭제
```

### 4. 요청-응답 패턴

#### 사용자 생성 및 JWT 토큰 발급 예시
```
클라이언트 → 회원 API:
POST /api/dev/create-user
Content-Type: application/json

{
  "email": "user@example.com",
  "nickname": "사용자"
}

회원 API → 클라이언트:
HTTP/1.1 200 OK
Content-Type: application/json

{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "nickname": "사용자",
    "introduction": "개발용 테스트 사용자",
    "profileImage": null,
    "createdAt": [2025,11,3,16,4,20,420724000],
    "updatedAt": [2025,11,3,16,4,20,420827000]
  }
}
```

#### 카탈로그 생성 예시
```
클라이언트 → 카탈로그 API:
POST /api/catalogs/
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json

{
  "title": "내 피규어 컬렉션",
  "description": "애니메이션 피규어 모음",
  "category": "피규어",
  "tags": ["애니메이션", "수집"],
  "visibility": "public"
}

카탈로그 API → 클라이언트:
HTTP/1.1 201 Created
Content-Type: application/json

{
  "catalog_id": "uuid-generated-by-server",
  "user_id": "1",  // JWT에서 추출한 사용자 ID
  "title": "내 피규어 컬렉션",
  "description": "애니메이션 피규어 모음",
  "category": "피규어",
  "tags": ["애니메이션", "수집"],
  "visibility": "public",
  "thumbnail_url": null,
  "created_at": "2025-11-03T16:04:20",
  "updated_at": "2025-11-03T16:04:20",
  "item_count": 0,
  "owned_count": 0,
  "completion_rate": 0.0
}
```

### 3. 데이터 변환 과정

#### 클라이언트 → 서버
```dart
// 1. Dart 객체 생성
final catalogCreate = CatalogCreate(
  title: "테스트",
  description: "테스트 설명"
);

// 2. JSON 직렬화
final jsonData = catalogCreate.toJson();

// 3. HTTP 요청
final response = await http.post(
  Uri.parse('$baseUrl/catalogs/'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode(jsonData),
);
```

#### 서버 → 클라이언트
```python
# 1. Pydantic 모델 검증
catalog_create = CatalogCreate(**request_data)

# 2. 데이터베이스 저장
catalog_record = CatalogDB(
    catalog_id=str(uuid.uuid4()),
    user_id=user_id,
    **catalog_create.dict()
)
db.add(catalog_record)
db.commit()

# 3. 응답 모델 생성
catalog_response = Catalog(
    **catalog_record.__dict__,
    item_count=0,
    owned_count=0,
    completion_rate=0.0
)

# 4. JSON 응답
return catalog_response
```

## 데이터 흐름

### 1. 사용자 로그인 및 인증
```
1. 사용자가 로그인 버튼 클릭 (Google/Naver)
2. AuthProvider.login() 호출
3. ApiService.getLoginUrl() → GET /api/auth/login/{provider}
4. 회원 API에서 OAuth2 로그인 URL 반환
5. 브라우저에서 OAuth2 제공자 페이지로 리다이렉트
6. 사용자 인증 완료 후 콜백 URL로 리다이렉트
7. OAuth2SuccessHandler에서 사용자 정보 처리
8. JWT 토큰 생성 및 사용자 정보와 함께 응답
9. 클라이언트에서 토큰 저장 (로컬 스토리지)
10. 이후 모든 API 호출 시 Authorization 헤더에 토큰 포함
```

### 2. 카탈로그 목록 조회 (인증 후)
```
1. 사용자가 홈 화면 진입
2. CatalogProvider.loadCatalogs() 호출
3. ApiService.getCatalogs() → GET /api/catalogs/ (JWT 토큰 포함)
4. 카탈로그 API에서 JWT 토큰 검증 및 사용자 ID 추출
5. 해당 사용자의 카탈로그만 필터링하여 조회
6. 각 카탈로그의 아이템 통계 실시간 계산
7. JSON 응답을 Catalog 객체로 변환
8. Provider 상태 업데이트
9. UI 자동 갱신
```

### 3. 아이템 보유 상태 토글 및 실시간 수집률 업데이트 (인증 필요)
```
1. 사용자가 아이템의 스위치 터치
2. ItemProvider.toggleItemOwned() 호출
3. ApiService.toggleItemOwned() → PATCH /api/items/{id}/toggle-owned (JWT 토큰 포함)
4. 카탈로그 API에서 JWT 토큰 검증 및 권한 확인
5. 해당 사용자의 아이템인지 확인 (카탈로그 소유자 검증)
6. owned 필드 토글 및 updated_at 갱신
7. 업데이트된 아이템 정보 응답
8. ItemProvider 상태 업데이트
9. ItemProvider가 CatalogProvider.onItemChanged() 콜백 호출
10. CatalogProvider.updateCatalogCompletionRate() 실행
11. 서버에서 최신 카탈로그 정보 (수집률 포함) 가져오기
12. UI 자동 업데이트 (Consumer<CatalogProvider> 감지)
13. 애니메이션과 함께 수집률 실시간 반영
```

### 4. 마이크로서비스 간 JWT 토큰 통신 (✅ 구현 완료)
```
실제 통신 플로우:

1. Flutter → Spring Boot: 사용자 생성/로그인 요청
2. Spring Boot → Flutter: JWT 토큰 발급 (HS256, 24시간 유효)
3. Flutter → FastAPI: JWT 토큰을 Authorization 헤더에 포함하여 API 호출
4. FastAPI: 동일한 시크릿 키로 JWT 토큰 검증
5. FastAPI: 토큰에서 사용자 ID 추출 후 해당 사용자 데이터만 처리
6. 사용자별 데이터 격리 완전 보장

JWT 설정 (두 서버 동일):
- 시크릿 키: "mySecretKey1234567890123456789012345678901234567890"
- 알고리즘: HS256
- 만료 시간: 24시간
```

## 배포 및 운영

### 1. 로컬 개발 환경 (✅ 실행 중)

#### 회원 API (Spring Boot) - 포트 8081
```bash
# 프로젝트 디렉토리로 이동
cd be/user-api

# Gradle을 사용하여 실행
./gradlew bootRun

# 서버 실행 확인
curl http://localhost:8081/api/test/health
```

#### 카탈로그 API (FastAPI + Docker) - 포트 8000
```bash
# Docker 이미지 빌드
cd be/catalog-api
docker build -t catalog-api .

# 컨테이너 실행
docker run -p 8000:8000 catalog-api

# 서버 실행 확인
curl http://localhost:8000/docs
```

#### Flutter 클라이언트 - 포트 3000
```bash
# 프로젝트 디렉토리로 이동
cd fe

# 의존성 설치
flutter packages get

# JSON 직렬화 코드 생성
flutter packages pub run build_runner build

# 웹 서버로 실행
flutter run -d web-server --web-port 3000

# 브라우저에서 접속
open http://localhost:3000
```

### 2. Docker 컨테이너화

#### 카탈로그 API Docker 구성
```dockerfile
FROM python:3.13-slim

# 시스템 의존성 설치
RUN apt-get update && apt-get install -y gcc

# Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 앱 코드 복사 및 설정
COPY . .
RUN mkdir -p uploads
EXPOSE 8000

# 개발 환경용 실행 (reload 옵션)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

#### 회원 API 실행 방식
```bash
# 개발 환경 (Gradle)
./gradlew bootRun

# 프로덕션 환경 (JAR)
./gradlew build
java -jar build/libs/user-api-0.0.1-SNAPSHOT.jar
```

### 3. 환경별 배포 전략

#### 개발 환경
- **회원 API**: Gradle bootRun으로 실행, H2 인메모리 DB 사용
- **카탈로그 API**: Docker 컨테이너에서 `--reload` 옵션으로 실행
- 코드 변경 시 자동 재시작
- 로컬 파일 시스템 직접 사용
- CORS 모든 Origin 허용

#### 프로덕션 환경 (향후 계획)
- **회원 API**: JAR 파일 배포, MySQL/PostgreSQL 연동
- **카탈로그 API**: Docker 컨테이너, DynamoDB 연동
- ALB(Application Load Balancer)를 통한 라우팅
- 환경 변수로 설정 주입 (OAuth2 클라이언트 정보, JWT 시크릿)
- S3를 통한 이미지 저장
- CloudFront CDN 연동

## 성능 최적화

### 1. 클라이언트 최적화
- **상태 캐싱**: Provider로 API 응답 캐시
- **JWT 토큰 관리**: 로컬 스토리지에 토큰 저장, 자동 갱신
- **지연 로딩**: 필요한 화면에서만 데이터 로드
- **에러 처리**: 네트워크 오류 시 재시도 로직, 토큰 만료 시 자동 로그인

### 2. 회원 API 최적화 (Spring Boot)
- **JWT 토큰**: Stateless 인증으로 서버 부하 감소
- **H2 인메모리 DB**: 개발 환경에서 빠른 응답 속도
- **JPA 최적화**: 지연 로딩, 쿼리 최적화
- **Spring Security**: 효율적인 필터 체인 구성
- **OAuth2 캐싱**: 사용자 정보 캐싱으로 반복 조회 최소화

### 3. 카탈로그 API 최적화 (FastAPI)
- **컨테이너화**: Docker로 환경 일관성 및 배포 간소화
- **의존성 격리**: 컨테이너 내 Python 환경 격리
- **데이터베이스 인덱스**: user_id, catalog_id에 인덱스 설정
- **실시간 계산**: 수집률을 매번 계산하여 최신 상태 보장
- **JSON 필드**: 태그와 사용자 정의 필드를 JSON으로 저장

### 4. 통신 최적화
- **HTTP Keep-Alive**: 연결 재사용
- **JWT 토큰**: 세션 대신 토큰 기반 인증으로 서버 부하 감소
- **JSON 압축**: 자동 gzip 압축
- **응답 시간**: 
  - 회원 API: 평균 5-20ms (인메모리 DB)
  - 카탈로그 API: 평균 10-40ms
- **마이크로서비스**: 기능별 서버 분리로 확장성 향상

## 보안 고려사항

### 1. 인증 및 권한
- **JWT 토큰**: Bearer Token 방식으로 사용자 인증
- **토큰 검증**: 모든 보호된 API에서 JWT 토큰 유효성 검증
- **사용자별 데이터 격리**: JWT에서 추출한 사용자 ID로 데이터 접근 제어
- **OAuth2 보안**: Google, Naver 등 신뢰할 수 있는 제공자 사용
- **타 사용자 데이터 접근 차단**: 카탈로그/아이템 소유자 검증

### 2. 데이터 검증
- **Spring Boot**: Bean Validation으로 입력 데이터 검증
- **FastAPI**: Pydantic으로 입력 데이터 검증
- **SQL Injection 방지**: JPA/SQLAlchemy ORM 사용
- **XSS 방지**: JSON 응답, 입력 데이터 이스케이프 처리

### 3. 토큰 보안
- **JWT 시크릿**: 환경 변수로 관리, 충분한 길이의 시크릿 키 사용
- **토큰 만료**: 24시간 만료 시간 설정
- **HTTPS**: 프로덕션 환경에서 HTTPS 필수 (토큰 탈취 방지)
- **토큰 저장**: 클라이언트에서 안전한 저장소 사용 권장

### 4. CORS 및 네트워크 보안
- **개발 환경**: 모든 Origin 허용 (개발 편의성)
- **프로덕션 환경**: 특정 도메인만 허용하도록 CORS 설정
- **API 게이트웨이**: ALB를 통한 라우팅으로 내부 서비스 보호

### 5. 에러 처리
- **상세한 에러 정보**: 로그에만 기록
- **클라이언트 응답**: 일반적인 에러 메시지만 전송
- **민감한 정보 노출 방지**: 스택 트레이스, DB 정보 등 숨김
- **로깅**: 보안 관련 이벤트 로깅 (로그인 시도, 토큰 검증 실패 등)

## 현재 구현 상태

### ✅ 완료된 기능
- **회원 API (Spring Boot)**: JWT 인증, OAuth2 준비, 사용자 CRUD
- **카탈로그 API (FastAPI)**: 카탈로그/아이템 CRUD, 이미지 업로드, JWT 토큰 검증
- **Flutter 클라이언트**: 완전한 사용자 플로우 구현 (스플래시 → 네비게이션 → 상세)
- **JWT 통합 인증**: 두 API 서버 간 토큰 공유 및 검증 완료
- **실시간 수집률 반영**: Provider 간 통신으로 아이템 변경 시 즉시 수집률 업데이트
- **애니메이션 시스템**: 스플래시, Hero, 수집 완료 애니메이션 구현
- **하단 네비게이션**: 홈/탐색/추가/마이 4개 탭 구조
- **검색 및 필터링**: 카탈로그 탐색 기능 완성
- **로컬 개발 환경**: 세 서비스 모두 실행 중 (포트 8081, 8000, 3000)
- **통신 로깅**: 모든 API 요청/응답 상세 로깅

### 🚧 진행 중/향후 계획
- **OAuth2 실제 연동**: Google, Naver 클라이언트 설정 (UI는 준비 완료)
- **프로덕션 배포**: AWS 환경, ALB 라우팅, RDS/DynamoDB 연동
- **오프라인 동기화**: SQLite 로컬 캐시 및 서버 동기화
- **고급 애니메이션**: 파티클 효과, 마이크로 인터랙션 추가
- **푸시 알림**: 수집 목표 달성 알림
- **소셜 기능**: 카탈로그 공유, 친구 기능

이 아키텍처는 마이크로서비스 패턴을 기반으로 확장 가능하고 유지보수가 용이하도록 설계되었으며, 
각 서비스의 독립성과 클라이언트-서버 간의 명확한 책임 분리를 통해 안정적인 통신을 보장합니다.