# 통합 테스트 가이드

## 개요

카탈로깅 시스템의 Flutter 클라이언트, Spring Boot 회원 API, FastAPI 카탈로그 API 간의 통합 테스트 가이드입니다.

## 시스템 실행 순서

### 1. Spring Boot 회원 API 실행 (포트 8081)
```bash
cd be/user-api
./gradlew bootRun
```

**확인 방법:**
```bash
curl http://localhost:8081/api/test/health
# 응답: {"status":"UP","message":"User API is running","timestamp":"..."}
```

### 2. FastAPI 카탈로그 API 실행 (포트 8000)
```bash
cd be/catalog-api
docker build -t catalog-api .
docker run -p 8000:8000 catalog-api
```

**확인 방법:**
```bash
curl http://localhost:8000/docs
# Swagger UI 페이지 접근 가능
```

### 3. Flutter 클라이언트 실행 (포트 3000)
```bash
cd fe
flutter packages get
flutter packages pub run build_runner build
flutter run -d web-server --web-port 3000
```

**확인 방법:**
- 브라우저에서 http://localhost:3000 접속
- 로그인 화면이 표시되어야 함

## 통합 테스트 시나리오

### 시나리오 1: 사용자 등록 및 로그인

#### 1.1 개발용 사용자 생성 (Spring Boot)
```bash
curl -X POST http://localhost:8081/api/dev/create-user \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "nickname": "테스트사용자"}'
```

**예상 응답:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": 1,
    "email": "test@example.com",
    "nickname": "테스트사용자",
    "introduction": "개발용 테스트 사용자"
  }
}
```

#### 1.2 JWT 토큰 검증 (Spring Boot)
```bash
# 위에서 받은 accessToken 사용
curl -X POST http://localhost:8081/api/test/validate-token \
  -H "Content-Type: application/json" \
  -d '{"token": "eyJhbGciOiJIUzI1NiJ9..."}'
```

**예상 응답:**
```json
{
  "valid": true,
  "userId": "1",
  "message": "유효한 토큰입니다."
}
```

### 시나리오 2: JWT 토큰으로 카탈로그 API 접근

#### 2.1 카탈로그 목록 조회 (FastAPI)
```bash
curl -X GET http://localhost:8000/api/catalogs/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**예상 응답:**
```json
[]
```
*처음에는 빈 배열 (카탈로그가 없음)*

#### 2.2 카탈로그 생성 (FastAPI)
```bash
curl -X POST http://localhost:8000/api/catalogs/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "title": "테스트 카탈로그",
    "description": "JWT 연동 테스트용 카탈로그",
    "category": "테스트",
    "tags": ["테스트", "JWT"]
  }'
```

**예상 응답:**
```json
{
  "catalog_id": "uuid-generated",
  "user_id": "1",
  "title": "테스트 카탈로그",
  "description": "JWT 연동 테스트용 카탈로그",
  "category": "테스트",
  "tags": ["테스트", "JWT"],
  "visibility": "public",
  "thumbnail_url": null,
  "created_at": "2025-11-03T07:31:19",
  "updated_at": "2025-11-03T07:31:19",
  "item_count": 0,
  "owned_count": 0,
  "completion_rate": 0.0
}
```

#### 2.3 생성된 카탈로그 확인
```bash
curl -X GET http://localhost:8000/api/catalogs/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**예상 응답:**
```json
[
  {
    "catalog_id": "uuid-generated",
    "user_id": "1",
    "title": "테스트 카탈로그",
    "item_count": 0,
    "completion_rate": 0.0
  }
]
```

### 시나리오 3: 아이템 관리 및 실시간 수집률 테스트

#### 3.1 아이템 생성
```bash
curl -X POST http://localhost:8000/api/items/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "catalog_id": "위에서-생성된-카탈로그-ID",
    "name": "테스트 아이템 1",
    "description": "첫 번째 테스트 아이템",
    "owned": false,
    "user_fields": {
      "시리즈": "테스트 시리즈",
      "희귀도": "일반"
    }
  }'
```

#### 3.2 두 번째 아이템 생성 (수집률 테스트용)
```bash
curl -X POST http://localhost:8000/api/items/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "catalog_id": "위에서-생성된-카탈로그-ID",
    "name": "테스트 아이템 2",
    "description": "두 번째 테스트 아이템",
    "owned": false
  }'
```

#### 3.3 첫 번째 아이템 보유 상태 토글 (0% → 50%)
```bash
curl -X PATCH http://localhost:8000/api/items/{item_id_1}/toggle-owned \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**예상 응답:**
```json
{
  "item_id": "uuid-1",
  "name": "테스트 아이템 1",
  "owned": true,
  "updated_at": "2025-11-03T16:04:20"
}
```

#### 3.4 카탈로그 수집률 확인 (50%)
```bash
curl -X GET http://localhost:8000/api/catalogs/{catalog_id} \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**예상 응답:**
```json
{
  "catalog_id": "uuid",
  "title": "테스트 카탈로그",
  "item_count": 2,
  "owned_count": 1,
  "completion_rate": 50.0
}
```

#### 3.5 두 번째 아이템 보유 상태 토글 (50% → 100%)
```bash
curl -X PATCH http://localhost:8000/api/items/{item_id_2}/toggle-owned \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

#### 3.6 최종 수집률 확인 (100%)
```bash
curl -X GET http://localhost:8000/api/catalogs/{catalog_id} \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**예상 응답:**
```json
{
  "catalog_id": "uuid",
  "title": "테스트 카탈로그",
  "item_count": 2,
  "owned_count": 2,
  "completion_rate": 100.0
}
```

### 시나리오 4: Flutter 앱 통합 테스트

#### 4.1 Flutter 앱에서 로그인
1. http://localhost:3000 접속
2. 로그인 화면에서 이메일/닉네임 입력
3. "개발용 로그인" 버튼 클릭
4. 홈 화면으로 이동 확인

#### 4.2 프로필 관리
1. 우상단 프로필 아이콘 클릭
2. 프로필 화면에서 정보 확인
3. "편집" 버튼으로 정보 수정
4. "저장" 버튼으로 변경사항 저장

#### 4.3 완전한 사용자 플로우 테스트
1. **스플래시 화면**: 2초간 로고 애니메이션 확인
2. **하단 네비게이션**: 4개 탭 (홈/탐색/추가/마이) 전환 테스트
3. **탐색 기능**: 검색창 및 필터 (전체/인기/신규) 테스트
4. **추가 기능**: 
   - "새 카탈로그 추가" 옵션 테스트
   - "기존 카탈로그에 아이템 추가" 바텀시트 테스트
5. **카탈로그 관리**:
   - 카탈로그 생성 및 수집률 0% 확인
   - 아이템 추가 (2개 이상 권장)
   - 아이템 클릭 → 상세 화면 Hero 애니메이션 확인
6. **수집 완료 애니메이션**:
   - 아이템 상세에서 "수집하기" 버튼 클릭
   - 스케일/회전 애니메이션 효과 확인
   - 수집률 실시간 업데이트 확인:
     - 0/2 → 수집률 0% (파란색)
     - 1/2 → 수집률 50% (파란색, 애니메이션)
     - 2/2 → 수집률 100% (초록색, 체크 아이콘)

## 에러 시나리오 테스트

### 1. 잘못된 JWT 토큰
```bash
curl -X GET http://localhost:8000/api/catalogs/ \
  -H "Authorization: Bearer invalid-token"
```

**예상 응답:**
```json
{
  "detail": "토큰 검증에 실패했습니다: Invalid token format"
}
```

### 2. 만료된 JWT 토큰
```bash
# 24시간 후 또는 임의로 만료된 토큰 사용
curl -X GET http://localhost:8000/api/catalogs/ \
  -H "Authorization: Bearer expired-token"
```

**예상 응답:**
```json
{
  "detail": "토큰이 만료되었습니다"
}
```

### 3. 인증 헤더 없음
```bash
curl -X GET http://localhost:8000/api/catalogs/
```

**예상 응답:**
```json
{
  "detail": "인증이 필요합니다. Authorization 헤더에 JWT 토큰 또는 개발용 사용자 ID를 포함해주세요."
}
```

### 4. 다른 사용자의 데이터 접근 시도
```bash
# 사용자 A의 토큰으로 사용자 B의 카탈로그 접근 시도
curl -X GET http://localhost:8000/api/catalogs/{other-user-catalog-id} \
  -H "Authorization: Bearer user-a-token"
```

**예상 응답:**
```json
{
  "detail": "접근 권한이 없습니다"
}
```

## 성능 테스트

### 1. 응답 시간 측정
```bash
# 시간 측정과 함께 요청
time curl -X GET http://localhost:8000/api/catalogs/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**목표 응답 시간:**
- Spring Boot API: < 50ms
- FastAPI: < 30ms
- Flutter 로딩: < 100ms

### 2. 동시 요청 테스트
```bash
# 여러 터미널에서 동시 실행
for i in {1..10}; do
  curl -X GET http://localhost:8000/api/catalogs/ \
    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." &
done
wait
```

## 로그 모니터링

### 1. 실시간 로그 확인
```bash
# Spring Boot 로그
tail -f be/user-api/logs/application.log

# FastAPI 로그 (Docker)
docker logs -f <container-id>

# Flutter 로그
# 브라우저 개발자 도구 콘솔 확인
```

### 2. 로그 패턴 확인
- **성공적인 요청**: 200/201 응답 코드
- **인증 실패**: 401 응답 코드
- **권한 없음**: 403 응답 코드
- **서버 오류**: 500 응답 코드

## 문제 해결 가이드

### 1. 서버 연결 실패
```bash
# 포트 사용 확인
lsof -i :8081  # Spring Boot
lsof -i :8000  # FastAPI
lsof -i :3000  # Flutter

# 프로세스 종료
kill -9 <PID>
```

### 2. JWT 토큰 불일치
- Spring Boot와 FastAPI의 JWT_SECRET_KEY 동일한지 확인
- 토큰 만료 시간 확인 (24시간)
- 알고리즘 일치 확인 (HS256)

### 3. CORS 오류
- FastAPI CORS 설정 확인
- 브라우저 개발자 도구에서 네트워크 탭 확인

### 4. 데이터베이스 초기화
```bash
# SQLite 파일 삭제 (FastAPI)
rm be/catalog-api/catalog.db

# H2 데이터베이스는 재시작 시 자동 초기화 (Spring Boot)
```

## 자동화된 테스트 스크립트

### 전체 통합 테스트 스크립트
```bash
#!/bin/bash
# integration-test.sh

echo "🚀 통합 테스트 시작"

# 1. 사용자 생성
echo "👤 사용자 생성 중..."
USER_RESPONSE=$(curl -s -X POST http://localhost:8081/api/dev/create-user \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "nickname": "테스트사용자"}')

TOKEN=$(echo $USER_RESPONSE | jq -r '.accessToken')
echo "🔐 JWT 토큰: ${TOKEN:0:20}..."

# 2. 토큰 검증
echo "🔍 토큰 검증 중..."
VALIDATION=$(curl -s -X POST http://localhost:8081/api/test/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\": \"$TOKEN\"}")

if [[ $(echo $VALIDATION | jq -r '.valid') == "true" ]]; then
  echo "✅ 토큰 검증 성공"
else
  echo "❌ 토큰 검증 실패"
  exit 1
fi

# 3. 카탈로그 생성
echo "📁 카탈로그 생성 중..."
CATALOG_RESPONSE=$(curl -s -X POST http://localhost:8000/api/catalogs/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "자동 테스트 카탈로그", "description": "통합 테스트용"}')

CATALOG_ID=$(echo $CATALOG_RESPONSE | jq -r '.catalog_id')
echo "📁 카탈로그 ID: $CATALOG_ID"

# 4. 아이템 생성 및 수집률 테스트
echo "📦 아이템 생성 중..."
ITEM1_RESPONSE=$(curl -s -X POST http://localhost:8000/api/items/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"catalog_id\": \"$CATALOG_ID\", \"name\": \"테스트 아이템 1\", \"description\": \"첫 번째 아이템\"}")

ITEM1_ID=$(echo $ITEM1_RESPONSE | jq -r '.item_id')
echo "📦 아이템 1 ID: $ITEM1_ID"

ITEM2_RESPONSE=$(curl -s -X POST http://localhost:8000/api/items/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"catalog_id\": \"$CATALOG_ID\", \"name\": \"테스트 아이템 2\", \"description\": \"두 번째 아이템\"}")

ITEM2_ID=$(echo $ITEM2_RESPONSE | jq -r '.item_id')
echo "📦 아이템 2 ID: $ITEM2_ID"

# 5. 수집률 테스트 (0% → 50% → 100%)
echo "📊 수집률 테스트 시작..."

# 첫 번째 아이템 보유 상태 토글
curl -s -X PATCH http://localhost:8000/api/items/$ITEM1_ID/toggle-owned \
  -H "Authorization: Bearer $TOKEN" > /dev/null

# 수집률 확인 (50%)
CATALOG_50=$(curl -s -X GET http://localhost:8000/api/catalogs/$CATALOG_ID \
  -H "Authorization: Bearer $TOKEN")
RATE_50=$(echo $CATALOG_50 | jq -r '.completion_rate')
echo "📈 수집률 (1/2): $RATE_50%"

# 두 번째 아이템 보유 상태 토글
curl -s -X PATCH http://localhost:8000/api/items/$ITEM2_ID/toggle-owned \
  -H "Authorization: Bearer $TOKEN" > /dev/null

# 최종 수집률 확인 (100%)
CATALOG_100=$(curl -s -X GET http://localhost:8000/api/catalogs/$CATALOG_ID \
  -H "Authorization: Bearer $TOKEN")
RATE_100=$(echo $CATALOG_100 | jq -r '.completion_rate')
echo "🎉 최종 수집률 (2/2): $RATE_100%"

if [[ "$RATE_100" == "100.0" ]]; then
  echo "✅ 실시간 수집률 반영 테스트 성공!"
else
  echo "❌ 수집률 테스트 실패: 예상 100.0%, 실제 $RATE_100%"
  exit 1
fi
```

이 가이드를 통해 전체 시스템의 통합 테스트를 체계적으로 수행할 수 있습니다.