package com.cataloging.userapi.service;

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

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class UserService {
    
    private final UserRepository userRepository;
    
    public User processOAuth2User(String provider, OAuth2User oAuth2User) {
        Map<String, Object> attributes = oAuth2User.getAttributes();
        
        String providerId;
        String email;
        String nickname;
        String profileImage = null;
        
        // Provider별 사용자 정보 추출
        switch (provider.toLowerCase()) {
            case "google":
                providerId = (String) attributes.get("sub");
                email = (String) attributes.get("email");
                nickname = (String) attributes.get("name");
                profileImage = (String) attributes.get("picture");
                break;
                
            case "naver":
                @SuppressWarnings("unchecked")
                Map<String, Object> response = (Map<String, Object>) attributes.get("response");
                providerId = (String) response.get("id");
                email = (String) response.get("email");
                nickname = (String) response.get("name");
                profileImage = (String) response.get("profile_image");
                break;
                
            default:
                throw new IllegalArgumentException("지원하지 않는 OAuth2 제공자입니다: " + provider);
        }
        
        log.debug("OAuth2 사용자 정보 추출: provider={}, providerId={}, email={}, nickname={}", 
                 provider, providerId, email, nickname);
        
        // 기존 사용자 확인
        Optional<User> existingUser = userRepository.findByProviderAndProviderId(provider, providerId);
        
        if (existingUser.isPresent()) {
            // 기존 사용자 정보 업데이트
            User user = existingUser.get();
            user.setEmail(email);
            user.setNickname(nickname);
            if (profileImage != null) {
                user.setProfileImage(profileImage);
            }
            return userRepository.save(user);
        } else {
            // 새 사용자 생성
            User newUser = User.builder()
                    .provider(provider)
                    .providerId(providerId)
                    .email(email)
                    .nickname(nickname)
                    .profileImage(profileImage)
                    .status(User.UserStatus.ACTIVE)
                    .build();
            
            return userRepository.save(newUser);
        }
    }
    
    @Transactional(readOnly = true)
    public User getUserById(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));
    }
    
    public User updateUser(Long userId, UserDto.UpdateRequest updateRequest) {
        User user = getUserById(userId);
        
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
    
    public void deleteUser(Long userId) {
        User user = getUserById(userId);
        user.setStatus(User.UserStatus.DELETED);
        userRepository.save(user);
    }
    
    public User processDevUser(String email, String nickname) {
        log.debug("개발용 사용자 처리: email={}, nickname={}", email, nickname);
        
        // 이메일로 기존 사용자 확인
        Optional<User> existingUser = userRepository.findByProviderAndProviderId("dev", email);
        
        if (existingUser.isPresent()) {
            // 기존 사용자 정보 업데이트
            User user = existingUser.get();
            user.setNickname(nickname);
            return userRepository.save(user);
        } else {
            // 새 사용자 생성
            User newUser = User.builder()
                    .provider("dev")
                    .providerId(email)
                    .email(email)
                    .nickname(nickname)
                    .status(User.UserStatus.ACTIVE)
                    .build();
            
            return userRepository.save(newUser);
        }
    }
}