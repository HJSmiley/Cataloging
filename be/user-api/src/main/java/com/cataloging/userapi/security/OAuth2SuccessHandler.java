package com.cataloging.userapi.security;

import com.cataloging.userapi.entity.User;
import com.cataloging.userapi.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class OAuth2SuccessHandler extends SimpleUrlAuthenticationSuccessHandler {
    
    private final UserService userService;
    private final JwtTokenProvider jwtTokenProvider;
    private final ObjectMapper objectMapper;
    
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, 
                                      HttpServletResponse response, 
                                      Authentication authentication) throws IOException, ServletException {
        
        OAuth2User oAuth2User = (OAuth2User) authentication.getPrincipal();
        String registrationId = getRegistrationId(request);
        
        log.debug("OAuth2 로그인 성공: provider={}, attributes={}", registrationId, oAuth2User.getAttributes());
        
        try {
            // 사용자 정보 추출 및 저장/업데이트
            User user = userService.processOAuth2User(registrationId, oAuth2User);
            
            // JWT 토큰 생성
            String accessToken = jwtTokenProvider.createToken(user.getId().toString());
            
            // 응답 데이터 구성
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("success", true);
            responseData.put("accessToken", accessToken);
            responseData.put("tokenType", "Bearer");
            responseData.put("expiresIn", jwtTokenProvider.getTokenValidityInMilliseconds() / 1000);
            responseData.put("user", Map.of(
                "id", user.getId(),
                "email", user.getEmail(),
                "nickname", user.getNickname(),
                "profileImage", user.getProfileImage() != null ? user.getProfileImage() : ""
            ));
            
            // JSON 응답
            response.setContentType("application/json;charset=UTF-8");
            response.setStatus(HttpServletResponse.SC_OK);
            response.getWriter().write(objectMapper.writeValueAsString(responseData));
            
        } catch (Exception e) {
            log.error("OAuth2 로그인 처리 중 오류 발생", e);
            
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "로그인 처리 중 오류가 발생했습니다.");
            
            response.setContentType("application/json;charset=UTF-8");
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
        }
    }
    
    private String getRegistrationId(HttpServletRequest request) {
        String requestURI = request.getRequestURI();
        // /login/oauth2/code/{registrationId} 형태에서 registrationId 추출
        String[] parts = requestURI.split("/");
        return parts[parts.length - 1];
    }
}