package com.cataloging.userapi.config;

/**
 * HTTP 요청/응답 로깅 필터
 * - Flutter 클라이언트와의 통신 내역을 명확하게 기록
 * - 요청/응답 본문을 포함한 상세 로그 출력
 */

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
public class LoggingFilter implements Filter {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // 요청/응답 본문을 캐싱하기 위한 래퍼 사용
        ContentCachingRequestWrapper requestWrapper = new ContentCachingRequestWrapper(httpRequest);
        ContentCachingResponseWrapper responseWrapper = new ContentCachingResponseWrapper(httpResponse);

        long startTime = System.currentTimeMillis();

        // 구분선 출력
        log.info("================================================================================");

        // 요청 로깅
        logRequest(requestWrapper);

        // 실제 요청 처리
        chain.doFilter(requestWrapper, responseWrapper);

        // 응답 로깅
        long duration = System.currentTimeMillis() - startTime;
        logResponse(responseWrapper, duration);

        log.info("================================================================================\n");

        // 응답 본문을 실제로 클라이언트에 전송
        responseWrapper.copyBodyToResponse();
    }

    private void logRequest(ContentCachingRequestWrapper request) {
        String method = request.getMethod();
        String uri = request.getRequestURI();
        String queryString = request.getQueryString();

        log.info("📤 [CLIENT → USER-API] REQUEST");
        log.info("   Method: {}", method);
        log.info("   URL: {}", uri);
        
        if (queryString != null && !queryString.isEmpty()) {
            log.info("   Query: {}", queryString);
        }

        // 중요한 헤더만 로깅
        Map<String, String> importantHeaders = new HashMap<>();
        Enumeration<String> headerNames = request.getHeaderNames();
        while (headerNames.hasMoreElements()) {
            String headerName = headerNames.nextElement();
            String lowerHeaderName = headerName.toLowerCase();
            
            if (lowerHeaderName.equals("authorization")) {
                String authHeader = request.getHeader(headerName);
                // JWT 토큰의 앞부분만 표시
                if (authHeader != null && authHeader.startsWith("Bearer ")) {
                    String tokenPreview = authHeader.length() > 40 
                        ? authHeader.substring(0, 37) + "..." 
                        : authHeader;
                    importantHeaders.put("Authorization", tokenPreview);
                }
            } else if (lowerHeaderName.equals("content-type")) {
                importantHeaders.put("Content-Type", request.getHeader(headerName));
            }
        }

        if (!importantHeaders.isEmpty()) {
            try {
                log.info("   Headers: {}", objectMapper.writeValueAsString(importantHeaders));
            } catch (Exception e) {
                log.info("   Headers: {}", importantHeaders);
            }
        }

        // 요청 본문 로깅 (POST, PUT, PATCH만)
        if ("POST".equals(method) || "PUT".equals(method) || "PATCH".equals(method)) {
            byte[] content = request.getContentAsByteArray();
            if (content.length > 0) {
                String body = new String(content, StandardCharsets.UTF_8);
                try {
                    // JSON을 한 줄로 출력
                    Object json = objectMapper.readValue(body, Object.class);
                    String compactJson = objectMapper.writeValueAsString(json);
                    log.info("   {}", compactJson);
                } catch (Exception e) {
                    // JSON이 아닌 경우 그대로 출력
                    log.info("   {}", body);
                }
            }
        }
    }

    private void logResponse(ContentCachingResponseWrapper response, long duration) {
        int status = response.getStatus();

        log.info("📥 [USER-API → CLIENT] RESPONSE");
        log.info("   Status: {}", status);
        log.info("   Time: {}ms", duration);

        // 응답 본문 로깅
        byte[] content = response.getContentAsByteArray();
        if (content.length > 0) {
            String body = new String(content, StandardCharsets.UTF_8);
            try {
                // JSON을 한 줄로 출력
                Object json = objectMapper.readValue(body, Object.class);
                String compactJson = objectMapper.writeValueAsString(json);
                log.info("   {}", compactJson);
            } catch (Exception e) {
                // JSON이 아닌 경우 그대로 출력
                log.info("   {}", body);
            }
        }
    }
}
