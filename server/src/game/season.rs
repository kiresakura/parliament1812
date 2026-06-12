//! 賽季系統
//!
//! 管理排名賽季：30 天一季，新季 ELO 往 1000 收縮 50%

use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

use super::elo;

/// 賽季結構
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Season {
    pub id: i32,
    pub name: String,
    pub start_date: DateTime<Utc>,
    pub end_date: DateTime<Utc>,
    pub is_active: bool,
}

/// 賽季長度（天）
const SEASON_DURATION_DAYS: i64 = 30;

/// 取得當前活躍賽季
///
/// 如果沒有活躍賽季，回傳 None。
pub async fn get_current_season(pool: &PgPool) -> Result<Option<Season>, sqlx::Error> {
    sqlx::query_as::<_, Season>(
        r#"
        SELECT id, name, start_date, end_date, is_active
        FROM seasons
        WHERE is_active = TRUE
        LIMIT 1
        "#,
    )
    .fetch_optional(pool)
    .await
}

/// 取得所有賽季（按開始日期降序）
pub async fn get_all_seasons(pool: &PgPool) -> Result<Vec<Season>, sqlx::Error> {
    sqlx::query_as::<_, Season>(
        r#"
        SELECT id, name, start_date, end_date, is_active
        FROM seasons
        ORDER BY start_date DESC
        "#,
    )
    .fetch_all(pool)
    .await
}

/// 開始新賽季
///
/// 1. 將舊賽季設為非活躍
/// 2. 建立新賽季
/// 3. 重置所有玩家 ELO（往 1000 收縮 50%）
///
/// # Returns
/// 新建立的 Season
pub async fn start_new_season(pool: &PgPool) -> Result<Season, sqlx::Error> {
    let now = Utc::now();
    let end_date = now + Duration::days(SEASON_DURATION_DAYS);

    // 計算賽季編號
    let count = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM seasons")
        .fetch_one(pool)
        .await?;
    let season_number = count + 1;
    let name = format!("Season {}", season_number);

    // 開始事務
    let mut tx = pool.begin().await?;

    // 停用所有現行賽季
    sqlx::query("UPDATE seasons SET is_active = FALSE WHERE is_active = TRUE")
        .execute(&mut *tx)
        .await?;

    // 建立新賽季
    let season = sqlx::query_as::<_, Season>(
        r#"
        INSERT INTO seasons (name, start_date, end_date, is_active)
        VALUES ($1, $2, $3, TRUE)
        RETURNING id, name, start_date, end_date, is_active
        "#,
    )
    .bind(&name)
    .bind(now)
    .bind(end_date)
    .fetch_one(&mut *tx)
    .await?;

    // 重置所有使用者 ELO（往 1000 收縮 50%）
    // new_elo = elo + (1000 - elo) * 0.5 = elo * 0.5 + 500
    // 然後 clamp 到 [800, 2400]
    sqlx::query(
        r#"
        UPDATE users
        SET elo_rating = LEAST(
            $1,
            GREATEST(
                $2,
                ROUND(COALESCE(elo_rating, 1000) * 0.5 + 500)::INTEGER
            )
        )
        WHERE elo_rating IS NOT NULL
        "#,
    )
    .bind(elo::ELO_CEILING)
    .bind(elo::ELO_FLOOR)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;

    tracing::info!(
        season_id = season.id,
        season_name = %season.name,
        "新賽季已開始"
    );

    Ok(season)
}

/// 檢查當前賽季是否已過期，如果是則自動輪轉
///
/// 適合在 server 啟動或定期檢查時呼叫。
pub async fn check_and_rotate_season(pool: &PgPool) -> Result<Option<Season>, sqlx::Error> {
    let current = get_current_season(pool).await?;

    match current {
        Some(season) if Utc::now() >= season.end_date => {
            tracing::info!(season_id = season.id, "賽季已過期，自動開始新賽季");
            let new_season = start_new_season(pool).await?;
            Ok(Some(new_season))
        }
        None => {
            tracing::info!("沒有活躍賽季，建立第一個賽季");
            let new_season = start_new_season(pool).await?;
            Ok(Some(new_season))
        }
        Some(season) => {
            tracing::debug!(
                season_id = season.id,
                days_remaining = (season.end_date - Utc::now()).num_days(),
                "當前賽季仍在進行中"
            );
            Ok(None) // 不需要輪轉
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_season_struct() {
        let season = Season {
            id: 1,
            name: "Season 1".to_string(),
            start_date: Utc::now(),
            end_date: Utc::now() + Duration::days(30),
            is_active: true,
        };
        assert_eq!(season.id, 1);
        assert!(season.is_active);
    }

    #[test]
    fn test_season_duration() {
        assert_eq!(SEASON_DURATION_DAYS, 30);
    }
}
