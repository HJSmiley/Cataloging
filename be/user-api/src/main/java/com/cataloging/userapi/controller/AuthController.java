package com.cataloging.userapi.controller;

import com.cataloging.userapi.dto.UserDto;
import com.cataloging.userapi.entity.User;
import com.cataloging.userapi.service.UserService;
import com.cataloging.userapi.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final UserService userService;
    private final JwtTokenProvider jwtTokenProvider;
    
    @PostMapping("/dev-login")
    public ResponseEntity<UserDto.LoginResponse> devLogin(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String nickname = request.get("nickname");
            
            log.info("개발용 로그인 요청: email={}, nickname={}", email, nickname);
            
            if (email == null || nickname == null) {
                throw new IllegalArgumentException("이메일과 닉네임이 필요합니다");
            }
            
            // 개발용 OAuth2User 시뮬레이션
            User user = userService.processDevUser(email, nickname);
            
            // JWT 토큰 생성
            String accessToken = jwtTokenProvider.createToken(user.getId().toString());
            
            UserDto.LoginResponse response = UserDto.LoginResponse.builder()
                    .accessToken(accessToken)
                    .tokenType("Bearer")
                    .expiresIn(86400L) // 24시간
                    .user(UserDto.Response.from(user))
                    .build();
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("개발용 로그인 실패", e);
            throw new RuntimeException("로그인 실패: " + e.getMessage());
        }
    }

    @GetMapping("/login/{provider}")
    public ResponseEntity<Map<String, String>> getLoginUrl(@PathVariable String provider) {
        String loginUrl = "/oauth2/authorization/" + provider;
        return ResponseEntity.ok(Map.of(
            "loginUrl", loginUrl,
            "message", provider + " 로그인 URL입니다."
        ));
    }
    
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout() {
        // JWT는 stateless하므로 클라이언트에서 토큰을 삭제하면 됨
        return ResponseEntity.ok(Map.of("message", "로그아웃되었습니다."));
    }
}