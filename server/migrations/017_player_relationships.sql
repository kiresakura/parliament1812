-- 跨局玩家關係系統
-- 追蹤玩家之間的信任分數、結盟與背叛歷史

CREATE TABLE player_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_a UUID NOT NULL REFERENCES users(id),
    player_b UUID NOT NULL REFERENCES users(id),
    alliance_count INT DEFAULT 0,
    betrayal_count INT DEFAULT 0,
    challenge_count INT DEFAULT 0,
    games_together INT DEFAULT 0,
    trust_score FLOAT DEFAULT 50.0,
    relationship_type VARCHAR(30) DEFAULT 'neutral',
    last_game_id UUID REFERENCES rooms(id),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_a, player_b),
    CHECK (player_a < player_b)
);

CREATE INDEX idx_relationships_player_a ON player_relationships(player_a);
CREATE INDEX idx_relationships_player_b ON player_relationships(player_b);
CREATE INDEX idx_relationships_type ON player_relationships(relationship_type);
CREATE INDEX idx_relationships_trust ON player_relationships(trust_score DESC);
