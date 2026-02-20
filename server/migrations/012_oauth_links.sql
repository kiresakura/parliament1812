-- 用戶 OAuth 連結表（支援多 OAuth 綁定）
CREATE TABLE IF NOT EXISTS user_oauth_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(20) NOT NULL,
    provider_user_id TEXT NOT NULL,
    email TEXT,
    linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(provider, provider_user_id)
);

CREATE INDEX IF NOT EXISTS idx_oauth_links_user_id ON user_oauth_links(user_id);
CREATE INDEX IF NOT EXISTS idx_oauth_links_provider ON user_oauth_links(provider, provider_user_id);

-- 遷移現有 OAuth 資料到新表
INSERT INTO user_oauth_links (user_id, provider, provider_user_id, email)
SELECT id, oauth_provider, oauth_id, email
FROM users
WHERE oauth_provider IS NOT NULL AND oauth_id IS NOT NULL
ON CONFLICT DO NOTHING;
