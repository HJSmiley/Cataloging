package com.cataloging.userapi.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import com.cataloging.userapi.security.JwtTokenProvider;

/**
 * Catalog API 연동 서비스
 * - user-api에서 catalog-api로 HTTP 요청 전송
 * - 회원 탈퇴 시 catalog-api의 사용자 데이터 삭제
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CatalogApiService {
    
    private final RestTemplate restTemplate = new RestTemplate();
    private final JwtTokenProvider jwtTokenProvider;
    
    @Value("${catalog-api.url}")
    private String catalogApiUrl;
    
    /**
     * Catalog API에서 사용자 데이터 삭제
     * - 회원 탈퇴 시 호출
     * - JWT 토큰으로 인증하여 사용자의 모든 카탈로그 데이터 삭제
     */
    public void deleteUserData(Long userId) {
        try {
            // JWT 토큰 생성
            String token = jwtTokenProvider.createToken(userId.toString());
            
            // HTTP 헤더 설정
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + token);
            
            HttpEntity<Void> entity = new HttpEntity<>(headers);
            
            // Catalog API 호출
            String url = catalogApiUrl + "/api/users/me";
            log.info("Catalog API 사용자 데이터 삭제 요청: userId={}, url={}", userId, url);
            
            ResponseEntity<String> response = restTemplate.exchange(
                url,
                HttpMethod.DELETE,
                entity,
                String.class
            );
            
            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Catalog API 사용자 데이터 삭제 성공: userId={}", userId);
            } else {
                log.warn("Catalog API 사용자 데이터 삭제 실패: userId={}, status={}", 
                        userId, response.getStatusCode());
            }
            
        } catch (Exception e) {
            // Catalog API 호출 실패 시 로그만 남기고 계속 진행
            // user-api의 회원 탈퇴는 성공시킴
            log.error("Catalog API 호출 실패: userId={}, error={}", userId, e.getMessage(), e);
        }
    }
}
