-- 建立 rooms 資料表
-- 用於儲存遊戲房間資訊

CREATE TYPE room_status AS ENUM ('waiting', 'playing', 'finished');

CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(6) UNIQUE NOT NULL,
    host_id UUID NOT NULL REFERENCES users(id),
    status room_status DEFAULT 'waiting',
    max_players INT DEFAULT 4,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rooms_code ON rooms(code);
CREATE INDEX idx_rooms_status ON rooms(status);
