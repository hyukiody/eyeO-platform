-- Drop existing tables if they exist (development only)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS security_audit_logs;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;
SET FOREIGN_KEY_CHECKS = 1;

-- ========================================
-- 1. ROLES TABLE (Fixed Enum)
-- ========================================
-- Matches JPA entity com.teraapi.identity.entity.Role

CREATE TABLE roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE INDEX idx_roles_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed the 3 fixed roles expected by the service
INSERT INTO roles (name, description, is_active) VALUES 
    ('ADMIN', 'System administrators with full access', TRUE),
    ('USER', 'Regular users with client-side decryption capability', TRUE),
    ('DEVICE', 'Edge devices (cameras and processing nodes)', TRUE);

-- ========================================
-- 2. USERS TABLE (Identities: Humans + Machines)
-- ========================================
-- Matches JPA entity com.teraapi.identity.entity.User

CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000),
    role_id BIGINT NOT NULL,
    UNIQUE INDEX idx_users_username (username),
    UNIQUE INDEX idx_users_email (email),
    INDEX idx_users_role (role_id),
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed default admin user (password: admin123 - change in production)
INSERT INTO users (username, password, email, role_id)
VALUES (
    'admin',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    'admin@eyeo-platform.local',
    (SELECT id FROM roles WHERE name = 'ADMIN')
);

-- ========================================
-- 3. SECURITY AUDIT LOG TABLE
-- ========================================
-- Matches JPA entity com.teraapi.identity.entity.SecurityAuditLog

CREATE TABLE security_audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    eventType VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    username VARCHAR(100),
    ipAddress VARCHAR(45) NOT NULL,
    userAgent VARCHAR(500),
    `timestamp` DATETIME NOT NULL,
    success BOOLEAN NOT NULL,
    message VARCHAR(1000),
    metadata TEXT,
    sessionId VARCHAR(100),
    resource VARCHAR(200),
    httpMethod VARCHAR(10),
    statusCode INT,
    INDEX idx_event_type (eventType),
    INDEX idx_username (username),
    INDEX idx_timestamp (`timestamp`),
    INDEX idx_severity (severity),
    INDEX idx_ip_address (ipAddress)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
