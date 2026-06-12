//! 領域模型模組
//!
//! 定義遊戲核心的資料結構

pub mod attribution;
pub mod card;
pub mod discord;
pub mod event;
pub mod game;
pub mod player;
pub mod referral;
pub mod relationship;
pub mod room;
pub mod season_pass;
pub mod streamer;
pub mod summary;
pub mod summons;
pub mod user;
pub mod user_bill;
pub mod streaming;
pub mod weekly_bill;

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
pub use event::{CreateEventLog, DramaScore, GameEventLog};
pub use user::{
    CreateUserRequest, ForgotPasswordRequest, LoginRequest, MessageResponse, OAuthLoginRequest,
    RefreshTokenRequest, ResetPasswordRequest, TokenResponse, User, UserResponse,
};
pub use attribution::{
    AttributionEvent, CreateInviteRequest, ConversionRequest, InviteLink, InviteResolution,
    InviteStats,
};
pub use summary::{
    GameSummary, Highlight, NewspaperData, NewspaperQuote, ReplayData, ReplayEvent,
    ReplayHighlight, ReplayPlayerScore,
};
pub use relationship::{
    PlayerRelationship, RelationshipListResponse, RelationshipResponse,
    relationship_type_from_trust,
};
pub use referral::{
    ClaimRewardRequest, ClaimRewardResponse, MilestoneProgress, ReferralMilestone,
    ReferralProgressResponse, ReferralRewardClaim,
};
pub use summons::{CreateSummonsRequest, InviterStats, SummonsResponse};
pub use user_bill::{
    BillVote, CreateUserBillRequest, UserBill, UserBillListResponse, UserBillResponse,
    VoteBillRequest,
};
pub use streaming::{
    LinkStreamingRequest, LinkStreamingResponse, SetLiveRequest, StreamHighlightPayload,
    StreamingAccount, StreamingAccountInfo, StreamingEvent, StreamingGameData,
    StreamingStatusResponse, UpdateStreamingSettingsRequest,
};
pub use weekly_bill::{BillHistoryResponse, CurrentBillResponse, WeeklyBill};
