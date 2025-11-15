package com.cataloging.userapi.controller;

/**
 * 인증 관련 REST API 컨트롤러
 * - Flutter 앱의 로그인/로그아웃 요청 처리
 * - JWT 토큰 발급 및 관리
 * - OAuth2 소셜 로그인 지원 (Google, GitHub 등)
 * - 개발용 간편 로그인 제공
 */

import com.cataloging.userapi.dto.UserDto;
import com.cataloging.userapi.entity.User;
import com.cataloging.userapi.service.UserService;
import com.cataloging.userapi.service.OAuth2Service;
import com.cataloging.userapi.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.HashMap;

@Slf4j                          // 로깅 기능 자동 생성
@RestController                 // REST API 컨트롤러 선언
@RequestMapping("/api/auth")    // 기본 경로: /api/auth
@RequiredArgsConstructor        // final 필드 생성자 자동 생성
public class AuthController {
    
    // 의존성 주입: 사용자 서비스와 JWT 토큰 제공자
    private final UserService userService;
    private final JwtTokenProvider jwtTokenProvider;
    private final OAuth2Service oauth2Service;
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper;
    
    // State 임시 저장소 (프로덕션에서는 Redis 사용 권장)
    private final Map<String, String> stateStore = new HashMap<>();
    
    /**
     * 개발용 간편 로그인 엔드포인트
     * - Flutter ApiService.devLogin()에서 호출
     * - OAuth2 없이 이메일/닉네임만으로 로그인
     * - 자동으로 사용자 생성 또는 기존 사용자 조회
     * - JWT 토큰 발급하여 catalog-api 인증에 사용
     */
    @PostMapping("/dev-login")
    public ResponseEntity<UserDto.LoginResponse> devLogin(@RequestBody Map<String, String> request) {
        try {
            // 1단계: 요청에서 사용자 정보 추출
            String email = request.get("email");
            String nickname = request.get("nickname");
            
            log.info("개발용 로그인 요청: email={}, nickname={}", email, nickname);
            
            // 2단계: 필수 필드 검증
            if (email == null || nickname == null) {
                throw new IllegalArgumentException("이메일과 닉네임이 필요합니다");
            }
            
            // 3단계: 사용자 처리 (신규 생성 또는 기존 사용자 조회)
            // OAuth2User 시뮬레이션 - 실제 OAuth2 없이 사용자 생성/조회
            User user = userService.processDevUser(email, nickname);
            
            // 4단계: JWT 액세스 토큰 생성
            // catalog-api에서 동일한 시크릿 키로 검증할 수 있도록 생성
            String accessToken = jwtTokenProvider.createToken(user.getId().toString());
            
            // 5단계: 로그인 응답 데이터 구성
            UserDto.LoginResponse response = UserDto.LoginResponse.builder()
                    .accessToken(accessToken)    // JWT 토큰
                    .tokenType("Bearer")         // 토큰 타입
                    .expiresIn(86400L)          // 24시간 유효기간
                    .user(UserDto.Response.from(user))  // 사용자 정보
                    .build();
            
            return ResponseEntity.ok(response);  // Flutter로 로그인 결과 반환
            
        } catch (Exception e) {
            log.error("개발용 로그인 실패", e);
            throw new RuntimeException("로그인 실패: " + e.getMessage());
        }
    }

    /**
     * 테스트 엔드포인트
     */
    @GetMapping("/test")
    public ResponseEntity<Map<String, String>> test() {
        log.info("=== Test endpoint called ===");
        return ResponseEntity.ok(Map.of("message", "Test successful"));
    }
    
    /**
     * OAuth2 인증 URL 요청
     * Flutter → Backend: 로그인 URL 요청
     * 
     * @param provider google 또는 naver
     * @param request HTTP 요청 (User-Agent 확인용)
     * @return 인증 URL과 state
     */
    @GetMapping("/oauth/{provider}/url")
    public ResponseEntity<Map<String, String>> getOAuthUrl(
            @PathVariable String provider,
            jakarta.servlet.http.HttpServletRequest request) {
        try {
            log.info("{} OAuth2 인증 URL 요청", provider);
            
            // User-Agent에서 플랫폼 감지
            String userAgent = request.getHeader("User-Agent");
            String baseUrl = determineBaseUrl(userAgent);
            
            log.info("감지된 플랫폼 Base URL: {}", baseUrl);
            
            // OAuth2 인증 URL 생성 (동적 base URL 사용)
            Map<String, String> result = oauth2Service.getAuthorizationUrl(provider, baseUrl);
            
            // State 저장 (CSRF 방지용)
            stateStore.put(result.get("state"), provider);
            
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("{} OAuth2 인증 URL 생성 실패", provider, e);
            throw new RuntimeException("인증 URL 생성 실패: " + e.getMessage());
        }
    }
    
    /**
     * User-Agent를 기반으로 Base URL 결정
     * - Android: 10.0.2.2 (에뮬레이터)
     * - iOS/기타: localhost
     */
    private String determineBaseUrl(String userAgent) {
        if (userAgent != null) {
            String ua = userAgent.toLowerCase();
            // Cataloging-Android 또는 android 포함
            if (ua.contains("cataloging-android") || ua.contains("android")) {
                log.info("Android 플랫폼 감지: {}", userAgent);
                return "http://10.0.2.2:8080";
            }
        }
        log.info("iOS/기타 플랫폼 감지: {}", userAgent);
        return "http://localhost:8080";
    }
    
    /**
     * OAuth2 콜백 처리
     * Google/Naver → Backend: Authorization Code 전달
     * 
     * @param provider google 또는 naver
     * @param code Authorization Code
     * @param state CSRF 방지용 state
     * @return JSON 응답 (WebView에서 직접 처리)
     */
    @GetMapping(value = "/oauth2/{provider}/callback")
    public ResponseEntity<?> oauthCallback(
            @PathVariable String provider,
            @RequestParam String code,
            @RequestParam String state) {
        try {
            log.info("=== {} OAuth2 콜백 시작 ===", provider);
            log.info("Code: {}", code);
            log.info("State: {}", state);
            
            // State 검증 (CSRF 방지) - 임시로 경고만 출력
            String storedProvider = stateStore.remove(state);
            if (storedProvider == null) {
                log.warn("State not found in store: {}. Continuing anyway for testing...", state);
                // 테스트를 위해 계속 진행
            } else if (!storedProvider.equals(provider)) {
                log.error("Provider mismatch: expected={}, actual={}", storedProvider, provider);
                throw new IllegalArgumentException("유효하지 않은 state 파라미터");
            }
            
            // 1. Authorization Code → Access Token
            log.info("Step 1: Authorization Code → Access Token 교환 시작");
            String accessToken = oauth2Service.exchangeCodeForToken(provider, code);
            log.info("Step 1 완료: Access Token 발급 성공");
            
            // 2. Access Token → 사용자 정보
            log.info("Step 2: Access Token → 사용자 정보 조회 시작");
            Map<String, Object> userInfo = oauth2Service.getUserInfo(provider, accessToken);
            log.info("Step 2 완료: 사용자 정보 조회 성공 - {}", userInfo);
            
            // 3. 사용자 정보 표준화
            log.info("Step 3: 사용자 정보 표준화 시작");
            Map<String, String> standardUserInfo = oauth2Service.extractUserInfo(provider, userInfo);
            log.info("Step 3 완료: 표준화된 사용자 정보 - {}", standardUserInfo);
            
            // 4. 사용자 처리 (신규 생성 또는 기존 사용자 조회)
            User user = userService.processOAuthUser(
                provider,
                standardUserInfo.get("providerId"),
                standardUserInfo.get("email"),
                standardUserInfo.get("name"),
                standardUserInfo.get("picture")
            );
            
            // 5. JWT 토큰 생성
            String jwtToken = jwtTokenProvider.createToken(user.getId().toString());
            
            // 6. 로그인 응답 데이터 구성
            UserDto.LoginResponse response = UserDto.LoginResponse.builder()
                    .accessToken(jwtToken)
                    .tokenType("Bearer")
                    .expiresIn(86400L)
                    .user(UserDto.Response.from(user))
                    .build();
            
            log.info("{} OAuth2 로그인 성공: userId={}", provider, user.getId());
            
            // 7. HTML 페이지 반환 (Flutter WebView로 데이터 전달)
            // 최소한의 HTML로 빠르게 데이터 전달
            String jsonData = objectMapper.writeValueAsString(response);
            String html = "<!DOCTYPE html>" +
                   "<html>" +
                   "<head><meta charset=\"UTF-8\"><title>로그인 중...</title></head>" +
                   "<body style=\"margin:0;padding:0;\">" +
                   "<script>" +
                   "window.loginData = " + jsonData + ";" +
                   "console.log('Login successful:', window.loginData);" +
                   "</script>" +
                   "</body>" +
                   "</html>";
            
            return ResponseEntity.ok()
                    .header("Content-Type", "text/html; charset=UTF-8")
                    .body(html);
            
        } catch (Exception e) {
            log.error("{} OAuth2 콜백 처리 실패", provider, e);
            String errorHtml = "<!DOCTYPE html>" +
                   "<html>" +
                   "<head><title>로그인 실패</title></head>" +
                   "<body>" +
                   "<h1>로그인 실패</h1>" +
                   "<p>" + e.getMessage() + "</p>" +
                   "</body>" +
                   "</html>";
            
            return ResponseEntity.status(500)
                    .header("Content-Type", "text/html; charset=UTF-8")
                    .body(errorHtml);
        }
    }
    
    /**
     * 로그아웃 처리
     * - JWT는 stateless하므로 서버에서 별도 처리 불필요
     * - Flutter에서 토큰을 삭제하면 자동으로 로그아웃 효과
     */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout() {
        // JWT 토큰은 서버에 저장되지 않으므로 클라이언트에서 삭제만 하면 됨
        return ResponseEntity.ok(Map.of("message", "로그아웃되었습니다."));
    }
}