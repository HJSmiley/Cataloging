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
import com.cataloging.userapi.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j                          // 로깅 기능 자동 생성
@RestController                 // REST API 컨트롤러 선언
@RequestMapping("/api/auth")    // 기본 경로: /api/auth
@RequiredArgsConstructor        // final 필드 생성자 자동 생성
public class AuthController {
    
    // 의존성 주입: 사용자 서비스와 JWT 토큰 제공자
    private final UserService userService;
    private final JwtTokenProvider jwtTokenProvider;
    
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
     * OAuth2 소셜 로그인 URL 제공
     * - Google, GitHub 등 소셜 로그인 URL 반환
     * - Spring Security OAuth2 자동 설정 활용
     */
    @GetMapping("/login/{provider}")
    public ResponseEntity<Map<String, String>> getLoginUrl(@PathVariable String provider) {
        // Spring Security OAuth2가 자동으로 생성하는 인증 URL
        String loginUrl = "/oauth2/authorization/" + provider;
        return ResponseEntity.ok(Map.of(
            "loginUrl", loginUrl,
            "message", provider + " 로그인 URL입니다."
        ));
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