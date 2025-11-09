package com.cataloging.userapi;

/**
 * User-API Spring Boot 애플리케이션 메인 클래스
 * - 사용자 인증 및 프로필 관리 API 서버
 * - Flutter 앱의 인증 요청을 처리
 * - JWT 토큰 기반 인증 시스템
 * - 포트 8080에서 실행 (Catalog-API는 8000)
 */

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication  // Spring Boot 자동 설정 활성화
public class UserApiApplication {

    /**
     * 애플리케이션 진입점
     * - Spring Boot 컨테이너 시작
     * - 자동 설정으로 다음 컴포넌트들 초기화:
     *   * Spring Security (JWT + OAuth2)
     *   * JPA/Hibernate (H2 데이터베이스)
     *   * 웹 MVC (REST 컨트롤러들)
     *   * 의존성 주입 컨테이너
     */
    public static void main(String[] args) {
        SpringApplication.run(UserApiApplication.class, args);
    }

}