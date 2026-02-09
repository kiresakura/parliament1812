//! 路由配置
//!
//! 建立和配置應用程式的所有路由

use axum::{
    http::{header, Method},
    middleware,
    routing::{any, delete, get, post},
    Router,
};

use tower_http::{
    compression::CompressionLayer,
    cors::{Any, CorsLayer},
    trace::{DefaultMakeSpan, DefaultOnRequest, DefaultOnResponse, TraceLayer},
};
use tracing::Level;

use crate::{auth::auth_middleware, AppState};

use super::handlers;

/// 建立應用程式路由
///
/// 包含所有中間件和路由配置
pub fn create_router(state: AppState) -> Router {
    // 建立 CORS 層
    // TODO: 在生產環境中應該限制允許的來源
    let cors = CorsLayer::new()
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PUT,
            Method::PATCH,
            Method::DELETE,
            Method::OPTIONS,
        ])
        .allow_headers([
            header::CONTENT_TYPE,
            header::AUTHORIZATION,
            header::ACCEPT,
            header::ORIGIN,
            header::SEC_WEBSOCKET_KEY,
            header::SEC_WEBSOCKET_VERSION,
            header::SEC_WEBSOCKET_PROTOCOL,
            header::UPGRADE,
            header::CONNECTION,
        ])
        .allow_origin(Any)
        .allow_credentials(false);

    // 建立追蹤層
    let trace_layer = TraceLayer::new_for_http()
        .make_span_with(DefaultMakeSpan::new().level(Level::INFO))
        .on_request(DefaultOnRequest::new().level(Level::INFO))
        .on_response(DefaultOnResponse::new().level(Level::INFO));

    // 建立壓縮層
    let compression = CompressionLayer::new();

    // 健康檢查路由
    let health_routes = Router::new()
        .route("/", get(handlers::health_check))
        .route("/db", get(handlers::db_health_check))
        .route("/redis", get(handlers::redis_health_check))
        .route("/full", get(handlers::full_health_check));

    // 公開認證路由（不需要驗證）
    let public_auth_routes = Router::new()
        .route("/register", post(handlers::register))
        .route("/login", post(handlers::login))
        .route("/refresh", post(handlers::refresh_token))
        .route("/oauth/google", post(handlers::oauth_google))
        .route("/oauth/apple", post(handlers::oauth_apple))
        .route("/forgot-password", post(handlers::forgot_password))
        .route("/reset-password", post(handlers::reset_password));

    // 受保護的認證路由（需要驗證）
    let protected_auth_routes = Router::new()
        .route("/me", get(handlers::me))
        .route("/account", delete(handlers::delete_account))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    // 房間路由
    // 公開路由
    let public_room_routes = Router::new()
        .route("/", get(handlers::list_rooms))
        .route("/:code", get(handlers::get_room));

    // 受保護的房間路由
    let protected_room_routes = Router::new()
        .route("/", post(handlers::create_room))
        .route("/quickmatch", post(handlers::quick_match))
        .route("/:code/join", post(handlers::join_room))
        .route("/:code/spectate", post(handlers::spectate_room))
        .route("/:code/leave", post(handlers::leave_room))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    // 合併房間路由
    let room_routes = Router::new()
        .merge(public_room_routes)
        .merge(protected_room_routes);

    // 合併認證路由
    let auth_routes = Router::new()
        .merge(public_auth_routes)
        .merge(protected_auth_routes);

    // 排行榜路由
    // 公開路由
    let public_ranking_routes = Router::new()
        .route("/global", get(handlers::global_rankings))
        .route("/seasons", get(handlers::list_seasons));

    // 受保護的排行榜路由
    let protected_ranking_routes = Router::new()
        .route("/me", get(handlers::my_ranking))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    // 合併排行榜路由
    let ranking_routes = Router::new()
        .merge(public_ranking_routes)
        .merge(protected_ranking_routes);

    // 每日任務路由（全部需要認證）
    let quest_routes = Router::new()
        .route("/daily", get(handlers::quests::get_daily_quests))
        .route("/claim/:quest_id", post(handlers::quests::claim_quest_reward))
        .route("/history", get(handlers::quests::get_quest_history))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    // 好友路由（全部需要認證）
    let friend_routes = Router::new()
        .route("/", get(handlers::friends::get_friends))
        .route("/pending", get(handlers::friends::get_pending_requests))
        .route("/request", post(handlers::friends::send_friend_request))
        .route("/accept", post(handlers::friends::accept_friend_request))
        .route("/reject", post(handlers::friends::reject_friend_request))
        .route("/:user_id", delete(handlers::friends::remove_friend))
        .route("/block", post(handlers::friends::block_user))
        .route("/unblock", post(handlers::friends::unblock_user))
        .route("/invite-game", post(handlers::friends::invite_game))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    // 用戶搜尋路由（需要認證）
    let user_routes = Router::new()
        .route("/search", get(handlers::friends::search_users))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    // 圖鑑路由（全部需要認證）
    let codex_routes = Router::new()
        .route("/cards", get(handlers::codex::get_codex_cards))
        .route("/collection", get(handlers::codex::get_collection))
        .route("/achievements", get(handlers::codex::get_achievements))
        .route("/stats", get(handlers::codex::get_codex_stats))
        .route(
            "/achievements/claim",
            post(handlers::codex::claim_achievement),
        )
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    // API v1 路由
    let api_v1_routes = Router::new()
        .nest("/auth", auth_routes)
        .nest("/rooms", room_routes)
        .nest("/rankings", ranking_routes)
        .nest("/quests", quest_routes)
        .nest("/friends", friend_routes)
        .nest("/users", user_routes);

    // 組合所有路由
    Router::new()
        .route("/", get(root))
        // WebSocket 端點
        // GET /ws - 一般 WebSocket 連線（不指定房間）
        .route("/ws", any(handlers::ws_handler_general))
        // GET /ws/:room_code - 指定房間的 WebSocket 連線
        .route("/ws/:room_code", any(handlers::ws_handler))
        .nest("/health", health_routes)
        .nest("/api/v1", api_v1_routes)
        .nest("/api/codex", codex_routes)
        // 套用中間件
        .layer(compression)
        .layer(trace_layer)
        .layer(cors)
        // 注入應用程式狀態
        .with_state(state)
}

/// 根路徑處理器
async fn root() -> &'static str {
    "1812 國會風雲 API Server"
}

/// 建立僅包含健康檢查的路由（不需要狀態）
///
/// 用於啟動前的基本測試
pub fn create_health_only_router() -> Router {
    Router::new()
        .route("/", get(|| async { "1812 國會風雲 API Server" }))
        .route("/health", get(handlers::health_check))
}
