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
│  │ - Forms     │  │ - Item      │  │ - Error Handling    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP/JSON
                              │ REST API
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    서버 (FastAPI)                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Router    │  │   Models    │  │     Database        │  │
│  │             │  │ (Pydantic)  │  │   (SQLAlchemy)      │  │
│  │ - Catalogs  │  │             │  │                     │  │
│  │ - Items     │  │ - Validation│  │ - ORM               │  │
│  │ - Upload    │  │ - Serializ. │  │ - Migrations        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ SQL
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   데이터베이스 (SQLite)                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐  ┌─────────────────────────────┐   │
│  │   catalogs 테이블    │  │      items 테이블           │   │
│  │                     │  │                             │   │
│  │ - catalog_id (PK)   │  │ - item_id (PK)              │   │
│  │ - user_id (INDEX)   │  │ - catalog_id (FK, INDEX)    │   │
│  │ - title             │  │ - name                      │   │
│  │ - description       │  │ - description               │   │
│  │ - category          │  │ - owned                     │   │
│  │ - tags (JSON)       │  │ - user_fields (JSON)       │   │
│  │ - visibility        │  │ - created_at                │   │
│  │ - created_at        │  │ - updated_at                │   │
│  │ - updated_at        │  │                             │   │
│  └─────────────────────┘  └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 클라이언트 아키텍처 (Flutter)

### 1. 디렉토리 구조
```
fe/lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── catalog.dart         # 카탈로그 모델
│   ├── catalog.g.dart       # JSON 직렬화 코드 (자동생성)
│   ├── item.dart            # 아이템 모델
│   └── item.g.dart          # JSON 직렬화 코드 (자동생성)
├── providers/               # 상태 관리
│   ├── catalog_provider.dart
│   └── item_provider.dart
├── services/                # API 통신
│   └── api_service.dart
└── screens/                 # UI 화면
    ├── home_screen.dart
    ├── catalog_detail_screen.dart
    ├── create_catalog_screen.dart
    └── create_item_screen.dart
```

### 2. 클라이언트가 관리하는 정보

#### 상태 관리 (Provider)
```dart
class CatalogProvider {
  List<Catalog> _catalogs = [];     // 카탈로그 목록 캐시
  bool _isLoading = false;          // 로딩 상태
  String? _error;                   // 에러 메시지
}

class ItemProvider {
  List<Item> _items = [];           // 아이템 목록 캐시
  bool _isLoading = false;          // 로딩 상태
  String? _error;                   // 에러 메시지
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
  final double completionRate;     // 수집률 (서버 계산)
}
```

## 서버 아키텍처 (FastAPI)

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
├── Dockerfile              # 컨테이너 설정
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
- **인증**: Authorization 헤더
- **CORS**: 모든 Origin 허용 (개발 환경)

### 2. 요청-응답 패턴

#### 카탈로그 생성 예시
```
클라이언트 → 서버:
POST /api/catalogs/
Authorization: flutter-user-1
Content-Type: application/json

{
  "title": "내 피규어 컬렉션",
  "description": "애니메이션 피규어 모음",
  "category": "피규어",
  "tags": ["애니메이션", "수집"],
  "visibility": "public"
}

서버 → 클라이언트:
HTTP/1.1 201 Created
Content-Type: application/json

{
  "catalog_id": "uuid-generated-by-server",
  "user_id": "flutter-user-1",
  "title": "내 피규어 컬렉션",
  "description": "애니메이션 피규어 모음",
  "category": "피규어",
  "tags": ["애니메이션", "수집"],
  "visibility": "public",
  "thumbnail_url": null,
  "created_at": "2025-11-02T13:31:38",
  "updated_at": "2025-11-02T13:31:38",
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

### 1. 카탈로그 목록 조회
```
1. 사용자가 홈 화면 진입
2. CatalogProvider.loadCatalogs() 호출
3. ApiService.getCatalogs() → GET /api/catalogs/
4. 서버에서 user_id로 필터링하여 카탈로그 조회
5. 각 카탈로그의 아이템 통계 실시간 계산
6. JSON 응답을 Catalog 객체로 변환
7. Provider 상태 업데이트
8. UI 자동 갱신
```

### 2. 아이템 보유 상태 토글
```
1. 사용자가 아이템의 스위치 터치
2. ItemProvider.toggleItemOwned() 호출
3. ApiService.toggleItemOwned() → PATCH /api/items/{id}/toggle-owned
4. 서버에서 owned 필드 토글 및 updated_at 갱신
5. 업데이트된 아이템 정보 응답
6. Provider 상태 업데이트
7. UI 즉시 반영 (스위치 상태 변경)
8. 상위 카탈로그의 수집률 자동 재계산
```

## 성능 최적화

### 1. 클라이언트 최적화
- **상태 캐싱**: Provider로 API 응답 캐시
- **지연 로딩**: 필요한 화면에서만 데이터 로드
- **에러 처리**: 네트워크 오류 시 재시도 로직

### 2. 서버 최적화
- **가상환경 격리**: Python venv로 의존성 격리 및 버전 관리
- **데이터베이스 인덱스**: user_id, catalog_id에 인덱스 설정
- **실시간 계산**: 수집률을 매번 계산하여 최신 상태 보장
- **JSON 필드**: 태그와 사용자 정의 필드를 JSON으로 저장

### 3. 통신 최적화
- **HTTP Keep-Alive**: 연결 재사용
- **JSON 압축**: 자동 gzip 압축
- **응답 시간**: 평균 10-40ms

## 보안 고려사항

### 1. 인증 및 권한
- Authorization 헤더로 사용자 식별
- 모든 API에서 사용자별 데이터 격리
- 타 사용자 데이터 접근 차단

### 2. 데이터 검증
- Pydantic으로 입력 데이터 검증
- SQL Injection 방지 (ORM 사용)
- XSS 방지 (JSON 응답)

### 3. 에러 처리
- 상세한 에러 정보는 로그에만 기록
- 클라이언트에는 일반적인 에러 메시지만 전송
- 민감한 정보 노출 방지

이 아키텍처는 확장 가능하고 유지보수가 용이하도록 설계되었으며, 
클라이언트와 서버 간의 명확한 책임 분리를 통해 안정적인 통신을 보장합니다.