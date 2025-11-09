# 🗂️ 카탈로깅 (Collectors' Companion App)

**수집가들을 위한 최적의 기록 & 공유 앱**

넘버링된 시리즈, 굿즈, 피규어, 음반, 스니커즈 등 다양한 수집품을 cataloging(목록으로 작성)하고, 나만의 컬렉션을 관리할 수 있습니다.

---

## ✨ 주요 기능

### 📦 컬렉션 만들기 & 관리
- 누구나 자유롭게 **나만의 컬렉션**을 만들 수 있습니다.
- 넘버링 아이템을 목록으로 정리해 **내가 보유한/미보유한 항목**을 한눈에 확인할 수 있습니다.
- "전종러(완전수집러)"를 위한 **수집률 % 표시** 및 **완성 뱃지**를 제공해 수집욕을 자극합니다.

### 🔖 공유 & 저장
- 직접 만든 컬렉션을 **공유하기/저장하기**로 다른 유저들과 함께 즐길 수 있습니다.
- 동일 취향의 수집가들과 **커뮤니티적 연결**이 가능합니다.
- 세상에 하나뿐인 나만의 컬렉션을 만들어 취향을 공유해 보세요.

### 🛒 쇼핑 & 트레이드
- 각 아이템을 **상품 판매 사이트**로 자동 연결해 판매처를 빠르게 확인할 수 있습니다.
- 같은 컬렉션을 수집하는 사람들끼리 **트레이드** 기능을 통해 서로에게 없는 아이템을 거래할 수 있습니다.

### 📷 자동 기록 기능
- **OCR / 이미지 인식 기능**을 지원해 사진만 찍어도 해당 아이템을 자동 검색 & 등록할 수 있습니다.

---

## 🚀 MVP

개발 기간<br>
2025.09.05 ~ 2025.12.06(예정)

### ✅ 구현 완료 기능
✅ **사용자 인증 시스템**
- JWT 기반 토큰 인증 (HS256)
- 개발용 간편 로그인
- OAuth2 소셜 로그인 준비 (Google, Naver)
- 사용자 프로필 관리 (조회/수정/삭제)

✅ **카탈로그 관리**
- 카탈로그 생성/수정/삭제
- 공개/비공개 설정
- 카테고리 및 태그 관리
- 썸네일 이미지 업로드
- 내 카탈로그 목록 조회
- 공개 카탈로그 탐색

✅ **아이템 관리**
- 아이템 추가/수정/삭제
- 이미지 업로드
- 보유 상태 토글 (체크박스)
- 사용자 정의 필드 (구매일, 가격 등)
- 실시간 수집률 계산

✅ **카탈로그 저장 기능**
- 다른 사용자의 공개 카탈로그 저장 (복사)
- 저장한 카탈로그 관리
- 소유권 및 저장 여부 확인

✅ **마이크로서비스 아키텍처**
- User API (Spring Boot): 인증 및 사용자 관리
- Catalog API (FastAPI): 카탈로그 및 아이템 관리
- Flutter 클라이언트: 웹 기반 UI
- JWT 기반 통합 인증
- 포트 번호는 환경 변수로 관리 (기본값: User API 8080, Catalog API 8000, Flutter 3000)

✅ **개발 인프라**
- 완전한 API 통신 로깅 시스템
- Health check 엔드포인트
- CORS 설정
- 에러 처리 및 검증
- 데이터베이스 (H2, SQLite)

✅ **문서화**
- 10개 시스템 개발 산출물 완성
- API 명세서 (User API, Catalog API)
- 시스템 아키텍처 문서
- 데이터 흐름 다이어그램
- 통합 테스트 가이드

### 🔄 개발 중 기능
🔄 **UI/UX 개선**
- 11개 화면 구현 중
- 반응형 디자인 적용
- 사용자 경험 최적화

### 📋 추후 개발 예정
🚫 컬렉션/아이템 검색 기능<br>
🚫 커뮤니티 기능 (댓글, 좋아요)<br>
🚫 마켓플레이스 거래(트레이드)<br>
🚫 쇼핑몰 연결<br>
🚫 자동 이미지 인식 (OCR)<br>
🚫 알림 기능<br>
🚫 통계 및 분석 대시보드

---

## 📚 개발 문서

### 📁 문서 구조
```
docs/
├── 0. 문제분석/          # 요구사항 분석 및 MVP 정의
├── 1. 설계/              # 아키텍처 설계 및 ERD
└── 2. 산출물/            # 시스템 개발 산출물 (10개)
```

### 📖 주요 문서

#### 시스템 개발 산출물 (완성)
1. **[프로젝트 개요](docs/2.%20산출물/01_프로젝트_개요.md)** - 목적, 기능, 기대효과
2. **[시스템 아키텍처](docs/2.%20산출물/02_시스템_아키텍처.md)** - 전체 구조, 데이터 흐름, 통신 구조
3. **[요구사항 명세서](docs/2.%20산출물/03_요구사항_명세서.md)** - 기능/비기능 요구사항 (FR-001~FR-022)
4. **[데이터 명세](docs/2.%20산출물/04_데이터_명세.md)** - 테이블 구조, ERD
5. **[API 명세](docs/2.%20산출물/05_API_명세.md)** - User API, Catalog API 엔드포인트
6. **[UI/UX 문서](docs/2.%20산출물/06_UI_UX_문서.md)** - 11개 화면, 이동 흐름
7. **[상태 관리 문서](docs/2.%20산출물/07_상태_관리_문서.md)** - GetX 컨트롤러 구조
8. **[보안/인증 문서](docs/2.%20산출물/08_보안_인증_문서.md)** - JWT, OAuth2
9. **[테스트 문서](docs/2.%20산출물/09_테스트_문서.md)** - 테스트 전략
10. **[운영 문서](docs/2.%20산출물/10_운영_문서.md)** - 배포, 모니터링

#### 기타 문서
- **[전체 문서 가이드](docs/README.md)** - 문서 활용 가이드
- **[PRD](docs/1.%20설계/prd.md)** - 제품 요구사항 정의서
- **[MVP 범위표](docs/0.%20문제분석/MVP%20범위표.md)** - MVP 기능 정의
- **[사용자 시나리오](docs/0.%20문제분석/사용자%20시나리오.md)** - 사용자 플로우

### 🏗️ 시스템 아키텍처

**마이크로서비스 구조**
```
Flutter Client
    ↓ HTTP/REST API
    ├─→ User API (Spring Boot)
    │   └─→ H2 Database
    │
    └─→ Catalog API (FastAPI)
        └─→ SQLite Database
```

**포트 설정**
- User API: `PORT` 환경 변수 (기본값: 8080)
- Catalog API: `PORT` 환경 변수 (기본값: 8000)
- Flutter Client: `--web-port` 옵션 (기본값: 3000)

**주요 특징**
- JWT 기반 통합 인증 (두 API 서버 간 동일한 시크릿 키)
- 사용자별 데이터 완전 격리
- 실시간 수집률 계산
- 완전한 API 통신 로깅
- Health check 엔드포인트

### 🔐 인증 흐름
```
1. Flutter → User API: 로그인 요청
2. User API → Flutter: JWT 토큰 발급
3. Flutter → Catalog API: JWT 토큰 포함 API 호출
4. Catalog API: 토큰 검증 및 user_id 추출
5. Catalog API → Flutter: 사용자별 데이터 응답
```

## 📂 프로젝트 구조

<details>
<summary>전체 디렉토리 구조</summary>

```
cataloging/
├── .git/                        # Git 버전 관리
├── .kiro/                       # Kiro AI 설정
│   └── specs/                   # 프로젝트 스펙 문서
├── .vscode/                     # VSCode 설정
├── be/                          # 백엔드
│   ├── user-api/               # Spring Boot (포트: PORT 환경 변수, 기본 8080)
│   └── catalog-api/            # FastAPI (포트: PORT 환경 변수, 기본 8000)
│       └── .venv/              # Python 가상환경 (catalog-api 전용)
├── fe/                          # Flutter 클라이언트 (포트 3000)
├── docs/                        # 프로젝트 문서
│   ├── 0. 문제분석/             # 요구사항 분석
│   ├── 1. 설계/                 # 아키텍처 설계
│   ├── 2. 산출물/               # 시스템 개발 산출물 (10개)
│   └── *.md                     # 기타 문서
├── .gitignore                   # Git 제외 파일
├── README.md                    # 프로젝트 개요
└── api_communication.log        # API 통신 로그
```

</details>

<details>
<summary>Front-End (Flutter)</summary>

```
fe/
├── lib/
│   ├── main.dart                # 앱 진입점, AuthWrapper
│   ├── controllers/             # 상태 관리 컨트롤러
│   │   ├── auth_controller.dart # 인증 상태 관리
│   │   └── catalog_controller.dart # 카탈로그 상태 관리
│   ├── models/                  # 데이터 모델
│   │   ├── user.dart           # 사용자 모델 (JWT 연동)
│   │   ├── catalog.dart        # 카탈로그 모델
│   │   └── item.dart           # 아이템 모델
│   ├── services/               # API 통신
│   │   └── api_service.dart    # 통합 API 서비스
│   ├── screens/                # UI 화면
│   │   ├── splash_screen.dart  # 스플래시 화면
│   │   ├── login_screen.dart   # 로그인 화면
│   │   ├── home_screen.dart    # 홈 화면
│   │   ├── explore_screen.dart # 탐색 화면
│   │   ├── add_screen.dart     # 추가 화면
│   │   ├── my_screen.dart      # 마이페이지
│   │   ├── catalog_detail_screen.dart # 카탈로그 상세
│   │   ├── catalog_edit_screen.dart   # 카탈로그 편집
│   │   ├── item_add_screen.dart       # 아이템 추가
│   │   ├── item_detail_screen.dart    # 아이템 상세
│   │   └── profile_edit_screen.dart   # 프로필 편집
│   └── widgets/                # 재사용 위젯
│       └── slide_to_act_button.dart # 슬라이드 버튼
├── android/                    # Android 빌드 설정
├── ios/                        # iOS 빌드 설정
├── web/                        # 웹 빌드 설정
├── test/                       # 테스트 코드
├── pubspec.yaml                # Flutter 의존성
└── analysis_options.yaml       # Dart 분석 옵션
```

</details>

<details>
<summary>Back-End: User API (Spring Boot)</summary>

```
be/user-api/
├── src/main/
│   ├── java/com/cataloging/userapi/
│   │   ├── UserApiApplication.java  # Spring Boot 진입점
│   │   ├── config/                  # 설정
│   │   │   ├── SecurityConfig.java  # Spring Security 설정
│   │   │   └── CorsConfig.java      # CORS 설정
│   │   ├── controller/              # REST API 컨트롤러
│   │   │   ├── AuthController.java  # 인증 API
│   │   │   └── UserController.java  # 사용자 API
│   │   ├── dto/                     # 데이터 전송 객체
│   │   │   ├── LoginRequest.java
│   │   │   ├── SignupRequest.java
│   │   │   └── JwtResponse.java
│   │   ├── entity/                  # JPA 엔티티
│   │   │   └── User.java           # 사용자 엔티티
│   │   ├── repository/              # 데이터 접근 계층
│   │   │   └── UserRepository.java
│   │   ├── security/                # JWT 보안
│   │   │   ├── JwtTokenProvider.java
│   │   │   ├── JwtAuthenticationFilter.java
│   │   │   └── CustomUserDetailsService.java
│   │   └── service/                 # 비즈니스 로직
│   │       ├── AuthService.java
│   │       └── UserService.java
│   └── resources/
│       └── application.yml          # 설정 파일
├── gradle/                          # Gradle Wrapper
├── build.gradle                     # Gradle 빌드 설정
├── gradlew                          # Gradle 실행 스크립트
└── README.md                        # User API 문서
```

</details>

<details>
<summary>Back-End: Catalog API (FastAPI)</summary>

```
be/catalog-api/
├── main.py                      # FastAPI 앱 진입점
├── app/
│   ├── core/                    # 핵심 기능
│   │   ├── config.py           # 환경 설정 및 로깅
│   │   ├── security.py         # JWT 인증 및 사용자 검증
│   │   └── middleware.py       # HTTP 요청/응답 로깅
│   ├── api/                     # API 라우터 (엔드포인트)
│   │   ├── catalogs.py         # 카탈로그 CRUD API
│   │   ├── items.py            # 아이템 CRUD API
│   │   ├── upload.py           # 파일 업로드 API
│   │   └── user_catalogs.py    # 사용자 카탈로그 관리 API
│   ├── models/                  # SQLAlchemy ORM 모델
│   │   └── database.py         # 데이터베이스 모델
│   ├── schemas/                 # Pydantic 스키마
│   │   ├── catalog.py          # 카탈로그 스키마
│   │   ├── item.py             # 아이템 스키마
│   │   ├── user_catalog.py     # 사용자 카탈로그 스키마
│   │   └── user_item.py        # 사용자 아이템 스키마
│   └── crud/                    # CRUD 작업 로직
│       ├── catalog.py          # 카탈로그 CRUD
│       ├── item.py             # 아이템 CRUD
│       └── user_catalog.py     # 사용자 카탈로그 CRUD
├── uploads/                     # 업로드된 파일
│   └── images/                 # 이미지 저장소
├── .env.example                 # 환경 변수 예시
├── requirements.txt             # Python 의존성
├── catalog.db                   # SQLite 데이터베이스
├── api_communication.log        # API 통신 로그
└── README.md                    # Catalog API 문서
```

</details>

## 🚀 실행 방법

### 1. User API 실행 (Spring Boot)
```bash
cd be/user-api

# 기본 포트(8080)로 실행
./gradlew bootRun

# 또는 포트 변경하여 실행
PORT=8080 ./gradlew bootRun

# Health check (포트는 설정에 따라 변경)
# 기본: http://localhost:8080/api/test/health
# 변경 시: http://localhost:8081/api/test/health
```

### 2. Catalog API 실행 (FastAPI)
```bash
cd be/catalog-api

# 가상환경 생성 (최초 1회만)
python3 -m venv .venv

# 가상환경 활성화
source .venv/bin/activate  # macOS/Linux
# 또는
.venv\Scripts\activate     # Windows

# 의존성 설치 (최초 1회 또는 requirements.txt 변경 시)
pip install -r requirements.txt

# .env 파일에서 포트 설정 (기본값: 8000)
# PORT=8000 또는 원하는 포트로 변경

# 서버 실행
python main.py

# 또는 uvicorn으로 직접 실행 (포트 지정)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Health check (포트는 .env 설정에 따라 변경)
# 기본: http://localhost:8000/health
# API 문서: http://localhost:8000/docs
```

### 3. Flutter 클라이언트 실행
```bash
cd fe
flutter pub get
flutter run -d chrome --web-port 3000
# 또는 모바일
flutter run -d ios      # iOS
flutter run -d android  # Android
flutter run -d macos    # macOS Desktop
```

### 4. 로그 확인
- **User API**: 콘솔 출력
- **Catalog API**: `api_communication.log` 파일 또는 콘솔
- **Flutter**: 브라우저 개발자 도구 콘솔

## 🛠️ 기술 스택

### Frontend
- **Flutter 3.x** - 크로스 플랫폼 프레임워크
- **Dart 3.x** - 프로그래밍 언어
- **GetX** - 상태 관리 및 라우팅
- **HTTP** - REST API 통신
- **SharedPreferences** - 로컬 저장소

### Backend
- **Spring Boot 3.2.0** - User API 서버
- **FastAPI** - Catalog API 서버
- **Java 17** - Spring Boot 런타임
- **Python 3.13** - FastAPI 런타임
- **Uvicorn** - ASGI 서버

### Database
- **H2** - User API 인메모리 데이터베이스
- **SQLite** - Catalog API 파일 기반 데이터베이스

### Authentication & Security
- **JWT (HS256)** - 토큰 기반 인증
- **Spring Security** - CSRF, CORS 보호
- **OAuth2** - 소셜 로그인 (Google, Naver)

### Development Tools
- **Gradle** - Spring Boot 빌드 도구
- **Git** - 버전 관리
- **VSCode / IntelliJ IDEA** - IDE

## ☁️ 배포 환경

### 현재 (로컬 개발)
```
- Flutter 클라이언트: http://localhost:3000 (기본값)
- User API: 환경 변수 PORT로 설정 (기본값: 8080)
- Catalog API: 환경 변수 PORT로 설정 (기본값: 8000)
- 데이터베이스: H2 (인메모리), SQLite (파일)
```

**포트 설정 방법**
- User API: `application.yml`의 `server.port` 또는 `PORT` 환경 변수 (기본: 8080)
- Catalog API: `.env` 파일의 `PORT` 설정 (기본: 8000)

### 향후 (프로덕션)
```
- 클라이언트: AWS S3 + CloudFront
- API 서버: AWS EC2 + ALB
- 데이터베이스: AWS RDS (MySQL)
- 이미지 저장: AWS S3
- 모니터링: CloudWatch
```

### 📅 WBS
👉🏻 [바로가기](https://docs.google.com/spreadsheets/d/e/2PACX-1vRNmWdnV2qvOL-9PIGcX0lRT1LHVXQsyksHRUPIMlxKmZFdqw4OTyg1zX3C6WjHVtbeMd60BnfcLQFG/pubhtml?gid=509945759&single=true)

### 📱 피그마
👉🏻 [바로가기](https://www.figma.com/design/n739zPv5T6kmol53qErEtC/%ED%92%80%EC%8A%A4%ED%83%9D%EC%84%9C%EB%B9%84%EC%8A%A4%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D?node-id=0-1&t=Dnr0GjPLAzKs9mMJ-1)

### 📝 커밋 규칙
- `type(타입): title(제목)`
- 제목 첫글자는 대문자로(EN)
- 제목 끝에 마침표 등 특수문자 X
- 제목은 명령문으로 사용, 과거형 X
- `type`은 아래 명시된 형태로

| 타입         | 설명                                                                                                 |
|--------------|-----------------------------------------------------------------------------------------------------|
| feat         | 새로운 기능 추가, 기존의 기능을 요구 사항에 맞추어 수정 커밋                                             |
| fix          | 기능에 대한 버그 수정 커밋                                                                          |
| build        | 빌드 관련 수정 / 모듈 설치 또는 삭제에 대한 커밋                                                      |
| chore        | 패키지 매니저 수정, 그 외 기타 수정 (ex. .gitignore)                                                 |
| ci           | CI 관련 설정 수정                                                                                   |
| docs         | 문서(주석) 수정                                                                                     |
| style        | 코드 스타일, 포맷팅에 대한 수정                                                                     |
| refactor     | 기능의 변화가 아닌 코드 리팩터링 (ex. 변수 이름 변경)                                               |
| test         | 테스트 코드 추가/수정                                                                               |
| release      | 버전 릴리즈                                                                                         |

---

## 🎨 기획
<details>
<summary>
자세히
</summary>

### 💡 카피

#### 🎯 수집가인 당신. 혹시 이런 고민, 경험 있으신가요?

"내가 어떤 넘버링/시리즈를 갖고 있었지?"<br>
"빠진 아이템은 뭐지, 한눈에 확인하고 싶다!"<br>
"존재도 몰랐던 아이템인데 이제 구할 수가 없네..."

#### ❓ 당신의 컬렉션, 완벽하게 기록하고 계신가요?

굿즈부터 브랜드 한정판까지, 종류별로 모으다 보면<br>
"내가 가진 게 정확히 뭐였지?" "빠진 건 뭐였지?" 헷갈릴 때가 많죠.

이제 피규어, 음반, 스니커즈까지
가지고 있는 것과 없는 것을 한 번에 손쉽게 관리하세요.

#### 💡 번거롭고 아쉬운 순간, 이젠 끝!
"깔별로 맞춤", "전종러", "올 컴플리트" 수집가들을 위한<br>
‘나만의 맞춤 앱’으로 소중한 컬렉션을 스마트하게 완성하세요.

---

### 🧑‍💻 예상 사용자
- 모든 아이템 한 점도 놓치지 않는 전 종류 수집을 목표로 하는 **완벽 수집가**
- 특정 브랜드나 시리즈, 한정판 굿즈를 체계적으로 추적하는 **팬덤 컬렉터**
- 깔별로 다 사야 직성이 풀리는 **컬러 덕후**
- 그 외 단순한 소유 기록 및 정리를 원하는 일반 사용자

---

### 🌱 비전
- 단순 기록을 넘어, **개인 맞춤형 수집 관리 플랫폼**을 목표로 합니다.
- 커뮤니티적 기능과 편리한 기록 방식을 통해, 수집의 재미와 완성의 뿌듯함을 극대화합니다.
- 나만의 소유 내역 관리에서 → 커뮤니티 공유 → 거래/쇼핑 연결까지 이어지는 **원스톱 수집 경험**을 제공합니다.

---

### 📌 향후 계획
- 📱 모바일 앱 (iOS/Android) 출시
- 🌐 웹 기반 버전 개발
- 🧮 AI 기반 자동 분류 기능 강화
- 🤝 사용자간 **교환/거래 마켓플레이스** 확장

</details>