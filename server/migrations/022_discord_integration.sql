-- Discord 整合
-- 2026-03-13: F3-1 Discord Bot 整合

-- Discord 伺服器綁定
CREATE TABLE discord_guilds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guild_id VARCHAR(30) NOT NULL UNIQUE,
    guild_name VARCHAR(100),
    webhook_url TEXT,
    notification_channel_id VARCHAR(30),
    is_active BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}',
    -- settings: {"auto_post_results": true, "weekly_bill_announce": true}
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Discord 用戶綁定
CREATE TABLE discord_user_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    discord_user_id VARCHAR(30) NOT NULL UNIQUE,
    discord_username VARCHAR(50),
    linked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX idx_discord_guilds_active ON discord_guilds(is_active) WHERE is_active = true;
CREATE INDEX idx_discord_links_user ON discord_user_links(user_id);
CREATE INDEX idx_discord_links_discord ON discord_user_links(discord_user_id);
