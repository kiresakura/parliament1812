//! 卡牌資料
//!
//! MVP 卡牌定義

use crate::domain::card::{CardRarity, CardType, GameCard, PlayerHand, TargetType};

/// 取得所有 MVP 卡牌
pub fn get_mvp_cards() -> Vec<GameCard> {
    vec![
        // === 通用對策卡 ===
        
        // 質詢 - 基礎攻擊卡
        GameCard {
            id: "common_interrogate".to_string(),
            name: "質詢".to_string(),
            description: "對目標議員提出尖銳質詢，造成 15 點聲望傷害。".to_string(),
            card_type: CardType::Attack,
            rarity: CardRarity::Normal,
            target_type: TargetType::SingleEnemy,
            influence_cost: 3,
            gold_cost: 0,
            base_value: 15,
            role_id: None,
        },
        
        // 反駁 - 基礎防禦卡
        GameCard {
            id: "common_rebut".to_string(),
            name: "反駁".to_string(),
            description: "抵消一次針對你的質詢攻擊。".to_string(),
            card_type: CardType::Defense,
            rarity: CardRarity::Normal,
            target_type: TargetType::SelfTarget,
            influence_cost: 2,
            gold_cost: 0,
            base_value: 0,
            role_id: None,
        },
        
        // 揭露醜聞 - 強力攻擊卡
        GameCard {
            id: "common_expose_scandal".to_string(),
            name: "揭露醜聞".to_string(),
            description: "揭露目標的不光彩過去，造成 25 點聲望傷害。".to_string(),
            card_type: CardType::Attack,
            rarity: CardRarity::Rare,
            target_type: TargetType::SingleEnemy,
            influence_cost: 5,
            gold_cost: 0,
            base_value: 25,
            role_id: None,
        },
        
        // 背書 - 治療/復活卡
        GameCard {
            id: "common_endorse".to_string(),
            name: "背書".to_string(),
            description: "公開支持目標議員，恢復 20 點聲望。可復活政治死亡的盟友。".to_string(),
            card_type: CardType::Utility,
            rarity: CardRarity::Rare,
            target_type: TargetType::SingleAny,
            influence_cost: 4,
            gold_cost: 0,
            base_value: 20,
            role_id: None,
        },
        
        // === 角色專屬卡 ===
        
        // 工人湯瑪斯 - 團結
        GameCard {
            id: "thomas_unity".to_string(),
            name: "團結".to_string(),
            description: "每有 1 名工人盟友，你獲得的防禦效果 +10。".to_string(),
            card_type: CardType::Signature,
            rarity: CardRarity::SuperRare,
            target_type: TargetType::SelfTarget,
            influence_cost: 3,
            gold_cost: 0,
            base_value: 10,
            role_id: Some("thomas".to_string()),
        },
        
        // 工廠主理查 - 收買
        GameCard {
            id: "richard_bribe".to_string(),
            name: "收買".to_string(),
            description: "花費 30 金幣使目標沉默 1 回合，無法發言和使用攻擊卡。".to_string(),
            card_type: CardType::Signature,
            rarity: CardRarity::SuperRare,
            target_type: TargetType::SingleEnemy,
            influence_cost: 2,
            gold_cost: 30,
            base_value: 0,
            role_id: Some("richard".to_string()),
        },
        
        // 記者愛德華 - 爆料
        GameCard {
            id: "edward_scoop".to_string(),
            name: "爆料".to_string(),
            description: "揭露目標的秘密任務。若目標有隱藏身份，公開之。".to_string(),
            card_type: CardType::Signature,
            rarity: CardRarity::SuperRare,
            target_type: TargetType::SingleEnemy,
            influence_cost: 4,
            gold_cost: 0,
            base_value: 0,
            role_id: Some("edward".to_string()),
        },
        
        // 盧德派喬治 - 怒火
        GameCard {
            id: "george_fury".to_string(),
            name: "怒火".to_string(),
            description: "造成雙倍傷害（30 點），但自己也扣 10 聲望。".to_string(),
            card_type: CardType::Signature,
            rarity: CardRarity::SuperRare,
            target_type: TargetType::SingleEnemy,
            influence_cost: 4,
            gold_cost: 0,
            base_value: 30,
            role_id: Some("george".to_string()),
        },
    ]
}

/// 取得通用卡牌
pub fn get_common_cards() -> Vec<GameCard> {
    get_mvp_cards()
        .into_iter()
        .filter(|c| c.role_id.is_none())
        .collect()
}

/// 取得角色專屬卡
pub fn get_signature_cards(role_id: &str) -> Vec<GameCard> {
    get_mvp_cards()
        .into_iter()
        .filter(|c| c.role_id.as_deref() == Some(role_id))
        .collect()
}

/// 根據 ID 取得卡牌
pub fn get_card_by_id(card_id: &str) -> Option<GameCard> {
    get_mvp_cards().into_iter().find(|c| c.id == card_id)
}

/// 建立初始手牌
pub fn create_starting_hand(role_id: &str) -> PlayerHand {
    let mut hand = PlayerHand::new();
    
    // 2 張質詢
    if let Some(card) = get_card_by_id("common_interrogate") {
        let mut card1 = card.clone();
        card1.id = format!("{}_1", card.id);
        hand.add_card(card1);
        
        let mut card2 = card;
        card2.id = format!("{}_2", card2.id);
        hand.add_card(card2);
    }
    
    // 2 張反駁
    if let Some(card) = get_card_by_id("common_rebut") {
        let mut card1 = card.clone();
        card1.id = format!("{}_1", card.id);
        hand.add_card(card1);
        
        let mut card2 = card;
        card2.id = format!("{}_2", card2.id);
        hand.add_card(card2);
    }
    
    // 1 張背書
    if let Some(mut card) = get_card_by_id("common_endorse") {
        card.id = format!("{}_1", card.id);
        hand.add_card(card);
    }
    
    // 1 張角色專屬卡
    let signature_cards = get_signature_cards(role_id);
    if let Some(mut card) = signature_cards.into_iter().next() {
        card.id = format!("{}_1", card.id);
        hand.add_card(card);
    }
    
    hand
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mvp_cards_count() {
        let cards = get_mvp_cards();
        assert_eq!(cards.len(), 8);
    }

    #[test]
    fn test_common_cards_count() {
        let cards = get_common_cards();
        assert_eq!(cards.len(), 4);
    }

    #[test]
    fn test_starting_hand() {
        let hand = create_starting_hand("thomas");
        assert_eq!(hand.count(), 6);
    }

    #[test]
    fn test_signature_card() {
        let cards = get_signature_cards("thomas");
        assert_eq!(cards.len(), 1);
        assert_eq!(cards[0].name, "團結");
    }
}
