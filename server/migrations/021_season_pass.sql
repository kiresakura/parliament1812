-- Migration 021: 賽季通行證系統
-- 賽季通行證等級、玩家進度、獎勵領取

-- 賽季通行證等級
CREATE TABLE season_pass_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    season_id INT NOT NULL REFERENCES seasons(id),
    tier_level INT NOT NULL,
    xp_required INT NOT NULL,
    free_reward JSONB,
    -- free_reward 格式：{"type": "avatar", "id": "seasonal_1", "name": "春季議員"}
    premium_reward JSONB,
    -- premium_reward 格式：{"type": "card_skin", "id": "gold_debate", "name": "黃金辯論卡面"}
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(season_id, tier_level)
);

-- 玩家賽季通行證進度
CREATE TABLE season_pass_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    season_id INT NOT NULL REFERENCES seasons(id),
    current_xp INT DEFAULT 0,
    current_tier INT DEFAULT 0,
    is_premium BOOLEAN DEFAULT false,
    premium_purchased_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, season_id)
);

-- 已領取的賽季獎勵
CREATE TABLE season_reward_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    season_id INT NOT NULL REFERENCES seasons(id),
    tier_level INT NOT NULL,
    reward_track VARCHAR(10) NOT NULL, -- 'free' or 'premium'
    claimed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, season_id, tier_level, reward_track)
);

CREATE INDEX idx_pass_tiers_season ON season_pass_tiers(season_id, tier_level);
CREATE INDEX idx_pass_progress_user ON season_pass_progress(user_id);
CREATE INDEX idx_pass_progress_season ON season_pass_progress(season_id);
CREATE INDEX idx_reward_claims_user ON season_reward_claims(user_id, season_id);

-- 為當前賽季預填充 30 級通行證
-- 注意：需要現有 seasons 表有 active 賽季，這裡用 placeholder
-- 實際使用時由 admin 或腳本填充
