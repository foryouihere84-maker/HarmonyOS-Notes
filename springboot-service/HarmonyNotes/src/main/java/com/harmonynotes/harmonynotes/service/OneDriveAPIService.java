package com.harmonynotes.harmonynotes.service;

import com.harmonynotes.harmonynotes.config.OneDriveConfig;
import com.harmonynotes.harmonynotes.dto.OneDriveTokenResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
public class OneDriveAPIService {
    
    @Autowired
    private OneDriveConfig oneDriveConfig;
    
    @Autowired
    private RestTemplate restTemplate;
    
    private static final String AUTHORIZATION_URL_TEMPLATE = "%s/oauth2/v2.0/authorize";
    private static final String TOKEN_URL = "%s/oauth2/v2.0/token";
    private static final String DRIVE_ROOT_URL = "%s/me/drive/root";
    private static final String DRIVE_CHILDREN_URL = "%s/me/drive/root/children";
    private static final String DRIVE_ITEM_URL = "%s/me/drive/items/%s";
    private static final String DRIVE_ITEM_CONTENT_URL = "%s/me/drive/items/%s/content";
    private static final String CREATE_FOLDER_URL = "%s/me/drive/root/children";
    
    /**
     * 生成授权URL
     * @param codeChallenge PKCE代码挑战
     * @param state 状态参数
     * @return 授权URL
     */
    public String generateAuthUrl(String codeChallenge, String state) {
        String authUrl = String.format(AUTHORIZATION_URL_TEMPLATE, oneDriveConfig.getAuthority());
        
        StringBuilder queryString = new StringBuilder();
        queryString.append("client_id=").append(urlEncode(oneDriveConfig.getClientId()));
        queryString.append("&response_type=").append(urlEncode("code"));
        queryString.append("&redirect_uri=").append(urlEncode(oneDriveConfig.getRedirectUri()));
        queryString.append("&scope=").append(urlEncode(oneDriveConfig.getScopes()));
        queryString.append("&state=").append(urlEncode(state));
        queryString.append("&code_challenge=").append(urlEncode(codeChallenge));
        queryString.append("&code_challenge_method=").append(urlEncode("S256"));
        
        log.info("生成OneDrive授权URL: {}", authUrl + "?" + queryString);
        return authUrl + "?" + queryString;
    }
    
    /**
     * 使用授权码交换访问令牌
     * @param code 授权码
     * @param codeVerifier PKCE代码验证器
     * @return 令牌响应
     */
    public OneDriveTokenResponse exchangeCodeForToken(String code, String codeVerifier) {
        String tokenUrl = String.format(TOKEN_URL, oneDriveConfig.getAuthority());
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        
        StringBuilder requestBody = new StringBuilder();
        requestBody.append("client_id=").append(urlEncode(oneDriveConfig.getClientId()));
        requestBody.append("&code=").append(urlEncode(code));
        requestBody.append("&redirect_uri=").append(urlEncode(oneDriveConfig.getRedirectUri()));
        requestBody.append("&grant_type=").append(urlEncode("authorization_code"));
        requestBody.append("&code_verifier=").append(urlEncode(codeVerifier));
        requestBody.append("&scope=").append(urlEncode(oneDriveConfig.getScopes()));
        
        HttpEntity<String> request = new HttpEntity<>(requestBody.toString(), headers);
        
        log.info("使用授权码交换访问令牌");
        
        ResponseEntity<OneDriveTokenResponse> response = restTemplate.postForEntity(
            tokenUrl,
            request,
            OneDriveTokenResponse.class
        );
        
        if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
            log.info("交换访问令牌成功");
            return response.getBody();
        } else {
            log.error("交换访问令牌失败: {}", response.getStatusCode());
            throw new RuntimeException("交换访问令牌失败");
        }
    }
    
    /**
     * 刷新访问令牌
     * @param refreshToken 刷新令牌
     * @return 令牌响应
     */
    public OneDriveTokenResponse refreshToken(String refreshToken) {
        String tokenUrl = String.format(TOKEN_URL, oneDriveConfig.getAuthority());
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        
        StringBuilder requestBody = new StringBuilder();
        requestBody.append("client_id=").append(urlEncode(oneDriveConfig.getClientId()));
        requestBody.append("&refresh_token=").append(urlEncode(refreshToken));
        requestBody.append("&grant_type=").append(urlEncode("refresh_token"));
        requestBody.append("&scope=").append(urlEncode(oneDriveConfig.getScopes()));
        
        HttpEntity<String> request = new HttpEntity<>(requestBody.toString(), headers);
        
        log.info("刷新访问令牌");
        
        ResponseEntity<OneDriveTokenResponse> response = restTemplate.postForEntity(
            tokenUrl,
            request,
            OneDriveTokenResponse.class
        );
        
        if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
            log.info("刷新访问令牌成功");
            return response.getBody();
        } else {
            log.error("刷新访问令牌失败: {}", response.getStatusCode());
            throw new RuntimeException("刷新访问令牌失败");
        }
    }
    
    /**
     * 检查文件夹是否存在
     * @param accessToken 访问令牌
     * @param folderPath 文件夹路径
     * @return 是否存在
     */
    public boolean checkFolderExists(String accessToken, String folderPath) {
        try {
            String url = String.format(DRIVE_ROOT_URL, oneDriveConfig.getGraphApiUrl()) + ":/" + folderPath;
            
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            
            HttpEntity<Void> request = new HttpEntity<>(headers);
            
            ResponseEntity<String> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                request,
                String.class
            );
            
            return response.getStatusCode() == HttpStatus.OK;
        } catch (Exception e) {
            log.warn("检查文件夹存在性失败: {}", e.getMessage());
            return false;
        }
    }
    
    /**
     * 创建文件夹
     * @param accessToken 访问令牌
     * @param folderPath 文件夹路径
     * @return 是否成功
     */
    public boolean createFolder(String accessToken, String folderPath) {
        try {
            String[] pathParts = folderPath.split("/");
            String currentPath = "";
            
            for (String folderName : pathParts) {
                if (folderName.isEmpty()) {
                    continue;
                }
                
                currentPath = currentPath.isEmpty() ? folderName : currentPath + "/" + folderName;
                
                if (!checkFolderExists(accessToken, currentPath)) {
                    String url = String.format(DRIVE_CHILDREN_URL, oneDriveConfig.getGraphApiUrl());
                    
                    HttpHeaders headers = new HttpHeaders();
                    headers.setBearerAuth(accessToken);
                    headers.setContentType(MediaType.APPLICATION_JSON);
                    
                    Map<String, Object> folderData = new HashMap<>();
                    folderData.put("name", folderName);
                    folderData.put("folder", new HashMap<>());
                    folderData.put("@microsoft.graph.conflictBehavior", "rename");
                    
                    HttpEntity<Map<String, Object>> request = new HttpEntity<>(folderData, headers);
                    
                    ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);
                    
                    if (response.getStatusCode() == HttpStatus.CREATED) {
                        log.info("创建文件夹成功: {}", currentPath);
                    } else {
                        log.warn("创建文件夹失败: {}, 状态码: {}", currentPath, response.getStatusCode());
                    }
                }
            }
            
            return true;
        } catch (Exception e) {
            log.error("创建文件夹失败: {}", e.getMessage(), e);
            return false;
        }
    }
    
    /**
     * 上传文件内容
     * @param accessToken 访问令牌
     * @param filePath 文件路径
     * @param content 文件内容
     * @return 是否成功
     */
    public boolean uploadFile(String accessToken, String filePath, String content) {
        try {
            String normalizedPath = filePath.replace("^/+", "");
            String url = String.format(DRIVE_ROOT_URL, oneDriveConfig.getGraphApiUrl()) + ":/" + normalizedPath + ":/content";
            
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            HttpEntity<String> request = new HttpEntity<>(content, headers);
            
            ResponseEntity<String> response = restTemplate.exchange(
                url,
                HttpMethod.PUT,
                request,
                String.class
            );
            
            if (response.getStatusCode() == HttpStatus.OK || response.getStatusCode() == HttpStatus.CREATED) {
                log.info("上传文件成功: {}", filePath);
                return true;
            } else {
                log.error("上传文件失败: {}, 状态码: {}", filePath, response.getStatusCode());
                return false;
            }
        } catch (Exception e) {
            log.error("上传文件异常: {}", e.getMessage(), e);
            return false;
        }
    }
    
    /**
     * 删除文件
     * @param accessToken 访问令牌
     * @param filePath 文件路径
     * @return 是否成功
     */
    public boolean deleteFile(String accessToken, String filePath) {
        try {
            String normalizedPath = filePath.replace("^/+", "");
            String url = String.format(DRIVE_ROOT_URL, oneDriveConfig.getGraphApiUrl()) + ":/" + normalizedPath;
            
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            
            HttpEntity<Void> request = new HttpEntity<>(headers);
            
            ResponseEntity<String> response = restTemplate.exchange(
                url,
                HttpMethod.DELETE,
                request,
                String.class
            );
            
            if (response.getStatusCode() == HttpStatus.NO_CONTENT) {
                log.info("删除文件成功: {}", filePath);
                return true;
            } else {
                log.error("删除文件失败: {}, 状态码: {}", filePath, response.getStatusCode());
                return false;
            }
        } catch (Exception e) {
            log.error("删除文件异常: {}", e.getMessage(), e);
            return false;
        }
    }
    
    /**
     * URL编码
     * @param value 待编码值
     * @return 编码后的值
     */
    private String urlEncode(String value) {
        try {
            return java.net.URLEncoder.encode(value, "UTF-8");
        } catch (Exception e) {
            log.error("URL编码失败: {}", e.getMessage());
            return value;
        }
    }
}
