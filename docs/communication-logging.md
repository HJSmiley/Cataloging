# 클라이언트-서버 통신 로깅 시스템

## 개요

카탈로깅 시스템의 모든 클라이언트-서버 간 통신을 상세하게 로깅하여 개발 및 디버깅을 지원합니다.

## 로깅 구조

### 1. Flutter 클라이언트 로깅

#### AuthService 로깅
```dart
// 위치: fe/lib/services/auth_service.dart
// 로거: developer.log with name 'AuthService'

예시:
🔐 토큰 저장됨: eyJhbGciOiJIUzI1NiJ9...
👤 사용자 정보 저장됨: 개발자 (dev@example.com)
🚀 개발용 사용자 생성 요청: dev@example.com
📡 응답 상태: 200
📡 응답 본문: {"accessToken":"...","user":{...}}
✅ 로그인 성공: 개발자
```

#### ApiService 로깅
```dart
// 위치: fe/lib/services/api_service.dart  
// 로거: developer.log with name 'ApiService'

예시:
🔵 CLIENT REQUEST: GET http://localhost:8000/api/catalogs/
   Headers: {Content-Type: application/json, Authorization: Bearer eyJ...}
🔴 CLIENT RESPONSE: 200 http://localhost:8000/api/catalogs/ (12ms)
   Response: [
     {
       "catalog_id": "8fa2086d-d5b8-45de-a8c0-4aebba33db63",
       "title": "테스트 카탈로그",
       "user_id": "1"
     }
   ]
```

#### AuthProvider 로깅
```dart
// 위치: fe/lib/providers/auth_provider.dart
// 로거: developer.log with name 'AuthProvider'

예시:
🚀 AuthProvider 초기화 시작
✅ 기존 로그인 상태 복원: 개발자
🔑 개발용 로그인 시작: dev@example.com
🔄 사용자 정보 새로고침
✏️ 사용자 정보 수정: {nickname: 수정된개발자}
🚪 로그아웃 시작
```

#### CatalogProvider 로깅
```dart
// 위치: fe/lib/providers/catalog_provider.dart
// 로거: developer.log with name 'CatalogProvider'

예시:
🔄 수집률 업데이트 시작: catalog-uuid-456
📊 수집률 업데이트 완료: 0.0% → 50.0%
🔔 notifyListeners() 호출
🎉 카탈로그 완성! 수집률 100% 달성
```

#### ItemProvider 로깅
```dart
// 위치: fe/lib/providers/item_provider.dart
// 로거: developer.log with name 'ItemProvider'

예시:
🔄 아이템 보유 상태 토글 시작: item-uuid-123
✅ 아이템 상태 업데이트 완료: owned=true
📞 CatalogProvider 콜백 호출: catalog-uuid-456, owned=true
```

### 2. Spring Boot 회원 API 로깅

#### 콘솔 로깅
```
# 위치: be/user-api (콘솔 출력)
# 설정: application.yml의 logging.level

예시:
2025-11-03T16:04:20.420+09:00 DEBUG [user-api] [main] 
  c.cataloging.userapi.UserApiApplication : Running with Spring Boot v3.2.0

2025-11-03T16:04:20.420+09:00 INFO [user-api] [nio-8081-exec-1] 
  c.c.userapi.service.UserService : OAuth2 사용자 정보 추출: 
  provider=dev, providerId=dev-1730621060420, email=dev@example.com

2025-11-03T16:04:20.420+09:00 INFO [user-api] [nio-8081-exec-1] 
  c.c.userapi.security.JwtTokenProvider : JWT 토큰 생성: 사용자 ID=1
```

### 3. FastAPI 카탈로그 API 로깅

#### API_COMMUNICATION 로거
```python
# 위치: be/catalog-api/main.py
# 로거: logging.getLogger("API_COMMUNICATION")

예시:
2025-11-03 07:31:19,373 - API_COMMUNICATION - INFO - 
🔵 REQUEST: POST http://localhost:8000/api/catalogs/
   Headers: {'authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9...'}
   Body: {"title": "테스트 카탈로그", "description": "JWT 연동 테스트용"}

2025-11-03 07:31:19,385 - API_COMMUNICATION - INFO - 
🔴 RESPONSE: 201 (0.012s)
   Response: {
     "catalog_id": "8fa2086d-d5b8-45de-a8c0-4aebba33db63",
     "user_id": "1",
     "title": "테스트 카탈로그"
   }
```

#### JWT 검증 로깅
```python
# 위치: be/catalog-api/app/utils.py
# 함수: verify_token()

예시:
🔍 토큰 검증 시도: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiaWF0...
🔑 사용 중인 시크릿: mySecretKey1234567890...
🔧 알고리즘: HS256
✅ 토큰 디코딩 성공: {'sub': '1', 'iat': 1762154656, 'exp': 1762241056}
```

## 실제 통신 플로우 로깅 예시

### 1. 사용자 로그인 플로우

#### Step 1: Flutter → Spring Boot (사용자 생성)
```
[AuthService] 🚀 개발용 사용자 생성 요청: dev@example.com
[AuthService] 📡 응답 상태: 200
[AuthService] 📡 응답 본문: {
  "accessToken": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiaWF0IjoxNzYyMTU0NjU2LCJleHAiOjE3NjIyNDEwNTZ9.h-pJLxJ8_3KuYOmnthYVYlXHf_d8udr5EvHuPcpFOs4",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": 1,
    "email": "dev@example.com",
    "nickname": "개발자"
  }
}
[AuthService] 🔐 토큰 저장됨: eyJhbGciOiJIUzI1NiJ9...
[AuthService] 👤 사용자 정보 저장됨: 개발자 (dev@example.com)
[AuthProvider] ✅ 로그인 성공: 개발자
```

#### Step 2: Flutter → FastAPI (카탈로그 조회)
```
[ApiService] 🔵 CLIENT REQUEST: GET http://localhost:8000/api/catalogs/
   Headers: {
     Content-Type: application/json, 
     Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiaWF0IjoxNzYyMTU0NjU2LCJleHAiOjE3NjIyNDEwNTZ9.h-pJLxJ8_3KuYOmnthYVYlXHf_d8udr5EvHuPcpFOs4
   }

[FastAPI] 🔍 토큰 검증 시도: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiaWF0...
[FastAPI] 🔑 사용 중인 시크릿: mySecretKey1234567890...
[FastAPI] 🔧 알고리즘: HS256
[FastAPI] ✅토큰 디코딩 성공: {'sub': '1', 'iat': 1762154656, 'exp': 1762241056}

[FastAPI] 2025-11-03 07:30:59,373 - API_COMMUNICATION - INFO - 
🔵 REQUEST: GET http://localhost:8000/api/catalogs/
   Headers: {'authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9...'}

[FastAPI] 2025-11-03 07:30:59,385 - API_COMMUNICATION - INFO - 
🔴 RESPONSE: 200 (0.012s)

[ApiService] 🔴 CLIENT RESPONSE: 200 http://localhost:8000/api/catalogs/ (12ms)
   Response: []
```

### 2. 카탈로그 생성 플로우

#### Flutter → FastAPI (카탈로그 생성)
```
[ApiService] 🔵 CLIENT REQUEST: POST http://localhost:8000/api/catalogs/
   Headers: {
     Content-Type: application/json,
     Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
   }
   Body: {
     "title": "내 피규어 컬렉션",
     "description": "애니메이션 피규어 모음",
     "category": "피규어"
   }

[FastAPI] 🔍 토큰 검증 시도: eyJhbGciOiJIUzI1NiJ9...
[FastAPI] ✅ 토큰 디코딩 성공: {'sub': '1', 'iat': 1762154656, 'exp': 1762241056}

[FastAPI] 2025-11-03 07:31:19,373 - API_COMMUNICATION - INFO - 
🔵 REQUEST: POST http://localhost:8000/api/catalogs/
   Headers: {'authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9...'}
   Body: {"title": "내 피규어 컬렉션", "description": "애니메이션 피규어 모음"}

[FastAPI] 2025-11-03 07:31:19,385 - API_COMMUNICATION - INFO - 
🔴 RESPONSE: 201 (0.012s)
   Response: {
     "catalog_id": "8fa2086d-d5b8-45de-a8c0-4aebba33db63",
     "user_id": "1",
     "title": "내 피규어 컬렉션",
     "item_count": 0,
     "completion_rate": 0.0
   }

[ApiService] 🔴 CLIENT RESPONSE: 201 http://localhost:8000/api/catalogs/ (15ms)
   Response: {
     "catalog_id": "8fa2086d-d5b8-45de-a8c0-4aebba33db63",
     "user_id": "1",
     "title": "내 피규어 컬렉션"
   }
```

### 3. 완전한 사용자 플로우 로깅

#### 3.1 스플래시 화면 로깅
```
[SplashScreen] 🎬 스플래시 애니메이션 시작
[SplashScreen] 🎨 로고 스케일 애니메이션: 0.5 → 1.0
[SplashScreen] 🎨 텍스트 슬라이드 애니메이션: Offset(0, 0.5) → Offset.zero
[SplashScreen] ✅ 스플래시 완료 - 메인 네비게이션으로 이동
```

#### 3.2 하단 네비게이션 로깅
```
[MainNavigationScreen] 🏠 홈 탭 선택 (index: 0)
[MainNavigationScreen] 🔍 탐색 탭 선택 (index: 1)
[MainNavigationScreen] ➕ 추가 탭 선택 (index: 2)
[MainNavigationScreen] 👤 마이 탭 선택 (index: 3)
```

#### 3.3 탐색 기능 로깅
```
[ExploreScreen] 🔍 검색어 입력: "스니커즈"
[ExploreScreen] 🏷️ 필터 변경: 전체 → 인기 카탈로그
[ExploreScreen] 📊 필터링 결과: 5개 카탈로그 → 3개 카탈로그
```

#### 3.4 아이템 상세 및 수집 완료 애니메이션 로깅
```
[ItemDetailScreen] 🎭 Hero 애니메이션 시작: item-uuid-123
[ItemDetailScreen] 💖 수집하기 버튼 클릭
[ItemDetailScreen] 🎬 수집 완료 애니메이션 시작
[ItemDetailScreen] 📈 스케일 애니메이션: 1.0 → 1.2 → 1.0
[ItemDetailScreen] 🔄 회전 애니메이션: 0.0 → 0.1 → 0.0
[ItemDetailScreen] ✅ 수집 완료! 스낵바 표시
```

### 4. 아이템 보유 상태 토글 및 실시간 수집률 업데이트 플로우

#### Step 1: Flutter → FastAPI (아이템 보유 상태 토글)
```
[ItemProvider] 🔄 아이템 보유 상태 토글 시작: item-uuid-123
[ApiService] 🔵 CLIENT REQUEST: PATCH http://localhost:8000/api/items/item-uuid-123/toggle-owned
   Headers: {
     Content-Type: application/json,
     Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
   }

[FastAPI] 🔍 토큰 검증 시도: eyJhbGciOiJIUzI1NiJ9...
[FastAPI] ✅ 토큰 디코딩 성공: {'sub': '1', 'iat': 1762154656, 'exp': 1762241056}

[FastAPI] 2025-11-03 16:04:20,373 - API_COMMUNICATION - INFO - 
🔵 REQUEST: PATCH http://localhost:8000/api/items/item-uuid-123/toggle-owned
   Headers: {'authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9...'}

[FastAPI] 2025-11-03 16:04:20,385 - API_COMMUNICATION - INFO - 
🔴 RESPONSE: 200 (0.008s)
   Response: {
     "item_id": "item-uuid-123",
     "catalog_id": "catalog-uuid-456",
     "name": "테스트 아이템",
     "owned": true,
     "updated_at": "2025-11-03T16:04:20"
   }

[ApiService] 🔴 CLIENT RESPONSE: 200 http://localhost:8000/api/items/item-uuid-123/toggle-owned (8ms)
[ItemProvider] ✅ 아이템 상태 업데이트 완료: owned=true
```

#### Step 2: Provider 간 콜백 통신
```
[ItemProvider] 📞 CatalogProvider 콜백 호출: catalog-uuid-456, owned=true
[CatalogProvider] 🔄 수집률 업데이트 시작: catalog-uuid-456
```

#### Step 3: Flutter → FastAPI (카탈로그 정보 재조회)
```
[ApiService] 🔵 CLIENT REQUEST: GET http://localhost:8000/api/catalogs/catalog-uuid-456
   Headers: {
     Content-Type: application/json,
     Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
   }

[FastAPI] 🔍 토큰 검증 시도: eyJhbGciOiJIUzI1NiJ9...
[FastAPI] ✅ 토큰 디코딩 성공: {'sub': '1', 'iat': 1762154656, 'exp': 1762241056}

[FastAPI] 2025-11-03 16:04:20,390 - API_COMMUNICATION - INFO - 
🔵 REQUEST: GET http://localhost:8000/api/catalogs/catalog-uuid-456
   Headers: {'authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9...'}

[FastAPI] 📊 수집률 실시간 계산: catalog-uuid-456
[FastAPI] 📊 아이템 통계: 총 2개, 보유 1개, 수집률 50.0%

[FastAPI] 2025-11-03 16:04:20,395 - API_COMMUNICATION - INFO - 
🔴 RESPONSE: 200 (0.005s)
   Response: {
     "catalog_id": "catalog-uuid-456",
     "title": "내 피규어 컬렉션",
     "item_count": 2,
     "owned_count": 1,
     "completion_rate": 50.0
   }

[ApiService] 🔴 CLIENT RESPONSE: 200 http://localhost:8000/api/catalogs/catalog-uuid-456 (5ms)
[CatalogProvider] 📊 수집률 업데이트 완료: 0.0% → 50.0%
[CatalogProvider] 🔔 notifyListeners() 호출
```

#### Step 4: UI 자동 업데이트
```
[Consumer<CatalogProvider>] 🎨 UI 업데이트 감지
[AnimatedContainer] 🎬 애니메이션 시작: 0% → 50% (300ms)
[CompletionRateBadge] 🎨 배경색 유지: 파란색 (미완성)
[CompletionRateBadge] 📊 텍스트 업데이트: "1/2 (50%)"
```

#### Step 5: 100% 완성 시 특별 효과
```
# 두 번째 아이템도 보유 상태로 변경 시
[CatalogProvider] 📊 수집률 업데이트 완료: 50.0% → 100.0%
[AnimatedContainer] 🎬 애니메이션 시작: 50% → 100% (300ms)
[CompletionRateBadge] 🎨 배경색 변경: 파란색 → 초록색
[CompletionRateBadge] 🎯 아이콘 변경: 파이차트 → 체크 아이콘
[CompletionRateBadge] 📊 텍스트 업데이트: "2/2 (100%)"
```

## 로깅 설정

### 1. Flutter 개발자 로그 확인
```bash
# Flutter 앱 실행 시 콘솔에서 확인
flutter run -d web-server --web-port 3000

# 또는 브라우저 개발자 도구 콘솔에서 확인
```

### 2. Spring Boot 로그 확인
```bash
# Gradle 실행 시 콘솔에서 확인
./gradlew bootRun

# 로그 레벨 설정 (application.yml)
logging:
  level:
    com.cataloging.userapi: DEBUG
    org.springframework.security: DEBUG
```

### 3. FastAPI 로그 확인
```bash
# Docker 컨테이너 로그 확인
docker logs <container_id>

# 또는 실행 중인 컨테이너에서 실시간 로그
docker run -p 8000:8000 catalog-api
```

## 로깅 데이터 활용

### 1. 성능 모니터링
- API 응답 시간 측정 (ms 단위)
- 느린 요청 식별 및 최적화

### 2. 보안 모니터링
- JWT 토큰 검증 실패 추적
- 인증되지 않은 접근 시도 감지

### 3. 사용자 행동 분석
- API 호출 패턴 분석
- 기능별 사용 빈도 측정 (탭 전환, 검색, 필터링)
- 수집률 변화 패턴 추적
- 애니메이션 효과 성능 모니터링
- 사용자 플로우 완료율 측정

### 4. 디버깅 지원
- 요청/응답 데이터 상세 확인
- 에러 발생 시점 및 원인 추적
- Provider 간 콜백 통신 추적
- 실시간 수집률 업데이트 플로우 모니터링
- 애니메이션 성능 및 타이밍 디버깅
- 네비게이션 상태 변화 추적
- 사용자 인터랙션 패턴 분석

## 로그 보안 고려사항

### 1. 민감 정보 마스킹
```dart
// JWT 토큰은 앞 20자만 로깅
developer.log('🔐 토큰 저장됨: ${token.substring(0, 20)}...', name: 'AuthService');

// 시크릿 키는 앞 20자만 로깅
print(f"🔑 사용 중인 시크릿: {settings.JWT_SECRET_KEY[:20]}...")
```

### 2. 프로덕션 환경 로그 레벨
- 개발 환경: DEBUG 레벨로 모든 정보 로깅
- 프로덕션 환경: INFO 레벨로 필수 정보만 로깅
- 민감한 정보는 로깅하지 않음

### 3. 로그 저장 및 관리
- 로컬 개발: 콘솔 출력
- 프로덕션: 파일 또는 로그 수집 시스템으로 전송
- 로그 로테이션 및 보관 정책 적용

이 로깅 시스템을 통해 전체 시스템의 동작을 실시간으로 모니터링하고, 문제 발생 시 빠른 디버깅이 가능합니다.