-- 歸因追蹤系統
-- 追蹤邀請連結和用戶轉化

CREATE TABLE attribution_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inviter_id UUID REFERENCES users(id),
    invitee_id UUID REFERENCES users(id),
    channel VARCHAR(30) NOT NULL,
    deep_link_token VARCHAR(64) UNIQUE,
    status VARCHAR(20) DEFAULT 'pending',
    click_count INT DEFAULT 0,
    converted_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_attribution_inviter ON attribution_events(inviter_id);
CREATE INDEX idx_attribution_token ON attribution_events(deep_link_token);
CREATE INDEX idx_attribution_status ON attribution_events(status);
CREATE INDEX idx_attribution_created ON attribution_events(created_at DESC);
