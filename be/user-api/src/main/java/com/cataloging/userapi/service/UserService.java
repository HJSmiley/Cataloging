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
    private final CatalogApiService catalogApiService;
    

    /**
     * 사용자 ID로 사용자 조회
     * - JWT 토큰에서 추출한 사용자 ID로 프로필 조회
     * - 읽기 전용 트랜잭션으로 성능 최적화
     */
    @Transactional(readOnly = true)
    public User getUserById(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("탈퇴했거나 존재하지 않는 사용자입니다."));
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
     * 회원 탈퇴 처리 (소프트 삭제)
     * - 상태만 DELETED로 변경 (데이터는 유지)
     * - 카탈로그/아이템은 유지
     * - 데이터 복구 가능 및 참조 무결성 유지
     * - 재가입 시 기존 데이터 재활성화 가능
     */
    public void deleteUser(Long userId) {
        User user = getUserById(userId);
        user.setStatus(User.UserStatus.DELETED);
        userRepository.save(user);
        
        log.info("사용자 소프트 삭제 완료: userId={}, email={}", userId, user.getEmail());
        log.info("카탈로그/아이템은 유지됨");
    }
    
    /**
     * 회원 탈퇴 처리 (하드 삭제) - 사용하지 않음
     * - DB에서 사용자 데이터 완전 삭제
     * - 주의: 삭제 후 복구 불가능
     */
    public void hardDeleteUser(Long userId) {
        User user = getUserById(userId);
        userRepository.delete(user);
        log.info("사용자 데이터 완전 삭제 완료: userId={}, email={}", userId, user.getEmail());
    }
    

    /**
     * OAuth2 사용자 처리 (통합 메서드)
     * - Google, Naver 등 모든 OAuth2 제공자에서 사용
     * - 기존 사용자: 이메일만 업데이트 (닉네임/프로필 이미지는 사용자가 수정한 것 유지)
     * - 신규 사용자: OAuth2 제공자 정보로 계정 생성
     * - 탈퇴 후 재가입: OAuth2 제공자 정보로 다시 초기화
     */
    public User processOAuthUser(String provider, String providerId, String email, String name, String picture) {
        log.info("{} OAuth2 사용자 처리: providerId={}, email={}, name={}", provider, providerId, email, name);
        
        // 기존 사용자 확인
        Optional<User> existingUser = userRepository.findByProviderAndProviderId(provider, providerId);
        
        if (existingUser.isPresent()) {
            User user = existingUser.get();
            
            // 탈퇴한 사용자가 재가입하는 경우
            if (user.getStatus() == User.UserStatus.DELETED) {
                log.info("탈퇴한 사용자 재가입: userId={}, 정보 재설정", user.getId());
                // 탈퇴 후 재가입 시 OAuth2 제공자 정보로 다시 초기화
                user.setEmail(email);
                user.setNickname(name);
                user.setProfileImage(picture);
                user.setStatus(User.UserStatus.ACTIVE);
                user.setIntroduction(null); // 자기소개 초기화
                return userRepository.save(user);
            }
            
            // 기존 활성 사용자: 이메일만 업데이트
            // 닉네임과 프로필 이미지는 사용자가 직접 수정한 것을 유지
            user.setEmail(email);
            log.info("기존 사용자 로그인: userId={}, 기존 닉네임 유지={}", user.getId(), user.getNickname());
            return userRepository.save(user);
        } else {
            // 새 사용자 생성: OAuth2 제공자 정보 사용
            User newUser = User.builder()
                    .provider(provider)
                    .providerId(providerId)
                    .email(email)
                    .nickname(name)
                    .profileImage(picture)
                    .status(User.UserStatus.ACTIVE)
                    .build();
            
            log.info("신규 사용자 생성: email={}, nickname={}", email, name);
            return userRepository.save(newUser);
        }
    }
    
    /**
     * 개발용 간편 로그인 사용자 처리
     * - OAuth2 없이 이메일/닉네임만으로 로그인
     * - 개발 및 테스트 환경에서 사용
     * - AuthController.devLogin()에서 호출
     * - Google 네이티브 로그인에서도 사용 (임시)
     */
    public User processDevUser(String email, String nickname) {
        log.debug("개발용 사용자 처리: email={}, nickname={}", email, nickname);
        
        // 1단계: 개발용 제공자로 기존 사용자 확인 (이메일을 providerId로 사용)
        Optional<User> existingUser = userRepository.findByProviderAndProviderId("dev", email);
        
        if (existingUser.isPresent()) {
            User user = existingUser.get();
            
            // 탈퇴한 사용자가 재가입하는 경우
            if (user.getStatus() == User.UserStatus.DELETED) {
                log.info("탈퇴한 사용자 재가입: userId={}, 정보 재설정", user.getId());
                user.setNickname(nickname);
                user.setStatus(User.UserStatus.ACTIVE);
                user.setIntroduction(null);
                user.setProfileImage(null); // 프로필 이미지 초기화
                return userRepository.save(user);
            }
            
            // 기존 활성 사용자: 정보 유지 (닉네임 업데이트 안 함)
            log.info("기존 사용자 로그인: userId={}, 기존 정보 유지", user.getId());
            return user; // 저장하지 않고 그대로 반환
        } else {
            // 2-B단계: 새 개발용 사용자 생성
            User newUser = User.builder()
                    .provider("dev")            // 개발용 제공자
                    .providerId(email)          // 이메일을 고유 ID로 사용
                    .email(email)               // 이메일
                    .nickname(nickname)         // 닉네임
                    .status(User.UserStatus.ACTIVE)  // 활성 상태
                    .build();
            
            log.info("신규 개발용 사용자 생성: email={}, nickname={}", email, nickname);
            return userRepository.save(newUser);
        }
    }
}