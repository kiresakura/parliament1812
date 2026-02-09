# Steamworks 整合計畫

**1812 國會風雲 | Parliament 1812**

---

## 基本資訊

| 欄位 | 值 |
|------|-----|
| **App ID** | 待申請 |
| **上架費** | USD $100（一次性，需透過 Steamworks 提交） |
| **開發者名稱** | Rush8787 |
| **遊戲類型** | Card Game, Strategy, Multiplayer |
| **標籤** | Card Game, Strategy, Political, Multiplayer, Turn-Based |
| **發行平台** | Windows, macOS（透過 Flutter desktop build） |

---

## Store Page 準備清單

### 圖片素材

| 素材名稱 | 尺寸 (px) | 用途 | 狀態 |
|----------|----------|------|------|
| **Header Capsule** | 460 × 215 | 搜尋結果、推薦列表 | ⬜ 待製作 |
| **Small Capsule** | 231 × 87 | 願望清單、通知 | ⬜ 待製作 |
| **Main Capsule** | 616 × 353 | Store 首頁、精選推薦 | ⬜ 待製作 |
| **Hero Capsule** | 1920 × 620 | Store 頁面頂部橫幅 | ⬜ 待製作 |
| **Page Background** | 1438 × 810 | Store 頁面背景 | ⬜ 待製作 |
| **Library Capsule** | 600 × 900 | Steam Library 垂直圖 | ⬜ 待製作 |
| **Library Header** | 460 × 215 | Steam Library 標頭 | ⬜ 待製作 |
| **Library Hero** | 3840 × 1240 | Steam Library 背景 | ⬜ 待製作 |
| **Library Logo** | 任意（透明背景） | Steam Library Logo | ⬜ 待製作 |
| **Community Icon** | 32 × 32 | 社群與論壇 | ⬜ 待製作 |

> ⚠️ 所有圖片必須為 PNG 或 JPG，不含成人內容或誤導性素材。

### 遊戲截圖

| 規格 | 要求 |
|------|------|
| **解析度** | 1920 × 1080（最低 1280 × 720） |
| **數量** | 至少 5 張，建議 10 張 |
| **格式** | PNG 或 JPG |
| **內容要求** | 真實遊戲畫面，不含桌面邊框或浮水印 |

**建議截圖場景：**
1. 主選單（展示美術風格）
2. 角色選擇畫面
3. 出牌階段（核心遊戲畫面）
4. 辯論互動
5. 投票決議
6. 結算畫面
7. 卡牌收藏 / 牌組編輯
8. 商店 / 卡牌包
9. 多人配對大廳
10. 排行榜 / 成就

### 遊戲描述

- **短版描述（Short Description）**：最多 300 字元 → 見 `store-description.md`
- **長版描述（About This Game）**：支援 BBCode 格式 → 見 `store-description.md`

### Trailer 影片

| 規格 | 要求 |
|------|------|
| **格式** | MP4 (H.264 + AAC) |
| **解析度** | 1920 × 1080 (1080p) 或 3840 × 2160 (4K) |
| **幀率** | 30 或 60 fps |
| **長度** | 30 秒 – 2 分鐘（建議 60-90 秒） |
| **音訊** | 立體聲，AAC 或未壓縮 |
| **檔案大小** | ≤ 500 MB |
| **縮圖** | 與影片相同解析度的 JPG |

**Trailer 建議結構：**
1. 0-10s：遊戲世界觀引入（1812 國會場景）
2. 10-30s：核心玩法展示（出牌、辯論、投票）
3. 30-50s：多人對戰精華片段
4. 50-60s：遊戲特色 + Logo + 上市日期

---

## 系統需求

### Windows

| | 最低配置 | 建議配置 |
|--|---------|---------|
| **OS** | Windows 10 (64-bit) | Windows 11 (64-bit) |
| **Processor** | Intel Core i3 / AMD Ryzen 3 | Intel Core i5 / AMD Ryzen 5 |
| **Memory** | 4 GB RAM | 8 GB RAM |
| **Graphics** | Integrated / Intel UHD 620 | Dedicated / GTX 1050 |
| **DirectX** | Version 11 | Version 12 |
| **Storage** | 500 MB | 1 GB |
| **Network** | Broadband Internet | Broadband Internet |

### macOS

| | 最低配置 | 建議配置 |
|--|---------|---------|
| **OS** | macOS 12.0 (Monterey) | macOS 14.0 (Sonoma) |
| **Processor** | Apple M1 / Intel Core i3 | Apple M1 Pro / Intel Core i5 |
| **Memory** | 4 GB RAM | 8 GB RAM |
| **Graphics** | Integrated | Integrated (M-series) |
| **Storage** | 500 MB | 1 GB |
| **Network** | Broadband Internet | Broadband Internet |

---

## Steamworks SDK 整合計畫

### 整合項目

| 功能 | Steamworks API | 優先度 | 狀態 |
|------|---------------|--------|------|
| **Steam Authentication** | `ISteamUser` | 🔴 必要 | ⬜ 待實作 |
| **Achievements** | `ISteamUserStats` | 🟡 高 | ⬜ 待實作 |
| **Steam Cloud Save** | `ISteamRemoteStorage` | 🟡 高 | ⬜ 待實作 |
| **Leaderboards** | `ISteamUserStats` | 🟡 高 | ⬜ 待實作 |
| **Rich Presence** | `ISteamFriends` | 🟢 中 | ⬜ 待實作 |
| **Overlay** | `ISteamUtils` | 🟢 中 | ⬜ 待實作 |
| **Workshop** | `ISteamUGC` | 🔵 未來 | ⬜ 未規劃 |
| **Trading Cards** | Steamworks 後台設定 | 🔵 未來 | ⬜ 未規劃 |

### 1. Steam Authentication

```
流程：
1. Steam Client 啟動 → 取得 Steam ID
2. 遊戲向 Steam 取得 Auth Session Ticket
3. 送至遊戲後端驗證
4. 後端呼叫 Steam Web API 驗證 ticket
5. 建立/關聯遊戲帳號
```

**注意事項：**
- 必須處理離線模式（Steam Offline Mode）
- 需要在後端實作 Steam Web API 驗證端點

### 2. Achievements

- 成就定義見 `achievements.md`
- 需在 Steamworks 後台設定所有成就 ID、名稱、圖示
- 遊戲內成就系統需對應 Steam 成就 API 呼叫
- 每個成就需要已鎖定/已解鎖兩種圖示（64×64 JPG）

### 3. Steam Cloud Save

```
同步策略：
- 存檔路徑：{SteamAppId}/saves/
- 同步檔案：player_data.json, deck_configs.json, settings.json
- 衝突解決：以最後修改時間為準（last-write-wins）
- 最大配額：100 MB per user
```

### 4. Rich Presence

```
狀態顯示範例：
- "In Main Menu" / 在主選單
- "Searching for Match" / 搜尋對手中
- "In Game - Round 3/5" / 對局中 - 第 3/5 回合
- "Debating - Bill #42" / 辯論中 - 議案 #42
- "Viewing Collection" / 瀏覽收藏
```

### 5. Leaderboards

| 排行榜名稱 | 排序 | 更新頻率 |
|------------|------|---------|
| **Total Wins** | 降序 | 每場結束 |
| **Win Rate** | 降序 | 每場結束 |
| **Highest Score** | 降序 | 每場結束 |
| **Weekly Wins** | 降序 | 每週重置 |
| **Season Rank** | 降序 | 每季重置 |

---

## Flutter Desktop 整合方案

### 建議方案：`steamworks` Flutter 插件

```yaml
# pubspec.yaml (desktop only)
dependencies:
  steamworks: ^x.x.x  # 或使用 FFI 直接呼叫 Steam API
```

### 替代方案：FFI + steam_api.dll

```
1. 下載 Steamworks SDK
2. 將 steam_api.dll / libsteam_api.so / libsteam_api.dylib 放入 build output
3. 透過 Dart FFI 呼叫 Steam API
4. 封裝為 platform channel plugin
```

### 條件編譯

```dart
// 根據平台切換 Steam / 非 Steam 模式
import 'package:flutter/foundation.dart';

abstract class PlatformAuth {
  factory PlatformAuth() {
    if (kIsWeb) return WebAuth();
    if (Platform.isWindows || Platform.isMacOS) return SteamAuth();
    if (Platform.isIOS) return AppleAuth();
    return GuestAuth();
  }
}
```

---

## 時程規劃

| 階段 | 工作項目 | 預估時間 |
|------|---------|---------|
| **Phase 1** | 付 $100、建立 App、設定 Store Page | 1 天 |
| **Phase 2** | 製作所有圖片素材 | 3-5 天 |
| **Phase 3** | 撰寫描述、設定系統需求 | 1 天 |
| **Phase 4** | 整合 Steamworks SDK（Auth + Achievements） | 5-7 天 |
| **Phase 5** | 整合 Cloud Save + Leaderboards | 3-5 天 |
| **Phase 6** | 整合 Rich Presence + 測試 | 2-3 天 |
| **Phase 7** | 上傳 Build + 內部測試 | 2-3 天 |
| **Phase 8** | 提交審核 | 審核時間約 1-5 個工作天 |

**總預估：3-4 週**

---

## 注意事項

- Steam 上架需要完成稅務資訊（W-8BEN 或 W-9）
- 首次上架需要等待 Steamworks 團隊審核（約 1-3 個工作天）
- App 發行前需設定至少 2 週的「Coming Soon」頁面（建議更久以累積願望清單）
- Steam Deck 相容性驗證（Proton 層級）
