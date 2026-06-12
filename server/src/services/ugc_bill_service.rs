//! 玩家自創法案服務（UGC Bill Service）
//!
//! 負責法案的建立、投票、查詢、精選等業務邏輯

use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::user_bill::{UserBill, UserBillListResponse, UserBillResponse};
use crate::error::{AppError, AppResult};

/// 有效的法案類型
const VALID_BILL_TYPES: &[&str] = &[
    "economic",
    "political",
    "social",
    "religious",
    "military",
    "colonial",
    "moral",
];

/// 玩家自創法案服務
pub struct UgcBillService;

impl UgcBillService {
    /// 建立法案
    ///
    /// 驗證輸入並寫入資料庫
    pub async fn create_bill(
        pool: &PgPool,
        author_id: Uuid,
        request: crate::domain::user_bill::CreateUserBillRequest,
    ) -> AppResult<UserBill> {
        // 驗證 bill_name 長度 (2-100)
        let name_len = request.bill_name.chars().count();
        if name_len < 2 || name_len > 100 {
            return Err(AppError::ValidationError(
                "法案名稱長度須在 2-100 字元之間".to_string(),
            ));
        }

        // 驗證 bill_description 長度 (10-500)
        let desc_len = request.bill_description.chars().count();
        if desc_len < 10 || desc_len > 500 {
            return Err(AppError::ValidationError(
                "法案描述長度須在 10-500 字元之間".to_string(),
            ));
        }

        // 驗證 bill_type 是有效值
        if !VALID_BILL_TYPES.contains(&request.bill_type.as_str()) {
            return Err(AppError::ValidationError(format!(
                "無效的法案類型: {}，有效值為: {}",
                request.bill_type,
                VALID_BILL_TYPES.join(", ")
            )));
        }

        let special_rules = request
            .special_rules
            .unwrap_or_else(|| serde_json::json!({}));

        let bill = sqlx::query_as::<_, UserBill>(
            r#"
            INSERT INTO user_bills (author_id, bill_name, bill_description, bill_type,
                                    version_a, version_b, version_c, special_rules)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id, author_id, bill_name, bill_description, bill_type,
                      version_a, version_b, version_c, special_rules,
                      status, upvotes, downvotes, play_count,
                      featured_week, featured_year, created_at, updated_at
            "#,
        )
        .bind(author_id)
        .bind(&request.bill_name)
        .bind(&request.bill_description)
        .bind(&request.bill_type)
        .bind(&request.version_a)
        .bind(&request.version_b)
        .bind(&request.version_c)
        .bind(&special_rules)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("建立法案失敗: {}", e)))?;

        Ok(bill)
    }

    /// 投票（支持 toggle：再次點擊取消）
    ///
    /// - 未投票 → 新增投票
    /// - 已投票且類型相同 → 取消投票（刪除記錄）
    /// - 已投票且類型不同 → 更新投票
    pub async fn vote_bill(
        pool: &PgPool,
        bill_id: Uuid,
        voter_id: Uuid,
        vote_type: &str,
    ) -> AppResult<()> {
        // 驗證 vote_type
        if vote_type != "up" && vote_type != "down" {
            return Err(AppError::ValidationError(
                "投票類型必須為 'up' 或 'down'".to_string(),
            ));
        }

        // 確認法案存在
        let exists: Option<(Uuid,)> =
            sqlx::query_as("SELECT id FROM user_bills WHERE id = $1")
                .bind(bill_id)
                .fetch_optional(pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("查詢法案失敗: {}", e)))?;

        if exists.is_none() {
            return Err(AppError::NotFound("法案不存在".to_string()));
        }

        // 查詢現有投票
        let existing: Option<(String,)> = sqlx::query_as(
            "SELECT vote_type FROM bill_votes WHERE bill_id = $1 AND voter_id = $2",
        )
        .bind(bill_id)
        .bind(voter_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢投票記錄失敗: {}", e)))?;

        match existing {
            Some((existing_type,)) if existing_type == vote_type => {
                // 類型相同 → 取消投票（toggle）
                sqlx::query("DELETE FROM bill_votes WHERE bill_id = $1 AND voter_id = $2")
                    .bind(bill_id)
                    .bind(voter_id)
                    .execute(pool)
                    .await
                    .map_err(|e| AppError::DatabaseError(format!("取消投票失敗: {}", e)))?;
            }
            Some(_) => {
                // 類型不同 → 更新投票
                sqlx::query(
                    "UPDATE bill_votes SET vote_type = $1 WHERE bill_id = $2 AND voter_id = $3",
                )
                .bind(vote_type)
                .bind(bill_id)
                .bind(voter_id)
                .execute(pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("更新投票失敗: {}", e)))?;
            }
            None => {
                // 未投票 → 新增
                sqlx::query(
                    "INSERT INTO bill_votes (bill_id, voter_id, vote_type) VALUES ($1, $2, $3)",
                )
                .bind(bill_id)
                .bind(voter_id)
                .bind(vote_type)
                .execute(pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("新增投票失敗: {}", e)))?;
            }
        }

        // 重新計算 upvotes/downvotes 計數
        sqlx::query(
            r#"
            UPDATE user_bills SET
                upvotes = (SELECT COUNT(*) FROM bill_votes WHERE bill_id = $1 AND vote_type = 'up'),
                downvotes = (SELECT COUNT(*) FROM bill_votes WHERE bill_id = $1 AND vote_type = 'down'),
                updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(bill_id)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("更新投票計數失敗: {}", e)))?;

        Ok(())
    }

    /// 列出法案
    ///
    /// 支援依狀態篩選、排序方式、分頁，並附帶觀看者投票狀態
    pub async fn list_bills(
        pool: &PgPool,
        status: Option<&str>,
        sort_by: Option<&str>,
        limit: i64,
        offset: i64,
        viewer_id: Option<Uuid>,
    ) -> AppResult<UserBillListResponse> {
        let sort_by = sort_by.unwrap_or("newest");
        let order_clause = match sort_by {
            "popular" => "ORDER BY (ub.upvotes - ub.downvotes) DESC, ub.created_at DESC",
            "controversial" => "ORDER BY (ub.upvotes + ub.downvotes) DESC, ub.created_at DESC",
            _ => "ORDER BY ub.created_at DESC", // newest（預設）
        };

        let status_filter = status.unwrap_or("approved");

        // 使用 viewer_id 的預設值（零 UUID 不會匹配任何記錄）
        let viewer = viewer_id.unwrap_or_else(Uuid::nil);

        let query = format!(
            r#"
            SELECT ub.id, ub.author_id, COALESCE(u.display_name, u.username) AS author_name,
                   ub.bill_name, ub.bill_description, ub.bill_type,
                   ub.version_a, ub.version_b, ub.version_c, ub.special_rules,
                   ub.status, ub.upvotes, ub.downvotes, ub.play_count,
                   ub.featured_week, ub.featured_year,
                   ub.created_at, ub.updated_at,
                   bv.vote_type AS user_vote
            FROM user_bills ub
            JOIN users u ON u.id = ub.author_id
            LEFT JOIN bill_votes bv ON bv.bill_id = ub.id AND bv.voter_id = $3
            WHERE ub.status = $4
            {}
            LIMIT $1 OFFSET $2
            "#,
            order_clause
        );

        let rows = sqlx::query_as::<_, BillRow>(&query)
            .bind(limit)
            .bind(offset)
            .bind(viewer)
            .bind(status_filter)
            .fetch_all(pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("查詢法案列表失敗: {}", e)))?;

        // 計算總數
        let total: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM user_bills WHERE status = $1")
                .bind(status_filter)
                .fetch_one(pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("計算法案總數失敗: {}", e)))?;

        let bills = rows.into_iter().map(|r| r.into_response()).collect();

        Ok(UserBillListResponse {
            bills,
            total: total.0,
        })
    }

    /// 取得單一法案詳情
    pub async fn get_bill(
        pool: &PgPool,
        bill_id: Uuid,
        viewer_id: Option<Uuid>,
    ) -> AppResult<UserBillResponse> {
        let viewer = viewer_id.unwrap_or_else(Uuid::nil);

        let row = sqlx::query_as::<_, BillRow>(
            r#"
            SELECT ub.id, ub.author_id, COALESCE(u.display_name, u.username) AS author_name,
                   ub.bill_name, ub.bill_description, ub.bill_type,
                   ub.version_a, ub.version_b, ub.version_c, ub.special_rules,
                   ub.status, ub.upvotes, ub.downvotes, ub.play_count,
                   ub.featured_week, ub.featured_year,
                   ub.created_at, ub.updated_at,
                   bv.vote_type AS user_vote
            FROM user_bills ub
            JOIN users u ON u.id = ub.author_id
            LEFT JOIN bill_votes bv ON bv.bill_id = ub.id AND bv.voter_id = $2
            WHERE ub.id = $1
            "#,
        )
        .bind(bill_id)
        .bind(viewer)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢法案失敗: {}", e)))?
        .ok_or_else(|| AppError::NotFound("法案不存在".to_string()))?;

        Ok(row.into_response())
    }

    /// 取得自己的法案
    pub async fn get_my_bills(
        pool: &PgPool,
        author_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> AppResult<UserBillListResponse> {
        let rows = sqlx::query_as::<_, BillRow>(
            r#"
            SELECT ub.id, ub.author_id, COALESCE(u.display_name, u.username) AS author_name,
                   ub.bill_name, ub.bill_description, ub.bill_type,
                   ub.version_a, ub.version_b, ub.version_c, ub.special_rules,
                   ub.status, ub.upvotes, ub.downvotes, ub.play_count,
                   ub.featured_week, ub.featured_year,
                   ub.created_at, ub.updated_at,
                   NULL::varchar AS user_vote
            FROM user_bills ub
            JOIN users u ON u.id = ub.author_id
            WHERE ub.author_id = $3
            ORDER BY ub.created_at DESC
            LIMIT $1 OFFSET $2
            "#,
        )
        .bind(limit)
        .bind(offset)
        .bind(author_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("查詢個人法案失敗: {}", e)))?;

        let total: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM user_bills WHERE author_id = $1")
                .bind(author_id)
                .fetch_one(pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("計算個人法案總數失敗: {}", e)))?;

        let bills = rows.into_iter().map(|r| r.into_response()).collect();

        Ok(UserBillListResponse {
            bills,
            total: total.0,
        })
    }

    /// 精選法案（管理功能）
    ///
    /// 將法案設為該週精選
    pub async fn feature_bill(
        pool: &PgPool,
        bill_id: Uuid,
        week: i32,
        year: i32,
    ) -> AppResult<()> {
        let result = sqlx::query(
            r#"
            UPDATE user_bills
            SET status = 'featured', featured_week = $2, featured_year = $3, updated_at = NOW()
            WHERE id = $1
            "#,
        )
        .bind(bill_id)
        .bind(week)
        .bind(year)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("精選法案失敗: {}", e)))?;

        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("法案不存在".to_string()));
        }

        Ok(())
    }
}

// ============================================================
// 內部查詢列映射
// ============================================================

/// 資料庫查詢結果列（含 JOIN 欄位）
#[derive(Debug, sqlx::FromRow)]
struct BillRow {
    id: Uuid,
    author_id: Uuid,
    author_name: String,
    bill_name: String,
    bill_description: String,
    bill_type: String,
    version_a: serde_json::Value,
    version_b: serde_json::Value,
    version_c: serde_json::Value,
    special_rules: serde_json::Value,
    status: String,
    upvotes: i32,
    downvotes: i32,
    play_count: i32,
    featured_week: Option<i32>,
    featured_year: Option<i32>,
    created_at: chrono::DateTime<chrono::Utc>,
    updated_at: chrono::DateTime<chrono::Utc>,
    user_vote: Option<String>,
}

impl BillRow {
    /// 轉換為 API 回應格式
    fn into_response(self) -> UserBillResponse {
        UserBillResponse {
            id: self.id,
            author_id: self.author_id,
            author_name: self.author_name,
            bill_name: self.bill_name,
            bill_description: self.bill_description,
            bill_type: self.bill_type,
            version_a: self.version_a,
            version_b: self.version_b,
            version_c: self.version_c,
            special_rules: self.special_rules,
            status: self.status,
            upvotes: self.upvotes,
            downvotes: self.downvotes,
            play_count: self.play_count,
            featured_week: self.featured_week,
            featured_year: self.featured_year,
            created_at: self.created_at,
            updated_at: self.updated_at,
            user_vote: self.user_vote,
        }
    }
}
