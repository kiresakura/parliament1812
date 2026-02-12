//! 領域模型模組
//!
//! 定義遊戲核心的資料結構

pub mod card;
pub mod game;
pub mod player;
pub mod room;
pub mod user;

// 重新匯出常用類型
pub use game::{
    ActionType, ChatRequest, GameActionRecord, GameEvent, GamePhase, GameResponse, GameState, Vote,
    VoteChoice, VoteRequest, VoteResult,
};
pub use player::{
    CharacterType, Player, PlayerActionRequest, PlayerResponse, SelectCharacterRequest,
};
pub use room::{
    CreateRoomRequest, JoinRoomRequest, Room, RoomCodeRequest, RoomResponse, RoomStatus,
};
pub use user::{
    CreateUserRequest, ForgotPasswordRequest, LoginRequest, MessageResponse, OAuthLoginRequest,
    RefreshTokenRequest, ResetPasswordRequest, TokenResponse, User, UserResponse,
};
