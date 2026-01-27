# 1812 國會風雲 - Rust 後端伺服器

高效能 Rust 後端，使用 Axum 框架提供 RESTful API 和 WebSocket 即時通訊。

## 技術棧

- **框架**: Axum 0.7
- **異步運行時**: Tokio
- **資料庫**: PostgreSQL (SQLx)
- **快取**: Redis (deadpool-redis)
- **認證**: JWT (jsonwebtoken)
- **密碼雜湊**: Argon2

## 快速開始

### 前置需求

- Rust 1.75+
- PostgreSQL 14+
- Redis 7+

### 本地開發

```bash
# 複製環境變數
cp .env.example .env

# 編輯 .env 設定資料庫和 Redis 連線

# 執行（會自動執行資料庫遷移）
cargo run

# 執行測試
cargo test
```

## 專案結構

```
server/
├── src/
│   ├── main.rs           # 應用程式入口
│   ├── lib.rs            # 模組匯出
│   ├── api/              # HTTP API
│   │   ├── handlers/     # 請求處理器
│   │   └── routes.rs     # 路由定義
│   ├── auth/             # 認證模組
│   │   ├── jwt.rs        # JWT 管理
│   │   └── middleware.rs # 認證中介軟體
│   ├── cache/            # Redis 快取
│   │   └── game_cache.rs # 遊戲狀態快取
│   ├── config/           # 應用設定
│   ├── domain/           # 領域模型
│   ├── error/            # 錯誤處理
│   ├── game/             # 遊戲引擎
│   │   ├── engine.rs     # 遊戲引擎核心
│   │   ├── state.rs      # 遊戲狀態
│   │   ├── actions.rs    # 遊戲行動
│   │   └── characters.rs # 角色技能
│   ├── repository/       # 資料存取層
│   ├── services/         # 業務邏輯
│   ├── state.rs          # 應用狀態
│   └── websocket/        # WebSocket 模組
│       ├── hub.rs        # 連線管理
│       ├── handler.rs    # 訊息處理
│       └── messages.rs   # 訊息定義
├── migrations/           # 資料庫遷移
├── fly.toml             # Fly.io 部署設定
├── Dockerfile           # Docker 映像檔
└── Cargo.toml           # 依賴定義
```

## API 端點

### 健康檢查

```
GET /health
Response: { "status": "ok", "timestamp": "..." }
```

### 認證

```
POST /api/auth/register
Body: { "username": "...", "password": "..." }
Response: { "token": "...", "user": {...} }

POST /api/auth/login
Body: { "username": "...", "password": "..." }
Response: { "token": "...", "user": {...} }

GET /api/auth/me
Headers: Authorization: Bearer {token}
Response: { "user": {...} }
```

### 房間

```
POST /api/rooms
Headers: Authorization: Bearer {token}
Body: { "player_name": "..." }
Response: { "room": {...}, "player": {...} }

POST /api/rooms/{code}/join
Headers: Authorization: Bearer {token}
Body: { "player_name": "..." }
Response: { "room": {...}, "player": {...} }

POST /api/rooms/{code}/leave
Headers: Authorization: Bearer {token}

POST /api/rooms/{code}/ready
Headers: Authorization: Bearer {token}
Body: { "is_ready": true }

POST /api/rooms/{code}/character
Headers: Authorization: Bearer {token}
Body: { "character": "thomas" }

POST /api/rooms/{code}/start
Headers: Authorization: Bearer {token}
```

### WebSocket

```
WS /ws?token={jwt_token}
```

## WebSocket 訊息格式

### 客戶端 → 伺服器

```json
// 加入房間
{ "type": "JoinRoom", "room_code": "ABC123", "player_name": "Player1" }

// 離開房間
{ "type": "LeaveRoom" }

// 發起質詢（攻擊）
{ "type": "Challenge", "target_id": "uuid" }

// 反駁（防禦）
{ "type": "Counter" }

// 使用技能
{ "type": "UseSkill", "target_id": "uuid" }

// 投票
{ "type": "Vote", "choice": "A" }

// 結盟
{ "type": "Alliance", "target_id": "uuid" }

// 心跳
{ "type": "Ping" }
```

### 伺服器 → 客戶端

```json
// 玩家加入
{ "type": "PlayerJoined", "player": {...} }

// 玩家離開
{ "type": "PlayerLeft", "player_id": "uuid" }

// 遊戲開始
{ "type": "GameStarted", "game_state": {...} }

// 階段變更
{ "type": "PhaseChanged", "phase": "Debate", "duration_secs": 300 }

// 遊戲行動
{ "type": "GameAction", "action": {...}, "result": {...} }

// 遊戲結果
{ "type": "GameResult", "winner_faction": "...", "votes": {...}, "rankings": [...] }

// 錯誤
{ "type": "Error", "message": "..." }

// 心跳回應
{ "type": "Pong" }
```

## 遊戲角色

| 角色 | 代碼 | 初始聲望 | 技能 |
|------|------|----------|------|
| 工人湯瑪斯 | `thomas` | 70 | 團結：每有 1 名工人盟友，防禦 +10 |
| 工廠主理查 | `richard` | 60 | 收買：花費金幣使目標沉默 1 回合 |
| 記者愛德華 | `edward` | 50 | 爆料：揭露目標的秘密任務 |
| 盧德派喬治 | `george` | 80 | 怒火：造成雙倍傷害，但自己也扣 10 聲望 |

## 遊戲階段

1. **Waiting** - 等待玩家
2. **Conspiracy** - 密謀階段（2 分鐘）
3. **Debate** - 辯論階段（5 分鐘）
4. **Voting** - 投票階段（2 分鐘）
5. **Result** - 結果階段
6. **Finished** - 遊戲結束

## 部署

### Fly.io

```bash
# 首次部署
fly launch --no-deploy
fly postgres create --name parliament1812-db --region nrt
fly postgres attach parliament1812-db
fly secrets set JWT_SECRET="$(openssl rand -hex 32)"
fly deploy

# 後續部署
fly deploy

# 查看日誌
fly logs

# SSH 連線
fly ssh console
```

### 環境變數

| 變數 | 說明 | 預設值 |
|------|------|--------|
| `HOST` | 伺服器監聽地址 | `0.0.0.0` |
| `PORT` | 伺服器監聽埠 | `8080` |
| `DATABASE_URL` | PostgreSQL 連線字串 | - |
| `DATABASE_MAX_CONNECTIONS` | 資料庫最大連線數 | `10` |
| `REDIS_URL` | Redis 連線字串 | - |
| `JWT_SECRET` | JWT 簽名密鑰 | - |
| `JWT_EXPIRATION_HOURS` | JWT 過期時間（小時） | `24` |
| `RUST_LOG` | 日誌等級 | `info` |

## 測試

```bash
# 執行所有測試
cargo test

# 執行特定測試
cargo test game_engine

# 顯示測試輸出
cargo test -- --nocapture
```

## 授權

MIT License
