//! 圖鑑 API 處理器
//!
//! 提供卡牌圖鑑、收藏、成就、統計等端點。

use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};

use crate::auth::AuthUser;
use crate::db::codex::{AchievementDb, CollectionDb};
use crate::error::AppError;
use crate::game::achievements::{
    get_achievement, get_achievement_target, get_all_achievements, AchievementReward,
};
use crate::game::card_codex::{get_all_codex_entries, CardCodexEntry, CodexRarity};
use crate::AppState;

// ═══════════════════════════════════════════
// 回應結構
// ═══════════════════════════════════════════

/// 卡牌列表回應（含收藏狀態）
#[derive(Debug, Serialize)]
pub struct CodexCardsResponse {
    pub cards: Vec<CodexCardWithOwnership>,
    pub total: usize,
}

/// 帶收藏狀態的卡牌條目
#[derive(Debug, Serialize)]
pub struct CodexCardWithOwnership {
    #[serde(flatten)]
    pub entry: CardCodexEntry,
    pub owned: bool,
}

/// 收藏列表回應
#[derive(Debug, Serialize)]
pub struct CollectionResponse {
    pub cards: Vec<CardCodexEntry>,
    pub collected: usize,
    pub total: usize,
}

/// 成就列表回應
#[derive(Debug, Serialize)]
pub struct AchievementsResponse {
    pub achievements: Vec<AchievementWithProgress>,
    pub completed_count: usize,
    pub total: usize,
    pub unclaimed_count: i64,
}

/// 帶進度的成就
#[derive(Debug, Serialize)]
pub struct AchievementWithProgress {
    pub id: String,
    pub name: String,
    pub name_en: String,
    pub description: String,
    pub difficulty: String,
    pub is_hidden: bool,
    pub icon_hint: String,
    pub rewards: Vec<AchievementReward>,
    pub progress: i32,
    pub target: i32,
    pub completed: bool,
    pub claimed: bool,
    pub completed_at: Option<String>,
}

/// 統計回應
#[derive(Debug, Serialize)]
pub struct CodexStatsResponse {
    pub total_cards: usize,
    pub collected_cards: usize,
    pub collection_percentage: f64,
    pub rarity_stats: RarityStats,
    pub achievements_completed: usize,
    pub achievements_total: usize,
}

/// 稀有度統計
#[derive(Debug, Serialize)]
pub struct RarityStats {
    pub common: RarityCount,
    pub uncommon: RarityCount,
    pub rare: RarityCount,
    pub legendary: RarityCount,
}

#[derive(Debug, Serialize)]
pub struct RarityCount {
    pub owned: usize,
    pub total: usize,
}

/// 領取成就獎勵請求
#[derive(Debug, Deserialize)]
pub struct ClaimRequest {
    pub achievement_id: String,
}

/// 領取成就獎勵回應
#[derive(Debug, Serialize)]
pub struct ClaimResponse {
    pub success: bool,
    pub rewards: Vec<AchievementReward>,
    pub unlocked_cards: Vec<String>,
    pub gold_earned: i32,
}

// ═══════════════════════════════════════════
// 處理器
// ═══════════════════════════════════════════

/// GET /api/codex/cards — 全卡牌列表（含收藏狀態）
pub async fn get_codex_cards(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<CodexCardsResponse>, AppError> {
    let owned_ids = CollectionDb::get_user_collection(&state.db, auth.user_id).await?;
    let all_entries = get_all_codex_entries();
    let total = all_entries.len();

    let cards: Vec<CodexCardWithOwnership> = all_entries
        .into_iter()
        .map(|entry| {
            let owned = owned_ids.contains(&entry.id);
            CodexCardWithOwnership { entry, owned }
        })
        .collect();

    Ok(Json(CodexCardsResponse { cards, total }))
}

/// GET /api/codex/collection — 我的收藏
pub async fn get_collection(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<CollectionResponse>, AppError> {
    let owned_ids = CollectionDb::get_user_collection(&state.db, auth.user_id).await?;
    let all_entries = get_all_codex_entries();
    let total = all_entries.len();

    let cards: Vec<CardCodexEntry> = all_entries
        .into_iter()
        .filter(|e| owned_ids.contains(&e.id))
        .collect();

    let collected = cards.len();

    Ok(Json(CollectionResponse {
        cards,
        collected,
        total,
    }))
}

/// GET /api/codex/achievements — 成就 + 進度
pub async fn get_achievements(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<AchievementsResponse>, AppError> {
    let db_records = AchievementDb::get_user_achievements(&state.db, auth.user_id).await?;
    let unclaimed_count = AchievementDb::get_unclaimed_count(&state.db, auth.user_id).await?;
    let all_defs = get_all_achievements();
    let total = all_defs.len();

    let achievements: Vec<AchievementWithProgress> = all_defs
        .into_iter()
        .map(|def| {
            let record = db_records.iter().find(|r| r.achievement_id == def.id);
            let target = get_achievement_target(&def.condition);

            AchievementWithProgress {
                id: def.id,
                name: def.name,
                name_en: def.name_en,
                description: if def.is_hidden && record.is_none_or(|r| !r.completed) {
                    "???".into()
                } else {
                    def.description
                },
                difficulty: format!("{:?}", def.difficulty).to_lowercase(),
                is_hidden: def.is_hidden,
                icon_hint: def.icon_hint,
                rewards: def.rewards,
                progress: record.map_or(0, |r| r.progress),
                target,
                completed: record.is_some_and(|r| r.completed),
                claimed: record.is_some_and(|r| r.claimed),
                completed_at: record.and_then(|r| r.completed_at).map(|t| t.to_rfc3339()),
            }
        })
        .collect();

    let completed_count = achievements.iter().filter(|a| a.completed).count();

    Ok(Json(AchievementsResponse {
        achievements,
        completed_count,
        total,
        unclaimed_count,
    }))
}

/// GET /api/codex/stats — 收藏統計
pub async fn get_codex_stats(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<CodexStatsResponse>, AppError> {
    let owned_ids = CollectionDb::get_user_collection(&state.db, auth.user_id).await?;
    let all_entries = get_all_codex_entries();
    let total_cards = all_entries.len();
    let collected_cards = owned_ids.len();

    // 計算各稀有度擁有/總量
    let count_owned = |rarity: CodexRarity| -> usize {
        all_entries
            .iter()
            .filter(|e| e.rarity == rarity && owned_ids.contains(&e.id))
            .count()
    };
    let count_total = |rarity: CodexRarity| -> usize {
        all_entries.iter().filter(|e| e.rarity == rarity).count()
    };

    let rarity_stats = RarityStats {
        common: RarityCount {
            owned: count_owned(CodexRarity::Common),
            total: count_total(CodexRarity::Common),
        },
        uncommon: RarityCount {
            owned: count_owned(CodexRarity::Uncommon),
            total: count_total(CodexRarity::Uncommon),
        },
        rare: RarityCount {
            owned: count_owned(CodexRarity::Rare),
            total: count_total(CodexRarity::Rare),
        },
        legendary: RarityCount {
            owned: count_owned(CodexRarity::Legendary),
            total: count_total(CodexRarity::Legendary),
        },
    };

    // 成就完成數
    let db_achievements = AchievementDb::get_user_achievements(&state.db, auth.user_id).await?;
    let achievements_completed = db_achievements.iter().filter(|a| a.completed).count();
    let achievements_total = get_all_achievements().len();

    let collection_percentage = if total_cards > 0 {
        (collected_cards as f64 / total_cards as f64 * 100.0).round()
    } else {
        0.0
    };

    Ok(Json(CodexStatsResponse {
        total_cards,
        collected_cards,
        collection_percentage,
        rarity_stats,
        achievements_completed,
        achievements_total,
    }))
}

/// POST /api/codex/achievements/claim — 領取成就獎勵
pub async fn claim_achievement(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<ClaimRequest>,
) -> Result<Json<ClaimResponse>, AppError> {
    // 找到成就定義
    let def = get_achievement(&req.achievement_id)
        .ok_or_else(|| AppError::NotFound("成就不存在".into()))?;

    // 檢查是否已完成
    let record =
        AchievementDb::get_achievement_progress(&state.db, auth.user_id, &req.achievement_id)
            .await?
            .ok_or_else(|| AppError::BadRequest("成就尚未開始".into()))?;

    if !record.completed {
        return Err(AppError::BadRequest("成就尚未完成".into()));
    }
    if record.claimed {
        return Err(AppError::BadRequest("獎勵已領取".into()));
    }

    // 領取
    AchievementDb::claim_reward(&state.db, auth.user_id, &req.achievement_id).await?;

    // 發放獎勵
    let mut unlocked_cards = Vec::new();
    let mut gold_earned = 0i32;

    for reward in &def.rewards {
        match reward {
            AchievementReward::UnlockCard { card_id } => {
                if CollectionDb::add_card(&state.db, auth.user_id, card_id).await? {
                    unlocked_cards.push(card_id.clone());
                }
            }
            AchievementReward::Gold { amount } => {
                gold_earned += amount;
                // TODO: 實際加到使用者帳戶
            }
            AchievementReward::Title { .. } => {
                // TODO: 設定使用者稱號
            }
        }
    }

    Ok(Json(ClaimResponse {
        success: true,
        rewards: def.rewards,
        unlocked_cards,
        gold_earned,
    }))
}
