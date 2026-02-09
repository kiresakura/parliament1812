-- 005_extended_schema.sql
-- 擴展 schema：遊戲持久化、排行榜、社交、交易等

-- ============================================================
-- 擴展 users 表（新增欄位）
-- ============================================================
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS display_name VARCHAR(100),
    ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE,
    ADD COLUMN IF NOT EXISTS oauth_provider VARCHAR(20),
    ADD COLUMN IF NOT EXISTS oauth_id VARCHAR(255),
    ADD COLUMN IF NOT EXISTS avatar_url TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS elo_rating INT DEFAULT 1000,
    ADD COLUMN IF NOT EXISTS total_games INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_wins INT DEFAULT 0;

-- 讓 password_hash 可為 NULL（OAuth 使用者沒有密碼）
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- ============================================================
-- games: 對局記錄（擴展自現有 rooms）
-- ============================================================
CREATE TABLE IF NOT EXISTS games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_code VARCHAR(10),
    status VARCHAR(20) NOT NULL DEFAULT 'waiting',
    game_mode VARCHAR(20) NOT NULL DEFAULT 'casual',
    round_count INT DEFAULT 0,
    max_rounds INT DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    winner_id UUID REFERENCES users(id),
    game_data JSONB
);

CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);
CREATE INDEX IF NOT EXISTS idx_games_room_code ON games(room_code);
CREATE INDEX IF NOT EXISTS idx_games_created_at ON games(created_at DESC);

-- ============================================================
-- game_players: 對局玩家結果
-- ============================================================
CREATE TABLE IF NOT EXISTS game_players (
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    character_type VARCHAR(50),
    final_reputation INT,
    final_gold INT,
    placement INT,
    is_mvp BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (game_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_game_players_user ON game_players(user_id);
CREATE INDEX IF NOT EXISTS idx_game_players_game ON game_players(game_id);

-- ============================================================
-- cards_collection: 卡牌收藏
-- ============================================================
CREATE TABLE IF NOT EXISTS cards_collection (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    card_id VARCHAR(50),
    obtained_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, card_id)
);

-- ============================================================
-- rankings: 排行榜
-- ============================================================
CREATE TABLE IF NOT EXISTS rankings (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    season INT NOT NULL,
    elo_rating INT DEFAULT 1000,
    rank_position INT,
    games_played INT DEFAULT 0,
    wins INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, season)
);

CREATE INDEX IF NOT EXISTS idx_rankings_season_elo ON rankings(season, elo_rating DESC);

-- ============================================================
-- daily_quests: 每日任務進度
-- ============================================================
CREATE TABLE IF NOT EXISTS daily_quests (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    quest_date DATE DEFAULT CURRENT_DATE,
    quest_id VARCHAR(50),
    progress INT DEFAULT 0,
    target INT NOT NULL,
    claimed BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, quest_date, quest_id)
);

-- ============================================================
-- friends: 好友關係
-- ============================================================
CREATE TABLE IF NOT EXISTS friends (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS idx_friends_friend ON friends(friend_id);

-- ============================================================
-- transactions: 交易記錄
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(30) NOT NULL,
    amount INT NOT NULL,
    currency VARCHAR(20) DEFAULT 'gem',
    description TEXT,
    receipt_data TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id, created_at DESC);
