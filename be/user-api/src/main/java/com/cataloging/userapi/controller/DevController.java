package com.cataloging.userapi.controller;

import com.cataloging.userapi.dto.UserDto;
import com.cataloging.userapi.entity.User;
import com.cataloging.userapi.repository.UserRepository;
import com.cataloging.userapi.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/dev")
@RequiredArgsConstructor
public class DevController {
    
    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;
    
    @PostMapping("/create-user")
    public ResponseEntity<UserDto.LoginResponse> createUser(@RequestBody Map<String, String> request) {
        String email = request.getOrDefault("email", "dev@example.com");
        String nickname = request.getOrDefault("nickname", "개발자");
        
        // 기존 사용자 확인
        Optional<User> existingUser = userRepository.findByEmail(email);
        
        User user;
        if (existingUser.isPresent()) {
            user = existingUser.get();
            log.info("기존 사용자 사용: {}", user.getEmail());
        } else {
            // 새 사용자 생성
            user = User.builder()
                    .provider("dev")
                    .providerId("dev-" + System.currentTimeMillis())
                    .email(email)
                    .nickname(nickname)
                    .introduction("개발용 테스트 사용자")
                    .status(User.UserStatus.ACTIVE)
                    .build();
            
            user = userRepository.save(user);
            log.info("새 사용자 생성: {}", user.getEmail());
        }
        
        // JWT 토큰 생성
        String accessToken = jwtTokenProvider.createToken(user.getId().toString());
        
        UserDto.LoginResponse response = UserDto.LoginResponse.builder()
                .accessToken(accessToken)
                .tokenType("Bearer")
                .expiresIn(jwtTokenProvider.getTokenValidityInMilliseconds() / 1000)
                .user(UserDto.Response.from(user))
                .build();
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/users")
    public ResponseEntity<java.util.List<UserDto.Response>> getAllUsers() {
        return ResponseEntity.ok(
            userRepository.findAll().stream()
                .map(UserDto.Response::from)
                .toList()
        );
    }
    
    @DeleteMapping("/users/{userId}")
    public ResponseEntity<Map<String, String>> deleteUser(@PathVariable Long userId) {
        userRepository.deleteById(userId);
        return ResponseEntity.ok(Map.of("message", "사용자가 삭제되었습니다."));
    }
}