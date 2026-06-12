-- 串流平台整合
-- 支援 Twitch / YouTube 帳號綁定與串流事件追蹤

-- 串流平台帳號綁定
CREATE TABLE streaming_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    platform VARCHAR(20) NOT NULL,
    -- platform: 'twitch', 'youtube'
    platform_user_id VARCHAR(100) NOT NULL,
    platform_username VARCHAR(100),
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMPTZ,
    is_live BOOLEAN DEFAULT false,
    settings JSONB DEFAULT '{}',
    -- settings: {"auto_post_results": true, "highlight_clips": true}
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, platform),
    UNIQUE(platform, platform_user_id)
);

-- 串流事件紀錄
CREATE TABLE streaming_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    streaming_account_id UUID NOT NULL REFERENCES streaming_accounts(id),
    event_type VARCHAR(30) NOT NULL,
    -- event_type: 'stream_start', 'stream_end', 'game_highlight', 'viewer_peak'
    game_id UUID REFERENCES rooms(id),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_streaming_user ON streaming_accounts(user_id);
CREATE INDEX idx_streaming_platform ON streaming_accounts(platform, platform_user_id);
CREATE INDEX idx_streaming_live ON streaming_accounts(is_live) WHERE is_live = true;
CREATE INDEX idx_streaming_events_account ON streaming_events(streaming_account_id);
CREATE INDEX idx_streaming_events_type ON streaming_events(event_type);
