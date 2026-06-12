-- 玩家自創法案（UGC Bills）
CREATE TABLE user_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES users(id),
    bill_name VARCHAR(100) NOT NULL,
    bill_description TEXT NOT NULL,
    bill_type VARCHAR(30) NOT NULL,
    version_a JSONB NOT NULL,
    version_b JSONB NOT NULL,
    version_c JSONB NOT NULL,
    special_rules JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'pending',
    -- status: pending, approved, rejected, featured
    upvotes INT DEFAULT 0,
    downvotes INT DEFAULT 0,
    play_count INT DEFAULT 0,
    featured_week INT,
    featured_year INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 法案投票記錄（防重複投票）
CREATE TABLE bill_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL REFERENCES user_bills(id),
    voter_id UUID NOT NULL REFERENCES users(id),
    vote_type VARCHAR(10) NOT NULL, -- 'up' or 'down'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(bill_id, voter_id)
);

CREATE INDEX idx_user_bills_author ON user_bills(author_id);
CREATE INDEX idx_user_bills_status ON user_bills(status);
CREATE INDEX idx_user_bills_votes ON user_bills(upvotes DESC);
CREATE INDEX idx_user_bills_created ON user_bills(created_at DESC);
CREATE INDEX idx_bill_votes_bill ON bill_votes(bill_id);
CREATE INDEX idx_bill_votes_voter ON bill_votes(voter_id);
