package com.cataloging.userapi.controller;

import com.cataloging.userapi.dto.UserDto;
import com.cataloging.userapi.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/test")
@RequiredArgsConstructor
public class TestController {
    
    private final JwtTokenProvider jwtTokenProvider;
    
    @PostMapping("/create-token")
    public ResponseEntity<UserDto.LoginResponse> createTestToken(@RequestBody Map<String, String> request) {
        String email = request.getOrDefault("email", "test@example.com");
        String nickname = request.getOrDefault("nickname", "테스트사용자");
        
        // 테스트용 사용자 ID (실제로는 DB에서 가져와야 함)
        String userId = "1";
        
        // JWT 토큰 생성
        String accessToken = jwtTokenProvider.createToken(userId);
        
        // Mock 사용자 응답 생성
        UserDto.Response mockUser = UserDto.Response.builder()
                .id(1L)
                .email(email)
                .nickname(nickname)
                .introduction("테스트 사용자입니다.")
                .profileImage(null)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        
        UserDto.LoginResponse response = UserDto.LoginResponse.builder()
                .accessToken(accessToken)
                .tokenType("Bearer")
                .expiresIn(jwtTokenProvider.getTokenValidityInMilliseconds() / 1000)
                .user(mockUser)
                .build();
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "message", "User API is running",
            "timestamp", java.time.Instant.now().toString()
        ));
    }
    
    @PostMapping("/validate-token")
    public ResponseEntity<Map<String, Object>> validateToken(@RequestBody Map<String, String> request) {
        String token = request.get("token");
        
        if (token == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "valid", false,
                "message", "토큰이 제공되지 않았습니다."
            ));
        }
        
        boolean isValid = jwtTokenProvider.validateToken(token);
        
        if (isValid) {
            String userId = jwtTokenProvider.getUserId(token);
            return ResponseEntity.ok(Map.of(
                "valid", true,
                "userId", userId,
                "message", "유효한 토큰입니다."
            ));
        } else {
            return ResponseEntity.ok(Map.of(
                "valid", false,
                "message", "유효하지 않은 토큰입니다."
            ));
        }
    }
}