package com.cataloging.userapi.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

/**
 * OAuth2 클라이언트 설정
 * application.yml의 oauth2 설정을 읽어옴
 */
@Data
@Component
@ConfigurationProperties(prefix = "oauth2")
public class OAuth2Properties {
    
    private Map<String, Client> client = new HashMap<>();
    
    @Data
    public static class Client {
        private String clientId;
        private String clientSecret;
        private String redirectUri;
        private String authorizationUri;
        private String tokenUri;
        private String userInfoUri;
        private String scope;
    }
}
