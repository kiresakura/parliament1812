//! ELO 評分引擎
//!
//! 標準 ELO 計算，支援多人（4人）場景。
//! - K=40（前30場），K=20（之後）
//! - Floor 800, Ceiling 2400
//! - 多人場：每人與其他3人分別算，取平均 delta

/// ELO 評分的下限
pub const ELO_FLOOR: i32 = 800;
/// ELO 評分的上限
pub const ELO_CEILING: i32 = 2400;
/// 新手 K 值（前 30 場）
const K_FACTOR_NEW: f64 = 40.0;
/// 老手 K 值
const K_FACTOR_VETERAN: f64 = 20.0;
/// 新手場次門檻
const NEWBIE_THRESHOLD: i32 = 30;

/// 取得 K 值
fn k_factor(games_played: i32) -> f64 {
    if games_played < NEWBIE_THRESHOLD {
        K_FACTOR_NEW
    } else {
        K_FACTOR_VETERAN
    }
}

/// 計算預期勝率 (expected score)
fn expected_score(rating_a: i32, rating_b: i32) -> f64 {
    1.0 / (1.0 + 10.0_f64.powf((rating_b as f64 - rating_a as f64) / 400.0))
}

/// 將 ELO 鉗制在 [FLOOR, CEILING] 之間
fn clamp_elo(elo: i32) -> i32 {
    elo.clamp(ELO_FLOOR, ELO_CEILING)
}

/// 1v1 ELO 計算結果
#[derive(Debug, Clone, PartialEq)]
pub struct EloChange {
    /// 新的 ELO 評分
    pub new_rating: i32,
    /// 變化量
    pub delta: i32,
}

/// 計算 1v1 ELO 變化
///
/// # Arguments
/// * `rating` - 玩家當前 ELO
/// * `opponent_rating` - 對手 ELO
/// * `score` - 實際得分（1.0 = 勝，0.5 = 平，0.0 = 敗）
/// * `games_played` - 已完成場次（決定 K 值）
pub fn calculate_1v1(
    rating: i32,
    opponent_rating: i32,
    score: f64,
    games_played: i32,
) -> EloChange {
    let k = k_factor(games_played);
    let expected = expected_score(rating, opponent_rating);
    let delta = (k * (score - expected)).round() as i32;
    let new_rating = clamp_elo(rating + delta);

    EloChange {
        new_rating,
        delta: new_rating - rating,
    }
}

/// 多人遊戲的玩家資訊
#[derive(Debug, Clone)]
pub struct MultiPlayerInfo {
    /// 玩家索引（用於識別）
    pub index: usize,
    /// 當前 ELO
    pub rating: i32,
    /// 已玩場次
    pub games_played: i32,
    /// 最終排名（1 = 第一名）
    pub placement: u32,
}

/// 多人遊戲 ELO 計算結果
#[derive(Debug, Clone, PartialEq)]
pub struct MultiEloChange {
    /// 玩家索引
    pub index: usize,
    /// 新的 ELO 評分
    pub new_rating: i32,
    /// 變化量
    pub delta: i32,
}

/// 計算多人遊戲（4人）的 ELO 變化
///
/// 每人與其他所有人分別計算 1v1，然後取平均 delta。
/// 排名較高（數字較小）的玩家得分 1.0，較低的得分 0.0，
/// 相同排名得 0.5。
///
/// # Arguments
/// * `players` - 所有參與者資訊
///
/// # Returns
/// 每個玩家的 ELO 變化
pub fn calculate_multiplayer(players: &[MultiPlayerInfo]) -> Vec<MultiEloChange> {
    let n = players.len();
    if n < 2 {
        return players
            .iter()
            .map(|p| MultiEloChange {
                index: p.index,
                new_rating: p.rating,
                delta: 0,
            })
            .collect();
    }

    let mut results = Vec::with_capacity(n);

    for i in 0..n {
        let k = k_factor(players[i].games_played);
        let mut total_delta = 0.0;

        for j in 0..n {
            if i == j {
                continue;
            }

            // 根據排名決定得分
            let score = if players[i].placement < players[j].placement {
                1.0 // i 排名更高（數字更小）
            } else if players[i].placement > players[j].placement {
                0.0
            } else {
                0.5 // 同排名
            };

            let expected = expected_score(players[i].rating, players[j].rating);
            total_delta += k * (score - expected);
        }

        // 取平均
        let avg_delta = (total_delta / (n - 1) as f64).round() as i32;
        let new_rating = clamp_elo(players[i].rating + avg_delta);

        results.push(MultiEloChange {
            index: players[i].index,
            new_rating,
            delta: new_rating - players[i].rating,
        });
    }

    results
}

/// 賽季重置時，ELO 往 1000 收縮 50%
pub fn season_reset_elo(current_elo: i32) -> i32 {
    let target = 1000;
    let new_elo = current_elo + ((target - current_elo) as f64 * 0.5).round() as i32;
    clamp_elo(new_elo)
}

/// 計算 AI 場的 ELO 權重調整（50% 權重）
pub fn apply_ai_weight(delta: i32) -> i32 {
    (delta as f64 * 0.5).round() as i32
}

// ============================================================
// Tests
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_1v1_win_against_equal() {
        // 相同 ELO 贏了，應該得到正的 delta
        let result = calculate_1v1(1000, 1000, 1.0, 0);
        assert!(result.delta > 0);
        assert_eq!(result.delta, 20); // K=40, expected=0.5, delta = 40*(1.0-0.5) = 20
        assert_eq!(result.new_rating, 1020);
    }

    #[test]
    fn test_1v1_loss_against_equal() {
        let result = calculate_1v1(1000, 1000, 0.0, 0);
        assert!(result.delta < 0);
        assert_eq!(result.delta, -20);
        assert_eq!(result.new_rating, 980);
    }

    #[test]
    fn test_1v1_veteran_k_factor() {
        // 30 場以上用 K=20
        let result = calculate_1v1(1000, 1000, 1.0, 30);
        assert_eq!(result.delta, 10); // K=20, expected=0.5, delta = 20*(1.0-0.5) = 10
    }

    #[test]
    fn test_1v1_upset_win() {
        // 弱者打敗強者，獲得更多分
        let weak = calculate_1v1(1000, 1400, 1.0, 0);
        let equal = calculate_1v1(1000, 1000, 1.0, 0);
        assert!(weak.delta > equal.delta);
    }

    #[test]
    fn test_elo_floor_ceiling() {
        // 不應低於 floor
        let result = calculate_1v1(810, 2000, 0.0, 0);
        assert!(result.new_rating >= ELO_FLOOR);

        // 不應高於 ceiling
        let result = calculate_1v1(2390, 800, 1.0, 0);
        assert!(result.new_rating <= ELO_CEILING);
    }

    #[test]
    fn test_multiplayer_4_players() {
        let players = vec![
            MultiPlayerInfo {
                index: 0,
                rating: 1000,
                games_played: 0,
                placement: 1,
            },
            MultiPlayerInfo {
                index: 1,
                rating: 1000,
                games_played: 0,
                placement: 2,
            },
            MultiPlayerInfo {
                index: 2,
                rating: 1000,
                games_played: 0,
                placement: 3,
            },
            MultiPlayerInfo {
                index: 3,
                rating: 1000,
                games_played: 0,
                placement: 4,
            },
        ];

        let results = calculate_multiplayer(&players);
        assert_eq!(results.len(), 4);

        // 第一名 delta > 0
        assert!(results[0].delta > 0, "1st place should gain ELO");
        // 最後一名 delta < 0
        assert!(results[3].delta < 0, "Last place should lose ELO");
        // 總 delta 大致為零（零和博弈）
        let total_delta: i32 = results.iter().map(|r| r.delta).sum();
        assert!(
            total_delta.abs() <= 4,
            "Total delta should be near zero, got {}",
            total_delta
        );
    }

    #[test]
    fn test_multiplayer_mixed_ratings() {
        let players = vec![
            MultiPlayerInfo {
                index: 0,
                rating: 1200,
                games_played: 50,
                placement: 1,
            },
            MultiPlayerInfo {
                index: 1,
                rating: 1000,
                games_played: 10,
                placement: 2,
            },
            MultiPlayerInfo {
                index: 2,
                rating: 800,
                games_played: 5,
                placement: 3,
            },
            MultiPlayerInfo {
                index: 3,
                rating: 1400,
                games_played: 100,
                placement: 4,
            },
        ];

        let results = calculate_multiplayer(&players);
        assert_eq!(results.len(), 4);

        // 1400 ELO 輸到最後一名，應該扣很多分
        let high_rated_loser = &results[3];
        assert!(high_rated_loser.delta < 0);

        // 800 ELO 贏了 1400 的（排名更高），所以 delta 不會很負
        // index=2 placement=3, so lost to 0 & 1, but beat 3
    }

    #[test]
    fn test_season_reset() {
        // 1200 -> 1200 + (1000-1200)*0.5 = 1200 - 100 = 1100
        assert_eq!(season_reset_elo(1200), 1100);
        // 800 -> 800 + (1000-800)*0.5 = 800 + 100 = 900
        assert_eq!(season_reset_elo(800), 900);
        // 1000 stays 1000
        assert_eq!(season_reset_elo(1000), 1000);
        // 2000 -> 2000 + (1000-2000)*0.5 = 2000 - 500 = 1500
        assert_eq!(season_reset_elo(2000), 1500);
    }

    #[test]
    fn test_ai_weight() {
        assert_eq!(apply_ai_weight(20), 10);
        assert_eq!(apply_ai_weight(-20), -10);
        assert_eq!(apply_ai_weight(0), 0);
        // Odd numbers round properly
        assert_eq!(apply_ai_weight(15), 8); // 7.5 -> 8
    }

    #[test]
    fn test_expected_score_symmetric() {
        // 相同 ELO，預期勝率應為 0.5
        let e = expected_score(1000, 1000);
        assert!((e - 0.5).abs() < 0.001);

        // A vs B + B vs A = 1.0
        let e_ab = expected_score(1200, 1000);
        let e_ba = expected_score(1000, 1200);
        assert!((e_ab + e_ba - 1.0).abs() < 0.001);
    }

    #[test]
    fn test_single_player_multiplayer() {
        // Edge case: 只有一個人不應 panic
        let players = vec![MultiPlayerInfo {
            index: 0,
            rating: 1000,
            games_played: 0,
            placement: 1,
        }];

        let results = calculate_multiplayer(&players);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].delta, 0);
    }
}
