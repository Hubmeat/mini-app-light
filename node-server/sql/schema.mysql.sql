-- 光屿 server 数据表（阿里云 RDS MySQL 8.0）
-- 用法：先在「数据库管理」建库（如 guangyu，字符集 utf8mb4），
-- 再「登录数据库」选中该库执行本文件。

-- 用户表：一个用户对应一种登录方式（微信 openid 或 手机号）
CREATE TABLE IF NOT EXISTS users (
  id          CHAR(36)     NOT NULL,
  login_type  VARCHAR(16)  NOT NULL,            -- 'wechat' | 'phone'
  openid        VARCHAR(64)  DEFAULT NULL,      -- 微信登录
  phone         VARCHAR(20)  DEFAULT NULL,      -- 手机号登录
  password_hash VARCHAR(255) DEFAULT NULL,      -- 手机号+密码登录：scrypt 哈希（salt:hash）
  nickname      VARCHAR(64)  DEFAULT '光屿用户',
  used_count  INT          NOT NULL DEFAULT 0,  -- 已用次数
  quota_limit INT          NOT NULL DEFAULT 20, -- 可用次数上限（免费额度 + 已购）
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_openid (openid),
  UNIQUE KEY uk_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 短信验证码表（按手机号覆盖；也可换用 Redis）
CREATE TABLE IF NOT EXISTS sms_codes (
  phone      VARCHAR(20) NOT NULL,
  code       VARCHAR(10) NOT NULL,
  expires_at DATETIME    NOT NULL,
  PRIMARY KEY (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 订单表
CREATE TABLE IF NOT EXISTS orders (
  id         CHAR(36)    NOT NULL,
  user_id    CHAR(36)    NOT NULL,
  plan_id    VARCHAR(32) NOT NULL,
  amount     INT         NOT NULL,             -- 金额（分）
  quota      INT         NOT NULL,             -- 该订单发放的次数
  status     VARCHAR(16) NOT NULL DEFAULT 'pending', -- pending | paid | failed
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_orders_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 已建表的库升级（补 password_hash 列；MySQL 不支持 IF NOT EXISTS 加列，先确认列不存在）：
--   ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) DEFAULT NULL AFTER phone;

-- 并发安全扣减由应用层单语句完成（见 src/db/mysql.adapter.js tryConsume）：
--   UPDATE users SET used_count = used_count + 1
--   WHERE id = ? AND quota_limit - used_count >= 1;
-- affectedRows = 1 表示扣减成功，0 表示额度不足。
