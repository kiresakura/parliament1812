-- 遊戲事件日誌
-- 用於收集遊戲過程中的所有事件，支持戲劇性指數計算和事後分析

CREATE TABLE game_event_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES rooms(id),
    event_type VARCHAR(50) NOT NULL,
    actor_id UUID REFERENCES users(id),
    target_id UUID REFERENCES users(id),
    card_type VARCHAR(30),
    metadata JSONB DEFAULT '{}',
    reputation_change INT DEFAULT 0,
    round_number INT NOT NULL,
    phase VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_event_logs_game ON game_event_logs(game_id);
CREATE INDEX idx_event_logs_actor ON game_event_logs(actor_id);
CREATE INDEX idx_event_logs_type ON game_event_logs(event_type);
CREATE INDEX idx_event_logs_game_round ON game_event_logs(game_id, round_number);
