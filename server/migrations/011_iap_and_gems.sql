-- Migration 011: IAP 內購系統 + 寶石系統
-- 新增寶石欄位、內購交易記錄表、戰役解鎖表、AI 對戰記錄表

-- 1. 用戶表新增寶石和 AI 無限對戰欄位
ALTER TABLE users ADD COLUMN IF NOT EXISTS gems BIGINT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS ai_unlimited_until TIMESTAMPTZ;

-- 2. 內購交易記錄表
CREATE TABLE IF NOT EXISTS iap_transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    platform VARCHAR(20) NOT NULL,           -- 'apple' or 'google'
    product_id VARCHAR(100) NOT NULL,        -- 產品 ID
    transaction_id VARCHAR(255) NOT NULL,    -- 平台交易 ID（Apple transactionId / Google orderId）
    purchase_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 防止重複交易（冪等性）
CREATE UNIQUE INDEX IF NOT EXISTS idx_iap_transactions_txn_id
    ON iap_transactions(transaction_id);

-- 使用者購買記錄查詢
CREATE INDEX IF NOT EXISTS idx_iap_transactions_user_id
    ON iap_transactions(user_id, created_at DESC);

-- 3. 戰役章節解鎖表
CREATE TABLE IF NOT EXISTS campaign_unlocks (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chapter INTEGER NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, chapter)
);

-- 4. 戰役進度表
CREATE TABLE IF NOT EXISTS campaign_progress (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chapter INTEGER NOT NULL,
    stage INTEGER NOT NULL,
    stars INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, chapter, stage)
);

CREATE INDEX IF NOT EXISTS idx_campaign_progress_user
    ON campaign_progress(user_id, chapter, stage);

-- 5. AI 對戰記錄表
CREATE TABLE IF NOT EXISTS ai_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    difficulty VARCHAR(20) NOT NULL,
    character_choice VARCHAR(50),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    won BOOLEAN,
    score INTEGER
);

CREATE INDEX IF NOT EXISTS idx_ai_matches_user
    ON ai_matches(user_id, started_at DESC);
