-- ========================================
-- 用户登录注册系统数据库设计
-- 适用于SpringBoot + MySQL
-- ========================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS harmonynotes DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE harmonynotes;

-- ========================================
-- 1. 用户表 (users)
-- ========================================
CREATE TABLE IF NOT EXISTS users (
                                     id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户ID',
                                     username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    email VARCHAR(100) NOT NULL UNIQUE COMMENT '邮箱',
    password VARCHAR(255) NOT NULL COMMENT '密码（BCrypt加密）',
    display_name VARCHAR(100) DEFAULT NULL COMMENT '显示名称',
    avatar_url VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
    status TINYINT DEFAULT 1 COMMENT '状态：1-正常，0-禁用',
    last_login_time DATETIME DEFAULT NULL COMMENT '最后登录时间',
    last_login_ip VARCHAR(50) DEFAULT NULL COMMENT '最后登录IP',
    created_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_created_time (created_time)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ========================================
-- 2. 角色表 (roles)
-- ========================================
CREATE TABLE IF NOT EXISTS roles (
                                     id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '角色ID',
                                     role_name VARCHAR(50) NOT NULL UNIQUE COMMENT '角色名称',
    role_code VARCHAR(50) NOT NULL UNIQUE COMMENT '角色编码',
    description VARCHAR(200) DEFAULT NULL COMMENT '角色描述',
    created_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_role_code (role_code)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色表';

-- ========================================
-- 3. 用户角色关联表 (user_roles)
-- ========================================
CREATE TABLE IF NOT EXISTS user_roles (
                                          id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '关联ID',
                                          user_id BIGINT NOT NULL COMMENT '用户ID',
                                          role_id BIGINT NOT NULL COMMENT '角色ID',
                                          created_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
                                          UNIQUE KEY uk_user_role (user_id, role_id),
    INDEX idx_user_id (user_id),
    INDEX idx_role_id (role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户角色关联表';

-- ========================================
-- 4. 登录日志表 (login_logs)
-- ========================================
CREATE TABLE IF NOT EXISTS login_logs (
                                          id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '日志ID',
                                          user_id BIGINT DEFAULT NULL COMMENT '用户ID（未登录时为NULL）',
                                          username VARCHAR(50) DEFAULT NULL COMMENT '用户名',
    login_type VARCHAR(20) NOT NULL COMMENT '登录类型：password-密码登录，register-注册',
    login_ip VARCHAR(50) DEFAULT NULL COMMENT '登录IP',
    user_agent VARCHAR(500) DEFAULT NULL COMMENT '用户代理',
    status TINYINT NOT NULL COMMENT '状态：1-成功，0-失败',
    error_message VARCHAR(500) DEFAULT NULL COMMENT '错误信息',
    created_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '登录时间',
    INDEX idx_user_id (user_id),
    INDEX idx_username (username),
    INDEX idx_login_type (login_type),
    INDEX idx_status (status),
    INDEX idx_created_time (created_time),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='登录日志表';

-- ========================================
-- 5. 密码重置表 (password_resets)
-- ========================================
CREATE TABLE IF NOT EXISTS password_resets (
                                               id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '重置ID',
                                               user_id BIGINT NOT NULL COMMENT '用户ID',
                                               token VARCHAR(255) NOT NULL UNIQUE COMMENT '重置令牌',
    expires_at DATETIME NOT NULL COMMENT '过期时间',
    used TINYINT DEFAULT 0 COMMENT '是否已使用：1-已使用，0-未使用',
    created_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_id (user_id),
    INDEX idx_token (token),
    INDEX idx_expires_at (expires_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='密码重置表';

-- ========================================
-- 插入初始角色数据
-- ========================================
INSERT INTO roles (role_name, role_code, description) VALUES
                                                          ('普通用户', 'USER', '普通用户，可以创建和编辑笔记'),
                                                          ('管理员', 'ADMIN', '管理员，拥有所有权限')
    ON DUPLICATE KEY UPDATE role_name=VALUES(role_name);

-- ========================================
-- 插入测试用户数据
-- ========================================
-- 密码：123456 (BCrypt加密后的值)
INSERT INTO users (username, email, password, display_name, status) VALUES
    ('testuser', 'test@example.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EHsM8lE9lBOsl7', '测试用户', 1)
    ON DUPLICATE KEY UPDATE username=VALUES(username);

-- 为测试用户分配普通用户角色
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u, roles r
WHERE u.username = 'testuser' AND r.role_code = 'USER'
    ON DUPLICATE KEY UPDATE user_id=VALUES(user_id);