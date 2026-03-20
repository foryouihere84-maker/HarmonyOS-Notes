-- ========================================
-- OneDrive 令牌表 (onedrive_token)
-- ========================================
CREATE TABLE IF NOT EXISTS onedrive_token (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '令牌ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    access_token TEXT NOT NULL COMMENT '访问令牌',
    refresh_token TEXT NOT NULL COMMENT '刷新令牌',
    expires_at DATETIME NOT NULL COMMENT '过期时间',
    created_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OneDrive令牌表';
