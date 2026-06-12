# 1812 國會風雲 — 病毒式傳播開發計劃與技術路線圖

> **文件版本：** v1.0
> **建立日期：** 2026-03-13
> **狀態：** 規劃階段
> **前置依賴：** GDD_v2.md 核心機制已確認
> **目標：** 將病毒傳播機制融入產品開發各階段，實現自然增長 K-factor > 1

---

## 目錄

1. [總覽：傳播飛輪模型](#1-總覽傳播飛輪模型)
2. [階段對齊：與 GDD 路線圖整合](#2-階段對齊與-gdd-路線圖整合)
3. [Phase 0：傳播基礎設施（MVP 同步，第 1-4 週）](#3-phase-0傳播基礎設施mvp-同步第-1-4-週)
4. [Phase 1：內容引擎（Beta 同步，第 5-8 週）](#4-phase-1內容引擎beta-同步第-5-8-週)
5. [Phase 2：社群飛輪（Launch 同步，第 9-12 週）](#5-phase-2社群飛輪launch-同步第-9-12-週)
6. [Phase 3：增長加速（Post-Launch，第 13-20 週）](#6-phase-3增長加速post-launch第-13-20-週)
7. [技術架構總覽](#7-技術架構總覽)
8. [功能詳細規格](#8-功能詳細規格)
9. [關鍵指標與成功標準](#9-關鍵指標與成功標準)
10. [風險與緩解](#10-風險與緩解)
11. [社群運營計劃](#11-社群運營計劃)
12. [優先級矩陣](#12-優先級矩陣)

---

## 1. 總覽：傳播飛輪模型

### 1.1 核心飛輪

```
┌─────────────────────────────────────────────────────────┐
│                    病毒傳播飛輪                            │
│                                                         │
│   玩家完成一局                                           │
│       │                                                 │
│       ▼                                                 │
│   自動生成「名場面」內容                                   │
│   （報紙頭版 / 精華回放 / 戰績卡）                         │
│       │                                                 │
│       ▼                                                 │
│   玩家分享到社群平台                                      │
│   （LINE / Discord / IG / TikTok）                       │
│       │                                                 │
│       ▼                                                 │
│   新玩家看到 → 好奇 → 點擊                               │
│       │                                                 │
│       ▼                                                 │
│   「議會傳票」邀請 → 15 秒內進入遊戲                       │
│       │                                                 │
│       ▼                                                 │
│   新玩家完成第一局 → 成為飛輪的新起點                       │
│       │                                                 │
│       └─────────────────→ 回到頂部 ↑                     │
└─────────────────────────────────────────────────────────┘
```

### 1.2 傳播漏斗指標

| 漏斗階段 | 動作 | 目標轉化率 |
|---------|------|-----------|
| 局後分享 | 玩家看到名場面 → 分享到社群 | ≥ 25% |
| 內容觸達 | 社群好友看到分享 → 點擊連結 | ≥ 15% |
| 快速進入 | 點擊連結 → 進入遊戲 | ≥ 60% |
| 首局完成 | 進入遊戲 → 完成第一局 | ≥ 70% |
| 留存轉化 | 完成第一局 → D1 回訪 | ≥ 40% |

**計算：** 每局 4 人，每人 25% 分享率 = 每局產生 1 次分享。每次分享觸達 ~50 人 × 15% 點擊 × 60% 進入 × 70% 完成 = **每局帶來 ~3.2 個新完成玩家。** K-factor = 3.2 / 4 = **0.8**（接近自然增長臨界點）。加上好友邀請的直接管道，目標 K > 1。

---

## 2. 階段對齊：與 GDD 路線圖整合

```
GDD 路線圖          傳播路線圖             重點交付物
─────────────────────────────────────────────────────────
Week 1-4            Phase 0               議會傳票邀請系統
MVP                 傳播基礎設施           Deep Link 架構
(核心循環可玩)                             對局摘要 API
                                          分享按鈕 UI
─────────────────────────────────────────────────────────
Week 5-8            Phase 1               報紙頭版生成器
Beta                內容引擎              30 秒精華回放
(法案多樣性)                              戰績卡系統
                                          觀戰模式 v1
─────────────────────────────────────────────────────────
Week 9-12           Phase 2               跨局關係系統
Launch              社群飛輪              每週議題輪替
(排位+完整單機)                            實況主模式
                                          Discord Bot
─────────────────────────────────────────────────────────
Week 13-20          Phase 3               推薦系統
Post-Launch         增長加速              UGC 法案工坊
                                          賽季系統
                                          跨平台推播
─────────────────────────────────────────────────────────
```

---

## 3. Phase 0：傳播基礎設施（MVP 同步，第 1-4 週）

### 3.1 目標

在 MVP 核心循環完成的同時，埋入傳播的基礎管線。這個階段不追求完美的傳播體驗，而是確保「資料流通」——每局結束後的關鍵事件能被記錄、能被取用。

### 3.2 功能清單

#### F0-1：對局事件記錄系統

**描述：** 在遊戲引擎的結算流程中，新增「事件收集器」。每個回合的關鍵動作都被結構化記錄，供後續的報紙生成器、精華回放等功能使用。

**需記錄的事件類型：**

| 事件類型 | 資料結構 | 觸發時機 |
|---------|---------|---------|
| `CardPlayed` | `{player_id, card_type, target_id, round}` | 每回合翻牌時 |
| `CardResolved` | `{player_id, card_type, target_id, result, reputation_change}` | 結算完成時 |
| `AllianceFormed` | `{player_a, player_b, round}` | 雙向結盟成功 |
| `AllianceBroken` | `{betrayer_id, victim_id, round}` | 結盟後爆料 |
| `AgendaExposed` | `{exposer_id, target_id, agenda_content, round}` | 爆料成功 |
| `VoteResult` | `{bill_version, votes_per_player, final_result}` | 表決結束 |
| `AgendaRevealed` | `{player_id, agenda, completed}` | 議程揭示 |
| `ReputationMilestone` | `{player_id, old_rep, new_rep, cause}` | 聲望大幅變動（≥15） |

**技術實作方向：**

- 在現有 `server/src/game/engine.rs` 的結算邏輯中，增加 `GameEventCollector` trait
- 事件以 `Vec<GameEvent>` 累積在 `GameState` 中
- 每局結束時序列化為 JSON，存入 PostgreSQL 的 `game_logs` 表
- 同時推一份到 Redis 作為短期快取（供即時分享用，TTL 24 小時）

**資料庫新增表：**

```sql
-- 對局事件日誌
CREATE TABLE game_event_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(id),
    events JSONB NOT NULL,           -- 完整事件序列
    highlights JSONB,                -- 高亮事件（由後端自動提取）
    drama_score INTEGER DEFAULT 0,   -- 戲劇性評分（用於排序）
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 對局摘要（輕量版，用於快速查詢和分享頁）
CREATE TABLE game_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(id),
    bill_name VARCHAR(100),
    bill_result VARCHAR(10),         -- A / B / C / DEADLOCK
    player_count INTEGER,
    mvp_player_id UUID,              -- 最高分玩家
    biggest_betrayal JSONB,          -- 最大背叛事件
    closest_vote BOOLEAN DEFAULT FALSE, -- 是否驚險表決
    share_token VARCHAR(32) UNIQUE,  -- 分享用短碼
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**工期估計：** 3 天（與 MVP 核心開發並行）

---

#### F0-2：議會傳票邀請系統

**描述：** 玩家建立房間時，生成一張維多利亞風格的「議會傳票」圖片 + Deep Link。收到傳票的人點擊即可直接加入房間。

**使用者流程：**

```
建立房間
    │
    ▼
自動生成「議會傳票」
    │
    ├── 傳票圖片（視覺化邀請卡）
    │     ├── 維多利亞報紙風格排版
    │     ├── 房主角色頭像 + 派系徽章
    │     ├── 「議員 {名字} 傳召閣下出席國會辯論」
    │     ├── 房間資訊（法案名 / 人數 / 空位）
    │     └── QR Code + 短連結
    │
    └── Deep Link
          └── parliament1812://join/{room_code}
              ├── 已安裝 App → 直接跳轉加入房間
              ├── 未安裝（手機）→ App Store / Google Play
              └── 未安裝（桌面）→ Web 版 lobby
    │
    ▼
分享管道
    ├── LINE（圖片 + 連結）
    ├── Discord（Embed 卡片）
    ├── IG Story（傳票圖片 + 連結貼紙）
    ├── 複製連結
    └── 系統分享（iOS/Android Share Sheet）
```

**技術實作方向：**

- **傳票圖片生成：** 客戶端使用 Godot 的 `Viewport` + `SubViewport` 渲染傳票模板，`get_texture().get_image()` 匯出 PNG
- **Deep Link：**
  - iOS: Universal Links（需要 `apple-app-site-association` 設在 Fly.io 域名上）
  - Android: App Links（`assetlinks.json`）
  - Web fallback: `https://parliament1812.com/join/{code}` → 偵測平台後導流
- **後端新增 API：**
  - `POST /api/rooms/{id}/invite` → 生成 `share_token`（6 位英數短碼）
  - `GET /api/join/{share_token}` → 驗證房間狀態，返回 WebSocket 連線資訊
  - `GET /.well-known/apple-app-site-association` → iOS Universal Link 配置
  - `GET /.well-known/assetlinks.json` → Android App Link 配置

**後端路由新增（`server/src/api/`）：**

```
api/
├── handlers/
│   ├── mod.rs
│   ├── share_handler.rs    ← 新增：分享相關 API
│   └── invite_handler.rs   ← 新增：邀請連結驗證
└── router.rs               ← 新增路由
```

**工期估計：** 5 天
- Deep Link 基礎設施：2 天
- 傳票圖片模板（Godot 端）：2 天
- 分享 API + 短碼系統：1 天

---

#### F0-3：局後分享按鈕（最小版）

**描述：** 每局結束的結算畫面中，增加一個「分享」按鈕。Phase 0 只做最基礎版：截取結算畫面 + 附帶 Deep Link。Phase 1 才做報紙頭版生成器。

**客戶端實作方向：**

- 結算畫面增加「📤 分享戰報」按鈕
- 點擊後：截取當前結算畫面為圖片 → 呼叫系統 Share Sheet
- 分享內容包含：
  - 截圖圖片
  - 固定文案：「我在 1812 國會風雲中 {完成/未完成} 了議程！{法案名} 以 {結果} 通過。」
  - Deep Link：`https://parliament1812.com/replay/{game_id}`（Phase 1 才會有回放頁面，Phase 0 先導向下載頁）

**工期估計：** 1 天

---

#### F0-4：歸因追蹤系統

**描述：** 追蹤每個新玩家是「從哪裡來的」——是傳票邀請、社群分享、還是自然搜尋。這是後續優化傳播漏斗的數據基礎。

**資料庫新增欄位：**

```sql
-- 在 users 表新增
ALTER TABLE users ADD COLUMN referral_source VARCHAR(50);
-- 可能的值: 'invite_{user_id}', 'share_{game_id}', 'organic', 'streamer_{id}'

-- 歸因事件表
CREATE TABLE attribution_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    new_user_id UUID NOT NULL REFERENCES users(id),
    source_type VARCHAR(20) NOT NULL, -- 'invite' / 'share' / 'organic' / 'streamer'
    source_id VARCHAR(100),           -- 邀請者 user_id 或 game_id
    utm_params JSONB,                 -- UTM 參數
    platform VARCHAR(20),             -- ios / android / web
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**技術實作方向：**

- Deep Link 帶有 `?ref={source_type}_{source_id}` 參數
- 新用戶註冊時，從 URL 參數解析歸因資訊
- 後端 `server/src/services/` 新增 `attribution_service.rs`

**工期估計：** 2 天

---

### 3.3 Phase 0 總覽

| 功能 | 工期 | 優先級 | 依賴 |
|------|------|--------|------|
| F0-1 對局事件記錄 | 3 天 | P0 | 遊戲引擎結算流程 |
| F0-2 議會傳票邀請 | 5 天 | P0 | Deep Link 基礎設施 |
| F0-3 局後分享按鈕 | 1 天 | P1 | F0-1 |
| F0-4 歸因追蹤 | 2 天 | P1 | 用戶系統 |
| **總計** | **11 天**（與 MVP 並行） | | |

---

## 4. Phase 1：內容引擎（Beta 同步，第 5-8 週）

### 4.1 目標

把每局遊戲自動轉化為可傳播的內容。這是傳播飛輪的核心——玩家不需要「主動想分享什麼」，系統幫他生成值得分享的東西。

### 4.2 功能清單

#### F1-1：報紙頭版生成器（The Parliament Gazette）

**描述：** 每局結束後，自動生成一張維多利亞時代報紙風格的「對局回顧」圖片。

**報紙內容結構：**

```
┌──────────────────────────────────────────┐
│  THE PARLIAMENT GAZETTE  ❧ 1812年3月13日  │
│  ═══════════════════════════════════════  │
│                                          │
│  [大標題] 震驚！保守黨議員臨陣倒戈        │
│           法案以一票之差通過！             │
│                                          │
│  ─────────────────────────────────────   │
│  [副標題] 商行聯盟密謀敗露，              │
│           兩名議員議程遭公開處刑           │
│                                          │
│  ─────────────────────────────────────   │
│  [關鍵時刻]                              │
│  • 第2回合：議員A質詢議員B，發現...       │
│  • 第3回合：議員C爆料議員D，全場譁然      │
│  • 表決：法案B以 12:11 險勝              │
│                                          │
│  ─────────────────────────────────────   │
│  [玩家排名]    [法案結果]                 │
│  1. 議員A 85分  ┃ 機器法案               │
│  2. 議員B 72分  ┃ 版本B通過              │
│  3. 議員C 58分  ┃ 財產受保護             │
│  4. 議員D 41分  ┃                        │
│                                          │
│  ❧ parliament1812.com/g/{share_code} ❧   │
└──────────────────────────────────────────┘
```

**標題生成邏輯（後端）：**

根據 `game_event_logs` 中的事件，用規則引擎生成戲劇化標題：

| 觸發條件 | 標題模板 |
|---------|---------|
| 有 `AllianceBroken` 事件 | 「震驚！{背叛者派系}議員臨陣倒戈，{受害者}遭盟友出賣！」 |
| 表決票差 ≤ 3 | 「千鈞一髮！{法案名}以{票差}票之差{通過/否決}」 |
| 有 ≥ 2 次 `AgendaExposed` | 「血洗國會！{N}名議員議程遭公開處刑」 |
| 攪局派獲勝 | 「暗流湧動：神秘勢力操控議會，真相令人震驚」 |
| 某人全程未被質詢成功 | 「影子議員{名字}全身而退，無人能窺其真面目」 |
| 預設（無特殊事件） | 「國會新聞：{法案名}辯論落幕，{版本}方案獲得通過」 |

**技術實作方向：**

- **後端：** 在 `server/src/services/` 新增 `gazette_service.rs`
  - 從 `game_event_logs` 提取高亮事件
  - 用規則引擎匹配標題模板
  - 輸出結構化 JSON（標題、副標題、關鍵時刻列表、排名）
  - API: `GET /api/games/{id}/gazette` → 返回 JSON
- **客戶端：** Godot 中用 `SubViewport` 渲染報紙模板
  - 維多利亞風格字體 + 紋理背景
  - 支援中文、英文兩個版本
  - 匯出為 1080×1920 PNG（適合 IG Story）和 1200×630 PNG（適合 LINE / Discord）

**工期估計：** 8 天
- 後端標題生成邏輯：3 天
- 報紙模板設計 + Godot 渲染：4 天
- API + 分享整合：1 天

---

#### F1-2：30 秒精華回放

**描述：** 自動剪輯每局最戲劇化的 2-3 個瞬間，生成短影音。

**精華片段選取邏輯：**

| 戲劇性評分 | 事件類型 | 分數 |
|-----------|---------|------|
| 背叛 | `AllianceBroken` | 100 |
| 爆料 | `AgendaExposed` | 90 |
| 驚險表決 | 票差 ≤ 3 | 85 |
| 雙向結盟 | `AllianceFormed` | 60 |
| 互相質詢 | 兩人同回合互相 `CardPlayed(質詢)` | 70 |
| 反駁成功 | `CardResolved(反駁, success)` | 50 |
| 聲望暴跌 | `ReputationMilestone` 且 delta ≤ -20 | 75 |

**技術實作方向：**

- **方案 A（推薦，MVP 版）：** 不生成真正的影片，而是生成「動態圖文卡片輪播」
  - 每個高亮事件 → 一張動態卡片（3-5 秒）
  - 2-3 張卡片串接 → 類似 IG Story 的多頁格式
  - 客戶端用 `AnimationPlayer` 播放翻牌、聲望變動的預錄動畫
  - 匯出為 GIF 或短影片（Godot 的 `MovieWriter` API）

- **方案 B（進階版，Phase 2+）：** 伺服器端錄影
  - 伺服器重播 `game_event_logs`，用 headless Godot 渲染為影片
  - 需要額外的 GPU 伺服器資源，成本較高

**工期估計：** 10 天
- 精華片段選取邏輯（後端）：2 天
- 動態卡片模板設計：3 天
- 動畫播放 + GIF/影片匯出：4 天
- 分享整合：1 天

---

#### F1-3：個人戰績卡

**描述：** 每局結束後，為每個玩家生成一張個人化的戰績卡片。

**卡片內容：**

```
┌─────────────────────────────┐
│  ❧ 議會紀錄 ❧               │
│                             │
│  [角色頭像]  議員 {名字}     │
│  {派系}     聲望 {數值}      │
│                             │
│  ━━━ 本局表現 ━━━           │
│  🏆 排名：第 {N} 名          │
│  📊 議程：{完成/未完成}       │
│  🗡️ 質詢 {X} 次             │
│  🤝 結盟 {Y} 次              │
│  💣 爆料 {Z} 次              │
│                             │
│  ━━━ 本局成就 ━━━           │
│  🎭 影子大師                 │
│  🤝 信守承諾                 │
│                             │
│  ❧ parliament1812.com ❧     │
└─────────────────────────────┘
```

**工期估計：** 3 天

---

#### F1-4：分享頁面（Web Landing Page）

**描述：** 當非玩家點擊分享連結時，顯示一個精美的對局回顧頁面 + 下載引導。

**URL 結構：** `https://parliament1812.com/g/{share_code}`

**頁面結構：**

```
[報紙頭版圖片]
    │
[「查看完整戰報」展開]
    ├── 每回合出牌記錄（以卡牌圖標呈現）
    ├── 關鍵時刻時間線
    └── 最終排名 + 議程揭示
    │
[CTA 按鈕]
    ├── 「加入下一場國會」→ Deep Link / App Store
    └── 「挑戰 AI 議員」→ Web 版單機模式
```

**技術實作方向：**

- 靜態頁面部署在 Fly.io 同一服務上
- 後端 API `GET /api/games/{share_code}/public` 返回脫敏的對局摘要
- 前端用純 HTML + CSS + 少量 JS（無需 SPA 框架，追求極快載入）
- OpenGraph meta tags 做好：LINE / Discord / Twitter 預覽卡片

**工期估計：** 5 天

---

#### F1-5：觀戰模式 v1

**描述：** 允許非參戰玩家即時觀看一局遊戲。觀眾看到所有公開資訊（出牌、聲望變動、公開聊天），但看不到私密資訊（質詢結果、私訊）。

**技術實作方向：**

- 在現有 WebSocket hub（`server/src/websocket/hub.rs`）中增加 `Spectator` 連線類型
- Spectator 連線只接收 `PublicEvent` 類型的訊息
- 新增 API：`GET /api/rooms/{id}/spectate` → 返回觀戰 WebSocket URL
- 客戶端新增「觀戰模式 UI」——與遊戲 UI 相同，但隱藏手牌和出牌介面

**工期估計：** 5 天

---

### 4.3 Phase 1 總覽

| 功能 | 工期 | 優先級 | 依賴 |
|------|------|--------|------|
| F1-1 報紙頭版生成器 | 8 天 | P0 | F0-1 |
| F1-2 30 秒精華回放 | 10 天 | P1 | F0-1 |
| F1-3 個人戰績卡 | 3 天 | P1 | F0-1 |
| F1-4 分享頁面 | 5 天 | P0 | F0-2, F1-1 |
| F1-5 觀戰模式 v1 | 5 天 | P2 | WebSocket hub |
| **總計** | **31 天**（與 Beta 並行） | | |

---

## 5. Phase 2：社群飛輪（Launch 同步，第 9-12 週）

### 5.1 目標

從「單次分享」進化到「持續回訪」和「社群生態」。

### 5.2 功能清單

#### F2-1：跨局政治關係系統

**描述：** 記錄玩家之間的歷史互動，建立「政治關係圖譜」。

**關係資料模型：**

```sql
CREATE TABLE player_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_a UUID NOT NULL REFERENCES users(id),
    player_b UUID NOT NULL REFERENCES users(id),
    games_together INTEGER DEFAULT 0,
    alliances_formed INTEGER DEFAULT 0,
    alliances_broken INTEGER DEFAULT 0,  -- A 背叛 B 的次數
    exposes_given INTEGER DEFAULT 0,     -- A 爆料 B 的次數
    exposes_received INTEGER DEFAULT 0,  -- B 爆料 A 的次數
    trust_score INTEGER DEFAULT 50,      -- 0-100，50 為中立
    relationship_tag VARCHAR(20),        -- 'nemesis' / 'ally' / 'rival' / null
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_a, player_b)
);
```

**關係標籤自動計算：**

| 標籤 | 條件 | 展示 |
|------|------|------|
| 🤝 盟友 | `alliances_formed ≥ 3` 且 `alliances_broken = 0` | 「你們在 {N} 局中結盟 {M} 次，從未背叛」 |
| ⚔️ 宿敵 | `exposes_given + exposes_received ≥ 3` | 「你們互相爆料了 {M} 次，議會著名冤家」 |
| 🎭 亦敵亦友 | `alliances_formed ≥ 2` 且 `alliances_broken ≥ 1` | 「結盟 {M} 次，背叛 {N} 次——你永遠猜不透他」 |
| 🔥 死對頭 | `trust_score ≤ 10` | 「他就是你的政治死敵」 |

**客戶端展示：**

- 個人頁面增加「政治關係」分頁
- 用節點圖展示你與常玩好友的關係網
- 每週推送「本週政治關係報告」

**工期估計：** 7 天

---

#### F2-2：每週議題輪替

**描述：** 每週更換 2-3 個新法案議題 + 對應的隱藏議程組合，製造回訪理由。

**後端系統設計：**

```sql
CREATE TABLE weekly_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    week_number INTEGER NOT NULL,       -- 年度第幾週
    season_id UUID REFERENCES seasons(id),
    bills JSONB NOT NULL,               -- 本週可用法案列表
    special_agendas JSONB,              -- 本週特殊議程
    special_rules JSONB,                -- 本週特殊規則（可選）
    theme_name VARCHAR(100),            -- 主題名（如「工業革命週」）
    active_from TIMESTAMPTZ NOT NULL,
    active_until TIMESTAMPTZ NOT NULL
);
```

**運營節奏：**

| 週 | 主題 | 特殊規則 | 目的 |
|----|------|---------|------|
| 第 1 週 | 機器法案（基礎） | 無 | 基線數據 |
| 第 2 週 | 選舉改革 | 增加 1 個攪局派議程 | 增加混亂度 |
| 第 3 週 | 海軍預算 | 軍事維度影響結算 | 引入四維度 |
| 第 4 週 | 自由貿易 | 商行聯盟起始聲望+10 | 派系平衡測試 |
| ... | 每週輪替 | ... | ... |

**工期估計：** 5 天（含法案內容設計工具）

---

#### F2-3：實況主模式

**描述：** 為直播主提供專屬功能，降低「觀眾和實況主一起玩」的門檻。

**功能清單：**

| 功能 | 說明 |
|------|------|
| 觀眾快速加入 | 實況主開房間 → 生成「觀眾專屬加入碼」→ 觀眾在聊天室輸入碼即加入 |
| 觀眾預測投票 | 觀眾在直播平台聊天室投票「你覺得誰是攪局者？」，結果疊加在實況畫面 |
| OBS 疊加層 | 提供透明背景的觀戰資訊面板，供 OBS 疊加 |
| 延遲同步 | 觀戰畫面可設定 30-60 秒延遲，避免觀眾透過直播幫特定玩家作弊 |

**技術實作方向：**

- 新增 `server/src/api/handlers/streamer_handler.rs`
- OBS 疊加層：提供一個 `https://parliament1812.com/overlay/{room_id}` 的透明 HTML 頁面，用 WebSocket 即時更新
- 觀眾預測投票：可先用 Twitch 的 Prediction API / YouTube Live Chat API 整合（Phase 3 再做）
- 延遲同步：Spectator WebSocket 連線增加 `delay` 參數，伺服器端緩衝訊息

**工期估計：** 8 天

---

#### F2-4：Discord Bot

**描述：** 在 Discord 伺服器中提供遊戲相關功能。

**指令清單：**

| 指令 | 功能 |
|------|------|
| `/parliament create` | 在 Discord 頻道中建立房間，生成邀請連結 |
| `/parliament stats @user` | 查看某人的戰績 |
| `/parliament leaderboard` | 本伺服器排行榜 |
| `/parliament gazette` | 查看最近一局的報紙頭版 |
| `/parliament challenge @user` | 向某人下戰帖（生成雙人邀請碼） |

**技術實作方向：**

- 獨立服務，用 Rust + Serenity（Discord Bot 框架）
- 呼叫現有後端 API 獲取數據
- 部署在 Fly.io 同一組織下

**工期估計：** 6 天

---

### 5.3 Phase 2 總覽

| 功能 | 工期 | 優先級 | 依賴 |
|------|------|--------|------|
| F2-1 跨局政治關係 | 7 天 | P0 | F0-1, 用戶系統 |
| F2-2 每週議題輪替 | 5 天 | P0 | 法案系統 |
| F2-3 實況主模式 | 8 天 | P1 | F1-5 觀戰模式 |
| F2-4 Discord Bot | 6 天 | P1 | 後端 API |
| **總計** | **26 天**（與 Launch 並行） | | |

---

## 6. Phase 3：增長加速（Post-Launch，第 13-20 週）

### 6.1 功能清單

#### F3-1：推薦匹配系統

**描述：** 根據玩家的遊戲風格、政治關係、在線時間，推薦「你可能想挑戰的對手」。

**推薦邏輯：**

| 推薦類型 | 觸發條件 | 推送文案 |
|---------|---------|---------|
| 宿敵再戰 | 與某人的 `trust_score ≤ 20` | 「你的宿敵 {名字} 正在線上，要去議會找他算帳嗎？」 |
| 盟友開局 | 常玩好友建立了房間 | 「你的盟友 {名字} 開了一桌國會，需要你的支持」 |
| 風格匹配 | 新玩家 vs 同風格的活躍玩家 | 「這位議員的風格和你很像，來看看誰更強？」 |

**工期估計：** 6 天

---

#### F3-2：UGC 法案工坊

**描述：** 允許玩家自訂法案議題和隱藏議程，在好友房中使用。

**功能：**

- 法案編輯器：設定法案名、A/B/C 三版本的描述和四維度影響
- 議程編輯器：設定自訂勝利條件（從預設條件模板中組合）
- 社群投票：自訂法案可以提交到「議案庫」，被社群投票後納入正式每週輪替

**工期估計：** 10 天

---

#### F3-3：賽季系統

**描述：** 每 8 週一個賽季，賽季有主題、專屬法案、排位獎勵。

**賽季結構：**

```
第一賽季：工業革命（Week 1-8）
    ├── 法案主題：工廠法、鐵路法、礦業法...
    ├── 排位獎勵：賽季限定卡牌外觀
    ├── 賽季挑戰：完成 20 個條件解鎖稱號
    └── 賽季結算：排行榜 → 獎勵發放

第二賽季：殖民擴張（Week 9-16）
    └── ...
```

**工期估計：** 8 天

---

#### F3-4：跨平台推播與再行銷

**描述：** 透過推播通知、Email、Discord 觸及流失玩家。

**推播策略：**

| 觸發條件 | 通知內容 | 時機 |
|---------|---------|------|
| D1 未回訪 | 「議會還在等你回來，新的法案需要你的一票」 | 安裝後 24 小時 |
| D3 未回訪 | 「你的宿敵 {名字} 已經贏了 3 局，你不來嗎？」 | 安裝後 72 小時 |
| D7 未回訪 | 「本週議題：{法案名}——全新的政治風暴」 | 每週一 |
| 好友上線 | 「你的盟友 {名字} 正在開局」 | 好友開房間時 |
| 賽季開始 | 「第 {N} 賽季開始！新法案、新挑戰、新獎勵」 | 賽季首日 |

**工期估計：** 5 天

---

### 6.3 Phase 3 總覽

| 功能 | 工期 | 優先級 | 依賴 |
|------|------|--------|------|
| F3-1 推薦匹配 | 6 天 | P1 | F2-1 |
| F3-2 UGC 法案工坊 | 10 天 | P2 | 法案系統 |
| F3-3 賽季系統 | 8 天 | P1 | 排位系統 |
| F3-4 跨平台推播 | 5 天 | P0 | 推播基礎設施 |
| **總計** | **29 天** | | |

---

## 7. 技術架構總覽

### 7.1 新增模組架構（後端）

```
server/src/
├── services/
│   ├── gazette_service.rs        ← 新增：報紙頭版生成
│   ├── highlight_service.rs      ← 新增：精華事件提取
│   ├── attribution_service.rs    ← 新增：歸因追蹤
│   ├── relationship_service.rs   ← 新增：玩家關係系統
│   ├── weekly_service.rs         ← 新增：每週議題管理
│   ├── notification_service.rs   ← 新增：推播通知
│   └── ...（既有服務）
├── api/handlers/
│   ├── share_handler.rs          ← 新增：分享相關 API
│   ├── invite_handler.rs         ← 新增：邀請連結驗證
│   ├── gazette_handler.rs        ← 新增：報紙 API
│   ├── streamer_handler.rs       ← 新增：實況主功能
│   ├── relationship_handler.rs   ← 新增：關係查詢
│   └── ...（既有處理器）
├── game/
│   ├── event_collector.rs        ← 新增：對局事件收集器
│   └── ...（既有遊戲引擎）
└── websocket/
    ├── spectator.rs              ← 新增：觀戰連線管理
    └── ...（既有 WebSocket）
```

### 7.2 新增 API 端點

| 端點 | 方法 | 用途 | Phase |
|------|------|------|-------|
| `/api/rooms/{id}/invite` | POST | 生成邀請短碼 | 0 |
| `/api/join/{share_token}` | GET | 驗證邀請加入 | 0 |
| `/api/games/{id}/events` | GET | 取得對局事件 | 0 |
| `/api/games/{id}/gazette` | GET | 取得報紙頭版資料 | 1 |
| `/api/games/{id}/highlights` | GET | 取得精華片段 | 1 |
| `/api/games/{share_code}/public` | GET | 公開分享頁資料 | 1 |
| `/api/rooms/{id}/spectate` | GET | 觀戰 WebSocket URL | 1 |
| `/api/users/{id}/relationships` | GET | 玩家關係圖 | 2 |
| `/api/weekly/current` | GET | 當前週議題 | 2 |
| `/overlay/{room_id}` | GET | OBS 觀戰疊加層 | 2 |

### 7.3 資料庫遷移計劃

| 遷移檔 | Phase | 內容 |
|--------|-------|------|
| `V5__game_event_logs.sql` | 0 | `game_event_logs` + `game_summaries` |
| `V6__attribution.sql` | 0 | `attribution_events` + `users` 新增欄位 |
| `V7__weekly_bills.sql` | 2 | `weekly_bills` + `seasons` |
| `V8__relationships.sql` | 2 | `player_relationships` |
| `V9__ugc_bills.sql` | 3 | `community_bills` + `bill_votes` |

### 7.4 客戶端新增模組（Godot）

```
godot_client/
├── scenes/share/
│   ├── parliament_gazette.tscn    ← 報紙頭版模板場景
│   ├── summons_card.tscn          ← 議會傳票模板場景
│   ├── player_stats_card.tscn     ← 個人戰績卡模板
│   └── highlight_player.tscn      ← 精華回放播放器
├── scripts/share/
│   ├── gazette_renderer.gd        ← 報紙渲染邏輯
│   ├── share_manager.gd           ← 分享管理器（調用系統 Share Sheet）
│   ├── deep_link_handler.gd       ← Deep Link 處理
│   └── image_exporter.gd          ← SubViewport 匯出 PNG
├── scenes/spectator/
│   ├── spectator_hud.tscn         ← 觀戰 HUD
│   └── spectator_controller.gd    ← 觀戰邏輯
└── assets/share/
    ├── fonts/                     ← 維多利亞風格字體
    ├── textures/                  ← 報紙紋理、邊框
    └── templates/                 ← 各種分享模板素材
```

---

## 8. 功能詳細規格

### 8.1 Deep Link 路由表

| URL Pattern | 目標 | 參數 |
|-------------|------|------|
| `parliament1812://join/{room_code}` | 加入房間 | `ref` |
| `parliament1812://replay/{game_id}` | 查看對局回顧 | — |
| `parliament1812://profile/{user_id}` | 查看玩家資料 | — |
| `parliament1812://weekly` | 查看本週議題 | — |
| `https://parliament1812.com/join/{code}` | Web fallback | `ref`, `utm_*` |
| `https://parliament1812.com/g/{share_code}` | 分享頁面 | — |
| `https://parliament1812.com/overlay/{room_id}` | OBS 疊加層 | `delay` |

### 8.2 分享內容規格

| 分享類型 | 圖片尺寸 | 文案長度 | 包含 Deep Link |
|---------|---------|---------|---------------|
| 議會傳票 | 1080×1080 | ≤ 50 字 | ✅ 加入房間 |
| 報紙頭版 | 1080×1920（Story）/ 1200×630（Feed） | ≤ 100 字 | ✅ 查看回顧 |
| 個人戰績卡 | 1080×1080 | ≤ 30 字 | ✅ 個人資料 |
| 精華回放 | 1080×1920 GIF/MP4 | ≤ 50 字 | ✅ 查看回顧 |

### 8.3 「戲劇性評分」算法

每局結束時計算 `drama_score`，用於排序精華和推薦：

```
drama_score =
    (betrayal_count × 30)           // 背叛次數
  + (expose_count × 25)             // 爆料次數
  + (close_vote ? 20 : 0)           // 驚險表決
  + (max_rep_swing × 0.5)           // 最大聲望波動
  + (mutual_challenge_count × 15)   // 互相質詢次數
  + (defection_count × 20)          // 倒戈次數
  + (underdog_win ? 25 : 0)         // 低聲望玩家獲勝
```

---

## 9. 關鍵指標與成功標準

### 9.1 北極星指標

**每週活躍局數（WAG, Weekly Active Games）**

這是最核心的指標。每一局都代表 4-6 個活躍玩家在互動。WAG 增長 = 用戶增長 × 留存 × 頻率，三合一。

### 9.2 Phase 指標

| Phase | 關鍵指標 | 目標值 | 衡量方式 |
|-------|---------|--------|---------|
| **Phase 0** | 邀請連結轉化率 | ≥ 40% 點擊 → 加入房間 | `attribution_events` |
| **Phase 0** | 首局完成率 | ≥ 70% 進入 → 完成 | 客戶端事件 |
| **Phase 1** | 局後分享率 | ≥ 25% 的局有至少 1 人分享 | 分享按鈕點擊數 / 總局數 |
| **Phase 1** | 分享頁 CTR | ≥ 15% 查看 → 點擊 CTA | Web 分析 |
| **Phase 2** | D7 留存率 | ≥ 30% | `users` + 活躍記錄 |
| **Phase 2** | K-factor | ≥ 0.8（目標 > 1） | 歸因數據 |
| **Phase 3** | D30 留存率 | ≥ 15% | 長期留存追蹤 |
| **Phase 3** | 自然增長佔比 | ≥ 60%（非付費） | 歸因數據 |

### 9.3 反指標（防止過度優化）

| 反指標 | 警戒值 | 意義 |
|--------|--------|------|
| 分享後立即解除安裝 | > 5% | 分享機制可能太煩人 |
| 推播導致的解除通知 | > 10% | 推播頻率或內容有問題 |
| 每局平均時長偏離 | < 8 分鐘或 > 15 分鐘 | 新功能干擾了核心循環 |

---

## 10. 風險與緩解

| 風險 | 影響 | 可能性 | 緩解策略 |
|------|------|--------|---------|
| Deep Link 跨平台相容性問題 | 邀請轉化率低 | 高 | 先只做 Web fallback，確保 100% 可用；Native Deep Link 逐步加入 |
| 報紙生成延遲影響分享體驗 | 分享率低 | 中 | 預渲染：對局結算時就開始生成，不等玩家點分享 |
| 每週議題輪替的內容量不足 | 內容乾涸 | 中 | 建立法案模板系統，降低新法案設計成本；Phase 3 引入 UGC |
| 觀戰延遲導致作弊 | 競技公平性 | 低 | 強制 60 秒延遲；排位賽不開放觀戰 |
| Discord Bot 維護成本 | 開發資源分散 | 中 | Phase 2 只做核心 3 個指令，其餘延後 |
| 精華回放的檔案大小 | 分享不順暢 | 高 | GIF 限制 15 秒 / 5MB；提供「分享為圖片」的備選方案 |

---

## 11. 社群運營計劃

### 11.1 冷啟動時間線

```
Week -2（上線前 2 週）
├── 進入 10-15 個中文狼人殺 / 社交推理 Discord 伺服器
├── 找到各伺服器的活躍組局管理員
├── 提供封測資格：每人 1 個帳號 + 5 個好友邀請碼
└── 建立官方 Discord 伺服器，設立 #封測回饋 頻道

Week -1（上線前 1 週）
├── 封測玩家開始遊玩 → 收集第一批回饋
├── 發布「報紙頭版」範例到社群 → 測試傳播效果
└── 聯繫 3-5 位中型 YouTuber / 實況主（5-30 萬訂閱）

Week 0（正式上線）
├── 公開 Discord 伺服器
├── 實況主同步開播（與粉絲一起玩）
└── App Store / Google Play 上架

Week 1-4
├── 每日在 Discord 發布「每日最佳報紙頭版」
├── 舉辦「週末國會」活動（固定時間組局）
├── 實況主內容持續產出
└── 監控 K-factor，調整分享機制
```

### 11.2 實況主合作策略

| 階段 | 對象 | 合作形式 | 預算 |
|------|------|---------|------|
| 封測 | 桌遊 / 狼人殺 Discord 管理員（5-10 人） | 免費封測資格 + 專屬角色頭銜 | $0 |
| 上線 | 中型 YouTuber（5-30 萬，3-5 人） | 邀請與粉絲共玩，非付費業配 | 免費帳號 + 遊戲內道具 |
| Week 4+ | 較大型實況主（30-100 萬，1-2 人） | 實況主模式搶先體驗 + 聯名道具 | 少量現金 + 聯名收益分潤 |

### 11.3 社群平台策略

| 平台 | 內容類型 | 發布頻率 | 目標 |
|------|---------|---------|------|
| Discord | 每日報紙頭版 + 組局公告 | 每日 | 核心社群經營 |
| YouTube | 實況精華剪輯 | 每週 2-3 支 | 拉新 |
| TikTok / Shorts | 30 秒精華回放 | 每日 1-2 支 | 病毒傳播 |
| IG Story | 戰績卡 + 報紙頭版 | 玩家自發 | 社交分享 |
| LINE 群組 | 議會傳票邀請 | 玩家自發 | 好友邀請 |
| PTT / 巴哈 | 遊戲介紹 + 攻略 | 每週 1 篇 | 社群討論 |

---

## 12. 優先級矩陣

### 12.1 影響力 vs 工程成本

```
          高影響力
            │
    ┌───────┼───────┐
    │       │       │
    │ F0-2  │ F1-1  │
    │ 傳票  │ 報紙  │
    │       │       │
    │ F2-2  │ F1-2  │
    │ 週輪替│ 回放  │
    │       │       │
低成本──────┼──────高成本
    │       │       │
    │ F0-3  │ F2-3  │
    │ 分享鈕│ 實況  │
    │       │       │
    │ F0-4  │ F3-2  │
    │ 歸因  │ UGC   │
    │       │       │
    └───────┼───────┘
            │
          低影響力
```

### 12.2 最終優先排序

| 排序 | 功能 | 工期 | 理由 |
|------|------|------|------|
| 🥇 1 | F0-1 對局事件記錄 | 3 天 | 所有傳播功能的資料基礎，必須最先做 |
| 🥇 2 | F0-2 議會傳票邀請 | 5 天 | 直接驅動新用戶獲取，K-factor 的核心 |
| 🥇 3 | F1-1 報紙頭版生成器 | 8 天 | 最高 ROI 的傳播內容，玩家會主動分享 |
| 🥈 4 | F0-3 局後分享按鈕 | 1 天 | 成本極低，立即可用 |
| 🥈 5 | F1-4 分享頁面 | 5 天 | 承接所有分享流量，沒有它分享就斷鏈 |
| 🥈 6 | F2-2 每週議題輪替 | 5 天 | 留存驅動器，低成本高回報 |
| 🥈 7 | F2-1 跨局政治關係 | 7 天 | 長線留存的核心，製造情感連結 |
| 🥉 8 | F0-4 歸因追蹤 | 2 天 | 數據驅動優化的基礎 |
| 🥉 9 | F1-3 個人戰績卡 | 3 天 | 低成本的額外分享素材 |
| 🥉 10 | F1-2 30 秒精華回放 | 10 天 | 高傳播力但工程成本大，可延後 |
| 🥉 11 | F2-4 Discord Bot | 6 天 | 社群經營工具，非核心 |
| 🥉 12 | F1-5 觀戰模式 | 5 天 | 實況主模式的前置，可延後 |
| 🥉 13 | F2-3 實況主模式 | 8 天 | 高槓桿但需要實況主生態先建立 |
| 📋 14 | F3-4 推播系統 | 5 天 | 留存工具，Post-Launch 再做 |
| 📋 15 | F3-1 推薦匹配 | 6 天 | 需要足夠用戶量才有意義 |
| 📋 16 | F3-3 賽季系統 | 8 天 | 長線留存，需要先有穩定用戶群 |
| 📋 17 | F3-2 UGC 法案工坊 | 10 天 | 社群飛輪的終極形態，但優先級最低 |

---

## 附錄 A：名詞對照

| 術語 | 定義 |
|------|------|
| K-factor | 每個用戶平均帶來的新用戶數。K > 1 = 自然病毒增長 |
| WAG | Weekly Active Games，每週活躍局數 |
| Deep Link | 可以直接跳轉到 App 特定頁面的 URL |
| Share Sheet | iOS / Android 系統級分享面板 |
| OBS | Open Broadcaster Software，實況主用的串流軟體 |
| Drama Score | 對局戲劇性評分，用於排序精華和推薦 |
| CTA | Call To Action，行動呼籲按鈕 |
| CTR | Click Through Rate，點擊率 |

---

> **下一步：** 確認本文件後，開始 Phase 0 的技術實作。建議先從 F0-1（對局事件記錄系統）開始，因為它是所有傳播功能的資料基礎。
