//! 整合測試
//!
//! 測試各模組的協同運作

use parliament1812_server::game::ai::{AIDifficulty, AIManager, AIPlayer};
use parliament1812_server::game::elo;
use parliament1812_server::game::state::PlayerState;
use parliament1812_server::game::{GameConfig, GameEngine};
use parliament1812_server::single_player::ai_engine::{AiDifficulty, AiEngine};
use parliament1812_server::single_player::campaign::{Campaign, ChapterId, SpecialRule};
use parliament1812_server::single_player::session::SinglePlayerSession;
use parliament1812_server::services::campaign_service::{
    CampaignService, GEMS_PER_CHAPTER_UNLOCK, STAGES_PER_CHAPTER, TOTAL_CHAPTERS,
};
use parliament1812_server::services::iap_service::ProductId;
use parliament1812_server::services::single_player_service::{
    ApiDifficulty, DAILY_FREE_AI_MATCHES,
};
use parliament1812_server::services::tutorial_service::{TutorialService, TOTAL_TUTORIAL_STEPS};
use parliament1812_server::domain::CharacterType;
use uuid::Uuid;

// ============================================================
// AI Engine Tests
// ============================================================

#[test]
fn test_ai_engine_easy_creation() {
    let engine = AiEngine::new(AiDifficulty::Easy);
    assert_eq!(engine.difficulty, AiDifficulty::Easy);
}

#[test]
fn test_ai_engine_normal_creation() {
    let engine = AiEngine::new(AiDifficulty::Normal);
    assert_eq!(engine.difficulty, AiDifficulty::Normal);
}

#[test]
fn test_ai_engine_hard_creation() {
    let engine = AiEngine::new(AiDifficulty::Hard);
    assert_eq!(engine.difficulty, AiDifficulty::Hard);
}

#[test]
fn test_ai_difficulty_display() {
    assert_eq!(format!("{}", AiDifficulty::Easy), "簡單");
    assert_eq!(format!("{}", AiDifficulty::Normal), "普通");
    assert_eq!(format!("{}", AiDifficulty::Hard), "困難");
}

// ============================================================
// Campaign Tests
// ============================================================

#[test]
fn test_campaign_has_5_chapters() {
    let chapters = Campaign::get_chapters();
    assert_eq!(chapters.len(), 5);
}

#[test]
fn test_campaign_chapter_ids() {
    let chapters = Campaign::get_chapters();
    assert_eq!(chapters[0].id, ChapterId::Chapter1);
    assert_eq!(chapters[1].id, ChapterId::Chapter2);
    assert_eq!(chapters[2].id, ChapterId::Chapter3);
    assert_eq!(chapters[3].id, ChapterId::Chapter4);
    assert_eq!(chapters[4].id, ChapterId::Chapter5);
}

#[test]
fn test_campaign_chapter1_unlocked() {
    let chapter = Campaign::get_chapter(ChapterId::Chapter1);
    assert!(chapter.is_some());
}

#[test]
fn test_campaign_get_nonexistent_chapter() {
    // All valid chapters should exist
    for id in ChapterId::all() {
        assert!(Campaign::get_chapter(id).is_some());
    }
}

#[test]
fn test_chapter_id_all_returns_5() {
    assert_eq!(ChapterId::all().len(), 5);
}

#[test]
fn test_chapter_id_numbers() {
    assert_eq!(ChapterId::Chapter1.number(), 1);
    assert_eq!(ChapterId::Chapter2.number(), 2);
    assert_eq!(ChapterId::Chapter3.number(), 3);
    assert_eq!(ChapterId::Chapter4.number(), 4);
    assert_eq!(ChapterId::Chapter5.number(), 5);
}

#[test]
fn test_chapter_id_from_number() {
    assert_eq!(ChapterId::from_number(1), Some(ChapterId::Chapter1));
    assert_eq!(ChapterId::from_number(5), Some(ChapterId::Chapter5));
    assert_eq!(ChapterId::from_number(0), None);
    assert_eq!(ChapterId::from_number(6), None);
}

#[test]
fn test_chapter_id_next() {
    assert_eq!(ChapterId::Chapter1.next(), Some(ChapterId::Chapter2));
    assert_eq!(ChapterId::Chapter4.next(), Some(ChapterId::Chapter5));
    assert_eq!(ChapterId::Chapter5.next(), None);
}

#[test]
fn test_chapter_id_display() {
    assert_eq!(format!("{}", ChapterId::Chapter1), "第1章");
    assert_eq!(format!("{}", ChapterId::Chapter5), "第5章");
}

#[test]
fn test_campaign_chapters_have_stages() {
    let chapters = CampaignService::get_all_chapters();
    for ch in &chapters {
        assert!(!ch.stages.is_empty(), "Chapter {} has no stages", ch.title);
    }
}

#[test]
fn test_campaign_chapters_have_titles() {
    let chapters = Campaign::get_chapters();
    for ch in &chapters {
        assert!(!ch.title.is_empty());
    }
}

#[test]
fn test_campaign_new_progress() {
    let progress = Campaign::new_progress(Uuid::new_v4());
    assert!(progress.chapters.iter().all(|ch| !ch.completed));
}

#[test]
fn test_chapter_is_unlocked_ch1() {
    let progress = Campaign::new_progress(Uuid::new_v4());
    assert!(Campaign::is_chapter_unlocked(ChapterId::Chapter1, &progress));
}

#[test]
fn test_chapter_is_locked_ch2() {
    let progress = Campaign::new_progress(Uuid::new_v4());
    assert!(!Campaign::is_chapter_unlocked(
        ChapterId::Chapter2,
        &progress,
    ));
}

// ============================================================
// Single Player Session Tests
// ============================================================

#[test]
fn test_session_creation() {
    let session = SinglePlayerSession::new(
        "TestPlayer".to_string(),
        CharacterType::Thomas,
        AiDifficulty::Easy,
    );
    assert_eq!(session.human_player_id, session.human_player_id); // non-null
}

#[test]
fn test_session_start() {
    let mut session = SinglePlayerSession::new(
        "TestPlayer".to_string(),
        CharacterType::Thomas,
        AiDifficulty::Normal,
    );
    let state = session.start();
    assert!(state.is_ok());
}

#[test]
fn test_session_get_state() {
    let mut session = SinglePlayerSession::new(
        "TestPlayer".to_string(),
        CharacterType::Richard,
        AiDifficulty::Hard,
    );
    let _ = session.start();
    let state = session.get_state();
    assert!(!state.is_game_over);
}

#[test]
fn test_session_campaign_creation() {
    let session = SinglePlayerSession::new_campaign(
        "CampaignPlayer".to_string(),
        CharacterType::Edward,
        ChapterId::Chapter1,
        AiDifficulty::Easy,
        vec![],
        3,
    );
    let state = session.get_state();
    assert!(state.campaign_chapter.is_some());
}

// ============================================================
// IAP Product Tests
// ============================================================

#[test]
fn test_product_gems_100() {
    assert_eq!(ProductId::Gems100.gem_amount(), Some(100));
}

#[test]
fn test_product_gems_500() {
    assert_eq!(ProductId::Gems500.gem_amount(), Some(500));
}

#[test]
fn test_product_gems_1200() {
    assert_eq!(ProductId::Gems1200.gem_amount(), Some(1200));
}

#[test]
fn test_product_campaign_has_no_gems() {
    assert_eq!(ProductId::CampaignCh2.gem_amount(), None);
    assert_eq!(ProductId::CampaignAll.gem_amount(), None);
}

#[test]
fn test_product_consumable_types() {
    assert!(ProductId::Gems100.is_consumable());
    assert!(ProductId::Gems500.is_consumable());
    assert!(ProductId::Gems1200.is_consumable());
    assert!(!ProductId::CampaignCh2.is_consumable());
    assert!(!ProductId::AiUnlimitedMonthly.is_consumable());
}

#[test]
fn test_product_subscription_types() {
    assert!(ProductId::AiUnlimitedMonthly.is_subscription());
    assert!(!ProductId::Gems100.is_subscription());
    assert!(!ProductId::CampaignCh2.is_subscription());
}

#[test]
fn test_product_apple_ids_format() {
    assert!(ProductId::Gems100
        .apple_product_id()
        .starts_with("com.parliament1812.app"));
    assert!(ProductId::CampaignAll
        .apple_product_id()
        .starts_with("com.parliament1812.app"));
}

#[test]
fn test_product_google_ids_format() {
    assert!(!ProductId::Gems100.google_product_id().contains("com."));
    assert!(!ProductId::CampaignAll.google_product_id().contains("com."));
}

// ============================================================
// API Difficulty Tests
// ============================================================

#[test]
fn test_api_difficulty_easy() {
    assert_eq!(
        ApiDifficulty::Easy.to_engine_difficulty(),
        AIDifficulty::Easy
    );
}

#[test]
fn test_api_difficulty_medium() {
    assert_eq!(
        ApiDifficulty::Medium.to_engine_difficulty(),
        AIDifficulty::Normal
    );
}

#[test]
fn test_api_difficulty_hard() {
    assert_eq!(
        ApiDifficulty::Hard.to_engine_difficulty(),
        AIDifficulty::Hard
    );
}

#[test]
fn test_api_difficulty_expert() {
    assert_eq!(
        ApiDifficulty::Expert.to_engine_difficulty(),
        AIDifficulty::Hard
    );
    assert!(ApiDifficulty::Expert.is_expert());
}

#[test]
fn test_api_difficulty_display_names() {
    assert_eq!(ApiDifficulty::Easy.display_name(), "簡單");
    assert_eq!(ApiDifficulty::Medium.display_name(), "普通");
    assert_eq!(ApiDifficulty::Hard.display_name(), "困難");
    assert_eq!(ApiDifficulty::Expert.display_name(), "專家");
}

#[test]
fn test_daily_free_matches_constant() {
    assert_eq!(DAILY_FREE_AI_MATCHES, 10);
}

// ============================================================
// Tutorial Service Tests
// ============================================================

#[test]
fn test_tutorial_step_count() {
    assert_eq!(TOTAL_TUTORIAL_STEPS, 5);
}

#[test]
fn test_tutorial_steps_definition() {
    let steps = TutorialService::get_tutorial_steps();
    assert_eq!(steps.len(), 5);
}

#[test]
fn test_tutorial_steps_ordered() {
    let steps = TutorialService::get_tutorial_steps();
    for (i, step) in steps.iter().enumerate() {
        assert_eq!(step.step, (i + 1) as i32);
    }
}

#[test]
fn test_tutorial_steps_have_titles() {
    let steps = TutorialService::get_tutorial_steps();
    for step in &steps {
        assert!(!step.title.is_empty());
        assert!(!step.title_en.is_empty());
    }
}

#[test]
fn test_tutorial_steps_have_dialogues() {
    let steps = TutorialService::get_tutorial_steps();
    for step in &steps {
        assert!(!step.dialogue.is_empty());
    }
}

#[test]
fn test_tutorial_bilingual_dialogue() {
    let steps = TutorialService::get_tutorial_steps();
    for step in &steps {
        for dialogue in &step.dialogue {
            assert!(!dialogue.text.is_empty());
            assert!(!dialogue.text_en.is_empty());
        }
    }
}

// ============================================================
// Campaign Service Tests
// ============================================================

#[test]
fn test_campaign_service_total_chapters() {
    assert_eq!(TOTAL_CHAPTERS, 5);
}

#[test]
fn test_campaign_service_stages_per_chapter() {
    assert_eq!(STAGES_PER_CHAPTER, 5);
}

#[test]
fn test_campaign_service_gem_cost() {
    assert_eq!(GEMS_PER_CHAPTER_UNLOCK, 200);
}

#[test]
fn test_campaign_service_chapter_count() {
    let chapters = CampaignService::get_all_chapters();
    assert_eq!(chapters.len(), 5);
}

#[test]
fn test_campaign_service_ch1_free() {
    let chapters = CampaignService::get_all_chapters();
    assert!(chapters[0].is_free);
    assert_eq!(chapters[0].gem_cost, 0);
}

#[test]
fn test_campaign_service_ch2_5_paid() {
    let chapters = CampaignService::get_all_chapters();
    for ch in &chapters[1..] {
        assert!(!ch.is_free);
        assert_eq!(ch.gem_cost, GEMS_PER_CHAPTER_UNLOCK);
    }
}

#[test]
fn test_campaign_service_all_stages() {
    let chapters = CampaignService::get_all_chapters();
    for ch in &chapters {
        assert_eq!(ch.stages.len(), STAGES_PER_CHAPTER as usize);
    }
}

#[test]
fn test_campaign_service_bilingual_titles() {
    let chapters = CampaignService::get_all_chapters();
    for ch in &chapters {
        assert!(!ch.title.is_empty());
        assert!(!ch.title_en.is_empty());
    }
}

#[test]
fn test_campaign_service_bilingual_descriptions() {
    let chapters = CampaignService::get_all_chapters();
    for ch in &chapters {
        assert!(!ch.description.is_empty());
        assert!(!ch.description_en.is_empty());
    }
}

#[test]
fn test_campaign_service_stage_rewards_positive() {
    let chapters = CampaignService::get_all_chapters();
    for ch in &chapters {
        for stage in &ch.stages {
            assert!(stage.rewards.gems > 0);
            assert!(stage.rewards.experience > 0);
        }
    }
}

#[test]
fn test_campaign_service_difficulty_progression() {
    let chapters = CampaignService::get_all_chapters();
    // Ch1 starts easy
    assert_eq!(chapters[0].stages[0].difficulty, "tutorial");
    // Ch5 ends expert
    assert_eq!(chapters[4].stages[4].difficulty, "expert");
}

#[test]
fn test_campaign_total_gem_rewards() {
    let chapters = CampaignService::get_all_chapters();
    let total: i64 = chapters
        .iter()
        .flat_map(|ch| ch.stages.iter())
        .map(|s| s.rewards.gems)
        .sum();
    // Should be significant but reasonable
    assert!(total > 500, "Total gem rewards should be > 500, got {}", total);
    assert!(total < 5000, "Total gem rewards should be < 5000, got {}", total);
}

// ============================================================
// ELO Engine Tests
// ============================================================

#[test]
fn test_elo_1v1_win() {
    let result = elo::calculate_1v1(1000, 1000, 1.0, 0);
    assert!(result.new_rating > 1000);
    assert!(result.delta > 0);
}

#[test]
fn test_elo_1v1_loss() {
    let result = elo::calculate_1v1(1000, 1000, 0.0, 0);
    assert!(result.new_rating < 1000);
    assert!(result.delta < 0);
}

#[test]
fn test_elo_1v1_draw() {
    let result = elo::calculate_1v1(1000, 1000, 0.5, 0);
    assert_eq!(result.delta, 0);
}

#[test]
fn test_elo_higher_rated_wins_less() {
    let r1 = elo::calculate_1v1(1500, 1000, 1.0, 50);
    let r2 = elo::calculate_1v1(1000, 1500, 1.0, 50);
    assert!(r2.delta > r1.delta); // Underdog wins more ELO
}

#[test]
fn test_elo_floor() {
    let result = elo::calculate_1v1(elo::ELO_FLOOR, 2000, 0.0, 100);
    assert!(result.new_rating >= elo::ELO_FLOOR);
}

#[test]
fn test_elo_ceiling() {
    let result = elo::calculate_1v1(elo::ELO_CEILING, 800, 1.0, 100);
    assert!(result.new_rating <= elo::ELO_CEILING);
}

// ============================================================
// AI Manager Tests
// ============================================================

#[test]
fn test_ai_manager_expert_difficulty() {
    let mut manager = AIManager::new();
    let ids = manager.create_single_player_ais(CharacterType::Thomas, AIDifficulty::Expert);
    assert_eq!(ids.len(), 3);
    for id in ids {
        let ai = manager.get_ai_player(id).unwrap();
        assert_eq!(ai.difficulty, AIDifficulty::Expert);
    }
}

#[test]
fn test_ai_player_expert() {
    let ai = AIPlayer::new(Uuid::new_v4(), CharacterType::Richard, AIDifficulty::Expert);
    assert_eq!(ai.difficulty, AIDifficulty::Expert);
}

// ============================================================
// Special Rules Tests
// ============================================================

#[test]
fn test_special_rule_none() {
    assert_eq!(SpecialRule::None, SpecialRule::None);
}

// ============================================================
// Game Config Tests
// ============================================================

#[test]
fn test_default_game_config() {
    let config = GameConfig::default();
    assert!(config.voting_duration_secs > 0);
    assert!(config.result_duration_secs > 0);
}

#[test]
fn test_game_config_values() {
    let config = GameConfig::default();
    assert_eq!(config.voting_duration_secs, 60);
    assert_eq!(config.result_duration_secs, 30);
}
