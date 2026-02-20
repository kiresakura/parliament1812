-- 013_weekly_challenges.sql
-- 週期性挑戰（Weekly Challenges）資料表

CREATE TABLE IF NOT EXISTS weekly_challenges (
    user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
    quest_week  VARCHAR(10) NOT NULL,  -- "2026-W08" 格式
    quest_id    VARCHAR(50) NOT NULL,
    progress    INT DEFAULT 0,
    target      INT NOT NULL,
    claimed     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, quest_week, quest_id)
);

-- 建立索引
CREATE INDEX IF NOT EXISTS idx_weekly_challenges_week
    ON weekly_challenges(quest_week);

CREATE INDEX IF NOT EXISTS idx_weekly_challenges_user_week
    ON weekly_challenges(user_id, quest_week);

-- 新增註解
COMMENT ON TABLE weekly_challenges IS '週期性挑戰進度記錄，每週一重置';
COMMENT ON COLUMN weekly_challenges.quest_week IS '挑戰週標籤，格式為 "YYYY-Www"';
COMMENT ON COLUMN weekly_challenges.quest_id IS '挑戰類型 ID，如 "weekly_win_5"';
COMMENT ON COLUMN weekly_challenges.progress IS '當前進度';
COMMENT ON COLUMN weekly_challenges.target IS '目標數量';
COMMENT ON COLUMN weekly_challenges.claimed IS '是否已領取獎勵';