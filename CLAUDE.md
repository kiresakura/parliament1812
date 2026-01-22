# 1812 國會風雲 — MVP 開發指引

## 專案概述

**1812 國會風雲**是一款以英國工業革命為背景的多人線上社交推理遊戲。
核心創新：**議會辯論 RPG** — 將 RPG 戰鬥系統融入社交推理遊戲。

## 技術棧

- **前端**：Flutter（跨平台：iOS、Android、Web）
- **狀態管理**：Riverpod
- **後端**：Node.js + WebSocket（部署於 Railway）
- **資料庫**：PostgreSQL（Railway 內建）
- **即時通訊**：Socket.IO

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
├── backend/                    # Node.js 後端（待建立）
│   ├── src/
│   │   ├── server.ts
│   │   ├── socket/            # WebSocket 處理
│   │   ├── game/              # 遊戲邏輯
│   │   └── models/            # 資料模型
│   └── package.json
└── railway.toml               # Railway 部署設定
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

---

**目標：2 週內完成 MVP，可以 4 人線上對戰！**
