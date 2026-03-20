package com.harmonynotes.harmonynotes.service;

import com.harmonynotes.harmonynotes.entity.OneDriveToken;
import com.harmonynotes.harmonynotes.mapper.OneDriveTokenMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Slf4j
@Service
public class OneDriveTokenService {
    
    @Autowired
    private OneDriveTokenMapper tokenMapper;
    
    /**
     * 保存令牌
     * @param token 令牌
     * @return 令牌
     */
    public OneDriveToken saveToken(OneDriveToken token) {
        tokenMapper.insert(token);
        log.info("保存OneDrive令牌成功，用户ID: {}", token.getUserId());
        return token;
    }
    
    /**
     * 获取用户的令牌
     * @param userId 用户ID
     * @return 令牌
     */
    public OneDriveToken getTokenByUserId(Long userId) {
        OneDriveToken token = tokenMapper.findByUserId(userId);
        if (token != null) {
            log.info("获取OneDrive令牌成功，用户ID: {}", userId);
        } else {
            log.warn("未找到OneDrive令牌，用户ID: {}", userId);
        }
        return token;
    }
    
    /**
     * 更新令牌
     * @param token 令牌
     * @return 令牌
     */
    public OneDriveToken updateToken(OneDriveToken token) {
        tokenMapper.update(token);
        log.info("更新OneDrive令牌成功，用户ID: {}", token.getUserId());
        return token;
    }
    
    /**
     * 删除用户的令牌
     * @param userId 用户ID
     */
    public void deleteTokenByUserId(Long userId) {
        tokenMapper.deleteByUserId(userId);
        log.info("删除OneDrive令牌成功，用户ID: {}", userId);
    }
    
    /**
     * 检查令牌是否过期
     * @param token 令牌
     * @return 是否过期
     */
    public boolean isTokenExpired(OneDriveToken token) {
        if (token == null || token.getExpiresAt() == null) {
            return true;
        }
        return LocalDateTime.now().isAfter(token.getExpiresAt());
    }
}
