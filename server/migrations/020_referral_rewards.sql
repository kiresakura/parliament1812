-- 推薦獎勵定義
CREATE TABLE referral_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    milestone_name VARCHAR(50) NOT NULL UNIQUE,
    required_referrals INT NOT NULL,
    reward_type VARCHAR(30) NOT NULL,
    -- reward_type: 'avatar', 'card_skin', 'title', 'gems', 'emote'
    reward_data JSONB NOT NULL,
    -- reward_data 格式：
    -- {"avatar_id": "gold_speaker", "display_name": "黃金議長"}
    -- {"gems_amount": 100}
    -- {"title": "人脈王", "title_color": "#FFD700"}
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用戶已領取的獎勵
CREATE TABLE referral_reward_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    milestone_id UUID NOT NULL REFERENCES referral_milestones(id),
    claimed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, milestone_id)
);

CREATE INDEX idx_reward_claims_user ON referral_reward_claims(user_id);
CREATE INDEX idx_milestones_required ON referral_milestones(required_referrals);

-- 預填充里程碑獎勵
INSERT INTO referral_milestones (milestone_name, required_referrals, reward_type, reward_data, description) VALUES
('初次引薦', 1, 'title', '{"title": "引薦人", "title_color": "#4A90D9"}'::jsonb, '邀請 1 位朋友加入國會'),
('社交議員', 3, 'avatar', '{"avatar_id": "social_mp", "display_name": "社交議員頭像"}'::jsonb, '邀請 3 位朋友加入國會'),
('人脈網絡', 5, 'gems', '{"gems_amount": 200}'::jsonb, '邀請 5 位朋友加入國會'),
('黨鞭', 10, 'card_skin', '{"skin_id": "golden_whip", "display_name": "黃金黨鞭卡面"}'::jsonb, '邀請 10 位朋友加入國會'),
('幕後操盤手', 25, 'title', '{"title": "幕後操盤手", "title_color": "#FFD700"}'::jsonb, '邀請 25 位朋友加入國會'),
('國會教父', 50, 'avatar', '{"avatar_id": "godfather", "display_name": "國會教父頭像"}'::jsonb, '邀請 50 位朋友加入國會');
