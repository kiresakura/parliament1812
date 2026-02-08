//! 路由配置
//!
//! 建立和配置應用程式的所有路由

use axum::{
    http::{header, Method},
    middleware,
    routing::{any, get, post},
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
        .route("/login", post(handlers::login));

    // 受保護的認證路由（需要驗證）
    let protected_auth_routes =
        Router::new()
            .route("/me", get(handlers::me))
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

    // API v1 路由
    let api_v1_routes = Router::new()
        .nest("/auth", auth_routes)
        .nest("/rooms", room_routes);

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
