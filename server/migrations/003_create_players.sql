-- 建立 players 資料表
-- 用於儲存遊戲中的玩家資訊

CREATE TYPE character_type AS ENUM ('thomas', 'richard', 'edward', 'george');

CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    character character_type,
    reputation INT DEFAULT 50,
    gold INT DEFAULT 0,
    is_ready BOOLEAN DEFAULT FALSE,
    is_host BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, room_id)
);

CREATE INDEX idx_players_room ON players(room_id);
CREATE INDEX idx_players_user ON players(user_id);
