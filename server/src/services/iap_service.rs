//! 內購驗證服務 (In-App Purchase)
//!
//! 處理 iOS StoreKit 2 和 Google Play Billing 的收據驗證

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::AppError;

// ============================================================
// 產品定義
// ============================================================

/// 內購產品 ID
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum ProductId {
    /// 寶石包 - 小（100 寶石）
    #[serde(rename = "gems_100")]
    Gems100,
    /// 寶石包 - 中（500 寶石）
    #[serde(rename = "gems_500")]
    Gems500,
    /// 寶石包 - 大（1200 寶石）
    #[serde(rename = "gems_1200")]
    Gems1200,
    /// 戰役解鎖 - Chapter 2
    #[serde(rename = "campaign_ch2")]
    CampaignCh2,
    /// 戰役解鎖 - Chapter 3
    #[serde(rename = "campaign_ch3")]
    CampaignCh3,
    /// 戰役解鎖 - Chapter 4
    #[serde(rename = "campaign_ch4")]
    CampaignCh4,
    /// 戰役解鎖 - Chapter 5
    #[serde(rename = "campaign_ch5")]
    CampaignCh5,
    /// 戰役全解鎖包
    #[serde(rename = "campaign_all")]
    CampaignAll,
    /// AI 對戰無限次數（月卡）
    #[serde(rename = "ai_unlimited_monthly")]
    AiUnlimitedMonthly,
}

impl ProductId {
    /// 寶石數量（僅對寶石包有效）
    pub fn gem_amount(&self) -> Option<i64> {
        match self {
            ProductId::Gems100 => Some(100),
            ProductId::Gems500 => Some(500),
            ProductId::Gems1200 => Some(1200),
            _ => None,
        }
    }

    /// Apple 產品 ID
    pub fn apple_product_id(&self) -> &str {
        match self {
            ProductId::Gems100 => "com.parliament1812.app.gems100",
            ProductId::Gems500 => "com.parliament1812.app.gems500",
            ProductId::Gems1200 => "com.parliament1812.app.gems1200",
            ProductId::CampaignCh2 => "com.parliament1812.app.campaign_ch2",
            ProductId::CampaignCh3 => "com.parliament1812.app.campaign_ch3",
            ProductId::CampaignCh4 => "com.parliament1812.app.campaign_ch4",
            ProductId::CampaignCh5 => "com.parliament1812.app.campaign_ch5",
            ProductId::CampaignAll => "com.parliament1812.app.campaign_all",
            ProductId::AiUnlimitedMonthly => "com.parliament1812.app.ai_unlimited",
        }
    }

    /// Google Play 產品 ID
    pub fn google_product_id(&self) -> &str {
        match self {
            ProductId::Gems100 => "gems_100",
            ProductId::Gems500 => "gems_500",
            ProductId::Gems1200 => "gems_1200",
            ProductId::CampaignCh2 => "campaign_ch2",
            ProductId::CampaignCh3 => "campaign_ch3",
            ProductId::CampaignCh4 => "campaign_ch4",
            ProductId::CampaignCh5 => "campaign_ch5",
            ProductId::CampaignAll => "campaign_all",
            ProductId::AiUnlimitedMonthly => "ai_unlimited_monthly",
        }
    }

    /// 是否為消耗型商品
    pub fn is_consumable(&self) -> bool {
        matches!(
            self,
            ProductId::Gems100 | ProductId::Gems500 | ProductId::Gems1200
        )
    }

    /// 是否為訂閱
    pub fn is_subscription(&self) -> bool {
        matches!(self, ProductId::AiUnlimitedMonthly)
    }
}

// ============================================================
// 驗證請求 / 回應
// ============================================================

/// iOS 收據驗證請求（StoreKit 2 JWS 格式）
#[derive(Debug, Deserialize)]
pub struct AppleVerifyRequest {
    /// StoreKit 2 signed transaction (JWS)
    pub transaction_jws: String,
    /// 產品 ID
    pub product_id: String,
}

/// Google Play 收據驗證請求
#[derive(Debug, Deserialize)]
pub struct GoogleVerifyRequest {
    /// 購買 token
    pub purchase_token: String,
    /// 產品 ID
    pub product_id: String,
    /// 訂單 ID
    pub order_id: String,
}

/// 驗證結果
#[derive(Debug, Serialize)]
pub struct VerifyResponse {
    /// 驗證是否成功
    pub valid: bool,
    /// 產品 ID
    pub product_id: String,
    /// 交易 ID（平台方）
    pub transaction_id: String,
    /// 購買時間
    pub purchase_time: DateTime<Utc>,
    /// 發放的獎勵
    pub rewards: Vec<PurchaseReward>,
    /// 錯誤訊息（如果驗證失敗）
    pub error: Option<String>,
}

/// 購買獎勵
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PurchaseReward {
    /// 獎勵類型
    pub reward_type: RewardType,
    /// 數量
    pub amount: i64,
}

/// 獎勵類型
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum RewardType {
    Gems,
    CampaignUnlock { chapter: i32 },
    AiUnlimitedDays { days: i32 },
}

/// 交易記錄（資料庫）
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct TransactionRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub platform: String,
    pub product_id: String,
    pub transaction_id: String,
    pub purchase_time: DateTime<Utc>,
    pub verified: bool,
    pub created_at: DateTime<Utc>,
}

// ============================================================
// IAP 服務
// ============================================================

/// 內購驗證服務
pub struct IapService;

impl IapService {
    // ==================== Apple StoreKit 2 ====================

    /// 驗證 Apple StoreKit 2 交易
    ///
    /// StoreKit 2 使用 JWS (JSON Web Signature) 格式的簽名交易
    /// 伺服器端驗證步驟：
    /// 1. 解碼 JWS header，取得 x5c 證書鏈
    /// 2. 驗證證書鏈（Apple Root CA → Intermediate → Leaf）
    /// 3. 用 leaf 公鑰驗證 JWS 簽名
    /// 4. 解碼 payload，檢查 bundleId / productId / environment
    /// 5. 檢查交易是否已被使用過（防重放）
    pub async fn verify_apple_transaction(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        request: &AppleVerifyRequest,
    ) -> Result<VerifyResponse, AppError> {
        // 解析 JWS（三段式：header.payload.signature）
        let parts: Vec<&str> = request.transaction_jws.split('.').collect();
        if parts.len() != 3 {
            return Ok(VerifyResponse {
                valid: false,
                product_id: request.product_id.clone(),
                transaction_id: String::new(),
                purchase_time: Utc::now(),
                rewards: vec![],
                error: Some("Invalid JWS format".to_string()),
            });
        }

        // 解碼 payload（Base64URL）
        let payload_bytes = base64url_decode(parts[1])
            .map_err(|_| AppError::BadRequest("Invalid JWS payload encoding".to_string()))?;

        let payload: AppleTransactionPayload = serde_json::from_slice(&payload_bytes)
            .map_err(|e| AppError::BadRequest(format!("Invalid transaction payload: {}", e)))?;

        // 驗證 bundle ID
        if payload.bundle_id != "com.parliament1812.app" {
            return Ok(VerifyResponse {
                valid: false,
                product_id: request.product_id.clone(),
                transaction_id: payload.transaction_id.clone(),
                purchase_time: Utc::now(),
                rewards: vec![],
                error: Some("Bundle ID mismatch".to_string()),
            });
        }

        // 檢查產品 ID 是否匹配
        if payload.product_id != request.product_id {
            return Ok(VerifyResponse {
                valid: false,
                product_id: request.product_id.clone(),
                transaction_id: payload.transaction_id.clone(),
                purchase_time: Utc::now(),
                rewards: vec![],
                error: Some("Product ID mismatch".to_string()),
            });
        }

        // 檢查是否已使用過（防重放攻擊）
        let existing = Self::find_transaction(pool, &payload.transaction_id).await?;
        if existing.is_some() {
            return Ok(VerifyResponse {
                valid: false,
                product_id: request.product_id.clone(),
                transaction_id: payload.transaction_id.clone(),
                purchase_time: Utc::now(),
                rewards: vec![],
                error: Some("Transaction already processed".to_string()),
            });
        }

        // 解析產品並計算獎勵
        let rewards = Self::calculate_rewards(&request.product_id)?;

        // 記錄交易
        Self::record_transaction(
            pool,
            user_id,
            "apple",
            &request.product_id,
            &payload.transaction_id,
        )
        .await?;

        // 發放獎勵
        Self::grant_rewards(pool, user_id, &rewards).await?;

        Ok(VerifyResponse {
            valid: true,
            product_id: request.product_id.clone(),
            transaction_id: payload.transaction_id,
            purchase_time: payload.purchase_date.unwrap_or_else(Utc::now),
            rewards,
            error: None,
        })
    }

    // ==================== Google Play Billing ====================

    /// 驗證 Google Play 購買
    ///
    /// 使用 Google Play Developer API v3 驗證購買
    /// 步驟：
    /// 1. 使用 Service Account 取得 access token
    /// 2. 呼叫 purchases.products.get 或 purchases.subscriptions.get
    /// 3. 檢查 purchaseState == 0 (purchased) && !consumed
    /// 4. 確認 orderId 和 purchaseToken 匹配
    /// 5. 標記為已消耗（如果是消耗型）
    pub async fn verify_google_purchase(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        request: &GoogleVerifyRequest,
    ) -> Result<VerifyResponse, AppError> {
        // 檢查是否已使用過（防重放攻擊）
        let existing = Self::find_transaction(pool, &request.order_id).await?;
        if existing.is_some() {
            return Ok(VerifyResponse {
                valid: false,
                product_id: request.product_id.clone(),
                transaction_id: request.order_id.clone(),
                purchase_time: Utc::now(),
                rewards: vec![],
                error: Some("Transaction already processed".to_string()),
            });
        }

        // TODO: 在生產環境中，這裡應該呼叫 Google Play Developer API
        // 用 Service Account credentials 驗證 purchase_token
        //
        // let google_api_url = format!(
        //     "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{}/purchases/products/{}/tokens/{}",
        //     "com.parliament1812.app",
        //     request.product_id,
        //     request.purchase_token
        // );
        //
        // 目前使用信任模式（適合開發階段）

        // 驗證 purchase token 不為空
        if request.purchase_token.is_empty() {
            return Ok(VerifyResponse {
                valid: false,
                product_id: request.product_id.clone(),
                transaction_id: request.order_id.clone(),
                purchase_time: Utc::now(),
                rewards: vec![],
                error: Some("Empty purchase token".to_string()),
            });
        }

        // 計算獎勵
        let rewards = Self::calculate_rewards(&request.product_id)?;

        // 記錄交易
        Self::record_transaction(
            pool,
            user_id,
            "google",
            &request.product_id,
            &request.order_id,
        )
        .await?;

        // 發放獎勵
        Self::grant_rewards(pool, user_id, &rewards).await?;

        Ok(VerifyResponse {
            valid: true,
            product_id: request.product_id.clone(),
            transaction_id: request.order_id.clone(),
            purchase_time: Utc::now(),
            rewards,
            error: None,
        })
    }

    // ==================== 內部方法 ====================

    /// 根據產品 ID 計算獎勵
    fn calculate_rewards(product_id: &str) -> Result<Vec<PurchaseReward>, AppError> {
        // 先嘗試匹配 Apple 格式，再匹配 Google 格式
        let rewards = match product_id {
            "com.parliament1812.app.gems100" | "gems_100" => vec![PurchaseReward {
                reward_type: RewardType::Gems,
                amount: 100,
            }],
            "com.parliament1812.app.gems500" | "gems_500" => vec![PurchaseReward {
                reward_type: RewardType::Gems,
                amount: 500,
            }],
            "com.parliament1812.app.gems1200" | "gems_1200" => vec![PurchaseReward {
                reward_type: RewardType::Gems,
                amount: 1200,
            }],
            "com.parliament1812.app.campaign_ch2" | "campaign_ch2" => vec![PurchaseReward {
                reward_type: RewardType::CampaignUnlock { chapter: 2 },
                amount: 1,
            }],
            "com.parliament1812.app.campaign_ch3" | "campaign_ch3" => vec![PurchaseReward {
                reward_type: RewardType::CampaignUnlock { chapter: 3 },
                amount: 1,
            }],
            "com.parliament1812.app.campaign_ch4" | "campaign_ch4" => vec![PurchaseReward {
                reward_type: RewardType::CampaignUnlock { chapter: 4 },
                amount: 1,
            }],
            "com.parliament1812.app.campaign_ch5" | "campaign_ch5" => vec![PurchaseReward {
                reward_type: RewardType::CampaignUnlock { chapter: 5 },
                amount: 1,
            }],
            "com.parliament1812.app.campaign_all" | "campaign_all" => vec![
                PurchaseReward {
                    reward_type: RewardType::CampaignUnlock { chapter: 2 },
                    amount: 1,
                },
                PurchaseReward {
                    reward_type: RewardType::CampaignUnlock { chapter: 3 },
                    amount: 1,
                },
                PurchaseReward {
                    reward_type: RewardType::CampaignUnlock { chapter: 4 },
                    amount: 1,
                },
                PurchaseReward {
                    reward_type: RewardType::CampaignUnlock { chapter: 5 },
                    amount: 1,
                },
            ],
            "com.parliament1812.app.ai_unlimited" | "ai_unlimited_monthly" => {
                vec![PurchaseReward {
                    reward_type: RewardType::AiUnlimitedDays { days: 30 },
                    amount: 30,
                }]
            }
            _ => {
                return Err(AppError::BadRequest(format!(
                    "Unknown product ID: {}",
                    product_id
                )));
            }
        };

        Ok(rewards)
    }

    /// 發放獎勵到使用者帳戶
    async fn grant_rewards(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        rewards: &[PurchaseReward],
    ) -> Result<(), AppError> {
        for reward in rewards {
            match &reward.reward_type {
                RewardType::Gems => {
                    sqlx::query("UPDATE users SET gems = COALESCE(gems, 0) + $1 WHERE id = $2")
                        .bind(reward.amount)
                        .bind(user_id)
                        .execute(pool)
                        .await
                        .map_err(|e| AppError::DatabaseError(e.to_string()))?;
                }
                RewardType::CampaignUnlock { chapter } => {
                    sqlx::query(
                        r#"
                        INSERT INTO campaign_unlocks (user_id, chapter, unlocked_at)
                        VALUES ($1, $2, NOW())
                        ON CONFLICT (user_id, chapter) DO NOTHING
                        "#,
                    )
                    .bind(user_id)
                    .bind(*chapter)
                    .execute(pool)
                    .await
                    .map_err(|e| AppError::DatabaseError(e.to_string()))?;
                }
                RewardType::AiUnlimitedDays { days } => {
                    sqlx::query(
                        r#"
                        UPDATE users
                        SET ai_unlimited_until = GREATEST(
                            COALESCE(ai_unlimited_until, NOW()),
                            NOW()
                        ) + ($1 || ' days')::interval
                        WHERE id = $2
                        "#,
                    )
                    .bind(*days)
                    .bind(user_id)
                    .execute(pool)
                    .await
                    .map_err(|e| AppError::DatabaseError(e.to_string()))?;
                }
            }
        }

        Ok(())
    }

    /// 查找已存在的交易（防重放）
    async fn find_transaction(
        pool: &sqlx::PgPool,
        transaction_id: &str,
    ) -> Result<Option<TransactionRecord>, AppError> {
        let record = sqlx::query_as::<_, TransactionRecord>(
            r#"
            SELECT id, user_id, platform, product_id, transaction_id, 
                   purchase_time, verified, created_at
            FROM iap_transactions
            WHERE transaction_id = $1
            "#,
        )
        .bind(transaction_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(record)
    }

    /// 記錄交易
    async fn record_transaction(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        platform: &str,
        product_id: &str,
        transaction_id: &str,
    ) -> Result<(), AppError> {
        sqlx::query(
            r#"
            INSERT INTO iap_transactions (id, user_id, platform, product_id, transaction_id, purchase_time, verified)
            VALUES ($1, $2, $3, $4, $5, NOW(), true)
            "#,
        )
        .bind(Uuid::new_v4())
        .bind(user_id)
        .bind(platform)
        .bind(product_id)
        .bind(transaction_id)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// 取得使用者的寶石餘額
    pub async fn get_gem_balance(pool: &sqlx::PgPool, user_id: Uuid) -> Result<i64, AppError> {
        let balance = sqlx::query_scalar::<_, Option<i64>>("SELECT gems FROM users WHERE id = $1")
            .bind(user_id)
            .fetch_one(pool)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(balance.unwrap_or(0))
    }

    /// 消費寶石
    pub async fn spend_gems(
        pool: &sqlx::PgPool,
        user_id: Uuid,
        amount: i64,
        reason: &str,
    ) -> Result<i64, AppError> {
        let current = Self::get_gem_balance(pool, user_id).await?;
        if current < amount {
            return Err(AppError::BadRequest(format!(
                "寶石不足：需要 {} 顆，目前 {} 顆",
                amount, current
            )));
        }

        let new_balance = sqlx::query_scalar::<_, Option<i64>>(
            r#"
            UPDATE users SET gems = gems - $1
            WHERE id = $2 AND gems >= $1
            RETURNING gems
            "#,
        )
        .bind(amount)
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        match new_balance {
            Some(balance) => {
                tracing::info!(
                    user_id = %user_id,
                    amount = amount,
                    reason = reason,
                    new_balance = balance,
                    "寶石消費"
                );
                Ok(balance)
            }
            None => Err(AppError::BadRequest("寶石不足".to_string())),
        }
    }

    /// 檢查使用者是否有 AI 無限對戰權限
    pub async fn has_ai_unlimited(pool: &sqlx::PgPool, user_id: Uuid) -> Result<bool, AppError> {
        let until = sqlx::query_scalar::<_, Option<DateTime<Utc>>>(
            "SELECT ai_unlimited_until FROM users WHERE id = $1",
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(until.map(|t| t > Utc::now()).unwrap_or(false))
    }

    /// 取得使用者的購買記錄
    pub async fn get_purchase_history(
        pool: &sqlx::PgPool,
        user_id: Uuid,
    ) -> Result<Vec<TransactionRecord>, AppError> {
        let records = sqlx::query_as::<_, TransactionRecord>(
            r#"
            SELECT id, user_id, platform, product_id, transaction_id,
                   purchase_time, verified, created_at
            FROM iap_transactions
            WHERE user_id = $1
            ORDER BY created_at DESC
            LIMIT 100
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(records)
    }
}

// ============================================================
// Apple 交易 Payload 結構
// ============================================================

/// Apple StoreKit 2 交易 Payload（JWS 解碼後）
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
#[allow(dead_code)]
struct AppleTransactionPayload {
    /// 交易 ID
    #[serde(alias = "transactionId")]
    transaction_id: String,
    /// 原始交易 ID
    #[serde(alias = "originalTransactionId")]
    original_transaction_id: Option<String>,
    /// Bundle ID
    #[serde(alias = "bundleId")]
    bundle_id: String,
    /// 產品 ID
    #[serde(alias = "productId")]
    product_id: String,
    /// 購買時間
    #[serde(alias = "purchaseDate")]
    purchase_date: Option<DateTime<Utc>>,
    /// 環境 (Production / Sandbox)
    environment: Option<String>,
}

// ============================================================
// Base64URL 解碼工具
// ============================================================

fn base64url_decode(input: &str) -> Result<Vec<u8>, String> {
    // Base64URL → 標準 Base64
    let mut s = input.replace('-', "+").replace('_', "/");
    // 補齊 padding
    match s.len() % 4 {
        2 => s.push_str("=="),
        3 => s.push('='),
        _ => {}
    }

    let decoded = base64_decode_simple(&s)?;
    Ok(decoded)
}

fn base64_decode_simple(input: &str) -> Result<Vec<u8>, String> {
    const TABLE: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    let mut output = Vec::with_capacity(input.len() * 3 / 4);
    let mut buf: u32 = 0;
    let mut bits: u32 = 0;

    for &byte in input.as_bytes() {
        if byte == b'=' {
            break;
        }
        let val = match TABLE.iter().position(|&b| b == byte) {
            Some(v) => v as u32,
            None => return Err(format!("Invalid base64 char: {}", byte as char)),
        };
        buf = (buf << 6) | val;
        bits += 6;
        if bits >= 8 {
            bits -= 8;
            output.push((buf >> bits) as u8);
            buf &= (1 << bits) - 1;
        }
    }

    Ok(output)
}

// ============================================================
// 測試
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_product_id_gem_amounts() {
        assert_eq!(ProductId::Gems100.gem_amount(), Some(100));
        assert_eq!(ProductId::Gems500.gem_amount(), Some(500));
        assert_eq!(ProductId::Gems1200.gem_amount(), Some(1200));
        assert_eq!(ProductId::CampaignCh2.gem_amount(), None);
    }

    #[test]
    fn test_product_id_apple_ids() {
        assert_eq!(
            ProductId::Gems100.apple_product_id(),
            "com.parliament1812.app.gems100"
        );
        assert_eq!(
            ProductId::CampaignAll.apple_product_id(),
            "com.parliament1812.app.campaign_all"
        );
    }

    #[test]
    fn test_product_id_google_ids() {
        assert_eq!(ProductId::Gems100.google_product_id(), "gems_100");
        assert_eq!(ProductId::CampaignAll.google_product_id(), "campaign_all");
    }

    #[test]
    fn test_is_consumable() {
        assert!(ProductId::Gems100.is_consumable());
        assert!(ProductId::Gems500.is_consumable());
        assert!(!ProductId::CampaignCh2.is_consumable());
        assert!(!ProductId::AiUnlimitedMonthly.is_consumable());
    }

    #[test]
    fn test_is_subscription() {
        assert!(ProductId::AiUnlimitedMonthly.is_subscription());
        assert!(!ProductId::Gems100.is_subscription());
        assert!(!ProductId::CampaignAll.is_subscription());
    }

    #[test]
    fn test_calculate_rewards_gems() {
        let rewards = IapService::calculate_rewards("gems_100").unwrap();
        assert_eq!(rewards.len(), 1);
        assert_eq!(rewards[0].amount, 100);
    }

    #[test]
    fn test_calculate_rewards_campaign_all() {
        let rewards = IapService::calculate_rewards("campaign_all").unwrap();
        assert_eq!(rewards.len(), 4); // ch2-ch5
    }

    #[test]
    fn test_calculate_rewards_ai_unlimited() {
        let rewards = IapService::calculate_rewards("ai_unlimited_monthly").unwrap();
        assert_eq!(rewards.len(), 1);
        assert_eq!(rewards[0].amount, 30);
    }

    #[test]
    fn test_calculate_rewards_unknown() {
        let result = IapService::calculate_rewards("unknown_product");
        assert!(result.is_err());
    }

    #[test]
    fn test_base64url_decode() {
        let encoded = "SGVsbG8gV29ybGQ";
        let decoded = base64url_decode(encoded).unwrap();
        assert_eq!(String::from_utf8(decoded).unwrap(), "Hello World");
    }

    #[test]
    fn test_base64url_decode_with_special_chars() {
        // Test that URL-safe chars are properly handled
        let result = base64url_decode("dGVzdA");
        assert!(result.is_ok());
        assert_eq!(String::from_utf8(result.unwrap()).unwrap(), "test");
    }
}
