# 사용자 API (Spring Boot + OAuth2 + JWT)

수집가를 위한 사용자 인증 및 프로필 관리 API 서버입니다.

## 기능

- SNS 로그인 (Google, Naver)
- JWT 토큰 기반 인증
- 사용자 프로필 관리 (조회, 수정, 삭제)
- 회원 탈퇴 (Soft Delete)

## 기술 스택

- **Spring Boot 3.2.0**: Java 웹 프레임워크
- **Spring Security**: 인증 및 보안
- **Spring OAuth2 Client**: SNS 로그인
- **JWT**: 토큰 기반 인증
- **JPA/Hibernate**: ORM
- **H2 Database**: 로컬 개발용 데이터베이스
- **Lombok**: 코드 간소화

## 설치 및 실행

### 1. 환경 변수 설정 (선택사항)

환경 변수를 설정하여 포트 및 OAuth2 설정을 변경할 수 있습니다:

```bash
# 포트 설정 (기본값: 8080)
export PORT=8080

# OAuth2 클라이언트 정보
export GOOGLE_CLIENT_ID=your-google-client-id
export GOOGLE_CLIENT_SECRET=your-google-client-secret
export NAVER_CLIENT_ID=your-naver-client-id
export NAVER_CLIENT_SECRET=your-naver-client-secret

# JWT 시크릿 키 (Catalog API와 동일하게 설정)
export JWT_SECRET=your-jwt-secret-key
```

**중요**: `JWT_SECRET`은 Catalog API의 `JWT_SECRET_KEY`와 동일해야 합니다.

### 2. 애플리케이션 실행

#### 방법 1: 실행 스크립트 사용 (권장)
```bash
# macOS/Linux
cd be/user-api
./run.sh

# Windows
cd be/user-api
run.bat
```

실행 스크립트는 `.env` 파일의 환경 변수를 자동으로 로드합니다.

#### 방법 2: 환경 변수 직접 설정
```bash
cd be/user-api

# macOS/Linux - .env 파일 로드
export $(cat .env | grep -v '^#' | xargs)
./gradlew bootRun

# Windows PowerShell
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#].+?)=(.+)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}
.\gradlew.bat bootRun
```

#### 방법 3: application-local.yml 사용
`src/main/resources/application-local.yml` 파일에 직접 값을 입력하고:
```bash
./gradlew bootRun
```

**참고**: `application-local.yml`은 `.gitignore`에 포함되어 Git에 커밋되지 않습니다.

**포트 설정**:
- 기본 포트: 8080
- 환경 변수 `PORT`로 변경 가능
- `application.yml`의 `server.port: ${PORT:8080}` 설정 참조

### 3. H2 데이터베이스 콘솔 접근

개발 중 데이터베이스 상태를 확인하려면:
- URL: http://localhost:{PORT}/h2-console (기본: http://localhost:8080/h2-console)
- JDBC URL: `jdbc:h2:mem:testdb`
- Username: `sa`
- Password: (비어있음)

**참고**: 포트를 변경한 경우 URL도 함께 변경됩니다.

### 4. 개발용 테스트

애플리케이션이 실행되면 다음 명령으로 테스트할 수 있습니다:

```bash
# 헬스체크 (포트는 환경 변수에 따라 변경)
curl -X GET http://localhost:8080/api/test/health

# 테스트 사용자 생성 및 JWT 토큰 발급
curl -X POST http://localhost:8080/api/dev/create-user \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "nickname": "테스트사용자"}'

# JWT 토큰으로 사용자 정보 조회 (위에서 받은 accessToken 사용)
curl -X GET http://localhost:8080/api/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**참고**: 포트를 변경한 경우 (예: PORT=8081), URL의 포트 번호도 함께 변경하세요.

## API 엔드포인트

### 인증 API

- `GET /api/auth/login/{provider}` - OAuth2 로그인 URL 조회 (provider: google, naver)
- `POST /api/auth/logout` - 로그아웃

### 사용자 API

- `GET /api/users/me` - 현재 사용자 정보 조회
- `PUT /api/users/me` - 현재 사용자 정보 수정
- `DELETE /api/users/me` - 회원 탈퇴
- `GET /api/users/{userId}` - 특정 사용자 정보 조회

### 개발용 API

- `GET /api/test/health` - 서버 상태 확인
- `POST /api/test/create-token` - 테스트용 JWT 토큰 생성
- `POST /api/test/validate-token` - JWT 토큰 검증
- `POST /api/dev/create-user` - 실제 사용자 생성 (개발용)
- `GET /api/dev/users` - 모든 사용자 조회 (개발용)
- `DELETE /api/dev/users/{userId}` - 사용자 삭제 (개발용)

### OAuth2 로그인 플로우

1. **로그인 URL 요청**:
   ```
   GET /api/auth/login/google
   ```

2. **OAuth2 인증 시작**:
   ```
   GET /oauth2/authorization/google
   ```

3. **콜백 처리**: 
   - Google/Naver에서 인증 완료 후 `/login/oauth2/code/{provider}`로 리다이렉트
   - 서버에서 사용자 정보 처리 후 JWT 토큰 발급

4. **API 요청 시 인증**:
   ```
   Authorization: Bearer {jwt-token}
   ```

## 데이터 구조

### 사용자 (User)

```json
{
  "id": 1,
  "email": "user@example.com",
  "nickname": "사용자닉네임",
  "introduction": "자기소개",
  "profileImage": "https://example.com/profile.jpg",
  "createdAt": "2024-01-01T00:00:00",
  "updatedAt": "2024-01-01T00:00:00"
}
```

### 로그인 응답

```json
{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "nickname": "사용자닉네임",
    "profileImage": "https://example.com/profile.jpg"
  }
}
```

## OAuth2 설정 가이드

### Google OAuth2 설정

1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트 생성
2. "API 및 서비스" > "사용자 인증 정보"로 이동
3. "사용자 인증 정보 만들기" > "OAuth 2.0 클라이언트 ID" 선택
4. 애플리케이션 유형: "웹 애플리케이션" 선택
5. 승인된 리디렉션 URI 추가:
   - `http://localhost:8080/login/oauth2/code/google`
   - 프로덕션: `https://your-domain.com/login/oauth2/code/google`
6. 생성된 클라이언트 ID와 클라이언트 보안 비밀을 `.env` 파일에 설정:
   ```bash
   GOOGLE_CLIENT_ID=your-google-client-id
   GOOGLE_CLIENT_SECRET=your-google-client-secret
   ```

### Naver OAuth2 설정

1. [네이버 개발자 센터](https://developers.naver.com/)에서 애플리케이션 등록
2. "Application > 애플리케이션 등록" 선택
3. 사용 API: "네이버 로그인" 선택
4. 제공 정보: "이메일", "닉네임" 필수 선택
5. 서비스 URL: `http://localhost:8080`
6. Callback URL: `http://localhost:8080/login/oauth2/code/naver`
   - 프로덕션: `https://your-domain.com/login/oauth2/code/naver`
7. 생성된 Client ID와 Client Secret을 `.env` 파일에 설정:
   ```bash
   NAVER_CLIENT_ID=your-naver-client-id
   NAVER_CLIENT_SECRET=your-naver-client-secret
   ```

### .env 파일 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```bash
# JWT 설정 (Catalog API와 동일하게 설정)
JWT_SECRET=mySecretKey1234567890123456789012345678901234567890

# Google OAuth2 설정
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Naver OAuth2 설정
NAVER_CLIENT_ID=your-naver-client-id
NAVER_CLIENT_SECRET=your-naver-client-secret

# 서버 포트
PORT=8080
```

**중요**: `.env` 파일은 `.gitignore`에 포함되어 있으므로 Git에 커밋되지 않습니다.

## 개발 참고사항

- JWT 토큰 만료 시간: 24시간 (설정 가능)
- 사용자 삭제는 Soft Delete 방식 (status를 DELETED로 변경)
- H2 데이터베이스는 애플리케이션 재시작 시 초기화됨
- 프로덕션 환경에서는 MySQL 등 영구 데이터베이스 사용 권장
- CORS 설정이 모든 도메인에 대해 허용되어 있음 (개발용)

## 테스트

```bash
# 단위 테스트 실행
./gradlew test

# 특정 테스트 클래스 실행
./gradlew test --tests UserServiceTest
```

## 프로덕션 배포 시 고려사항

1. **환경 변수 설정**: 실제 OAuth2 클라이언트 정보 및 JWT 시크릿 설정
2. **데이터베이스**: H2에서 MySQL/PostgreSQL로 변경
3. **CORS 설정**: 실제 프론트엔드 도메인만 허용하도록 수정
4. **HTTPS**: 프로덕션에서는 HTTPS 필수
5. **로깅**: 적절한 로그 레벨 설정 및 로그 수집 시스템 연동