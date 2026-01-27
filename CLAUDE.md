# 1812 國會風雲 — MVP 開發指引

## 專案概述

**1812 國會風雲**是一款以英國工業革命為背景的多人線上社交推理遊戲。
核心創新：**議會辯論 RPG** — 將 RPG 戰鬥系統融入社交推理遊戲。

## 技術棧

- **前端**：Flutter（跨平台：iOS、Android、Web）
- **狀態管理**：Riverpod
- **後端**：Rust (Axum + Tokio)
- **部署**：Fly.io
- **資料庫**：PostgreSQL (Fly Postgres)
- **快取**：Redis (Fly Redis)
- **即時通訊**：Tokio-Tungstenite (WebSocket)

## 核心設計（詳見 docs/GAME_SYSTEM_DESIGN.md）

### 聲望 = 生命

```
初始聲望：50-100（依角色）
歸零效果：政治死亡（失去投票權，但可幕後影響）
```

### 辯論 = 戰鬥

```
質詢 → 攻擊（消耗 10 聲望，造成 15 傷害）
反駁 → 防禦（消耗 5 聲望，抵消質詢）
```

### MVP 角色（4 個）

| 角色 | 聲望 | 技能 |
|------|------|------|
| 🔨 工人湯瑪斯 | 70 | 團結：每有 1 名工人盟友，防禦 +10 |
| 💰 工廠主理查 | 60 | 收買：花費金幣使目標沉默 1 回合 |
| 📰 記者愛德華 | 50 | 爆料：揭露目標的秘密任務 |
| 🔥 盧德派喬治 | 80 | 怒火：造成雙倍傷害，但自己也扣 10 聲望 |

### MVP 議案（1 個）

**【機器法案】**
- A. 禁止機器 → 工人派 +50 分
- B. 保護財產 → 資方派 +50 分
- C. 折衷改革 → 改革派 +30 分

### 遊戲流程（10-15 分鐘）

```
Phase 1: 密謀（2 分鐘）→ 私訊、結盟
Phase 2: 辯論（5 分鐘）→ 質詢、反駁、技能
Phase 3: 投票（2 分鐘）→ 聲望加權計票
```

## 專案結構

```
parliament1812/
├── docs/                       # 設計文檔（重要！）
│   └── GAME_SYSTEM_DESIGN.md   # 完整遊戲設計
├── parliament_assets/          # UI 設計、主題、素材
├── platforms/flutter/          # Flutter 前端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/               # App 入口
│   │   ├── core/              # 核心：主題、常數、工具
│   │   ├── data/              # 資料層：API、WebSocket
│   │   ├── domain/            # 領域層：模型、邏輯
│   │   ├── presentation/      # UI 層：頁面、元件
│   │   └── providers/         # Riverpod 狀態
│   └── assets/                # 素材
├── server/                     # Rust 後端（主要）
│   ├── src/
│   │   ├── main.rs            # 應用程式入口
│   │   ├── lib.rs             # 模組匯出
│   │   ├── api/               # HTTP API 路由和處理器
│   │   ├── auth/              # JWT 認證
│   │   ├── cache/             # Redis 快取
│   │   ├── config/            # 應用設定
│   │   ├── domain/            # 領域模型
│   │   ├── error/             # 錯誤處理
│   │   ├── game/              # 遊戲引擎
│   │   ├── repository/        # 資料存取層
│   │   ├── services/          # 業務邏輯
│   │   └── websocket/         # WebSocket 模組
│   ├── migrations/            # 資料庫遷移
│   ├── fly.toml               # Fly.io 部署設定
│   ├── Dockerfile             # Docker 映像檔
│   └── Cargo.toml             # Rust 依賴
├── backend/                    # Node.js 後端（舊版）
│   └── ...
└── .github/workflows/          # GitHub Actions CI/CD
    ├── deploy-server.yml      # 自動部署
    └── rust-check.yml         # PR 檢查
```

## 開發原則

1. **MVP 優先**：先做最小可玩版本
2. **簡單至上**：複雜功能之後再加
3. **可玩性**：確保核心循環有趣
4. **可測試**：方便快速迭代

## 設計參考

- `docs/GAME_SYSTEM_DESIGN.md` — 完整遊戲系統設計
- `parliament_assets/theme/` — UI 主題設定
- `parliament_assets/components/` — UI 元件參考

## 顏色主題

```dart
// 維多利亞風格配色
primaryDark: Color(0xFF1A1A2E)    // 深藍黑
primaryMid: Color(0xFF16213E)     // 中藍
accent: Color(0xFFD4AF37)         // 金色
textPrimary: Color(0xFFE8E8E8)    // 淺灰
textSecondary: Color(0xFFA0A0A0)  // 中灰
danger: Color(0xFFE74C3C)         // 紅色
success: Color(0xFF27AE60)        // 綠色
```

## 單人模式

單人模式允許玩家與 AI 對戰，無需連線伺服器。

### 檔案結構

```
lib/
├── presentation/pages/
│   ├── solo_mode_page.dart        # 單人模式入口
│   ├── solo_game_setup_page.dart  # 遊戲設定（難度、角色）
│   ├── solo_game_page.dart        # 主遊戲畫面
│   └── solo_game_result_page.dart # 結算畫面
├── providers/
│   ├── solo_game_provider.dart    # 單人遊戲狀態管理
│   └── tutorial_provider.dart     # 教學系統狀態
└── domain/services/
    ├── ai_decision_engine.dart    # AI 決策引擎
    ├── ai_character_behaviors.dart # 角色專屬行為
    └── ai_dialogue_manager.dart   # AI 對話管理
```

### 遊戲流程

```
入口頁 → 設定頁（3 步驟）→ 遊戲頁 → 結算頁
         │
         ├── 1. 選擇難度
         ├── 2. 選擇角色
         └── 3. 確認開始
```

## AI 系統架構

### 決策引擎 (`ai_decision_engine.dart`)

AI 決策流程：
1. **局勢分析** - 評估自身狀態、威脅、機會
2. **策略選擇** - 根據個性選擇攻擊/防守/外交策略
3. **行動生成** - 根據遊戲階段生成可能行動
4. **行動評分** - 策略適配、目標選擇、風險評估
5. **難度調整** - 根據難度加入隨機因子

### AI 難度設定

| 難度 | 隨機因子 | 傷害修正 | 攻擊頻率 | 玩家勝率 |
|------|----------|----------|----------|----------|
| 見習 | 70% | 60% | 30% | ~80% |
| 資淺 | 45% | 80% | 50% | ~65% |
| 資深 | 25% | 100% | 70% | ~50% |
| 老練 | 10% | 115% | 85% | ~35% |
| 大師 | 3% | 125% | 95% | ~20% |

### AI 個性類型

- **激進型** (`aggressive`) - 優先攻擊
- **防守型** (`defensive`) - 保護聲望
- **外交型** (`diplomatic`) - 尋求盟友
- **狡詐型** (`cunning`) - 伺機背叛

### 角色專屬行為

每個角色有獨特的行為模式：
- 投票偏好（支持哪個選項）
- 攻擊目標優先級
- 技能使用時機
- 行為修正因子

## 教學系統 (`tutorial_provider.dart`)

### 教學課程

1. **基礎操作** - UI 導覽
2. **聲望系統** - 理解聲望機制
3. **辯論戰鬥** - 質詢與反駁
4. **投票機制** - 聲望加權計票
5. **進階策略** - 結盟與背叛

### 教學步驟類型

- `info` - 純資訊展示
- `highlight` - 高亮 UI 元素
- `action` - 要求玩家操作
- `choice` - 選擇題
- `demo` - 示範動作

## 狀態管理

### 主要 Provider

```dart
// 單人遊戲狀態
final soloGameProvider = StateNotifierProvider<SoloGameNotifier, SoloGameState>

// 遊戲是否結束
final isGameOverProvider = Provider<bool>

// 當前階段時間
final phaseTimeRemainingProvider = Provider<int>
```

### SoloGameState 結構

```dart
SoloGameState {
  SoloGameRoom? gameRoom,      // 遊戲房間
  Player? humanPlayer,         // 人類玩家
  List<AIPlayer> aiPlayers,    // AI 玩家列表
  GamePhase currentPhase,      // 當前階段
  int currentRound,            // 當前回合
  int phaseTimeRemaining,      // 階段剩餘時間
  List<GameEvent> gameLog,     // 遊戲日誌
  Map<String, String> votes,   // 投票記錄
  bool isGameOver,             // 遊戲是否結束
  String? winner,              // 獲勝者
}
```

---

**目標：2 週內完成 MVP，可以 4 人線上對戰！**
