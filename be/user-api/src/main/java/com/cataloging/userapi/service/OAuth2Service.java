package com.cataloging.userapi.service;

import com.cataloging.userapi.config.OAuth2Properties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;

/**
 * OAuth2 인증 서비스
 * - Google, Naver OAuth2 인증 URL 생성
 * - Authorization Code → Access Token 교환
 * - Access Token → 사용자 정보 조회
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OAuth2Service {
    
    private final OAuth2Properties oauth2Properties;
    private final WebClient.Builder webClientBuilder;
    
    /**
     * OAuth2 인증 URL 생성
     * @param provider google 또는 naver
     * @return 인증 URL과 state
     */
    public Map<String, String> getAuthorizationUrl(String provider) {
        OAuth2Properties.Client client = oauth2Properties.getClient().get(provider);
        
        if (client == null) {
            throw new IllegalArgumentException("지원하지 않는 OAuth2 제공자: " + provider);
        }
        
        // CSRF 방지용 state 생성
        String state = UUID.randomUUID().toString();
        
        // 인증 URL 생성
        String authUrl = client.getAuthorizationUri() +
                "?client_id=" + client.getClientId() +
                "&redirect_uri=" + URLEncoder.encode(client.getRedirectUri(), StandardCharsets.UTF_8) +
                "&response_type=code" +
                "&scope=" + URLEncoder.encode(client.getScope(), StandardCharsets.UTF_8) +
                "&state=" + state;
        
        log.info("{} OAuth2 인증 URL 생성: state={}", provider, state);
        
        return Map.of(
            "authUrl", authUrl,
            "state", state
        );
    }
    
    /**
     * OAuth2 인증 URL 생성 (동적 Base URL)
     * @param provider google 또는 naver
     * @param baseUrl 플랫폼별 Base URL (예: http://10.0.2.2:8080 또는 http://localhost:8080)
     * @return 인증 URL과 state
     */
    public Map<String, String> getAuthorizationUrl(String provider, String baseUrl) {
        OAuth2Properties.Client client = oauth2Properties.getClient().get(provider);
        
        if (client == null) {
            throw new IllegalArgumentException("지원하지 않는 OAuth2 제공자: " + provider);
        }
        
        // CSRF 방지용 state 생성
        String state = UUID.randomUUID().toString();
        
        // 동적 Redirect URI 생성
        String redirectUri = baseUrl + "/api/auth/oauth2/" + provider + "/callback";
        
        // 인증 URL 생성
        String authUrl = client.getAuthorizationUri() +
                "?client_id=" + client.getClientId() +
                "&redirect_uri=" + URLEncoder.encode(redirectUri, StandardCharsets.UTF_8) +
                "&response_type=code" +
                "&scope=" + URLEncoder.encode(client.getScope(), StandardCharsets.UTF_8) +
                "&state=" + state;
        
        log.info("{} OAuth2 인증 URL 생성: state={}, redirectUri={}", provider, state, redirectUri);
        
        return Map.of(
            "authUrl", authUrl,
            "state", state
        );
    }
    
    /**
     * Authorization Code를 Access Token으로 교환
     * @param provider google 또는 naver
     * @param code Authorization Code
     * @return Access Token
     */
    public String exchangeCodeForToken(String provider, String code) {
        OAuth2Properties.Client client = oauth2Properties.getClient().get(provider);
        
        if (client == null) {
            throw new IllegalArgumentException("지원하지 않는 OAuth2 제공자: " + provider);
        }
        
        log.info("{} Authorization Code를 Access Token으로 교환 시작", provider);
        
        try {
            WebClient webClient = webClientBuilder.build();
            
            Map<String, Object> response = webClient.post()
                    .uri(client.getTokenUri())
                    .header("Content-Type", "application/x-www-form-urlencoded")
                    .bodyValue(
                        "grant_type=authorization_code" +
                        "&code=" + code +
                        "&client_id=" + client.getClientId() +
                        "&client_secret=" + client.getClientSecret() +
                        "&redirect_uri=" + URLEncoder.encode(client.getRedirectUri(), StandardCharsets.UTF_8)
                    )
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            String accessToken = (String) response.get("access_token");
            log.info("{} Access Token 발급 성공", provider);
            
            return accessToken;
            
        } catch (Exception e) {
            log.error("{} Access Token 발급 실패", provider, e);
            throw new RuntimeException("Access Token 발급 실패: " + e.getMessage());
        }
    }
    
    /**
     * Access Token으로 사용자 정보 조회
     * @param provider google 또는 naver
     * @param accessToken Access Token
     * @return 사용자 정보
     */
    public Map<String, Object> getUserInfo(String provider, String accessToken) {
        OAuth2Properties.Client client = oauth2Properties.getClient().get(provider);
        
        if (client == null) {
            throw new IllegalArgumentException("지원하지 않는 OAuth2 제공자: " + provider);
        }
        
        log.info("{} 사용자 정보 조회 시작", provider);
        
        try {
            WebClient webClient = webClientBuilder.build();
            
            Map<String, Object> response = webClient.get()
                    .uri(client.getUserInfoUri())
                    .header("Authorization", "Bearer " + accessToken)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            log.info("{} 사용자 정보 조회 성공", provider);
            
            return response;
            
        } catch (Exception e) {
            log.error("{} 사용자 정보 조회 실패", provider, e);
            throw new RuntimeException("사용자 정보 조회 실패: " + e.getMessage());
        }
    }
    
    /**
     * 사용자 정보에서 표준 필드 추출
     * @param provider google 또는 naver
     * @param userInfo 원본 사용자 정보
     * @return 표준화된 사용자 정보
     */
    public Map<String, String> extractUserInfo(String provider, Map<String, Object> userInfo) {
        if ("google".equals(provider)) {
            return Map.of(
                "providerId", (String) userInfo.get("id"),
                "email", (String) userInfo.get("email"),
                "name", (String) userInfo.get("name"),
                "picture", userInfo.getOrDefault("picture", "").toString()
            );
        } else if ("naver".equals(provider)) {
            // Naver는 response 객체 안에 사용자 정보가 있음
            Map<String, Object> response = (Map<String, Object>) userInfo.get("response");
            
            // Naver는 'name' 대신 'nickname' 사용
            String name = (String) response.get("name");
            if (name == null || name.isEmpty()) {
                name = (String) response.get("nickname");
            }
            
            return Map.of(
                "providerId", (String) response.get("id"),
                "email", (String) response.get("email"),
                "name", name != null ? name : "",
                "picture", response.getOrDefault("profile_image", "").toString()
            );
        }
        
        throw new IllegalArgumentException("지원하지 않는 OAuth2 제공자: " + provider);
    }
}
