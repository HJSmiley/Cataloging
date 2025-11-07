package com.cataloging.userapi.entity;

/**
 * 사용자 엔티티 클래스
 * - H2 데이터베이스의 users 테이블과 매핑
 * - OAuth2 소셜 로그인 사용자 정보 저장
 * - JWT 토큰의 사용자 ID로 참조됨
 * - catalog-api에서 user_id로 카탈로그 소유자 식별
 */

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity                     // JPA 엔티티로 선언
@Table(name = "users")      // 데이터베이스 테이블명 지정
@Data                       // Getter/Setter 자동 생성
@NoArgsConstructor          // 기본 생성자 자동 생성
@AllArgsConstructor         // 모든 필드 생성자 자동 생성
@Builder                    // 빌더 패턴 자동 생성
public class User {
    
    @Id                                                     // 기본 키
    @GeneratedValue(strategy = GenerationType.IDENTITY)    // 자동 증가 ID
    private Long id;                                        // 사용자 고유 ID (JWT sub 클레임에 사용)
    
    @Column(nullable = false)
    private String provider;                                // OAuth2 제공자 (google, naver, dev 등)
    
    @Column(nullable = false, unique = true)
    private String providerId;                              // 제공자별 고유 식별자 (중복 방지)
    
    @Column(nullable = false)
    private String email;                                   // 이메일 주소
    
    @Column(nullable = false)
    private String nickname;                                // 사용자 닉네임 (Flutter에서 표시)
    
    @Column(columnDefinition = "TEXT")
    private String introduction;                            // 자기소개 (긴 텍스트)
    
    private String profileImage;                            // 프로필 이미지 URL
    
    @Enumerated(EnumType.STRING)                           // Enum을 문자열로 저장
    @Column(nullable = false)
    @Builder.Default
    private UserStatus status = UserStatus.ACTIVE;         // 사용자 상태 (기본값: 활성)
    
    @CreationTimestamp                                     // 생성 시 자동으로 현재 시간 설정
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;                        // 계정 생성 시간
    
    @UpdateTimestamp                                       // 수정 시 자동으로 현재 시간 설정
    @Column(nullable = false)
    private LocalDateTime updatedAt;                        // 마지막 수정 시간
    
    /**
     * 사용자 상태 열거형
     * - ACTIVE: 정상 활성 사용자
     * - INACTIVE: 비활성 사용자 (일시 정지 등)
     * - DELETED: 탈퇴한 사용자 (소프트 삭제)
     */
    public enum UserStatus {
        ACTIVE, INACTIVE, DELETED
    }
}