# 1812 國會風雲 — MVP 開發指引

## 專案概述

**1812 國會風雲**是一款以英國工業革命為背景的多人線上社交推理遊戲。
核心創新：**同時出牌資訊戰** — 資訊戰 × 策略卡牌 × 社交推理，10 分鐘一局。

## 技術棧

- **客戶端**：Flutter 3.x + Riverpod（`app/`，跨平台 iOS/Android，Web 後期）
- **後端**：Rust (Axum + Tokio)，權威伺服器（`server/`）
- **即時通訊**：WebSocket（tokio-tungstenite ↔ web_socket_channel）
- **資料庫**：PostgreSQL（Fly Postgres）
- **快取**：Redis（Fly Redis）
- **部署**：Fly.io
- **已封存**：`godot-client/`（Godot 4.6 試作，停止開發、保留參考，勿刪）；`backend/`（Node.js 舊版）

## 設計文件（重要！讀的順序）

1. `docs/GDD_v3_Design_Response.md` — **v3 設計回應書：數值經濟、社交機制、課金、技術棧的現行權威**。與 GDD_v2 衝突時以此為準。
2. `docs/GDD_v2.md` — 遊戲設計文件（同時出牌資訊戰的完整框架）
3. `docs/Design_Review_v2_Critique.md` — v2 辛辣評測（v3 的問題來源）
4. `parliament_assets/` — UI 主題、元件參考

## 核心設計（v3 數值）

### 同時出牌資訊戰

所有玩家同時選牌→同時翻牌，零等待。核心資源是「資訊」——誰知道什麼、誰在說謊。
v3 主軸：**雙幣分權** — 聲望（票權+行動費）與把柄（情報資本）分離，計分採兩層制。

### 三幕劇結構（9.5–11 分鐘，4 回合制）

```
第一幕：暗流（90 秒）→ 法案最先公布 → 私訊 2 條（自由派 3 條）
第二幕：辯論（4 回合）→ 選牌 30s → 翻牌結算 15s → 公開聊天 40s（每回合私訊 1 條 + 表態 1 次）
第三幕：表決（90 秒）→ 回顧 15s → 投票+壓票 45s → 唱票 30s（聲望低→高依序亮票）→ 議程揭示
```

### 六種卡牌（v3）

| 卡牌 | 功能 | 聲望/效果 |
|------|------|----------|
| 🗡️ 質詢 | 偷看目標議程，成功 → 獲得**把柄**×1（同對同目標上限 1 枚） | -5 |
| 🛡️ 反質詢 | 擋下質詢 +5 並反看質詢者議程類別；無人質詢 +3 保底 | 0 |
| 📢 演說 | 遞減 +10/+5/+0/+0，**必須公開表態 A/B/C**（可說謊，入言行紀錄） | 遞減 |
| 🤝 結盟 | 雙向 +15（同一對象第二次 +5）/ 單向 -5；聊天階段可發 handshake 提案 | 囚徒困境 |
| 💣 爆料 | 消耗 1 枚把柄、自費 0、**+5 紅利**；目標 -20 + 議程公開 + 號外時刻 | 收割 |
| 🔄 倒戈 | -10；銷毀指向自己的把柄，持有者各退 +5 | 燒檔案 |

超時 = 棄權（+0，不出牌）；連續 2 次 → AI 接管 + 本局不計排位。

### 把柄系統（v3 新資源）

持有數公開、內容私密。四個出口：
1. **壓票**：表決階段打出 → 目標 -2 票（保底 1 票）
2. **囤積**：局末每枚 +10 分
3. **爆料彈藥**：見上表
4. **揭穿**：局末若目標投票 ≠ 最後公開表態 → 目標 -15 分、你 +5 分

### 計分與排名（v3 兩層制）

```
最終分 = 議程分 + ⌊剩餘聲望/2⌋ + 把柄×10 + 表態結算 + 成就分
排名：完成議程者永遠 > 未完成者；層內按分數
票權 = 1 + floor(聲望/20)；最低聲望 = 5
```

### 表態系統（一鍵，免打字）

- **指控**「X 是攪局派」：對 +8 / 錯 -3
- **擔保**「X 言行一致」：對 +5 / 錯 -15

### 隱藏議程（v3 平衡後）

法案派 50 / 穩健派 55 / 人望王 50 / 合縱連橫 50（2 個**不同**對象）/ 縱火犯 55+關鍵票條件 / 雙面人 45+誘騙條件 / **黑函作者 50（新：局末持 2 名不同玩家把柄）** / 政治殺手已刪除。

### 三大派系

| 派系 | 起始聲望 | 補償 | 風格 |
|------|----------|------|------|
| 🏛️ 保守黨 | 60 | — | 穩定防禦 |
| 📜 自由派 | 50 | 第一幕私訊 3 條 | 情報 |
| 💰 商行聯盟 | 45 | 開局 1 條隨機議程類別情報 | 欺詐 |

### 稀有度鐵律

**Sidegrade only**：同強度、不同形狀；永不違反同時出牌支柱。議長裁決已刪除。strictly-better 卡一律重設計（範本見 v3 回應書 §2.1）。

## 專案結構

```
parliament1812/
├── docs/                       # 設計文檔（重要！）
│   ├── GDD_v3_Design_Response.md  # ★ 現行權威：v3 數值/機制/課金/技術棧
│   ├── GDD_v2.md               # 遊戲設計文件（框架）
│   ├── Design_Review_v2_Critique.md  # v2 評測
│   └── Product_Positioning_v1.docx   # 產品定位書
├── app/                        # Flutter 客戶端（主要）
│   ├── lib/
│   │   ├── main.dart / app.dart
│   │   ├── config/            # 常數、主題、色彩
│   │   ├── l10n/              # i18n（zh/en）
│   │   ├── models/            # freezed 模型（game_state、player、card、room…）
│   │   ├── providers/         # Riverpod（game、room、auth、quests、single_player…）
│   │   ├── screens/           # 畫面（game、room、auth、quests、codex、single_player…）
│   │   ├── services/          # api、websocket、auth、local_game_engine、audio、haptic
│   │   ├── ui/theme/          # 字體、間距、動畫常數
│   │   └── widgets/           # parliament/（hand、opponent_rail、hud…）、animations/
│   └── pubspec.yaml           # riverpod、go_router、web_socket_channel、freezed…
├── server/                     # Rust 後端（權威伺服器）
│   ├── src/
│   │   ├── api/               # HTTP 路由與 handlers
│   │   ├── auth/ cache/ config/ domain/ error/
│   │   ├── game/              # 遊戲引擎：engine、state、cards、bills、ai、elo、
│   │   │                      #   quests、season、achievements、anti_cheat…
│   │   ├── repository/ services/
│   │   └── websocket/         # hub、connection、messages
│   ├── migrations/            # 含 018 weekly_bills、020 referral、021 season_pass
│   └── fly.toml / Dockerfile
├── godot-client/               # 【封存】Godot 試作，停止開發
├── backend/                    # 【封存】Node.js 舊版
├── assets/ parliament_assets/  # 素材（PNG/OGG 通用，Flutter 直接取用）
└── .github/workflows/          # deploy-server.yml、rust-check.yml
```

## 開發原則

1. **MVP 優先**：先做最小可玩版本
2. **數值先模擬後上線**：經濟改動必須過 `server/src/bin/sim.rs` 驗收門檻（v3 回應書 §4）
3. **權威伺服器**：規則結算一律在 server，客戶端只做呈現
4. **依賴順序**：兩層計分與議程重平衡必須同包上線（v3 §1.3）

## 模擬驗收門檻（Sprint A 出口條件）

純演說勝率 <25%、爆料 >35%/局、質詢 <45%/回合、各議程完成率 35–65%、雙排優勢 <8%、派系差 <6%。

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

## 單人模式（Flutter 實際檔案）

單人模式與 AI 對戰，本地引擎驅動、無需連線。

```
app/lib/
├── screens/single_player/
│   ├── single_player_game_screen.dart   # 主遊戲畫面
│   ├── difficulty_select_screen.dart    # 難度選擇
│   └── campaign_screen.dart             # 戰役模式
├── providers/single_player_provider.dart # 單人遊戲狀態
├── models/single_player.dart
└── services/local_game_engine.dart       # 本地規則引擎
```

多人 AI（補位/模擬）在伺服器端：`server/src/game/ai.rs`。AI 席位必須明確標識；新手前 5 場進保護房（v3 §1.4-6）。

## 開發路線圖（v3）

- **Sprint A（W1–2）經濟重做**：sim.rs 模擬器 → 把柄/演說遞減/反質詢/爆料 v3/議程 v3/兩層計分/4 回合（server）+ 把柄徽章/表態 UI/結算畫面（Flutter）→ 跑驗收門檻
- **Sprint B（W3–4）社交扳機**：每回合私訊、表態按鈕、handshake、號外 overlay、唱票、AI 標識/新手房、日週任務串接
- **Sprint C（W5–8 = S1）舞台與商店**：翻牌特效、議會紀錄版式+分享、BP 30 級、排位軟上線、號外模板、議席外觀

---

**目標：Sprint A 數值閉環 + 模擬驗證，再談封測。4–6 人同時出牌線上對戰！**
