//! 玩家關係 API 處理器
//!
//! - GET /api/v1/relationships           — 我的所有關係列表
//! - GET /api/v1/relationships/nemeses   — 我的宿敵列表
//! - GET /api/v1/relationships/allies    — 我的盟友列表
//! - GET /api/v1/relationships/:user_id  — 與特定玩家的關係

use axum::{
    extract::{Path, State},
    Json,
};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::domain::relationship::RelationshipListResponse;
use crate::domain::relationship::RelationshipResponse;
use crate::error::{AppError, AppResult};
use crate::services::RelationshipService;
use crate::AppState;

/// GET /api/v1/relationships
///
/// 取得目前使用者的所有玩家關係
pub async fn get_relationships(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<RelationshipListResponse>> {
    let result = RelationshipService::get_relationships(&state.db, auth.user_id).await?;
    Ok(Json(result))
}

/// GET /api/v1/relationships/:user_id
///
/// 取得與特定玩家的關係
pub async fn get_relationship_with(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(user_id): Path<String>,
) -> AppResult<Json<RelationshipResponse>> {
    let other_id = Uuid::parse_str(&user_id)
        .map_err(|_| AppError::BadRequest("無效的使用者 ID 格式".to_string()))?;

    if other_id == auth.user_id {
        return Err(AppError::BadRequest("不能查詢與自己的關係".to_string()));
    }

    let result =
        RelationshipService::get_relationship_with(&state.db, auth.user_id, other_id).await?;
    Ok(Json(result))
}

/// GET /api/v1/relationships/nemeses
///
/// 取得宿敵列表（nemesis / rival）
pub async fn get_nemeses(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<RelationshipListResponse>> {
    let result = RelationshipService::get_nemeses(&state.db, auth.user_id).await?;
    Ok(Json(result))
}

/// GET /api/v1/relationships/allies
///
/// 取得盟友列表（sworn_ally / trusted）
pub async fn get_allies(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<RelationshipListResponse>> {
    let result = RelationshipService::get_allies(&state.db, auth.user_id).await?;
    Ok(Json(result))
}
