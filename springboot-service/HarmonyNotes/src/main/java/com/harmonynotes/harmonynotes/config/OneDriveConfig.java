package com.harmonynotes.harmonynotes.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "onedrive")
public class OneDriveConfig {
    
    private String clientId = "e2c2ad83-515d-4a96-bd09-fc0d73ece400";
    
    private String authority = "https://login.microsoft.com/consumers";
    
    private String redirectUri = "harmonynote://oauth/callback";
    
    private String scopes = "Files.ReadWrite User.Read offline_access";
    
    private String graphApiUrl = "https://graph.microsoft.com/v1.0";
    
    private String basePath = "/iherefor_Notebook";
    
    private int requestTimeoutMs = 30000;
    
    private int maxRetryCount = 3;
    
    private int retryDelayMs = 1000;
}
