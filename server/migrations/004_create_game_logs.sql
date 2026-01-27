-- 建立 game_logs 資料表
-- 用於記錄遊戲行動日誌

CREATE TABLE game_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,
    actor_id UUID REFERENCES players(id),
    target_id UUID REFERENCES players(id),
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_game_logs_room ON game_logs(room_id);
CREATE INDEX idx_game_logs_created ON game_logs(created_at);
