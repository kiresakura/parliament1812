//! WebSocket 模組
//!
//! 提供 WebSocket 連線處理和訊息傳遞功能

pub mod connection;
pub mod hub;
pub mod messages;
pub mod timer;

// 重新匯出常用類型
pub use connection::{handle_socket, process_message};
pub use hub::{ConnectionHandle, Hub, WebSocketHub};
pub use messages::{error_codes, ClientMessage, PlayerRanking, ServerMessage, SystemMessageType};
pub use timer::{GameTimerManager, SharedTimerManager};
