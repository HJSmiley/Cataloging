package com.cataloging.userapi.controller;

/**
 * 사용자 관리 REST API 컨트롤러
 * - 사용자 프로필 조회/수정/삭제
 * - JWT 토큰 기반 인증 필요
 * - Flutter 앱의 마이페이지 기능 지원
 */

import com.cataloging.userapi.dto.UserDto;
import com.cataloging.userapi.entity.User;
import com.cataloging.userapi.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@Slf4j                          // 로깅 기능 자동 생성
@RestController                 // REST API 컨트롤러 선언
@RequestMapping("/api/users")   // 기본 경로: /api/users
@RequiredArgsConstructor        // final 필드 생성자 자동 생성
public class UserController {
    
    // 의존성 주입: 사용자 서비스
    private final UserService userService;
    
    /**
     * 현재 로그인한 사용자 정보 조회
     * - Flutter ApiService.getCurrentUser()에서 호출
     * - JWT 토큰에서 사용자 ID 추출하여 프로필 조회
     * - 마이페이지 화면에서 사용
     */
    @GetMapping("/me")
    public ResponseEntity<UserDto.Response> getCurrentUser(Authentication authentication) {
        // JWT 토큰에서 추출된 사용자 ID (Spring Security가 자동 처리)
        Long userId = Long.parseLong(authentication.getName());
        User user = userService.getUserById(userId);
        return ResponseEntity.ok(UserDto.Response.from(user));
    }
    
    /**
     * 현재 사용자 프로필 수정
     * - Flutter 프로필 편집 화면에서 호출
     * - 닉네임, 프로필 이미지 등 수정 가능
     */
    @PutMapping("/me")
    public ResponseEntity<UserDto.Response> updateCurrentUser(
            @RequestBody UserDto.UpdateRequest updateRequest,
            Authentication authentication) {
        
        // JWT 토큰에서 사용자 ID 추출
        Long userId = Long.parseLong(authentication.getName());
        User updatedUser = userService.updateUser(userId, updateRequest);
        return ResponseEntity.ok(UserDto.Response.from(updatedUser));
    }
    
    /**
     * 회원 탈퇴 처리
     * - 사용자 계정 완전 삭제
     * - 관련된 모든 데이터 정리 필요 (catalog-api와 연동)
     */
    @DeleteMapping("/me")
    public ResponseEntity<Map<String, String>> deleteCurrentUser(Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        userService.deleteUser(userId);
        return ResponseEntity.ok(Map.of("message", "회원 탈퇴가 완료되었습니다."));
    }
    
    /**
     * 특정 사용자 정보 조회 (공개 프로필)
     * - 다른 사용자의 공개 프로필 조회
     * - 카탈로그 작성자 정보 표시용
     * - 탈퇴한 사용자 조회 시 특별한 응답 반환
     */
    @GetMapping("/{userId}")
    public ResponseEntity<UserDto.Response> getUser(@PathVariable Long userId) {
        try {
            User user = userService.getUserById(userId);
            
            // 탈퇴한 사용자인 경우
            if (user.getStatus() == User.UserStatus.DELETED) {
                // 탈퇴한 사용자 정보를 익명으로 표시
                UserDto.Response deletedUserResponse = UserDto.Response.builder()
                    .id(user.getId())
                    .email("deleted@user.com")
                    .nickname("탈퇴한 사용자")
                    .introduction("탈퇴한 사용자입니다.")
                    .profileImage(null)
                    .createdAt(user.getCreatedAt())
                    .updatedAt(user.getUpdatedAt())
                    .build();
                
                return ResponseEntity.ok(deletedUserResponse);
            }
            
            // 정상 사용자
            return ResponseEntity.ok(UserDto.Response.from(user));
            
        } catch (IllegalArgumentException e) {
            // 존재하지 않는 사용자
            throw new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "존재하지 않는 사용자입니다."
            );
        }
    }
}