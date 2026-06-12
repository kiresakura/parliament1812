//! 國會公報 HTML 頁面處理器
//!
//! - GET /gazette/:share_token — 維多利亞報紙風格的分享頁面

use axum::{
    extract::{Path, State},
    response::Html,
};
use tera::Tera;

use crate::error::AppResult;
use crate::services::SummaryService;
use crate::AppState;

/// 內嵌 gazette HTML 模板（避免部署時的路徑問題）
const GAZETTE_TEMPLATE: &str = include_str!("../../../templates/gazette.html");

/// GET /gazette/:share_token
///
/// 國會公報 HTML 頁面。返回維多利亞報紙風格的分享頁面，
/// 包含 Open Graph 和 Twitter Card meta tags 以支援社群分享預覽。
pub async fn gazette_page(
    State(state): State<AppState>,
    Path(share_token): Path<String>,
) -> AppResult<Html<String>> {
    // 1. 透過分享 token 取得摘要（同時增加瀏覽次數）
    let summary = SummaryService::get_by_share_token(&state.db, &share_token).await?;

    // 2. 建立 Tera 引擎並載入內嵌模板
    let mut tera = Tera::default();
    tera.add_raw_template("gazette.html", GAZETTE_TEMPLATE)
        .map_err(|e| {
            crate::error::AppError::InternalError(format!("載入公報模板失敗: {}", e))
        })?;

    // 3. 建立模板上下文
    let context = SummaryService::build_gazette_context(&summary);

    // 4. 渲染 HTML
    let html = tera.render("gazette.html", &context).map_err(|e| {
        crate::error::AppError::InternalError(format!("渲染公報頁面失敗: {}", e))
    })?;

    Ok(Html(html))
}
