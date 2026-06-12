# 1812 國會風雲 — Claude Code 開發指令【已封存 2026-06-12】

> ⚠️ 本文件為專案初建時期（Flutter + Node.js + Railway）的逐步開發指令，路徑與技術棧均已過時。
> 現行開發手冊：根目錄 `CLAUDE.md`；設計權威：`docs/GDD_v3_Design_Response.md`。

## 開發順序總覽

```
Step 1: Flutter 專案初始化 + 依賴
Step 2: 核心模型（角色、遊戲狀態）
Step 3: UI 框架（首頁、房間列表）
Step 4: 遊戲畫面（辯論、投票）
Step 5: Node.js 後端 + WebSocket
Step 6: 前後端連接
Step 7: Railway 部署
```

---

## Step 1: Flutter 專案初始化

```
請在 /Users/zhongliyuanshiqi/Documents/parliament1812/platforms/flutter 建立 Flutter 專案結構。

要求：
1. 建立 lib/ 資料夾結構：
   - lib/main.dart
   - lib/app/app.dart
   - lib/core/theme/app_theme.dart
   - lib/core/constants/game_constants.dart
   - lib/providers/game_provider.dart
   - lib/presentation/screens/home_screen.dart
   - lib/presentation/screens/lobby_screen.dart
   - lib/presentation/screens/game_screen.dart
   - lib/presentation/widgets/common/

2. 更新 pubspec.yaml 加入依賴：
   - flutter_riverpod: ^2.4.0
   - go_router: ^12.0.0
   - socket_io_client: ^2.0.0
   - google_fonts: ^6.1.0
   - uuid: ^4.0.0

3. 建立維多利亞風格主題（參考 CLAUDE.md 的顏色）

4. 確保 main.dart 可以正常啟動顯示首頁

先只做基礎框架，不用實作完整邏輯。
```

---

## Step 2: 核心模型

```
請在 Flutter 專案建立遊戲核心模型。

位置：lib/domain/models/

要建立的模型：

1. player.dart - 玩家模型
   - id: String
   - name: String
   - roleId: String?
   - reputation: int (聲望/生命值)
   - gold: int (金幣)
   - isAlive: bool (政治死亡判定)
   - isReady: bool

2. role.dart - 角色模型
   - id: String
   - name: String (工人湯瑪斯、工廠主理查、記者愛德華、盧德派喬治)
   - faction: Faction (worker/factory/press/luddite)
   - initialReputation: int
   - skillName: String
   - skillDescription: String

3. game_state.dart - 遊戲狀態
   - roomId: String
   - phase: GamePhase (waiting/conspiracy/debate/voting/result)
   - players: List<Player>
   - currentTurn: int
   - billVotes: Map<String, BillOption> (A/B/C)
   - timeRemaining: int

4. action.dart - 遊戲動作
   - GameAction 抽象類
   - QueryAction (質詢攻擊)
   - RebutAction (反駁防禦)
   - SkillAction (使用技能)
   - VoteAction (投票)

5. 在 lib/core/constants/game_constants.dart 定義：
   - 4 個角色的完整資料
   - 傷害計算公式
   - 階段時間限制

參考 docs/GAME_SYSTEM_DESIGN.md 的設計。
```

---

## Step 3: UI 框架 — 首頁 + 房間

```
請建立遊戲的首頁和房間系統 UI。

1. lib/presentation/screens/home_screen.dart
   - 遊戲標題「1812 國會風雲」
   - 維多利亞風格背景
   - 「創建房間」按鈕
   - 「加入房間」按鈕（輸入房間代碼）
   - 玩家暱稱輸入框

2. lib/presentation/screens/lobby_screen.dart
   - 顯示房間代碼（可複製）
   - 玩家列表（顯示已加入的玩家）
   - 玩家準備狀態
   - 「準備」按鈕
   - 房主「開始遊戲」按鈕（全員準備後可點）
   - 最少 4 人才能開始

3. lib/presentation/widgets/
   - victorian_button.dart — 維多利亞風格按鈕
   - player_avatar.dart — 玩家頭像卡片
   - room_code_display.dart — 房間代碼顯示

4. 使用 go_router 設定路由：
   - / → HomeScreen
   - /lobby/:roomId → LobbyScreen
   - /game/:roomId → GameScreen

5. 風格要求：
   - 深色背景 (#1A1A2E)
   - 金色強調 (#D4AF37)
   - 優雅的邊框裝飾
   - Google Fonts: Cinzel (標題)、Lora (內文)

先用假資料測試 UI，之後再接 WebSocket。
```

---

## Step 4: 遊戲畫面

```
請建立遊戲主要畫面。

1. lib/presentation/screens/game_screen.dart
   - 頂部：階段指示器 + 倒數計時
   - 中間：根據階段顯示不同內容
   - 底部：玩家狀態欄

2. lib/presentation/widgets/game/
   
   a. phase_indicator.dart — 階段指示
      - 密謀 → 辯論 → 投票 → 結算
      - 當前階段高亮
   
   b. player_status_bar.dart — 玩家狀態
      - 頭像 + 暱稱
      - 聲望條（紅色血條風格）
      - 金幣數量
      - 角色技能按鈕
   
   c. debate_panel.dart — 辯論階段
      - 議案內容顯示
      - 發言輸入框
      - 「質詢」按鈕（選擇目標 → 確認攻擊）
      - 「反駁」按鈕
      - 發言歷史記錄
   
   d. voting_panel.dart — 投票階段
      - 三個選項按鈕 (A/B/C)
      - 當前票數顯示（投票後才顯示）
      - 確認投票按鈕
   
   e. result_panel.dart — 結算畫面
      - 投票結果
      - 各玩家得分
      - 身份揭露
      - 「再來一局」按鈕

3. lib/presentation/widgets/game/action_target_selector.dart
   - 選擇質詢目標的彈窗
   - 顯示所有存活玩家
   - 點擊選擇 → 確認

4. 動畫效果：
   - 聲望變化時的數字跳動
   - 質詢時的攻擊特效（簡單閃爍即可）
   - 階段轉換的淡入淡出

使用 Riverpod 管理遊戲狀態，先用假資料測試流程。
```

---

## Step 5: Node.js 後端

```
請在 /Users/zhongliyuanshiqi/Documents/parliament1812/backend 建立 Node.js 後端。

1. 專案結構：
   backend/
   ├── package.json
   ├── tsconfig.json
   ├── src/
   │   ├── index.ts          # 入口
   │   ├── server.ts         # Express + Socket.IO
   │   ├── socket/
   │   │   ├── handlers.ts   # Socket 事件處理
   │   │   └── events.ts     # 事件常數
   │   ├── game/
   │   │   ├── GameRoom.ts   # 房間邏輯
   │   │   ├── GameState.ts  # 遊戲狀態
   │   │   └── actions.ts    # 動作處理
   │   └── models/
   │       ├── Player.ts
   │       └── Role.ts
   └── Dockerfile

2. 依賴：
   - express
   - socket.io
   - typescript
   - uuid
   - cors

3. Socket.IO 事件：
   
   Client → Server:
   - create_room { playerName }
   - join_room { roomId, playerName }
   - player_ready { roomId }
   - start_game { roomId }
   - game_action { roomId, action }
   - vote { roomId, option }
   
   Server → Client:
   - room_created { roomId }
   - player_joined { player }
   - player_left { playerId }
   - game_started { gameState }
   - phase_changed { phase, timeRemaining }
   - action_result { action, result }
   - game_ended { results }

4. 遊戲邏輯：
   - 房間管理（創建、加入、離開）
   - 階段計時器（密謀 2 分鐘、辯論 5 分鐘、投票 2 分鐘）
   - 質詢傷害計算
   - 投票計票（聲望加權）

5. 暫時用記憶體存儲（之後再加 PostgreSQL）

確保可以本地啟動測試。
```

---

## Step 6: 前後端連接

```
請將 Flutter 前端連接到 Node.js 後端。

1. lib/data/services/socket_service.dart
   - 單例模式
   - 連接 / 斷線處理
   - 事件監聽與發送
   - 自動重連機制

2. lib/providers/
   - socket_provider.dart — Socket 連接狀態
   - room_provider.dart — 房間狀態
   - game_provider.dart — 遊戲狀態（更新為真實資料）

3. 連接流程：
   a. 首頁：輸入暱稱 → 創建/加入房間
   b. 大廳：WebSocket 連接 → 監聽玩家加入
   c. 遊戲：監聽階段變化 → 發送動作 → 接收結果

4. 錯誤處理：
   - 連接失敗提示
   - 房間不存在提示
   - 斷線重連

5. 測試：
   - 本地啟動後端 (localhost:3000)
   - Flutter 連接測試
   - 兩個模擬器同時測試

後端 URL 先寫成可配置的，之後部署時切換。
```

---

## Step 7: Railway 部署

```
請配置 Railway 部署。

1. 更新 /Users/zhongliyuanshiqi/Documents/parliament1812/railway.toml：
   [build]
   builder = "nixpacks"
   
   [deploy]
   startCommand = "cd backend && npm start"
   healthcheckPath = "/health"
   healthcheckTimeout = 100
   restartPolicyType = "on_failure"
   restartPolicyMaxRetries = 3

2. backend/src/server.ts 加入 health check：
   app.get('/health', (req, res) => res.send('OK'));

3. 環境變數設定（Railway Dashboard）：
   - PORT: 由 Railway 自動設定
   - NODE_ENV: production

4. Flutter 端更新：
   - lib/core/constants/api_constants.dart
   - 開發環境：localhost:3000
   - 生產環境：Railway URL

5. 部署步驟：
   a. 確保 backend/ 可以獨立運行
   b. git push 到 GitHub
   c. Railway 連接 GitHub repo
   d. 設定 root directory 為 backend/
   e. 部署並取得 URL
   f. 更新 Flutter 的 API URL
   g. 測試連接

6. Flutter 打包：
   - flutter build apk --release
   - flutter build ios --release
```

---

## 快速測試指令

```bash
# 後端本地測試
cd backend && npm install && npm run dev

# Flutter 測試
cd platforms/flutter && flutter run

# 同時測試（開兩個終端）
# 終端 1: 後端
cd /Users/zhongliyuanshiqi/Documents/parliament1812/backend && npm run dev

# 終端 2: Flutter
cd /Users/zhongliyuanshiqi/Documents/parliament1812/platforms/flutter && flutter run
```

---

## 注意事項

1. **先做能跑的版本，再優化**
2. **每完成一個 Step 就測試**
3. **遇到問題先看 docs/GAME_SYSTEM_DESIGN.md**
4. **UI 風格參考 parliament_assets/**

---

**目標：2 週內 4 人可線上對戰！加油！！**
