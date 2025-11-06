package com.cataloging.userapi.controller;

/**
 * 개발용 사용자 관리 컨트롤러
 * - Flutter 앱에서 간편한 로그인을 위한 개발용 엔드포인트
 * - 실제 OAuth2 로그인 없이 테스트 사용자 생성 및 JWT 토큰 발급
 * - Flutter AuthService.createDevUser()에서 호출
 */

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

@Slf4j                                    // 로깅을 위한 Lombok 어노테이션
@RestController                           // REST API 컨트롤러 선언
@RequestMapping("/api/dev")               // 기본 경로: /api/dev
@RequiredArgsConstructor                  // final 필드 자동 생성자 주입
public class DevController {
    
    // 의존성 주입: 사용자 데이터베이스 접근
    private final UserRepository userRepository;
    // 의존성 주입: JWT 토큰 생성 및 검증
    private final JwtTokenProvider jwtTokenProvider;
    
    /**
     * 개발용 사용자 생성 및 로그인
     * - Flutter AuthService.createDevUser()에서 POST /api/dev/create-user 호출
     * - 이메일과 닉네임을 받아 사용자 생성 또는 기존 사용자 조회
     * - JWT 토큰을 생성하여 LoginResponse로 반환
     */
    @PostMapping("/create-user")
    public ResponseEntity<UserDto.LoginResponse> createUser(@RequestBody Map<String, String> request) {
        // 1단계: 요청에서 이메일과 닉네임 추출 (기본값 설정)
        String email = request.getOrDefault("email", "dev@example.com");
        String nickname = request.getOrDefault("nickname", "개발자");
        
        // 2단계: 기존 사용자 확인 (이메일 중복 체크)
        Optional<User> existingUser = userRepository.findByEmail(email);
        
        User user;
        if (existingUser.isPresent()) {
            // 기존 사용자가 있으면 재사용 (중복 생성 방지)
            user = existingUser.get();
            log.info("기존 사용자 사용: {}", user.getEmail());
        } else {
            // 3단계: 새 사용자 생성 (H2 데이터베이스에 저장)
            user = User.builder()
                    .provider("dev")                                    // 개발용 프로바이더
                    .providerId("dev-" + System.currentTimeMillis())   // 고유 ID 생성
                    .email(email)
                    .nickname(nickname)
                    .introduction("개발용 테스트 사용자")
                    .status(User.UserStatus.ACTIVE)                    // 활성 상태
                    .build();
            
            user = userRepository.save(user);  // JPA를 통해 H2 DB에 저장
            log.info("새 사용자 생성: {}", user.getEmail());
        }
        
        // 4단계: JWT 토큰 생성 (사용자 ID를 페이로드에 포함)
        String accessToken = jwtTokenProvider.createToken(user.getId().toString());
        
        // 5단계: 로그인 응답 객체 생성
        UserDto.LoginResponse response = UserDto.LoginResponse.builder()
                .accessToken(accessToken)                                           // JWT 토큰
                .tokenType("Bearer")                                               // 토큰 타입
                .expiresIn(jwtTokenProvider.getTokenValidityInMilliseconds() / 1000) // 만료 시간(초)
                .user(UserDto.Response.from(user))                                 // 사용자 정보
                .build();
        
        // 6단계: Flutter AuthService로 응답 반환
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