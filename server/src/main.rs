//! 1812 國會風雲 - 後端伺服器入口點
//!
//! 伺服器啟動流程：
//! 1. 初始化日誌系統
//! 2. 載入設定
//! 3. 建立資料庫連線池
//! 4. 建立 Redis 連線池
//! 5. 建立應用程式狀態
//! 6. 建立路由
//! 7. 啟動 HTTP 伺服器

use parliament1812_server::{create_health_only_router, create_router, AppState, Settings};
use std::net::SocketAddr;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // 初始化 tracing 日誌
    init_tracing();

    tracing::info!("正在啟動 1812 國會風雲伺服器...");

    // 載入設定
    let settings = Settings::new()?;
    let addr: SocketAddr = settings.server_addr().parse()?;

    tracing::info!("設定載入完成");
    tracing::info!("  伺服器地址: {}", addr);
    tracing::info!("  資料庫: {}", mask_url(&settings.database.url));
    tracing::info!("  Redis: {}", mask_url(&settings.redis.url));

    // 檢查啟動模式
    let health_only = std::env::var("HEALTH_ONLY").is_ok();
    let memory_only = std::env::var("MEMORY_ONLY").is_ok();

    let app = if health_only {
        tracing::warn!("以僅健康檢查模式啟動（不連接資料庫和 Redis）");
        create_health_only_router()
    } else if memory_only {
        // 使用記憶體儲存模式（不連接資料庫和 Redis）
        tracing::warn!("以記憶體模式啟動（不連接資料庫和 Redis，資料不持久化）");
        let state = AppState::for_testing(settings);
        create_router(state)
    } else {
        // 建立應用程式狀態（包含資料庫和 Redis 連線池）
        tracing::info!("正在連接資料庫和 Redis...");
        match AppState::new(settings).await {
            Ok(state) => {
                tracing::info!("資料庫和 Redis 連接成功");

                // 執行資料庫遷移
                tracing::info!("正在執行資料庫遷移...");
                if let Err(e) = sqlx::migrate!("./migrations").run(&state.db).await {
                    tracing::error!("資料庫遷移失敗: {}", e);
                    return Err(anyhow::anyhow!("資料庫遷移失敗: {}", e));
                }
                tracing::info!("資料庫遷移完成");

                create_router(state)
            }
            Err(e) => {
                tracing::error!("連接失敗: {}", e);
                tracing::warn!("降級為僅健康檢查模式");
                create_health_only_router()
            }
        }
    };

    // 啟動伺服器
    tracing::info!("伺服器已啟動，監聽 http://{}", addr);
    tracing::info!("健康檢查端點: http://{}/health", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    tracing::info!("伺服器已關閉");
    Ok(())
}

/// 初始化 tracing 日誌系統
fn init_tracing() {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| {
                // 預設日誌級別
                "parliament1812_server=debug,tower_http=debug,axum=debug".into()
            }),
        )
        .with(
            tracing_subscriber::fmt::layer()
                .with_target(true)
                .with_thread_ids(false)
                .with_file(false)
                .with_line_number(false),
        )
        .init();
}

/// 遮罩 URL 中的敏感資訊（密碼）
fn mask_url(url: &str) -> String {
    // 簡單的密碼遮罩：將 :password@ 替換為 :***@
    if let Some(at_pos) = url.find('@') {
        if let Some(colon_pos) = url[..at_pos].rfind(':') {
            let scheme_end = url.find("://").map(|p| p + 3).unwrap_or(0);
            if colon_pos > scheme_end {
                return format!("{}:***{}", &url[..colon_pos], &url[at_pos..]);
            }
        }
    }
    url.to_string()
}

/// 優雅關閉信號處理
async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("無法安裝 Ctrl+C 處理器");
    };

    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("無法安裝 SIGTERM 處理器")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {
            tracing::info!("收到 Ctrl+C 信號，正在關閉伺服器...");
        }
        _ = terminate => {
            tracing::info!("收到 SIGTERM 信號，正在關閉伺服器...");
        }
    }
}
