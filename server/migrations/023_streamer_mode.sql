-- 實況主設定
CREATE TABLE streamer_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id),
    is_streamer BOOLEAN DEFAULT false,
    overlay_token VARCHAR(64) UNIQUE,
    -- overlay_token: OBS 存取用的唯一 token
    overlay_theme VARCHAR(30) DEFAULT 'classic',
    -- themes: classic, dark, minimal, victorian
    show_spectator_count BOOLEAN DEFAULT true,
    show_chat BOOLEAN DEFAULT true,
    show_drama_score BOOLEAN DEFAULT true,
    show_round_timer BOOLEAN DEFAULT true,
    custom_title VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_streamer_overlay ON streamer_settings(overlay_token) WHERE overlay_token IS NOT NULL;
CREATE INDEX idx_streamer_user ON streamer_settings(user_id);
