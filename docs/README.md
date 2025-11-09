# 카탈로깅 프로젝트 문서

## 개요

카탈로깅(Cataloging) 프로젝트의 전체 문서 모음입니다. 
Flutter 클라이언트와 FastAPI 서버 간의 통신 구조와 테스트 결과를 상세히 문서화했습니다.

## 📋 문서 목록

### 📁 0. 문제분석
- [MVP 범위표](./0.%20문제분석/MVP%20범위표.md) - MVP 기능 정의 및 우선순위
- [사용자 시나리오](./0.%20문제분석/사용자%20시나리오.md) - 주요 사용자 플로우
- MVP 기능 리스트.xlsx - 기능 상세 목록

### 📁 1. 설계
- [PRD (Product Requirements Document)](./1.%20설계/prd.md) - 제품 요구사항 정의서
- Architectures/ - 아키텍처 설계 문서
- ERD/ - 데이터베이스 설계 다이어그램
- UI(Figma)/ - UI/UX 디자인 파일

### 📁 2. 산출물 (시스템 개발 산출물)

#### 2.1 [프로젝트 개요](./2.%20산출물/01_프로젝트_개요.md)
- 프로젝트 목적 및 핵심 목표
- 주요 기능 설명
- 기대 효과
- 기술적 특징

#### 2.2 [시스템 아키텍처](./2.%20산출물/02_시스템_아키텍처.md)
- 전체 시스템 구성도
- 마이크로서비스 아키텍처 (User API, Catalog API)
- 주요 기술 스택 (Spring Boot, FastAPI, Flutter)
- **데이터 흐름 다이어그램** (로그인, 카탈로그 조회, 아이템 토글)
- JWT 기반 마이크로서비스 통신
- 레이어 아키텍처

#### 2.3 [요구사항 명세서](./2.%20산출물/03_요구사항_명세서.md)
- 기능 요구사항 (FR-001 ~ FR-022)
- 비기능 요구사항 (NFR-001 ~ NFR-015)
- 화면 기능 매핑
- 제약 사항

#### 2.4 [데이터 명세](./2.%20산출물/04_데이터_명세.md)
- 데이터베이스 개요 (H2, SQLite)
- 테이블 구조 (users, catalogs, items, user_item_status, user_catalogs)
- ERD (Entity Relationship Diagram)
- 데이터 무결성 및 백업 전략

#### 2.5 [API 명세](./2.%20산출물/05_API_명세.md)
- User API 엔드포인트 (Spring Boot, 포트 8080)
- Catalog API 엔드포인트 (FastAPI, 포트 8000)
- **JWT 인증 흐름**
- 요청/응답 예시
- 에러 처리

#### 2.6 [UI/UX 문서](./2.%20산출물/06_UI_UX_문서.md)
- 화면 목록 (11개 화면)
- **화면 간 이동 흐름**
- 사용자 시나리오
- 디자인 가이드라인

#### 2.7 [상태 관리 문서](./2.%20산출물/07_상태_관리_문서.md)
- GetX 컨트롤러 구조
- AuthController (인증 상태 관리)
- CatalogController (카탈로그 상태 관리)
- **상태 업데이트 흐름**

#### 2.8 [보안/인증 문서](./2.%20산출물/08_보안_인증_문서.md)
- JWT 토큰 발급 및 검증
- 마이크로서비스 간 인증 연동
- OAuth2 소셜 로그인 (Google, Naver)
- 권한 관리 및 보안 고려사항

#### 2.9 [테스트 문서](./2.%20산출물/09_테스트_문서.md)
- 프론트엔드 테스트 전략 (Unit, Widget, Integration)
- 백엔드 테스트 전략 (JUnit, pytest)
- 통합 테스트 시나리오
- Mock 전략 및 CI/CD

#### 2.10 [운영 문서](./2.%20산출물/10_운영_문서.md)
- 실행 및 배포 절차
- 환경 변수 설정
- 로그 및 모니터링
- 트러블슈팅 가이드
- 백업 및 복구
- 보안 점검

### 📄 기타 문서
- [API 명세서](./api-specification.md) - RESTful API 상세 문서
- [백엔드 API 레퍼런스](./backend-api-reference.md) - 백엔드 API 참조
- [시스템 아키텍처](./system-architecture.md) - 시스템 구조 상세
- [통신 로깅](./communication-logging.md) - API 통신 로깅 시스템
- [통합 테스트 가이드](./integration-testing-guide.md) - 통합 테스트 방법
- [사용자 플로우](./user-flow.md) - 사용자 경험 흐름
- [프로젝트 현황](./project-status.md) - 개발 진행 상황

## 🎯 문서 완성도 현황

### ✅ 완성된 산출물 (10개)
1. ✅ **프로젝트 개요** - 목적, 기능, 기대효과
2. ✅ **시스템 아키텍처** - 전체 구조, 데이터 흐름, 통신 구조
3. ✅ **요구사항 명세서** - 기능/비기능 요구사항 (FR-001~FR-022, NFR-001~NFR-015)
4. ✅ **데이터 명세** - 테이블 구조, ERD, 데이터 무결성
5. ✅ **API 명세** - User API, Catalog API 엔드포인트 상세
6. ✅ **UI/UX 문서** - 11개 화면, 이동 흐름, 사용자 시나리오
7. ✅ **상태 관리 문서** - GetX 컨트롤러, 상태 업데이트 흐름
8. ✅ **보안/인증 문서** - JWT 인증, OAuth2, 권한 관리
9. ✅ **테스트 문서** - 프론트엔드/백엔드 테스트 전략
10. ✅ **운영 문서** - 배포, 모니터링, 트러블슈팅

### 📊 문서 품질 지표

| 항목 | 상태 | 비고 |
|------|------|------|
| **문서 완성도** | 100% | 10개 산출물 모두 작성 완료 |
| **실제 코드 반영** | 100% | 구현된 코드 기반 작성 |
| **통신 흐름 문서화** | 완료 | 로그인, 카탈로그 조회, 아이템 토글 흐름 상세 기술 |
| **API 명세 정확성** | 100% | 모든 엔드포인트 검증 완료 |
| **다이어그램 포함** | 완료 | 아키텍처, ERD, 데이터 흐름 다이어그램 |

### 🔍 주요 문서화 내용

#### (A) 정보의 명확성
- **클라이언트**: Flutter 모델, GetX 상태 관리 구조 명확히 정의
- **서버**: Spring Boot (User API), FastAPI (Catalog API) 구조 상세 문서화
- **데이터베이스**: H2, SQLite 테이블 구조 및 관계 명확히 정의

#### (B) 정보 교환의 명확성
- **RESTful API**: 모든 엔드포인트와 데이터 구조 상세 문서화
- **통신 흐름**: 로그인, 카탈로그 조회, 아이템 토글 등 주요 흐름 다이어그램 포함
- **JWT 인증**: 마이크로서비스 간 토큰 기반 인증 흐름 상세 기술
- **요청/응답**: 실제 JSON 예시 및 에러 처리 방법 제공

#### (C) 기능의 명확성
- **클라이언트 기능**: UI, 상태 관리, API 통신 역할 명확히 분리
- **서버 기능**: User API (인증), Catalog API (카탈로그 관리) 역할 구분
- **데이터 처리**: 비즈니스 로직, 데이터 검증, 응답 생성 과정 명확히 정의

## 🔍 시스템 주요 특징

### 1. 마이크로서비스 아키텍처
- **User API (Spring Boot)**: 사용자 인증, 프로필 관리, OAuth2 소셜 로그인
- **Catalog API (FastAPI)**: 카탈로그 관리, 아이템 관리, 수집률 계산
- **JWT 기반 통합 인증**: 두 서비스 간 동일한 시크릿 키로 토큰 검증
- **독립적 확장**: 각 서비스별 독립적 배포 및 스케일링 가능

### 2. 완전한 통신 로깅
- **Catalog API**: FastAPI 미들웨어로 모든 요청/응답 자동 로깅
- **Flutter**: developer.log로 API 호출 추적
- **성능 측정**: 응답 시간, 데이터 크기 추적
- **디버깅 용이**: 상세한 로그로 문제 진단 간소화

### 3. 타입 안전한 데이터 교환
- **Spring Boot**: DTO 및 Entity 기반 타입 안전성
- **FastAPI**: Pydantic 모델로 데이터 검증
- **Flutter**: 강타입 Dart 모델 및 JSON 직렬화
- **자동 검증**: 입력 데이터 자동 검증으로 에러 방지

### 4. 실시간 데이터 동기화
- **GetX 상태 관리**: 반응형 상태 업데이트
- **수집률 실시간 계산**: API 호출 시마다 최신 수집률 계산
- **아이템 상태 즉시 반영**: 보유 상태 변경 시 UI 즉시 업데이트
- **다중 사용자 지원**: user_item_status 테이블로 사용자별 상태 관리

### 5. 보안 강화
- **JWT 인증**: 상태 비저장 토큰 기반 인증 (HS256 알고리즘)
- **OAuth2**: Google, Naver 소셜 로그인 지원
- **Spring Security**: CSRF 보호, CORS 설정, 세션 관리
- **권한 관리**: JWT 토큰 기반 사용자 인증 및 권한 검증

## 🚀 실행 방법

### 1. User API 실행 (Spring Boot)
```bash
cd be/user-api
./gradlew bootRun
# 포트: 8080 (기본값, PORT 환경 변수로 변경 가능)
# 헬스체크: http://localhost:8080/api/test/health
```

### 2. Catalog API 실행 (FastAPI)
```bash
cd be/catalog-api
# Python 가상환경 활성화 (이미 생성된 경우)
source .venv/bin/activate  # Windows: .venv\Scripts\activate
# 또는 새로 생성
python3 -m venv .venv
source .venv/bin/activate
# 의존성 설치
pip install -r requirements.txt
# 서버 실행
python main.py
# 또는 uvicorn으로 실행
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
# 포트: 8000 (기본값, .env 파일의 PORT로 변경 가능)
# 헬스체크: http://localhost:8000/health
# API 문서: http://localhost:8000/docs
```

### 3. Flutter 클라이언트 실행
```bash
cd fe
flutter pub get
flutter run -d chrome --web-port 3000
# 또는 모바일: flutter run -d ios / flutter run -d android
```

### 4. 로그 확인
- **User API**: 콘솔 출력
- **Catalog API**: `api_communication.log` 파일 또는 콘솔 출력
- **Flutter**: 브라우저 개발자 도구 콘솔 또는 `flutter logs`

## 📂 프로젝트 구조

### 전체 디렉토리 구조

```
cataloging/
├── .git/                        # Git 버전 관리
├── .kiro/                       # Kiro AI 설정
│   └── specs/                   # 프로젝트 스펙 문서
├── .venv/                       # Python 가상환경
├── .vscode/                     # VSCode 설정
├── be/                          # 백엔드 (Spring Boot + FastAPI)
│   ├── user-api/               # Spring Boot 회원 API (포트 8080)
│   └── catalog-api/            # FastAPI 카탈로그 API (포트 8000)
├── fe/                          # 프론트엔드 (Flutter, 포트 3000)
├── docs/                        # 프로젝트 문서
│   ├── 0. 문제분석/             # 요구사항 분석
│   ├── 1. 설계/                 # 아키텍처 설계
│   ├── api-specification.md     # API 명세서
│   ├── backend-api-reference.md # 백엔드 API 레퍼런스
│   ├── communication-logging.md # 통신 로깅 시스템
│   ├── integration-testing-guide.md # 통합 테스트 가이드
│   ├── prd.md                   # 제품 요구사항 정의서
│   ├── project-status.md        # 프로젝트 현황
│   ├── system-architecture.md   # 시스템 아키텍처
│   └── user-flow.md             # 사용자 플로우
├── .gitignore                   # Git 제외 파일
├── README.md                    # 프로젝트 개요
└── api_communication.log        # API 통신 로그
```

### 백엔드 구조

#### User API (Spring Boot)
```
be/user-api/
├── src/main/java/com/cataloging/userapi/
│   ├── UserApiApplication.java  # Spring Boot 진입점
│   ├── config/                  # Security, CORS 설정
│   ├── controller/              # REST API 컨트롤러
│   ├── dto/                     # 데이터 전송 객체
│   ├── entity/                  # JPA 엔티티
│   ├── repository/              # 데이터 접근 계층
│   ├── security/                # JWT, OAuth2 보안
│   └── service/                 # 비즈니스 로직
├── src/main/resources/
│   └── application.yml          # 설정 파일
└── build.gradle                 # Gradle 빌드 설정
```

#### Catalog API (FastAPI)
```
be/catalog-api/
├── main.py                      # FastAPI 진입점
├── app/
│   ├── core/                    # 핵심 기능 (설정, 보안, 미들웨어)
│   ├── api/                     # API 라우터 (엔드포인트)
│   ├── models/                  # SQLAlchemy ORM 모델
│   ├── schemas/                 # Pydantic 스키마
│   └── crud/                    # CRUD 작업 로직
├── uploads/images/              # 업로드된 이미지
├── catalog.db                   # SQLite 데이터베이스
└── requirements.txt             # Python 의존성
```

### 프론트엔드 구조

```
fe/lib/
├── main.dart                    # 앱 진입점
├── controllers/                 # 상태 관리 컨트롤러
│   ├── auth_controller.dart    # 인증 상태 관리
│   └── catalog_controller.dart # 카탈로그 상태 관리
├── models/                      # 데이터 모델
│   ├── user.dart               # 사용자 모델
│   ├── catalog.dart            # 카탈로그 모델
│   └── item.dart               # 아이템 모델
├── services/                    # API 통신
│   └── api_service.dart        # 통합 API 서비스
├── screens/                     # UI 화면 (11개)
└── widgets/                     # 재사용 위젯
```

## 📝 기술 스택 및 환경

### 개발 환경
- **OS**: macOS (Linux, Windows 호환)
- **IDE**: VSCode, Android Studio, IntelliJ IDEA
- **버전 관리**: Git

### 백엔드
- **User API**: Spring Boot 3.2.0, Java 17, Gradle
- **Catalog API**: FastAPI, Python 3.13, Uvicorn
- **데이터베이스**: H2 (User API), SQLite (Catalog API)
- **인증**: JWT (HS256), OAuth2 (Google, Naver)

### 프론트엔드
- **프레임워크**: Flutter 3.x, Dart 3.x
- **상태 관리**: GetX
- **HTTP 통신**: HTTP 패키지
- **로컬 저장**: SharedPreferences

### 통신 및 보안
- **프로토콜**: HTTP/1.1 REST API
- **데이터 형식**: JSON (UTF-8)
- **인증 방식**: JWT 토큰 기반 통합 인증
- **보안**: Spring Security (CSRF, CORS), FastAPI CORS 미들웨어

### 배포 및 운영
- **실행 환경**: JVM (User API), Python 가상환경 (Catalog API)
- **로깅**: Spring Boot 기본 로깅 (User API), Python logging (Catalog API)
- **모니터링**: Health check 엔드포인트

## 💡 문서 활용 가이드

### 개발자용
1. **시스템 이해**: [프로젝트 개요](./2.%20산출물/01_프로젝트_개요.md) → [시스템 아키텍처](./2.%20산출물/02_시스템_아키텍처.md)
2. **기능 구현**: [요구사항 명세서](./2.%20산출물/03_요구사항_명세서.md) → [API 명세](./2.%20산출물/05_API_명세.md) → [데이터 명세](./2.%20산출물/04_데이터_명세.md)
3. **상태 관리**: [상태 관리 문서](./2.%20산출물/07_상태_관리_문서.md)
4. **테스트**: [테스트 문서](./2.%20산출물/09_테스트_문서.md)

### 운영자용
1. **배포**: [운영 문서](./2.%20산출물/10_운영_문서.md) - 실행 및 배포 절차
2. **모니터링**: 로그 및 모니터링 섹션
3. **장애 대응**: 트러블슈팅 가이드

### 기획자/PM용
1. **기능 확인**: [요구사항 명세서](./2.%20산출물/03_요구사항_명세서.md)
2. **화면 구성**: [UI/UX 문서](./2.%20산출물/06_UI_UX_문서.md)
3. **보안**: [보안/인증 문서](./2.%20산출물/08_보안_인증_문서.md)

## 📞 문의 및 피드백

모든 문서는 실제 구현된 코드를 기반으로 작성되었으며, 프로젝트의 전체 구조와 통신 흐름을 명확하게 문서화하였습니다.
문서 관련 문의사항이나 개선 제안은 프로젝트 이슈 트래커를 통해 제출해 주시기 바랍니다.