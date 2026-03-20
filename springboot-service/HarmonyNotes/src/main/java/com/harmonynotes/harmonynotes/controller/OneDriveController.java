package com.harmonynotes.harmonynotes.controller;

import com.harmonynotes.harmonynotes.dto.ApiResponse;
import com.harmonynotes.harmonynotes.dto.OneDriveTokenResponse;
import com.harmonynotes.harmonynotes.entity.OneDriveToken;
import com.harmonynotes.harmonynotes.service.OneDriveAPIService;
import com.harmonynotes.harmonynotes.service.OneDriveTokenService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v16/onedrive")
@CrossOrigin(origins = "*")
public class OneDriveController {
    
    @Autowired
    private OneDriveAPIService oneDriveAPIService;
    
    @Autowired
    private OneDriveTokenService tokenService;
    
    private static final SecureRandom random = new SecureRandom();
    
    private static final Map<String, String> codeVerifierCache = new java.util.concurrent.ConcurrentHashMap<>();
    
    /**
     * 生成授权URL
     * @param userId 用户ID
     * @return 授权URL
     */
    @GetMapping("/auth/url")
    public ApiResponse<Map<String, String>> generateAuthUrl(@RequestParam Long userId) {
        try {
            String codeVerifier = generateCodeVerifier();
            String codeChallenge = generateCodeChallenge(codeVerifier);
            String state = generateState(userId);
            
            String authUrl = oneDriveAPIService.generateAuthUrl(codeChallenge, state);
            
            codeVerifierCache.put(state, codeVerifier);
            
            Map<String, String> result = new HashMap<>();
            result.put("authUrl", authUrl);
            result.put("state", state);
            
            log.info("生成OneDrive授权URL成功，用户ID: {}", userId);
            return ApiResponse.success(result);
        } catch (Exception e) {
            log.error("生成OneDrive授权URL失败: {}", e.getMessage(), e);
            return ApiResponse.error("生成授权URL失败: " + e.getMessage());
        }
    }
    
    /**
     * 使用授权码交换访问令牌
     * @param code 授权码
     * @param state 状态参数
     * @param userId 用户ID
     * @return 令牌响应
     */
    @PostMapping("/auth/token")
    public ApiResponse<OneDriveTokenResponse> exchangeCodeForToken(
            @RequestParam String code,
            @RequestParam String state,
            @RequestParam Long userId) {
        try {
            String codeVerifier = extractCodeVerifier(state);
            if (codeVerifier == null) {
                log.error("无法从state中提取codeVerifier");
                return ApiResponse.error("无效的state参数");
            }
            
            OneDriveTokenResponse tokenResponse = oneDriveAPIService.exchangeCodeForToken(code, codeVerifier);
            
            OneDriveToken token = new OneDriveToken();
            token.setUserId(userId);
            token.setAccessToken(tokenResponse.getAccess_token());
            token.setRefreshToken(tokenResponse.getRefresh_token());
            token.setExpiresAt(LocalDateTime.now().plusSeconds(tokenResponse.getExpires_in()));
            
            tokenService.saveToken(token);
            
            log.info("交换OneDrive访问令牌成功，用户ID: {}", userId);
            return ApiResponse.success(tokenResponse);
        } catch (Exception e) {
            log.error("交换OneDrive访问令牌失败: {}", e.getMessage(), e);
            return ApiResponse.error("交换令牌失败: " + e.getMessage());
        }
    }
    
    /**
     * 刷新访问令牌
     * @param userId 用户ID
     * @return 令牌响应
     */
    @PostMapping("/auth/refresh")
    public ApiResponse<OneDriveTokenResponse> refreshToken(@RequestParam Long userId) {
        try {
            OneDriveToken token = tokenService.getTokenByUserId(userId);
            if (token == null) {
                log.error("未找到用户的OneDrive令牌，用户ID: {}", userId);
                return ApiResponse.error("未找到令牌");
            }
            
            OneDriveTokenResponse tokenResponse = oneDriveAPIService.refreshToken(token.getRefreshToken());
            
            token.setAccessToken(tokenResponse.getAccess_token());
            token.setRefreshToken(tokenResponse.getRefresh_token());
            token.setExpiresAt(LocalDateTime.now().plusSeconds(tokenResponse.getExpires_in()));
            
            tokenService.updateToken(token);
            
            log.info("刷新OneDrive访问令牌成功，用户ID: {}", userId);
            return ApiResponse.success(tokenResponse);
        } catch (Exception e) {
            log.error("刷新OneDrive访问令牌失败: {}", e.getMessage(), e);
            return ApiResponse.error("刷新令牌失败: " + e.getMessage());
        }
    }
    
    /**
     * 删除用户的令牌
     * @param userId 用户ID
     * @return 是否成功
     */
    @DeleteMapping("/auth/token")
    public ApiResponse<Void> deleteToken(@RequestParam Long userId) {
        try {
            tokenService.deleteTokenByUserId(userId);
            log.info("删除OneDrive令牌成功，用户ID: {}", userId);
            return ApiResponse.success(null);
        } catch (Exception e) {
            log.error("删除OneDrive令牌失败: {}", e.getMessage(), e);
            return ApiResponse.error("删除令牌失败: " + e.getMessage());
        }
    }
    
    /**
     * 生成随机字符串
     * @param length 长度
     * @return 随机字符串
     */
    private String generateRandomString(int length) {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
        StringBuilder result = new StringBuilder();
        for (int i = 0; i < length; i++) {
            result.append(chars.charAt(random.nextInt(chars.length())));
        }
        return result.toString();
    }
    
    /**
     * 生成代码验证器
     * @return 代码验证器
     */
    private String generateCodeVerifier() {
        return generateRandomString(128);
    }
    
    /**
     * 生成代码挑战
     * @param codeVerifier 代码验证器
     * @return 代码挑战
     */
    private String generateCodeChallenge(String codeVerifier) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(codeVerifier.getBytes());
            
            return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            log.error("生成代码挑战失败: {}", e.getMessage());
            throw new RuntimeException("生成代码挑战失败");
        }
    }
    
    /**
     * 生成状态参数
     * @param userId 用户ID
     * @return 状态参数
     */
    private String generateState(Long userId) {
        return userId + ":" + System.currentTimeMillis();
    }
    
    /**
     * 从state中提取codeVerifier
     * @param state 状态参数
     * @return codeVerifier
     */
    private String extractCodeVerifier(String state) {
        return codeVerifierCache.get(state);
    }
}
