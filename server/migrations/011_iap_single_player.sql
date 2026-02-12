-- M7: IAP 交易記錄
CREATE TABLE IF NOT EXISTS iap_transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    platform VARCHAR(20) NOT NULL,  -- 'apple' or 'google'
    product_id VARCHAR(100) NOT NULL,
    transaction_id VARCHAR(200) NOT NULL UNIQUE,
    purchase_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_iap_transactions_user ON iap_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_iap_transactions_txn ON iap_transactions(transaction_id);

-- 用戶新增欄位：寶石、AI無限權限到期
ALTER TABLE users ADD COLUMN IF NOT EXISTS gems BIGINT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS ai_unlimited_until TIMESTAMPTZ;

-- M14a: AI 對戰記錄
CREATE TABLE IF NOT EXISTS ai_matches (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    difficulty VARCHAR(20) NOT NULL,
    character_choice VARCHAR(50),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    won BOOLEAN,
    score INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_matches_user ON ai_matches(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_matches_date ON ai_matches(user_id, started_at);

-- M14b: 教學進度
CREATE TABLE IF NOT EXISTS tutorial_progress (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    step INTEGER NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, step)
);

-- M14c: 戰役章節解鎖
CREATE TABLE IF NOT EXISTS campaign_unlocks (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chapter INTEGER NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, chapter)
);

-- M14c: 戰役關卡進度
CREATE TABLE IF NOT EXISTS campaign_progress (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chapter INTEGER NOT NULL,
    stage INTEGER NOT NULL,
    stars INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, chapter, stage)
);

CREATE INDEX IF NOT EXISTS idx_campaign_progress_user ON campaign_progress(user_id);
