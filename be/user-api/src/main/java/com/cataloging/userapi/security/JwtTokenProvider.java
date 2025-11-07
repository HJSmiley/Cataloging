package com.cataloging.userapi.security;

/**
 * JWT 토큰 생성 및 검증 컴포넌트
 * - 사용자 인증 후 JWT 액세스 토큰 발급
 * - catalog-api와 동일한 시크릿 키 사용하여 호환성 보장
 * - HMAC SHA-256 알고리즘으로 토큰 서명
 * - 24시간 유효기간 설정
 */

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Slf4j                  // 로깅 기능 자동 생성
@Component              // Spring 컴포넌트로 등록
public class JwtTokenProvider {
    
    // JWT 서명용 시크릿 키 (catalog-api와 동일해야 함)
    private final SecretKey key;
    // 토큰 유효기간 (밀리초 단위)
    private final long tokenValidityInMilliseconds;
    
    /**
     * JWT 토큰 제공자 생성자
     * - application.yml에서 JWT 설정값 주입
     * - catalog-api와 동일한 시크릿 키 사용 필수
     */
    public JwtTokenProvider(@Value("${jwt.secret}") String secret,
                           @Value("${jwt.expiration}") long tokenValidityInMilliseconds) {
        // 시크릿 키를 HMAC SHA-256용 SecretKey로 변환
        this.key = Keys.hmacShaKeyFor(secret.getBytes());
        this.tokenValidityInMilliseconds = tokenValidityInMilliseconds;
    }
    
    /**
     * JWT 액세스 토큰 생성
     * - 로그인 성공 시 호출되어 토큰 발급
     * - catalog-api에서 동일한 시크릿 키로 검증 가능
     * - Flutter에서 Authorization 헤더에 포함하여 API 호출
     */
    public String createToken(String userId) {
        Date now = new Date();                                              // 현재 시간
        Date validity = new Date(now.getTime() + tokenValidityInMilliseconds);  // 만료 시간
        
        return Jwts.builder()
                .setSubject(userId)                         // 사용자 ID (sub 클레임)
                .setIssuedAt(now)                          // 발급 시간 (iat 클레임)
                .setExpiration(validity)                   // 만료 시간 (exp 클레임)
                .signWith(key, SignatureAlgorithm.HS256)   // HMAC SHA-256으로 서명
                .compact();                                // JWT 문자열로 변환
    }
    
    /**
     * JWT 토큰에서 사용자 ID 추출
     * - 토큰의 sub 클레임에서 사용자 ID 반환
     * - Spring Security 인증 필터에서 사용
     */
    public String getUserId(String token) {
        return Jwts.parser()
                .verifyWith(key)                    // 시크릿 키로 서명 검증
                .build()
                .parseSignedClaims(token)           // 토큰 파싱
                .getPayload()                       // 페이로드 추출
                .getSubject();                      // sub 클레임 (사용자 ID) 반환
    }
    
    /**
     * JWT 토큰 유효성 검증
     * - 서명, 만료시간, 형식 등 종합 검증
     * - Spring Security 필터에서 인증 전 호출
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                .verifyWith(key)                    // 시크릿 키로 서명 검증
                .build()
                .parseSignedClaims(token);          // 토큰 파싱 (예외 발생 시 유효하지 않음)
            return true;                            // 파싱 성공 시 유효한 토큰
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Invalid JWT token: {}", e.getMessage());
            return false;                           // 파싱 실패 시 유효하지 않은 토큰
        }
    }
    
    /**
     * 토큰 유효기간 반환 (밀리초)
     * - 클라이언트에서 토큰 만료 시간 계산용
     */
    public long getTokenValidityInMilliseconds() {
        return tokenValidityInMilliseconds;
    }
}