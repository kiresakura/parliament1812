# 1812 國會風雲 - Android 開發指南

## 專案概述

這是一款以 1812 年英國盧德運動為背景的國會辯論角色扮演遊戲 Android 版本。
使用 Flutter 開發，支援 NFC 防作弊系統。

**目標**: Alpha Demo 於 2026/01/07，支援 6 人同時遊玩

## 目錄結構

```
platforms/android/
├── flutter_android/     # Android 原生配置 (gradle, AndroidManifest)
├── lib/                 # Dart 源代碼
│   ├── config/          # 配置 (app_config.dart)
│   ├── models/          # 資料模型 (player.dart, room.dart, role.dart 等)
│   ├── providers/       # 狀態管理 (room_provider.dart, player_provider.dart)
│   ├── screens/         # 畫面 (home_screen.dart, waiting_room_screen.dart 等)
│   ├── services/        # 服務 (api_service.dart, nfc_service.dart, websocket_service.dart)
│   └── widgets/         # 共用組件
├── assets/              # 資源文件 (圖片, 字體)
├── releases/            # APK 發布版本 (v1~v4)
├── pubspec.yaml         # Flutter 依賴配置
└── CLAUDE_CODE_PROMPT.md
```

## 後端 API

**生產環境**: `https://1812-production.up.railway.app`
**API 文檔**: `https://1812-production.up.railway.app/docs`

### 主要 API 端點

| 端點 | 方法 | 說明 |
|------|------|------|
| `/api/rooms` | POST | 建立房間 |
| `/api/rooms/{code}` | GET | 取得房間資訊 |
| `/api/rooms/{code}/join` | POST | 加入房間 |
| `/api/rooms/{code}/players` | GET | 取得房間玩家 |
| `/api/nfc/scan` | POST | NFC 掃卡驗證 |
| `/api/roles` | GET | 取得所有角色 |
| `/api/roles/{role_type}` | GET | 取得特定角色 |

### WebSocket

連接: `wss://1812-production.up.railway.app/ws/{room_code}/{player_id}`

事件類型:
- `player_joined` - 玩家加入
- `player_left` - 玩家離開
- `role_assigned` - 角色分配
- `game_started` - 遊戲開始
- `vote_started` - 投票開始
- `vote_ended` - 投票結束


---

## NFC 防作弊系統

### 正確的 NFC 格式規範

| 項目 | 規範 | 範例 |
|------|------|------|
| card_id | 大寫，無底線 | `WORKER01`, `GEORGEIII01` |
| secret_hash | HMAC-SHA256，16 字元 | `a1b2c3d4e5f67890` |
| nfc_url | Deep link 格式 | `parliament1812://role?id=WORKER01&secret=a1b2c3d4e5f67890` |

### 所有有效卡片 ID

| 角色 | 卡片 ID | 短代碼 |
|------|---------|--------|
| 工人 | WORKER01 ~ WORKER04 | W01 ~ W04 |
| 工廠主 | FACTORY01 ~ FACTORY04 | F01 ~ F04 |
| 盧德派 | LUDDITE01 ~ LUDDITE04 | L01 ~ L04 |
| 改革者 | REFORMER01 ~ REFORMER04 | R01 ~ R04 |
| 議員 | MP01 ~ MP04 | M01 ~ M04 |
| 👑 喬治三世 | GEORGEIII01 ~ GEORGEIII04 | G01 ~ G04 |

### 正確範例 (George III)

```json
{
  "card_id": "GEORGEIII01",
  "role_id": "george_iii",
  "role_name_zh": "喬治三世",
  "secret_hash": "7f3a9c2b1e5d8f04",
  "nfc_url": "parliament1812://role?id=GEORGEIII01&secret=7f3a9c2b1e5d8f04"
}
```

### 取得正確 hash 的方法

```bash
curl "https://1812-production.up.railway.app/api/admin/nfc-cards?admin_key=YOUR_ADMIN_KEY"
```

### NFC 掃描 API

```
POST /api/nfc/scan
Content-Type: application/json

{
  "room_code": "ABC123",
  "player_id": "uuid-string",
  "card_id": "GEORGEIII01",
  "signature": "7f3a9c2b1e5d8f04"
}
```

成功回應:
```json
{
  "success": true,
  "role_type": "george_iii",
  "role_index": 1,
  "role": {
    "id": "george_iii",
    "name_zh": "喬治三世",
    "name_en": "George III",
    "faction": "crown"
  }
}
```


---

## 已知問題 (待修復)

### 問題 1: 加入房間顯示警告訊息

**現象**: 加入房間成功後，仍顯示警告/錯誤訊息

**可能原因**:
1. `joinRoom` API 回應格式與 `Player` model 不匹配
2. `RoomProvider` 的錯誤狀態未正確清除
3. `home_screen.dart` 的 `_submit` 方法處理邏輯問題

**需檢查檔案**:
- `lib/services/api_service.dart` - `joinRoom` 方法
- `lib/providers/room_provider.dart` - 錯誤狀態管理
- `lib/screens/home_screen.dart` - `_submit` 方法

### 問題 2: NFC 掃描讀取資料但角色未分配

**現象**: NFC 掃描能讀取卡片資料，但玩家角色未成功分配

**可能原因**:
1. NFC 卡片寫入的格式錯誤（見上方 NFC 格式規範）
2. `NfcService._parseUri()` 解析 URI 失敗
3. `PlayerProvider.scanNfcCard()` 未正確呼叫 API
4. `Player.hasRole` getter 邏輯錯誤

**需檢查檔案**:
- `lib/services/nfc_service.dart` - `startScan`, `_parseUri`, `_decodeUri`
- `lib/providers/player_provider.dart` - `scanNfcCard`
- `lib/services/api_service.dart` - `scanNfc`
- `lib/screens/scan_nfc_screen.dart` - `_startScan`
- `lib/models/player.dart` - `hasRole` getter

**調試步驟**:
1. 在 `_parseUri` 添加 `debugPrint` 輸出解析的 URI
2. 確認 URI 格式為 `parliament1812://role?id=XXX&secret=YYY`
3. 檢查 API 回應是否正確


---

## 角色系統

### 6 種角色

| 角色 | role_type | 陣營 | 描述 |
|------|-----------|------|------|
| 👑 喬治三世 | `george_iii` | 皇室 | 精神狀態不穩定的國王 |
| 🔨 工人 | `worker` | 勞工 | 紡織工人湯瑪斯 |
| 🏭 工廠主 | `factory_owner` | 資方 | 理查·威爾森 |
| ⚔️ 盧德派 | `luddite` | 激進派 | 機器破壞者喬治 |
| 📜 改革者 | `reformer` | 改革派 | 羅伯特·歐文 |
| 🎩 議員 | `mp` | 國會 | 威廉·菲茨傑拉德 |

### 秘密任務

每個角色有專屬秘密任務，需在遊戲中達成。

---

## 開發指南

### 執行專案

```bash
cd /Users/zhongliyuanshiqi/Documents/parliament1812/platforms/android
flutter pub get
flutter run -d android
```

### 打包 APK

```bash
flutter build apk --release
# 輸出: build/app/outputs/flutter-apk/app-release.apk
```

### 調試 NFC

1. 確保設備支援 NFC 且已開啟
2. 在 `nfc_service.dart` 添加調試輸出:

```dart
Future<NfcCardData?> _processTag(NfcTag tag) async {
  debugPrint('🔍 NFC Tag detected');
  // ... 
  final uri = _decodeUri(record.payload);
  debugPrint('🔗 Decoded URI: $uri');
  final cardData = _parseUri(uri);
  debugPrint('📋 Parsed data: cardId=${cardData?.cardId}, signature=${cardData?.signature}');
  // ...
}
```

### 調試 API

在 `api_service.dart` 添加請求/回應日誌:

```dart
debugPrint('📤 Request: $method $url');
debugPrint('📥 Response: ${response.statusCode} ${response.body}');
```


---

## 關鍵檔案說明

### lib/services/nfc_service.dart

NFC 卡片掃描服務，負責：
- 檢查 NFC 可用性
- 啟動/停止掃描
- 解析 NDEF URI 格式
- 提取 card_id 和 signature

**重要方法**:
- `isAvailable()` - 檢查 NFC 硬體
- `startScan()` - 開始掃描，返回 `NfcCardData`
- `_parseUri(uri)` - 解析 `parliament1812://role?id=XXX&secret=YYY`

### lib/providers/player_provider.dart

玩家狀態管理，負責：
- 當前玩家資訊
- NFC 掃卡分配角色
- 手動分配角色（備用）

**重要方法**:
- `scanNfcCard(roomCode)` - 掃描 NFC 並呼叫 API 分配角色
- `assignRoleManually(roomCode, roleType, roleIndex)` - 手動分配

### lib/providers/room_provider.dart

房間狀態管理，負責：
- 房間資訊
- 玩家列表
- 建立/加入房間

**重要方法**:
- `createRoom(hostNickname)` - 建立房間
- `joinRoom(roomCode, nickname)` - 加入房間
- `getRoom(roomCode)` - 取得房間資訊

### lib/services/api_service.dart

API 服務，所有 HTTP 請求的入口。

**重要類別**:
- `CreateRoomResult` - 建立房間結果
- `NfcScanResult` - NFC 掃描結果
- `ApiException` - API 錯誤

---

## 共用資源

位於 `/Users/zhongliyuanshiqi/Documents/parliament1812/shared/`

| 目錄 | 說明 |
|------|------|
| `backend/` | FastAPI 後端源碼 |
| `nfc_tools/` | NFC 工具和卡片資料庫 |
| `docs/` | 專案文檔 |
| `flutter_original/` | Flutter 原始專案備份 |

### NFC 卡片資料

```
shared/nfc_tools/nfc_cards.json
```

⚠️ **注意**: 此檔案的格式已過時，需要更新為正確格式。

---

## 測試用資料

### 測試用房間

可直接使用後端建立測試房間:

```bash
curl -X POST https://1812-production.up.railway.app/api/rooms \
  -H "Content-Type: application/json" \
  -d '{"host_nickname": "測試主持人"}'
```

### 模擬 NFC 掃描

若無實體 NFC 卡，可使用手動分配:

```dart
playerProvider.assignRoleManually(
  roomCode: "ABC123",
  roleType: "george_iii",
  roleIndex: 1,
);
```

---

## 常見錯誤處理

| 錯誤 | 原因 | 解決 |
|------|------|------|
| `Instance of 'NfcException'` | 錯誤訊息未格式化 | 使用 `_formatError()` |
| `type 'Null' is not a subtype` | JSON 欄位缺失 | 檢查 `.fromJson()` 的 null 處理 |
| `Connection refused` | 後端未啟動或網路問題 | 檢查 API URL |
| NFC 掃描無反應 | NFC 未開啟或卡片格式錯誤 | 檢查設備設定和卡片內容 |

---

*最後更新: 2024-12-20*
