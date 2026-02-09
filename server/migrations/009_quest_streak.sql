-- 009_quest_streak.sql
-- 每日任務連續完成紀錄

CREATE TABLE IF NOT EXISTS quest_streaks (
    user_id UUID REFERENCES users(id) PRIMARY KEY,
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    last_completed_date DATE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
