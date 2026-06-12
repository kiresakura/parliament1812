-- 遊戲摘要表
-- 儲存每場遊戲結束後的摘要資料，包含戲劇指數、精華時刻、報紙資料等

CREATE TABLE game_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL UNIQUE REFERENCES rooms(id),
    drama_score FLOAT NOT NULL DEFAULT 0.0,
    total_rounds INT NOT NULL,
    winning_faction VARCHAR(30),
    mvp_player_id UUID REFERENCES users(id),
    betrayal_count INT DEFAULT 0,
    expose_count INT DEFAULT 0,
    alliance_count INT DEFAULT 0,
    biggest_comeback_player_id UUID REFERENCES users(id),
    highlights JSONB DEFAULT '[]',
    newspaper_data JSONB DEFAULT '{}',
    share_token VARCHAR(64) UNIQUE,
    view_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_summaries_drama ON game_summaries(drama_score DESC);
CREATE INDEX idx_summaries_share ON game_summaries(share_token);
CREATE INDEX idx_summaries_created ON game_summaries(created_at DESC);
CREATE INDEX idx_summaries_game ON game_summaries(game_id);
