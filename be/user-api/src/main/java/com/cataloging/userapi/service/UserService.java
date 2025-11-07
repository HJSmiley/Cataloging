package com.cataloging.userapi.service;

/**
 * 사용자 관리 서비스 클래스
 * - OAuth2 소셜 로그인 사용자 처리
 * - 개발용 간편 로그인 사용자 처리
 * - 사용자 프로필 CRUD 작업
 * - H2 데이터베이스에 사용자 정보 저장
 */

import com.cataloging.userapi.dto.UserDto;
import com.cataloging.userapi.entity.User;
import com.cataloging.userapi.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;

@Slf4j                      // 로깅 기능 자동 생성
@Service                    // Spring 서비스 컴포넌트로 등록
@RequiredArgsConstructor    // final 필드 생성자 자동 생성
@Transactional              // 모든 메서드에 트랜잭션 적용
public class UserService {
    
    // 의존성 주입: 사용자 데이터 접근 객체
    private final UserRepository userRepository;
    
    /**
     * OAuth2 소셜 로그인 사용자 처리
     * - Google, Naver 등 소셜 로그인 성공 시 호출
     * - 기존 사용자면 정보 업데이트, 신규 사용자면 계정 생성
     * - OAuth2SuccessHandler에서 호출
     */
    public User processOAuth2User(String provider, OAuth2User oAuth2User) {
        Map<String, Object> attributes = oAuth2User.getAttributes();
        
        String providerId;
        String email;
        String nickname;
        String profileImage = null;
        
        // 1단계: OAuth2 제공자별 사용자 정보 추출
        switch (provider.toLowerCase()) {
            case "google":
                // Google OAuth2 응답 구조에 맞춰 정보 추출
                providerId = (String) attributes.get("sub");        // Google 고유 ID
                email = (String) attributes.get("email");           // 이메일
                nickname = (String) attributes.get("name");         // 표시명
                profileImage = (String) attributes.get("picture");  // 프로필 이미지
                break;
                
            case "naver":
                // Naver OAuth2 응답 구조에 맞춰 정보 추출 (response 객체 내부)
                @SuppressWarnings("unchecked")
                Map<String, Object> response = (Map<String, Object>) attributes.get("response");
                providerId = (String) response.get("id");           // Naver 고유 ID
                email = (String) response.get("email");             // 이메일
                nickname = (String) response.get("name");           // 표시명
                profileImage = (String) response.get("profile_image");  // 프로필 이미지
                break;
                
            default:
                throw new IllegalArgumentException("지원하지 않는 OAuth2 제공자입니다: " + provider);
        }
        
        log.debug("OAuth2 사용자 정보 추출: provider={}, providerId={}, email={}, nickname={}", 
                 provider, providerId, email, nickname);
        
        // 2단계: 기존 사용자 확인 (제공자 + 제공자 ID 조합으로 검색)
        Optional<User> existingUser = userRepository.findByProviderAndProviderId(provider, providerId);
        
        if (existingUser.isPresent()) {
            // 3-A단계: 기존 사용자 정보 업데이트 (최신 정보로 동기화)
            User user = existingUser.get();
            user.setEmail(email);
            user.setNickname(nickname);
            if (profileImage != null) {
                user.setProfileImage(profileImage);
            }
            return userRepository.save(user);
        } else {
            // 3-B단계: 새 사용자 계정 생성
            User newUser = User.builder()
                    .provider(provider)                     // OAuth2 제공자 (google, naver 등)
                    .providerId(providerId)                 // 제공자별 고유 ID
                    .email(email)                          // 이메일
                    .nickname(nickname)                    // 닉네임
                    .profileImage(profileImage)            // 프로필 이미지 URL
                    .status(User.UserStatus.ACTIVE)        // 활성 상태
                    .build();
            
            return userRepository.save(newUser);
        }
    }
    
    /**
     * 사용자 ID로 사용자 조회
     * - JWT 토큰에서 추출한 사용자 ID로 프로필 조회
     * - 읽기 전용 트랜잭션으로 성능 최적화
     */
    @Transactional(readOnly = true)
    public User getUserById(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));
    }
    
    /**
     * 사용자 프로필 정보 수정
     * - Flutter 프로필 편집 화면에서 호출
     * - 닉네임, 자기소개, 프로필 이미지 수정 가능
     */
    public User updateUser(Long userId, UserDto.UpdateRequest updateRequest) {
        User user = getUserById(userId);
        
        // null이 아닌 필드만 업데이트 (부분 업데이트)
        if (updateRequest.getNickname() != null) {
            user.setNickname(updateRequest.getNickname());
        }
        if (updateRequest.getIntroduction() != null) {
            user.setIntroduction(updateRequest.getIntroduction());
        }
        if (updateRequest.getProfileImage() != null) {
            user.setProfileImage(updateRequest.getProfileImage());
        }
        
        return userRepository.save(user);
    }
    
    /**
     * 회원 탈퇴 처리
     * - 실제 삭제가 아닌 상태를 DELETED로 변경 (소프트 삭제)
     * - 데이터 복구 및 참조 무결성 유지
     */
    public void deleteUser(Long userId) {
        User user = getUserById(userId);
        user.setStatus(User.UserStatus.DELETED);  // 상태만 변경
        userRepository.save(user);
    }
    
    /**
     * 개발용 간편 로그인 사용자 처리
     * - OAuth2 없이 이메일/닉네임만으로 로그인
     * - 개발 및 테스트 환경에서 사용
     * - AuthController.devLogin()에서 호출
     */
    public User processDevUser(String email, String nickname) {
        log.debug("개발용 사용자 처리: email={}, nickname={}", email, nickname);
        
        // 1단계: 개발용 제공자로 기존 사용자 확인 (이메일을 providerId로 사용)
        Optional<User> existingUser = userRepository.findByProviderAndProviderId("dev", email);
        
        if (existingUser.isPresent()) {
            // 2-A단계: 기존 사용자 정보 업데이트
            User user = existingUser.get();
            user.setNickname(nickname);  // 닉네임만 업데이트
            return userRepository.save(user);
        } else {
            // 2-B단계: 새 개발용 사용자 생성
            User newUser = User.builder()
                    .provider("dev")            // 개발용 제공자
                    .providerId(email)          // 이메일을 고유 ID로 사용
                    .email(email)               // 이메일
                    .nickname(nickname)         // 닉네임
                    .status(User.UserStatus.ACTIVE)  // 활성 상태
                    .build();
            
            return userRepository.save(newUser);
        }
    }
}