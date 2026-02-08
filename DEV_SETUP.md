# 1812 國會風雲 — 開發環境設定

> _最後更新：2026-02-08_

---

## 📋 前置需求

| 工具 | 版本 | 安裝 |
|------|------|------|
| **Rust** | ≥ 1.93.0 | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| **Flutter** | ≥ 3.38.0 | [flutter.dev/get-started](https://flutter.dev/docs/get-started/install) |
| **PostgreSQL** | ≥ 15 | `brew install postgresql@15` |
| **Redis** | ≥ 7 | `brew install redis` |
| **Git** | ≥ 2 | 預裝 |

### 驗證
```bash
rustc --version    # rustc 1.93.0+
cargo --version    # cargo 1.93.0+
flutter --version  # Flutter 3.38+
psql --version     # psql 15+
redis-cli --version # redis-cli 7+
```

---

## 📦 專案結構

```
parliament1812/
├── server/              # Rust 後端 (Axum) ← 主要後端
│   ├── src/
│   │   ├── api/         # REST API handlers
│   │   ├── auth/        # JWT 認證
│   │   ├── cache/       # Redis 快取
│   │   ├── config/      # 設定
│   │   ├── domain/      # 領域模型 (Card, Player, Room, Game)
│   │   ├── error/       # 錯誤處理
│   │   ├── game/        # 遊戲引擎（核心）
│   │   ├── repository/  # PostgreSQL CRUD
│   │   ├── services/    # 業務邏輯
│   │   └── websocket/   # WebSocket hub + handlers
│   ├── migrations/      # SQL migrations
│   └── Cargo.toml
│
├── app/                 # Flutter 前端
│   ├── lib/
│   │   ├── config/      # 主題 + 常數
│   │   ├── models/      # 資料模型 (Freezed)
│   │   ├── providers/   # Riverpod 狀態管理
│   │   ├── screens/     # 畫面
│   │   ├── services/    # WebSocket + REST
│   │   └── widgets/     # 可複用元件
│   └── pubspec.yaml
│
├── backend/             # ⚠️ Node.js 後端（已棄用，僅供參考）
├── docs/                # 設計文件
└── parliament_assets/   # 美術素材
```

---

## 🔧 Rust 後端設定

### 1. 環境變數

建立 `server/.env`：
```env
# 資料庫
DATABASE_URL=postgresql://parliament:password@localhost:5432/parliament1812

# Redis
REDIS_URL=redis://127.0.0.1:6379

# JWT
JWT_SECRET=your-secret-key-change-in-production

# 伺服器
SERVER_HOST=0.0.0.0
SERVER_PORT=8080

# 日誌
RUST_LOG=parliament1812_server=debug,tower_http=info
```

### 2. 資料庫設定
```bash
# 建立資料庫
createdb parliament1812

# 建立使用者
psql -c "CREATE USER parliament WITH PASSWORD 'password';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE parliament1812 TO parliament;"

# 跑 migrations（如果有 sqlx-cli）
cargo install sqlx-cli --no-default-features --features postgres
sqlx migrate run --source server/migrations
```

### 3. 啟動
```bash
cd server

# 檢查編譯
cargo check

# 跑測試
cargo test

# 開發模式
cargo run

# 生產模式
cargo build --release
./target/release/parliament1812-server
```

**伺服器預設在 `http://localhost:8080`**

### 4. API 端點

| 方法 | 路徑 | 說明 |
|------|------|------|
| GET | `/health` | 健康檢查 |
| POST | `/api/auth/register` | 註冊 |
| POST | `/api/auth/login` | 登入 |
| GET | `/api/rooms` | 房間列表 |
| POST | `/api/rooms` | 建立房間 |
| GET | `/ws` | WebSocket 升級 |

---

## 📱 Flutter 前端設定

### 1. 安裝依賴
```bash
cd app
flutter pub get
```

### 2. 生成程式碼（Freezed models）
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. 設定後端 URL

編輯 `app/lib/config/constants.dart`：
```dart
static const String wsUrl = 'ws://localhost:8080/ws';      // 本地開發
static const String apiBaseUrl = 'http://localhost:8080';   // 本地開發
```

### 4. 執行
```bash
# iOS 模擬器
flutter run -d ios

# Android 模擬器
flutter run -d android

# 靜態分析
flutter analyze

# 測試
flutter test
```

---

## 🔄 開發流程

### 日常開發
```bash
# Terminal 1: Rust 後端
cd server && cargo run

# Terminal 2: Flutter 前端
cd app && flutter run

# Terminal 3: Redis
redis-server
```

### Git 分支策略
```
main          ← 穩定版本
  └── dev     ← 開發整合
       ├── feat/xxx    ← 功能分支
       └── fix/xxx     ← 修復分支
```

### 提交格式
```
feat(M1): 功能描述
fix: bug 描述
docs: 文件更新
refactor: 重構
test: 測試
```

---

## 📊 測試狀態

| 組件 | 測試數 | 狀態 |
|------|--------|------|
| Rust 後端 | 78 | ✅ 全通過 |
| Flutter 前端 | 0 | ⚠️ 待建立 |

---

## ⚡ 常見問題

### Rust 編譯慢
```bash
# 使用 sccache 加速
cargo install sccache
export RUSTC_WRAPPER=sccache
```

### Flutter 依賴衝突
```bash
cd app
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### PostgreSQL 連不上
```bash
brew services start postgresql@15
psql -l  # 確認資料庫存在
```

### Redis 連不上
```bash
brew services start redis
redis-cli ping  # 應該回 PONG
```

---

## 🎮 WebSocket 協議

### 連線
```
ws://localhost:8080/ws
```

### 客戶端 → 伺服器 (ClientMessage)
```json
{"type": "join_room", "room_code": "ABCD", "player_name": "時七"}
{"type": "select_character", "character": "thomas"}
{"type": "ready"}
{"type": "start_game"}
{"type": "challenge", "target_id": "uuid"}
{"type": "counter"}
{"type": "use_skill", "target_id": "uuid"}
{"type": "vote", "choice": "support"}
{"type": "use_card", "card_id": "atk_001", "target_id": "uuid"}
{"type": "draw_card"}
{"type": "send_chat", "content": "你好"}
{"type": "ping"}
```

### 伺服器 → 客戶端 (ServerMessage, 26 種)
```
connected, error, room_state, player_joined, player_left,
player_selected_character, player_ready, player_unready,
game_started, phase_changed, chat_message,
challenge_event, counter_event, skill_used,
reputation_changed, gold_changed,
card_used, card_drawn, hand_updated, player_hand_count_changed,
vote_received, vote_result, game_result,
player_political_death, system_message, pong, timer_update
```

---

_「看完這份文件，你就可以開始寫程式了。看不完的話——也不是我的問題。」_
