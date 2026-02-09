-- 008_achievements.sql
-- 成就系統

CREATE TABLE IF NOT EXISTS achievements_progress (
    user_id UUID REFERENCES users(id),
    achievement_id VARCHAR(50),
    progress INT DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    claimed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_achievements_user ON achievements_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_completed ON achievements_progress(user_id, completed);
