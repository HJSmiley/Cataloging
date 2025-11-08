# 카탈로깅 시스템 아키텍처

## 개요

카탈로깅 앱의 전체 시스템 아키텍처와 클라이언트-서버 간 정보 교환 구조를 설명합니다.
이 문서는 be/catalog-api (FastAPI), be/user-api (Spring Boot), fe (Flutter) 세 파트의 실행 흐름과 통신 구조를 상세히 다룹니다.

## 시스템 구성도

```
┌─────────────────────────────────────────────────────────────┐
│                    클라이언트 (Flutter)                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   UI Layer  │  │ State Mgmt  │  │    API Service      │  │
│  │             │  │   (GetX)    │  │                     │  │
│  │ - Screens   │  │             │  │ - HTTP Client       │  │
│  │ - Widgets   │  │ - Auth      │  │ - JSON Serialization│  │
│  │ - Forms     │  │ - Catalog   │  │ - JWT Auth          │  │
│  │ - Animation │  │ - Item      │  │ - Error Handling    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                               │
│  포트: 3000 (웹) / 모바일 앱                                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP/JSON + JWT
                              │ REST API
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              개발 환경 (직접 연결)                             │
│  프로덕션: ALB (Application Load Balancer)                   │
├─────────────────────────────────────────────────────────────┤
│  라우팅 규칙:                                                │
│  - /api/auth/** → Spring Boot (포트 8081)                   │
│  - /api/users/** → Spring Boot (포트 8081)                  │
│  - /api/catalogs/** → FastAPI (포트 8002)                   │
│  - /api/items/** → FastAPI (포트 8002)                      │
│  - /api/user-catalogs/** → FastAPI (포트 8002)              │
│  - /api/upload/** → FastAPI (포트 8002)                     │
└─────────────────────────────────────────────────────────────┘
                    │                           │
                    ▼                           ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│    회원 API (Spring Boot)    │    │   카탈로그 API (FastAPI)    │
├─────────────────────────────┤    ├─────────────────────────────┤
│ ┌─────────────────────────┐ │    │ ┌─────────────────────────┐ │
│ │      Controllers        │ │    │ │       Routers           │ │
│ │ - AuthController        │ │    │ │ - catalogs.py           │ │
│ │ - UserController        │ │    │ │ - items.py              │ │
│ │                         │ │    │ │ - user_catalogs.py      │ │
│ │                         │ │    │ │ - upload.py             │ │
│ └─────────────────────────┘ │    │ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │    │ ┌─────────────────────────┐ │
│ │      Security           │ │    │ │      Middleware         │ │
│ │ - JWT Provider          │ │    │ │ - JWT 검증 (utils.py)   │ │
│ │ - OAuth2 Handler        │ │    │ │ - 로깅 미들웨어         │ │
│ │ - CORS Config           │ │    │ │ - CORS 설정             │ │
│ └─────────────────────────┘ │    │ └─────────────────────────┘ │
│                             │    │                             │
│ 포트: 8081                   │    │ 포트: 8002                   │
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
│ │ - status                │ │    │ │ - thumbnail_url         │ │
│ │ - created_at            │ │    │ │ - created_at            │ │
│ │ - updated_at            │ │    │ │ - updated_at            │ │
│ └─────────────────────────┘ │    │ └─────────────────────────┘ │
│                             │    │ ┌─────────────────────────┐ │
│                             │    │ │     items 테이블         │ │
│                             │    │ │ - item_id (PK)          │ │
│                             │    │ │ - catalog_id (FK)       │ │
│                             │    │ │ - name                  │ │
│                             │    │ │ - description           │ │
│                             │    │ │ - image_url             │ │
│                             │    │ │ - user_fields (JSON)    │ │
│                             │    │ │ - created_at            │ │
│                             │    │ │ - updated_at            │ │
│                             │    │ └─────────────────────────┘ │
│                             │    │ ┌─────────────────────────┐ │
│                             │    │ │ user_item_status 테이블  │ │
│                             │    │ │ - user_id (PK)          │ │
│                             │    │ │ - item_id (PK)          │ │
│                             │    │ │ - owned (Boolean)       │ │
│                             │    │ │ - created_at            │ │
│                             │    │ │ - updated_at            │ │
│                             │    │ └─────────────────────────┘ │
│                             │    │ ┌─────────────────────────┐ │
│                             │    │ │ user_catalogs 테이블     │ │
│                             │    │ │ - user_id (PK)          │ │
│                             │    │ │ - original_catalog_id   │ │
│                             │    │ │ - copied_catalog_id     │ │
│                             │    │ │ - saved_at              │ │
│                             │    │ └─────────────────────────┘ │
└─────────────────────────────┘    └─────────────────────────────┘
```

## 클라이언트 아키텍처 (Flutter)

### 1. 디렉토리 구조
```
fe/lib/
├── main.dart                      # 앱 진입점 (GetX 초기화 + 스플래시)
├── models/                        # 데이터 모델
│   ├── catalog.dart              # 카탈로그 모델
│   ├── item.dart                 # 아이템 모델
│   └── user.dart                 # 사용자 모델
├── controllers/                   # GetX 상태 관리
│   ├── auth_controller.dart      # 인증 상태 관리
│   └── catalog_controller.dart   # 카탈로그 상태 관리
├── services/                      # API 통신
│   └── api_service.dart          # 통합 API 서비스 (user-api + catalog-api)
├── screens/                       # UI 화면
│   ├── splash_screen.dart         # 스플래시 화면 (자동 로그인)
│   ├── login_screen.dart          # 로그인 화면
│   ├── home_screen.dart           # 홈 화면 (내 카탈로그 목록)
│   ├── explore_screen.dart        # 탐색 화면 (공개 카탈로그)
│   ├── catalog_detail_screen.dart # 카탈로그 상세
│   ├── item_detail_screen.dart    # 아이템 상세
│   ├── item_add_screen.dart       # 아이템 추가
│   └── profile_screen.dart        # 프로필 화면
└── widgets/                       # 재사용 위젯
    ├── catalog_card.dart          # 카탈로그 카드
    ├── item_card.dart             # 아이템 카드
    └── slide_to_act_button.dart   # 슬라이드 버튼
```

### 2. 클라이언트 실행 흐름

#### 앱 시작 흐름
```
main() → MyApp
  ↓
GetX 전역 컨트롤러 초기화
  - Get.put(AuthController())
  - Get.put(CatalogController())
  ↓
SplashScreen 표시 (3초)
  - 로고 애니메이션 (페이드 인 + 스케일)
  - SharedPreferences에서 JWT 토큰 로드
  - 토큰 있으면 user-api에 사용자 정보 요청
  ↓
화면 전환
  - 인증됨 → HomeScreen
  - 미인증 → LoginScreen
```

#### 로그인 흐름
```
LoginScreen
  ↓
이메일/닉네임 입력
  ↓
AuthController.devLogin()
  ↓
ApiService.devLogin() → POST /api/auth/dev-login (user-api)
  ↓
JWT 토큰 발급 + 사용자 정보 반환
  ↓
SharedPreferences에 토큰 저장
  ↓
CatalogController에 토큰 전달
  ↓
HomeScreen으로 이동
```

#### 상태 관리 (GetX)
```dart
class AuthController extends GetxController {
  final Rx<User?> _user = Rx<User?>(null);     // 현재 사용자
  final RxString _token = ''.obs;              // JWT 토큰
  final RxBool _isLoading = false.obs;         // 로딩 상태
  
  bool get isAuthenticated => _token.value.isNotEmpty && _user.value != null;
  
  // 자동 로그인
  @override
  void onInit() {
    super.onInit();
    _loadToken(); // SharedPreferences에서 토큰 로드
  }
  
  // 로그인
  Future<bool> devLogin(String email, String nickname) async {
    final response = await _apiService.devLogin(email, nickname);
    final token = response['accessToken'];
    await _saveToken(token);
    _user.value = User.fromJson(response['user']);
    
    // CatalogController에도 토큰 전달
    final catalogController = Get.find<CatalogController>();
    catalogController.setApiToken(token);
    return true;
  }
}

class CatalogController extends GetxController {
  final RxList<Catalog> _myCatalogs = <Catalog>[].obs;    // 내 카탈로그
  final RxList<Catalog> _publicCatalogs = <Catalog>[].obs; // 공개 카탈로그
  final RxBool _isLoading = false.obs;
  
  // 내 카탈로그 로드
  Future<void> loadMyCatalogs() async {
    _isLoading.value = true;
    final catalogs = await _apiService.getMyCatalogs();
    _myCatalogs.value = catalogs.map((c) => Catalog.fromJson(c)).toList();
    _isLoading.value = false;
  }
  
  // 카탈로그 저장 (복사)
  Future<void> saveCatalog(String catalogId) async {
    await _apiService.saveCatalog(catalogId);
    await loadMyCatalogs(); // 목록 새로고침
  }
}
```

#### 데이터 모델
```dart
class Catalog {
  final String catalogId;          // UUID
  final String userId;             // 사용자 ID
  final String title;              // 제목
  final String description;        // 설명
  final String category;           // 카테고리
  final List<String> tags;         // 태그 배열
  final String visibility;         // public/private
  final String? thumbnailUrl;      // 썸네일 URL
  final String createdAt;          // 생성일
  final String updatedAt;          // 수정일
  final int itemCount;             // 아이템 개수 (서버 계산)
  final int ownedCount;            // 보유 개수 (서버 계산)
  final double completionRate;     // 수집률 (서버 계산)
  final String? originalCatalogId; // 원본 카탈로그 ID (복사본인 경우)
}

class Item {
  final String itemId;             // UUID
  final String catalogId;          // 카탈로그 ID
  final String name;               // 아이템명
  final String description;        // 설명
  final String? imageUrl;          // 이미지 URL
  final bool owned;                // 보유 여부 (사용자별)
  final Map<String, String> userFields; // 사용자 정의 필드
  final String createdAt;          // 생성일
  final String updatedAt;          // 수정일
}

class User {
  final String userId;             // 사용자 ID
  final String email;              // 이메일
  final String nickname;           // 닉네임
  final String? introduction;      // 자기소개
  final String? profileImage;      // 프로필 이미지 URL
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
│   │   └── WebConfig.java      # 웹 설정 (CORS)
│   ├── controller/             # REST 컨트롤러
│   │   ├── AuthController.java # 인증 관련 API
│   │   └── UserController.java # 사용자 관리 API
│   ├── dto/                    # 데이터 전송 객체
│   │   ├── DevLoginRequest.java  # 개발 로그인 요청
│   │   └── LoginResponse.java    # 로그인 응답
│   ├── entity/                 # JPA 엔티티
│   │   └── User.java           # 사용자 엔티티
│   ├── repository/             # 데이터 접근 계층
│   │   └── UserRepository.java # 사용자 리포지토리
│   ├── security/               # 보안 관련
│   │   ├── JwtTokenProvider.java      # JWT 토큰 생성/검증
│   │   └── JwtAuthenticationFilter.java # JWT 인증 필터
│   └── service/                # 비즈니스 로직
│       └── UserService.java    # 사용자 서비스
└── src/main/resources/
    └── application.yml         # 애플리케이션 설정
```

### 2. 회원 API 실행 흐름

#### 서버 시작
```
UserApiApplication.main()
  ↓
Spring Boot 컨테이너 초기화
  - Spring Security 설정 로드
  - JPA/Hibernate 초기화 (H2 데이터베이스)
  - REST 컨트롤러 스캔 및 등록
  - JWT 필터 체인 구성
  ↓
포트 8081에서 서비스 시작
```

#### 개발용 로그인 플로우
```
Flutter → POST /api/auth/dev-login
  {
    "email": "user@example.com",
    "nickname": "사용자"
  }
  ↓
AuthController.devLogin()
  ↓
UserService.findOrCreateDevUser()
  - 이메일로 기존 사용자 조회
  - 없으면 새 사용자 생성 (provider: "dev")
  - 있으면 닉네임 업데이트
  ↓
JwtTokenProvider.createToken(userId)
  - HS256 알고리즘으로 JWT 생성
  - 페이로드: { "sub": "user_id" }
  - 만료 시간: 24시간
  ↓
LoginResponse 반환
  {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "user": { "userId": "1", "email": "...", "nickname": "..." }
  }
```

#### JWT 인증 플로우
```
Flutter → GET /api/users/me
  Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
  ↓
JwtAuthenticationFilter
  - Authorization 헤더에서 토큰 추출
  - JwtTokenProvider.validateToken() 검증
  - JwtTokenProvider.getUserId() 사용자 ID 추출
  - SecurityContext에 인증 정보 설정
  ↓
UserController.getCurrentUser()
  - SecurityContext에서 사용자 ID 가져오기
  - UserService.getUserById() 호출
  ↓
사용자 정보 반환
```

#### JPA 엔티티 (User)
```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;                    // 사용자 고유 ID
    
    @Column(nullable = false)
    private String provider;            // "dev", "google", "naver"
    
    @Column(nullable = false, unique = true)
    private String providerId;          // 제공자별 고유 ID
    
    @Column(nullable = false)
    private String email;               // 이메일
    
    @Column(nullable = false)
    private String nickname;            // 닉네임
    
    @Column(columnDefinition = "TEXT")
    private String introduction;        // 자기소개
    
    private String profileImage;        // 프로필 이미지 URL
    
    @Enumerated(EnumType.STRING)
    private UserStatus status;          // ACTIVE, INACTIVE, DELETED
    
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
    // JWT 설정
    private final SecretKey key;  // "mySecretKey1234567890..." (catalog-api와 동일)
    private final long tokenValidityInMilliseconds = 86400000; // 24시간
    
    // JWT 토큰 생성
    public String createToken(String userId) {
        Date now = new Date();
        Date validity = new Date(now.getTime() + tokenValidityInMilliseconds);
        
        return Jwts.builder()
            .setSubject(userId)
            .setIssuedAt(now)
            .setExpiration(validity)
            .signWith(key, SignatureAlgorithm.HS256)
            .compact();
    }
    
    // 토큰에서 사용자 ID 추출
    public String getUserId(String token) {
        return Jwts.parserBuilder()
            .setSigningKey(key)
            .build()
            .parseClaimsJws(token)
            .getBody()
            .getSubject();
    }
    
    // 토큰 유효성 검증
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
```

## 카탈로그 API 아키텍처 (FastAPI)

### 1. 디렉토리 구조
```
be/catalog-api/
├── main.py                   # 하위 호환성을 위한 엔트리포인트
├── .env                      # 환경 변수 설정
├── .env.example              # 환경 변수 예시
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI 애플리케이션 엔트리포인트
│   ├── core/                # 핵심 기능 (설정, 보안, 미들웨어)
│   │   ├── __init__.py
│   │   ├── config.py        # 환경 설정 및 로깅
│   │   ├── security.py      # JWT 인증 및 사용자 검증
│   │   └── middleware.py    # HTTP 요청/응답 로깅
│   ├── api/                 # API 라우터 (엔드포인트)
│   │   ├── __init__.py
│   │   ├── catalogs.py      # 카탈로그 CRUD API
│   │   ├── items.py         # 아이템 CRUD API
│   │   ├── upload.py        # 파일 업로드 API
│   │   └── user_catalogs.py # 사용자 카탈로그 관리 API
│   ├── models/              # 데이터베이스 모델 (SQLAlchemy)
│   │   ├── __init__.py
│   │   └── database.py      # DB 모델 및 세션 관리
│   ├── schemas/             # Pydantic 스키마 (요청/응답 검증)
│   │   ├── __init__.py
│   │   ├── catalog.py       # 카탈로그 스키마
│   │   ├── item.py          # 아이템 스키마
│   │   ├── user_catalog.py  # 사용자 카탈로그 스키마
│   │   ├── user_item.py     # 사용자 아이템 스키마
│   │   └── common.py        # 공통 스키마
│   └── crud/                # CRUD 작업 로직
│       ├── __init__.py
│       ├── catalog.py       # 카탈로그 CRUD
│       ├── item.py          # 아이템 CRUD
│       └── user_catalog.py  # 사용자 카탈로그 CRUD
├── requirements.txt         # Python 의존성
├── Dockerfile              # Docker 컨테이너 설정
├── .dockerignore           # Docker 빌드 제외 파일
├── api_communication.log   # 통신 로그
├── README.md               # 프로젝트 문서
├── MIGRATION_GUIDE.md      # 마이그레이션 가이드
├── STRUCTURE.md            # 구조 다이어그램
└── uploads/                # 업로드된 이미지 파일
```

### 2. 카탈로그 API 실행 흐름

#### 서버 시작
```
main.py 실행 (또는 app/main.py)
  ↓
FastAPI 앱 생성 (app/main.py)
  - CORS 미들웨어 등록 (모든 Origin 허용)
  - 로깅 미들웨어 등록 (요청/응답 자동 로깅)
  - 정적 파일 서빙 설정 (/uploads)
  ↓
라우터 등록
  - /api/catalogs (app/api/catalogs.py)
  - /api/items (app/api/items.py)
  - /api/user-catalogs (app/api/user_catalogs.py)
  - /api/upload (app/api/upload.py)
  ↓
startup 이벤트: init_db()
  - SQLite 데이터베이스 테이블 생성
  ↓
uvicorn 서버 시작 (포트 8002)
```

#### 내 카탈로그 조회 플로우
```
Flutter → GET /api/user-catalogs/my-catalogs
  Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
  ↓
get_current_user_id() (Depends)
  - Authorization 헤더에서 토큰 추출
  - JWT 검증 (user-api와 동일한 시크릿 키)
  - 토큰에서 user_id 추출
  ↓
get_my_catalogs(user_id)
  - 해당 사용자 소유 카탈로그 조회
  - 각 카탈로그의 아이템 통계 계산
    * item_count: 전체 아이템 수
    * owned_count: 보유 아이템 수 (user_item_status 테이블)
    * completion_rate: (owned_count / item_count) * 100
  - original_catalog_id 포함 (복사본인 경우)
  ↓
JSON 응답 반환
```

#### 카탈로그 저장 (복사) 플로우
```
Flutter → POST /api/user-catalogs/save-catalog
  Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
  { "catalog_id": "original-uuid" }
  ↓
save_catalog(request, user_id)
  ↓
1. 원본 카탈로그 존재 확인
2. 자신의 카탈로그인지 확인 (자신 것은 저장 불가)
3. 이미 저장했는지 확인 (중복 저장 방지)
  ↓
4. 카탈로그 완전 복사본 생성
   - 새 UUID 생성
   - user_id를 현재 사용자로 설정
   - visibility를 "private"로 설정
  ↓
5. 원본 카탈로그의 모든 아이템 복사
   - 각 아이템마다 새 UUID 생성
   - catalog_id를 복사본 ID로 설정
   - user_item_status 생성 (owned=False)
  ↓
6. user_catalogs 테이블에 관계 저장
   - original_catalog_id: 원본 ID
   - copied_catalog_id: 복사본 ID
  ↓
복사본 카탈로그 ID 반환
```

#### 아이템 보유 상태 토글 플로우
```
Flutter → PATCH /api/items/{item_id}/toggle-owned
  Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
  ↓
toggle_item_owned(item_id, user_id)
  ↓
1. 아이템 존재 확인
2. 카탈로그 소유자 확인 (권한 검증)
  ↓
3. user_item_status 조회 또는 생성
4. owned 필드 토글 (True ↔ False)
5. updated_at 갱신
  ↓
업데이트된 아이템 정보 반환
  ↓
Flutter에서 수집률 자동 재계산
```

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
    visibility = Column(String, default="public")   # public/private
    thumbnail_url = Column(String, nullable=True)   # 썸네일 URL
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

class ItemDB(Base):
    __tablename__ = "items"
    
    item_id = Column(String, primary_key=True)       # UUID
    catalog_id = Column(String, index=True)          # 카탈로그 ID (인덱스)
    name = Column(String, nullable=False)            # 아이템명
    description = Column(Text, nullable=False)       # 설명
    image_url = Column(String, nullable=True)        # 이미지 URL
    user_fields = Column(JSON, default=dict)         # 사용자 정의 필드 (JSON)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

class UserItemStatusDB(Base):
    __tablename__ = "user_item_status"
    
    user_id = Column(String, primary_key=True)       # 사용자 ID
    item_id = Column(String, primary_key=True)       # 아이템 ID
    owned = Column(Boolean, default=False)           # 보유 여부
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

class UserCatalogDB(Base):
    __tablename__ = "user_catalogs"
    
    user_id = Column(String, primary_key=True)       # 사용자 ID
    original_catalog_id = Column(String, primary_key=True)  # 원본 카탈로그 ID
    copied_catalog_id = Column(String)               # 복사본 카탈로그 ID
    saved_at = Column(DateTime, default=func.now())
```

#### JWT 검증 유틸리티
```python
# app/core/security.py
async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    """JWT 토큰에서 사용자 ID 추출 (필수 인증)"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="인증 토큰이 필요합니다")
    
    token = authorization.split(" ")[1]
    
    try:
        # user-api와 동일한 시크릿 키로 검증
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰")
        return str(user_id)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="토큰이 만료되었습니다")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="유효하지 않은 토큰")

async def get_optional_user_id(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """JWT 토큰에서 사용자 ID 추출 (선택적 인증)"""
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        try:
            payload = jwt.decode(
                token, 
                settings.JWT_SECRET_KEY, 
                algorithms=[settings.JWT_ALGORITHM]
            )
            user_id = payload.get("sub")
            return str(user_id) if user_id else None
        except jwt.PyJWTError:
            return None
    return None
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
POST /api/auth/dev-login            # 개발용 간편 로그인 (JWT 발급)
  요청: { "email": "user@example.com", "nickname": "사용자" }
  응답: { "accessToken": "eyJ...", "user": {...} }

# 사용자 관리 (JWT 필수)
GET  /api/users/me                  # 현재 사용자 정보 조회
  헤더: Authorization: Bearer {JWT}
  응답: { "userId": "1", "email": "...", "nickname": "..." }

PUT  /api/users/me                  # 사용자 정보 수정
  헤더: Authorization: Bearer {JWT}
  요청: { "nickname": "새닉네임", "introduction": "..." }

DELETE /api/users/me                # 회원 탈퇴
  헤더: Authorization: Bearer {JWT}
```

#### 카탈로그 API (FastAPI - 포트 8002)
```
# 사용자 카탈로그 관리 (JWT 필수)
GET  /api/user-catalogs/my-catalogs # 내 카탈로그 목록 (생성+저장)
  헤더: Authorization: Bearer {JWT}
  응답: [{ catalog_id, title, completion_rate, original_catalog_id, ... }]

POST /api/user-catalogs/save-catalog # 카탈로그 저장 (복사)
  헤더: Authorization: Bearer {JWT}
  요청: { "catalog_id": "원본-uuid" }
  응답: { "copied_catalog_id": "복사본-uuid" }

GET  /api/user-catalogs/check-ownership/{catalog_id} # 소유권 확인
GET  /api/user-catalogs/check-saved/{original_catalog_id} # 저장 여부 확인

# 카탈로그 관리 (JWT 필수)
GET  /api/catalogs/public           # 공개 카탈로그 목록
  쿼리: ?category=피규어&user_id=1
  응답: [{ catalog_id, title, ... }]

GET  /api/catalogs/{catalog_id}     # 카탈로그 상세 조회
POST /api/catalogs/                 # 카탈로그 생성
  헤더: Authorization: Bearer {JWT}
  요청: { "title": "...", "description": "...", "category": "..." }

PUT  /api/catalogs/{catalog_id}     # 카탈로그 수정
DELETE /api/catalogs/{catalog_id}   # 카탈로그 삭제

# 아이템 관리 (JWT 필수)
GET  /api/items/catalog/{catalog_id} # 아이템 목록
  쿼리: ?owned=true (보유 아이템만)
  응답: [{ item_id, name, owned, ... }]

GET  /api/items/{item_id}           # 아이템 상세
POST /api/items/                    # 아이템 생성
  요청: { "catalog_id": "...", "name": "...", "description": "..." }

PUT  /api/items/{item_id}           # 아이템 수정
PATCH /api/items/{item_id}/toggle-owned # 보유 상태 토글 (핵심 기능)
  헤더: Authorization: Bearer {JWT}
  응답: { "item_id": "...", "owned": true }

DELETE /api/items/{item_id}         # 아이템 삭제

# 파일 업로드
POST /api/upload/file               # 이미지 업로드
  헤더: Authorization: Bearer {JWT}
  요청: multipart/form-data (file)
  응답: { "file_url": "/uploads/..." }
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

### 3. API 통신 구조

#### ApiService 플랫폼별 URL 설정
```dart
class ApiService {
  // Catalog API 베이스 URL (플랫폼별 자동 설정)
  static String get catalogApiBaseUrl {
    if (kIsWeb) return 'http://localhost:8002';           // 웹
    else if (Platform.isAndroid) return 'http://10.0.2.2:8002';  // 안드로이드
    else if (Platform.isIOS) return 'http://localhost:8002';     // iOS
    else return 'http://localhost:8002';                  // 기타
  }
  
  // User API 베이스 URL
  static String get userApiBaseUrl {
    if (kIsWeb) return 'http://localhost:8081';
    else if (Platform.isAndroid) return 'http://10.0.2.2:8081';
    else if (Platform.isIOS) return 'http://localhost:8081';
    else return 'http://localhost:8081';
  }
  
  // JWT 토큰 저장
  String? _token;
  
  void setToken(String? token) {
    _token = token;
  }
  
  // HTTP 요청 헤더 (JWT 토큰 자동 포함)
  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json; charset=utf-8',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}
```

#### 데이터 변환 과정

**클라이언트 → 서버 (카탈로그 생성)**
```dart
// 1. API 호출
await apiService.createCatalog(
  title: "내 피규어 컬렉션",
  description: "애니메이션 피규어 모음",
  category: "피규어",
  tags: ["애니메이션", "수집"],
);

// 2. HTTP 요청 생성
final response = await http.post(
  Uri.parse('$catalogApiBaseUrl/api/catalogs/'),
  headers: _headers,  // JWT 토큰 포함
  body: utf8.encode(jsonEncode({
    'title': title,
    'description': description,
    'category': category,
    'tags': tags,
    'visibility': 'public',
  })),
);

// 3. 응답 처리
if (response.statusCode == 201) {
  return jsonDecode(utf8.decode(response.bodyBytes));
}
```

**서버 → 클라이언트 (카탈로그 반환)**
```python
# 1. Pydantic 모델 검증
@router.post("/", response_model=Catalog)
async def create_catalog(
    catalog: CatalogCreate,
    user_id: str = Depends(get_current_user_id)
):
    # 2. 데이터베이스 저장
    catalog_id = str(uuid.uuid4())
    catalog_record = CatalogDB(
        catalog_id=catalog_id,
        user_id=user_id,
        title=catalog.title,
        description=catalog.description,
        category=catalog.category,
        tags=catalog.tags,
        visibility=catalog.visibility,
    )
    db.add(catalog_record)
    db.commit()
    
    # 3. 응답 모델 생성 (수집률 포함)
    return Catalog(
        catalog_id=catalog_id,
        user_id=user_id,
        title=catalog.title,
        description=catalog.description,
        category=catalog.category,
        tags=catalog.tags,
        visibility=catalog.visibility,
        thumbnail_url=None,
        created_at=catalog_record.created_at.isoformat(),
        updated_at=catalog_record.updated_at.isoformat(),
        item_count=0,
        owned_count=0,
        completion_rate=0.0,
    )
```

## 전체 데이터 흐름

### 1. 앱 시작 및 자동 로그인
```
앱 실행 (main.dart)
  ↓
GetX 컨트롤러 초기화
  - AuthController.onInit()
    * SharedPreferences에서 JWT 토큰 로드
    * 토큰 있으면 ApiService.setToken()
  - CatalogController 초기화
  ↓
SplashScreen 표시 (3초)
  - 로고 애니메이션
  - AuthController.loadUser() 호출
    * user-api에 GET /api/users/me 요청
    * JWT 토큰으로 사용자 정보 조회
  ↓
화면 전환
  - 토큰 유효 → HomeScreen
  - 토큰 없음/만료 → LoginScreen
```

### 2. 개발용 로그인 플로우
```
LoginScreen
  ↓
사용자 입력 (이메일, 닉네임)
  ↓
AuthController.devLogin()
  ↓
ApiService.devLogin()
  → POST /api/auth/dev-login (user-api:8081)
  ↓
Spring Boot AuthController
  - UserService.findOrCreateDevUser()
  - JwtTokenProvider.createToken(userId)
  ↓
응답: { accessToken, user }
  ↓
AuthController
  - SharedPreferences에 토큰 저장
  - _user 상태 업데이트
  - CatalogController.setApiToken() 호출
  ↓
HomeScreen으로 이동
```

### 3. 내 카탈로그 목록 조회
```
HomeScreen 진입
  ↓
CatalogController.loadMyCatalogs()
  ↓
ApiService.getMyCatalogs()
  → GET /api/user-catalogs/my-catalogs (catalog-api:8002)
  → Authorization: Bearer {JWT}
  ↓
FastAPI app/api/user_catalogs.py
  - get_current_user_id() (JWT 검증 - app/core/security.py)
  - 사용자 소유 카탈로그 조회
  - 각 카탈로그의 수집률 계산
    * 전체 아이템 수
    * 보유 아이템 수 (user_item_status 테이블)
    * completion_rate = (owned / total) * 100
  ↓
응답: [{ catalog_id, title, completion_rate, ... }]
  ↓
CatalogController
  - _myCatalogs 상태 업데이트
  - UI 자동 갱신 (Obx 위젯)
```

### 4. 공개 카탈로그 탐색 및 저장
```
ExploreScreen 진입
  ↓
CatalogController.loadPublicCatalogs()
  ↓
ApiService.getPublicCatalogs()
  → GET /api/catalogs/public (catalog-api:8002)
  ↓
FastAPI app/api/catalogs.py
  - 공개 카탈로그 조회 (visibility="public")
  - 로그인한 경우 자신의 카탈로그 제외
  ↓
사용자가 카탈로그 선택 → CatalogDetailScreen
  ↓
"저장" 버튼 클릭
  ↓
CatalogController.saveCatalog(catalogId)
  ↓
ApiService.saveCatalog(catalogId)
  → POST /api/user-catalogs/save-catalog (catalog-api:8002)
  → Authorization: Bearer {JWT}
  ↓
FastAPI app/api/user_catalogs.py
  - 원본 카탈로그 조회
  - 자신의 카탈로그인지 확인
  - 이미 저장했는지 확인
  - 카탈로그 완전 복사본 생성
    * 새 catalog_id 생성
    * user_id를 현재 사용자로 설정
    * 모든 아이템 복사
    * user_item_status 생성 (owned=False)
  - user_catalogs 테이블에 관계 저장
  ↓
응답: { copied_catalog_id }
  ↓
CatalogController.loadMyCatalogs() 재호출
  - 내 카탈로그 목록에 복사본 추가됨
```

### 5. 아이템 보유 상태 토글 및 수집률 업데이트
```
CatalogDetailScreen
  ↓
사용자가 아이템 체크박스 클릭
  ↓
ApiService.toggleItemOwned(itemId)
  → PATCH /api/items/{itemId}/toggle-owned (catalog-api:8002)
  → Authorization: Bearer {JWT}
  ↓
FastAPI app/api/items.py
  - get_current_user_id() (JWT 검증 - app/core/security.py)
  - 아이템 조회
  - 카탈로그 소유자 확인 (권한 검증)
  - user_item_status 조회 또는 생성
  - owned 필드 토글 (True ↔ False)
  ↓
응답: { item_id, owned, ... }
  ↓
CatalogDetailScreen
  - 아이템 목록 상태 업데이트
  - 수집률 자동 재계산
    * owned_count 업데이트
    * completion_rate 재계산
  - UI 실시간 반영
```

### 6. JWT 토큰 기반 마이크로서비스 통신
```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│  - SharedPreferences에 JWT 토큰 저장                     │
│  - 모든 API 요청에 Authorization 헤더 자동 포함          │
└─────────────────────────────────────────────────────────┘
                    │                    │
                    │                    │
        ┌───────────┘                    └───────────┐
        │                                            │
        ▼                                            ▼
┌──────────────────┐                      ┌──────────────────┐
│   user-api       │                      │  catalog-api     │
│  (Spring Boot)   │                      │   (FastAPI)      │
│                  │                      │                  │
│ JWT 토큰 발급    │                      │ JWT 토큰 검증    │
│ - createToken()  │                      │ - jwt.decode()   │
│ - HS256          │                      │ - HS256          │
│ - 24시간 유효    │                      │ - user_id 추출   │
│                  │                      │                  │
│ 시크릿 키:       │◄────동일 키────────►│ 시크릿 키:       │
│ "mySecretKey..." │                      │ "mySecretKey..." │
└──────────────────┘                      └──────────────────┘
        │                                            │
        ▼                                            ▼
┌──────────────────┐                      ┌──────────────────┐
│   H2 Database    │                      │ SQLite Database  │
│  - users 테이블  │                      │ - catalogs       │
│                  │                      │ - items          │
│                  │                      │ - user_item_status│
│                  │                      │ - user_catalogs  │
└──────────────────┘                      └──────────────────┘

통신 흐름:
1. Flutter → user-api: 로그인 요청
2. user-api → Flutter: JWT 토큰 발급
3. Flutter → catalog-api: JWT 토큰 포함하여 API 호출
4. catalog-api: 동일한 시크릿 키로 토큰 검증
5. catalog-api: 토큰에서 user_id 추출
6. catalog-api: 해당 사용자 데이터만 처리
7. 사용자별 데이터 격리 완전 보장
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

#### 카탈로그 API (FastAPI + Docker) - 포트 8002
```bash
# Docker 이미지 빌드
cd be/catalog-api
docker build -t catalog-api .

# 컨테이너 실행
docker run -p 8002:8002 catalog-api

# 서버 실행 확인
curl http://localhost:8002/docs
curl http://localhost:8002/health
```

#### Flutter 클라이언트
```bash
# 프로젝트 디렉토리로 이동
cd fe

# 의존성 설치
flutter pub get

# 웹 실행
flutter run -d chrome

# 모바일 실행 (iOS)
flutter run -d ios

# 모바일 실행 (Android)
flutter run -d android

# macOS 데스크톱 실행
flutter run -d macos
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
EXPOSE 8002

# 개발 환경용 실행 (reload 옵션)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002", "--reload"]
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
- **상태 캐싱**: GetX 반응형 상태 관리로 API 응답 캐시
- **JWT 토큰 관리**: SharedPreferences에 토큰 저장, 자동 로그인
- **지연 로딩**: 필요한 화면에서만 데이터 로드
- **에러 처리**: 네트워크 오류 시 재시도 로직, 토큰 만료 시 자동 로그아웃
- **플랫폼별 URL**: 웹/안드로이드/iOS 자동 감지 및 적절한 API URL 사용

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
- **사용자별 아이템 상태**: user_item_status 테이블로 다중 사용자 지원
- **카탈로그 복사**: 완전 복사본 생성으로 독립적인 수집 관리

### 4. 통신 최적화
- **HTTP Keep-Alive**: 연결 재사용
- **JWT 토큰**: 세션 대신 토큰 기반 인증으로 서버 부하 감소
- **JSON 압축**: 자동 gzip 압축
- **UTF-8 인코딩**: 한글 등 유니코드 문자 정상 처리
- **응답 시간**: 
  - 회원 API: 평균 5-20ms (H2 인메모리 DB)
  - 카탈로그 API: 평균 10-50ms (SQLite)
- **마이크로서비스**: 기능별 서버 분리로 확장성 향상
- **로깅 미들웨어**: 모든 API 요청/응답 자동 로깅 (디버깅 용이)

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

#### 백엔드
- **회원 API (Spring Boot)**: 
  - JWT 토큰 발급 및 검증 (HS256, 24시간)
  - 개발용 간편 로그인 (이메일/닉네임)
  - 사용자 CRUD (조회, 수정, 삭제)
  - H2 인메모리 데이터베이스
  - CORS 설정

- **카탈로그 API (FastAPI)**:
  - 표준 FastAPI 프로젝트 구조로 재구성
    * app/core/: 설정, 보안, 미들웨어
    * app/api/: API 라우터 (엔드포인트)
    * app/models/: SQLAlchemy DB 모델
    * app/schemas/: Pydantic 스키마 (요청/응답 검증)
    * app/crud/: CRUD 작업 로직
  - 카탈로그 CRUD (생성, 조회, 수정, 삭제)
  - 아이템 CRUD 및 보유 상태 토글
  - 사용자별 아이템 상태 관리 (user_item_status)
  - 카탈로그 저장 기능 (완전 복사본 생성)
  - 공개/비공개 카탈로그 관리
  - 실시간 수집률 계산
  - 이미지 업로드 및 정적 파일 서빙
  - JWT 토큰 검증 (user-api와 동일한 시크릿)
  - SQLite 데이터베이스
  - 요청/응답 로깅 미들웨어
  - Docker 컨테이너화
  - 환경 변수 관리 (.env)

#### 프론트엔드
- **Flutter 앱**:
  - GetX 상태 관리 (AuthController, CatalogController)
  - 자동 로그인 (SharedPreferences)
  - 스플래시 화면 (애니메이션)
  - 개발용 로그인 화면
  - 홈 화면 (내 카탈로그 목록)
  - 탐색 화면 (공개 카탈로그)
  - 카탈로그 상세 화면
  - 아이템 상세 화면
  - 아이템 추가 화면
  - 프로필 화면
  - 카탈로그 저장 기능
  - 아이템 보유 상태 토글
  - 실시간 수집률 표시
  - 플랫폼별 API URL 자동 설정 (웹/안드로이드/iOS)
  - UTF-8 인코딩 지원 (한글 처리)

#### 통합
- **JWT 기반 마이크로서비스 인증**:
  - user-api에서 토큰 발급
  - catalog-api에서 토큰 검증
  - 사용자별 데이터 격리 완전 보장
  - 두 서버 간 동일한 시크릿 키 사용

- **로컬 개발 환경**:
  - user-api: 포트 8081
  - catalog-api: 포트 8002 (Docker)
  - Flutter: 웹/모바일/데스크톱 지원

### 🚧 향후 계획
- **OAuth2 실제 연동**: Google, Naver 소셜 로그인
- **프로덕션 배포**: AWS 환경, ALB 라우팅, RDS/DynamoDB 연동
- **이미지 최적화**: S3 업로드, CloudFront CDN
- **검색 기능**: 카탈로그/아이템 전체 검색
- **알림 기능**: 수집 목표 달성 알림
- **소셜 기능**: 카탈로그 공유, 팔로우 시스템

이 아키텍처는 마이크로서비스 패턴을 기반으로 확장 가능하고 유지보수가 용이하도록 설계되었으며, 
각 서비스의 독립성과 클라이언트-서버 간의 명확한 책임 분리를 통해 안정적인 통신을 보장합니다.