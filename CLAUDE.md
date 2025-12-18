# CLAUDE.md - Parliament 1812 開發指南

## 🎯 專案概述

這是「1812 國會風雲」角色扮演遊戲的完整開發專案。玩家透過 NFC 卡片獲得角色，參與模擬 1812 年英國國會針對「機器問題」的辯論。

### 核心功能
1. **NFC 掃卡選角** - 玩家掃描實體 NFC 卡片獲得角色和秘密任務
2. **即時連線** - 20 人同時在線，WebSocket 即時同步
3. **秘密任務** - 每張卡片綁定獨特秘密任務，只有自己看得到
4. **私訊系統** - 玩家間可以發送悄悄話密謀
5. **突發事件** - 主持人可以抽取事件卡改變局勢
6. **多輪投票** - 第一輪匿名（只顯示比例）、第二輪記名（公開唱票）

### 技術棧
- **後端**: FastAPI + PostgreSQL + Redis + WebSocket
- **前端**: Flutter (iOS + Android 跨平台)
- **部署**: Railway
- **NFC**: NTAG215 卡片 + ACR122U 讀卡機

---

## 📊 資料庫 Schema

```sql
-- 用戶表（支援未來上架）
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE,
    display_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 遊戲房間
CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(6) UNIQUE NOT NULL,
    host_id UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'waiting',
    phase INT DEFAULT 1,
    current_round INT DEFAULT 0,
    timer_end_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 玩家
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    nickname VARCHAR(50) NOT NULL,
    role_type VARCHAR(20),
    role_index INT,
    secret_mission_id VARCHAR(50),
    is_host BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMP DEFAULT NOW()
);

-- 秘密任務
CREATE TABLE secret_missions (
    id VARCHAR(50) PRIMARY KEY,
    role_type VARCHAR(20) NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    success_condition TEXT,
    points INT DEFAULT 50
);

-- 私訊
CREATE TABLE private_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES players(id),
    receiver_id UUID REFERENCES players(id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT NOW()
);

-- 突發事件
CREATE TABLE events (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    effect_type VARCHAR(50),
    severity INT DEFAULT 1
);

-- 投票
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    player_id UUID REFERENCES players(id),
    round INT NOT NULL,
    choice VARCHAR(1),
    voted_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(room_id, player_id, round)
);

-- 遊戲事件紀錄
CREATE TABLE game_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
    event_id VARCHAR(50) REFERENCES events(id),
    triggered_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔌 API 端點設計

### 房間管理
```
POST   /api/rooms              # 建立房間（回傳 6 位房間碼）
GET    /api/rooms/{code}       # 取得房間資訊
POST   /api/rooms/{code}/join  # 加入房間
DELETE /api/rooms/{code}       # 關閉房間（僅主持人）
```

### 玩家操作
```
POST   /api/rooms/{code}/scan-nfc     # NFC 掃卡分配角色
GET    /api/rooms/{code}/players      # 取得所有玩家列表
GET    /api/players/{id}/secret       # 取得自己的秘密任務
```

### 私訊系統
```
POST   /api/messages                  # 發送私訊
GET    /api/messages?room={code}      # 取得私訊列表
PUT    /api/messages/{id}/read        # 標記已讀
```

### 遊戲流程
```
POST   /api/rooms/{code}/phase        # 切換階段（僅主持人）
POST   /api/rooms/{code}/timer        # 設定計時器
POST   /api/rooms/{code}/event        # 觸發突發事件（僅主持人）
```

### 投票系統
```
POST   /api/rooms/{code}/vote         # 投票
GET    /api/rooms/{code}/votes        # 取得投票結果
```

---

## 🔄 WebSocket 事件

### 連線
```
WS /ws/{room_code}?player_id={player_id}
```

### 事件類型 (server → client)
```json
{"type": "player_join", "data": {"player": {...}}}
{"type": "player_leave", "data": {"player_id": "..."}}
{"type": "phase_change", "data": {"phase": 2, "phase_name": "debate"}}
{"type": "timer_sync", "data": {"end_at": "2024-01-01T12:00:00Z"}}
{"type": "private_message", "data": {"from": "...", "content": "..."}}
{"type": "event_trigger", "data": {"event": {...}}}
{"type": "vote_update", "data": {"round": 1, "progress": 0.75}}
{"type": "vote_result", "data": {"round": 1, "results": {"A": 5, "B": 8, "C": 7}}}
{"type": "secret_revealed", "data": {"player_id": "...", "mission": {...}}}
```

### 事件類型 (client → server)
```json
{"type": "send_message", "data": {"to": "player_id", "content": "..."}}
{"type": "cast_vote", "data": {"round": 1, "choice": "B"}}
{"type": "request_sync", "data": {}}
```

---

## 🎭 角色與秘密任務資料

### 五種角色
1. **worker** - 紡織工人 湯瑪斯 (38歲)
2. **factory** - 工廠主 理查·威爾森 (45歲)  
3. **luddite** - 盧德派 喬治 (28歲)
4. **reformer** - 改革者 羅伯特·烏爾文 (35歲)
5. **mp** - 議員 威廉·菲茨傑拉德 (52歲)

### 秘密任務設計原則
每種角色有 4 種不同任務，分配給 4 張卡片：
- **_01**: 內心衝突型（私人利益 vs 公開立場）
- **_02**: 復仇/恩怨型
- **_03**: 雙面人/臥底型
- **_04**: 理想主義/覺醒型

---

## 📱 Flutter 頁面結構

```
lib/
├── main.dart
├── screens/
│   ├── home_screen.dart          # 首頁（建立/加入房間）
│   ├── scan_nfc_screen.dart      # NFC 掃描頁面
│   ├── waiting_room_screen.dart  # 等待室
│   ├── role_card_screen.dart     # 角色卡展示
│   ├── debate_screen.dart        # 辯論主畫面
│   ├── message_screen.dart       # 私訊頁面
│   ├── vote_screen.dart          # 投票頁面
│   ├── result_screen.dart        # 結果頁面
│   └── host_panel_screen.dart    # 主持人控制面板
├── widgets/
│   ├── role_card_widget.dart     # 角色卡元件
│   ├── timer_widget.dart         # 計時器
│   ├── player_avatar.dart        # 玩家頭像
│   ├── message_bubble.dart       # 訊息泡泡
│   ├── vote_option_card.dart     # 投票選項卡
│   └── event_card.dart           # 突發事件卡
├── services/
│   ├── api_service.dart          # HTTP API
│   ├── websocket_service.dart    # WebSocket
│   └── nfc_service.dart          # NFC 掃描
├── models/
│   ├── room.dart
│   ├── player.dart
│   ├── role.dart
│   ├── message.dart
│   └── vote.dart
└── providers/
    ├── room_provider.dart
    ├── player_provider.dart
    └── game_provider.dart
```

---

## 🎲 遊戲流程狀態機

```
WAITING → PREPARING → CONSPIRACY → DEBATE → EVENT1 → 
DEBATE2 → EVENT2 → VOTE_ROUND1 → FINAL_DEBATE → 
VOTE_ROUND2 → REVEAL → FINISHED

Phase 1: WAITING      - 等待玩家加入
Phase 2: PREPARING    - 角色研究 + 陣營策略 (15min)
Phase 3: CONSPIRACY   - 私下密謀時間 (10min)
Phase 4: DEBATE       - 開場陳述 (25min)
Phase 5: EVENT1       - 突發事件 #1 (5min)
Phase 6: DEBATE2      - 自由辯論 (30min)
Phase 7: EVENT2       - 突發事件 #2 (5min)
Phase 8: VOTE_ROUND1  - 第一輪匿名投票 (5min)
Phase 9: FINAL_DEBATE - 最後攻防 (10min)
Phase 10: VOTE_ROUND2 - 第二輪記名投票 (5min)
Phase 11: REVEAL      - 結果揭曉 + 秘密任務公開 (10min)
Phase 12: FINISHED    - 遊戲結束
```

---

## 🗳️ 投票選項

```
A - 【禁止機器】立法禁止工廠使用省力機器
B - 【保護財產】嚴厲打擊破壞機器的暴民
C - 【折衷改革】允許機器但立法保障工人權益
D - 【皇家調查】(隱藏選項，由突發事件觸發)
```

---

## 🚀 部署配置 (Railway)

### 環境變數
```
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
SECRET_KEY=your-secret-key
CORS_ORIGINS=*
```

### Dockerfile (Backend)
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY ./app ./app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## ⚡ 開發優先順序

### Week 1 (12/17-24): 後端基礎
1. FastAPI 專案初始化
2. PostgreSQL 資料庫 + Alembic migration
3. 房間 CRUD API
4. 玩家加入 + NFC 掃卡 API
5. WebSocket 基礎連線

### Week 2 (12/25-31): Flutter + 即時同步
1. Flutter 專案初始化
2. 首頁 + 等待室 UI
3. NFC 掃描功能
4. 角色卡頁面
5. WebSocket 連線 + 狀態同步
6. 私訊系統

### Week 3 (1/1-7): 投票 + 收尾
1. 投票系統（兩輪）
2. 突發事件系統
3. 主持人控制面板
4. 結果統計頁面
5. Bug 修復 + 測試
6. Railway 部署

---

## 📝 注意事項

1. **NFC URL 格式**: `parliament1812://role?id={card_id}&secret={hash}`
2. **房間碼**: 6 位大寫英數字，避免混淆字元 (0/O, 1/I/L)
3. **WebSocket 心跳**: 每 30 秒 ping/pong
4. **投票第一輪**: 只回傳百分比，不回傳具體人數
5. **秘密任務**: 只能透過 `/players/{id}/secret` 取得自己的任務
