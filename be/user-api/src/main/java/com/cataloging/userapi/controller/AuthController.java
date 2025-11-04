package com.cataloging.userapi.controller;

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