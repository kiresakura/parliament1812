# Steam 成就設計

**1812 國會風雲 | Parliament 1812**

共 25 個成就

---

## 成就概覽

| 難度分佈 | 數量 | 說明 |
|----------|------|------|
| 🟢 簡單 | 8 | 正常遊玩即可解鎖 |
| 🟡 中等 | 9 | 需要一定技巧或時間 |
| 🔴 困難 | 5 | 需要高技巧或大量時間 |
| 🟣 隱藏 | 3 | 特殊條件觸發 |

---

## 完整成就列表

### 🟢 新手入門（簡單）

| # | API Name | 名稱 | English | 條件 | 圖示建議 |
|---|----------|------|---------|------|---------|
| 1 | `FIRST_MATCH` | 🏆 新手議員 | Freshman Representative | 完成第一場對局 | 議會入口大門 |
| 2 | `FIRST_WIN` | 🏆 初嚐勝利 | First Victory | 贏得第一場對局 | 勝利獎盃 |
| 3 | `PLAY_10` | 🏆 常客 | Regular Attendee | 完成 10 場對局 | 議員座椅 |
| 4 | `COLLECT_50` | 🏆 收藏入門 | Card Collector | 收集 50 張不同卡牌 | 小型卡冊 |
| 5 | `BUILD_DECK` | 🏆 組牌新手 | Deck Builder | 首次自訂牌組 | 卡牌堆疊 |
| 6 | `FIRST_IAP` | 🏆 贊助者 | Patron | 完成首次商店購買 | 金幣袋 |
| 7 | `ADD_FRIEND` | 🏆 政治結盟 | Political Alliance | 首次加入多人房間 | 握手 |
| 8 | `TUTORIAL_DONE` | 🏆 學成出師 | Graduation Day | 完成新手教學 | 畢業帽 |

### 🟡 進階挑戰（中等）

| # | API Name | 名稱 | English | 條件 | 圖示建議 |
|---|----------|------|---------|------|---------|
| 9 | `ATTACK_STREAK_5` | 🏆 辯論達人 | Master Debater | 一場對局中連續出 5 張攻擊牌 | 火焰麥克風 |
| 10 | `WIN_50` | 🏆 資深議員 | Senior Member | 贏得 50 場對局 | 銀色議員徽章 |
| 11 | `GOLD_10K` | 🏆 金主 | Deep Pockets | 累積獲得 10,000 金幣 | 金幣寶箱 |
| 12 | `COLLECT_200` | 🏆 卡牌鑑賞家 | Card Connoisseur | 收集 200 張不同卡牌 | 大型卡冊 |
| 13 | `PERFECT_VOTE` | 🏆 民意代表 | Voice of the People | 在投票階段獲得全數支持 | 舉手投票 |
| 14 | `WIN_STREAK_5` | 🏆 不敗神話 | Winning Streak | 連勝 5 場 | 連續火焰 |
| 15 | `ALL_ROLES` | 🏆 百變議員 | Versatile Politician | 使用所有角色各贏一場 | 面具集合 |
| 16 | `DEFENSE_MASTER` | 🏆 鐵壁防線 | Iron Defense | 一場對局中成功防禦 10 次攻擊 | 盾牌 |
| 17 | `COMEBACK_WIN` | 🏆 逆轉裁決 | Comeback King | 在最後一回合逆轉勝 | 翻轉箭頭 |

### 🔴 大師成就（困難）

| # | API Name | 名稱 | English | 條件 | 圖示建議 |
|---|----------|------|---------|------|---------|
| 18 | `WIN_100` | 🏆 人民之聲 | Voice of the Nation | 贏得 100 場對局 | 金色議員徽章 |
| 19 | `WIN_STREAK_10` | 🏆 議會霸主 | Parliament Dominator | 連勝 10 場 | 皇冠 |
| 20 | `COLLECT_ALL` | 🏆 全卡收藏家 | Complete Collection | 收集所有基礎卡牌 | 彩虹卡冊 |
| 21 | `GOLD_100K` | 🏆 財閥 | Tycoon | 累積獲得 100,000 金幣 | 金庫 |
| 22 | `TOP_LEADERBOARD` | 🏆 議長 | Speaker of the House | 登上排行榜第一名 | 議長木槌 |

### 🟣 隱藏成就

| # | API Name | 名稱 | English | 條件 | 圖示建議 |
|---|----------|------|---------|------|---------|
| 23 | `PACIFIST` | 🏆 和平使者 | The Pacifist | 一場對局中 0 張攻擊牌通關 | 和平鴿 |
| 24 | `ALL_ATTACK` | 🏆 戰爭狂人 | Warmonger | 一場對局中只出攻擊牌 | 交叉劍 |
| 25 | `EASTER_EGG` | 🏆 歷史學家 | The Historian | 發現遊戲中的隱藏彩蛋 | 放大鏡 |

---

## 成就圖示規格

| 規格 | 要求 |
|------|------|
| **尺寸** | 64 × 64 px |
| **格式** | JPG |
| **每個成就需要** | 2 張圖（已解鎖 + 未解鎖/灰階版） |
| **總圖片數** | 25 × 2 = **50 張** |

### 設計風格建議
- **已解鎖**：全彩、明亮、有光暈效果
- **未解鎖**：灰階或暗色調、加鎖頭圖示
- **統一風格**：復古議會風、暖色調金色邊框
- **辨識度**：在 64px 小尺寸下仍能清楚辨識

---

## Steamworks 後台設定

### API Name 命名規則
- 全大寫 + 底線分隔
- 前綴依類別：無特殊前綴，直接描述

### 成就統計對應

部分成就需要追蹤統計值（Stats）：

| Stat API Name | 類型 | 說明 |
|---------------|------|------|
| `total_matches` | INT | 總對局數 |
| `total_wins` | INT | 總勝場數 |
| `win_streak` | INT | 當前連勝數 |
| `max_win_streak` | INT | 最高連勝數 |
| `total_gold` | INT | 累積金幣 |
| `unique_cards` | INT | 不同卡牌收集數 |
| `attack_streak` | INT | 當前連續攻擊牌數 |

### 成就解鎖觸發點

```
對局結束時：
├── 檢查 total_matches → FIRST_MATCH, PLAY_10
├── 檢查 total_wins → FIRST_WIN, WIN_50, WIN_100
├── 檢查 win_streak → WIN_STREAK_5, WIN_STREAK_10
├── 檢查對局內統計：
│   ├── attack_count == 0 → PACIFIST
│   ├── non_attack_count == 0 → ALL_ATTACK
│   ├── max_consecutive_attacks >= 5 → ATTACK_STREAK_5
│   ├── defense_count >= 10 → DEFENSE_MASTER
│   ├── last_round_comeback → COMEBACK_WIN
│   └── perfect_vote → PERFECT_VOTE
├── 檢查 unique_cards → COLLECT_50, COLLECT_200, COLLECT_ALL
└── 檢查 total_gold → GOLD_10K, GOLD_100K

收藏變更時：
├── 新牌組建立 → BUILD_DECK
└── unique_cards 更新

商店購買時：
└── 首次購買 → FIRST_IAP

排行榜更新時：
└── rank == 1 → TOP_LEADERBOARD

角色使用記錄：
└── 所有角色各贏一場 → ALL_ROLES
```

---

## Game Center 對應

| Steam 成就 | Game Center 成就 | 備註 |
|-----------|-----------------|------|
| 相同成就 ID | 相同設計 | iOS 與 Steam 成就系統獨立 |

> 遊戲內成就系統為統一邏輯，根據平台分別呼叫 Steam / Game Center API。
