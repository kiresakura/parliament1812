# 🎭 1812 國會風雲 - NFC 卡片寫入指南

## 📦 你需要的東西

### 硬體
- **NFC 卡片**: NTAG213/215/216（推薦 NTAG215，容量 504 bytes）
- **智慧型手機**: iPhone 7 以上（iOS 13+）或 支援 NFC 的 Android 手機

### 軟體
- **NFC Tools** App（iOS/Android 免費）
  - [iOS App Store](https://apps.apple.com/app/nfc-tools/id1252962749)
  - [Google Play Store](https://play.google.com/store/apps/details?id=com.wakdev.wdnfc)

---

## 🚀 快速開始

### 步驟 1: 生成 NFC URL

```bash
cd /Users/zhongliyuanshiqi/Documents/parliament1812/nfc_tools
python3 generate_nfc_urls.py
```

這會生成兩個檔案：
- `nfc_cards.json` - 完整的卡片資料（程式用）
- `nfc_urls_for_writing.txt` - 寫入清單（人工操作用）

### 步驟 2: 寫入 NFC 卡片

#### iPhone 寫入方式

1. 開啟 **NFC Tools** App
2. 點擊底部的 **「寫入」** 分頁
3. 點擊 **「新增紀錄」**
4. 選擇 **「URL/URI」**
5. 在輸入框貼上對應角色的 URL，例如：
   ```
   parliament1812://role?id=george_iii_01&secret=A1B2C3D4
   ```
6. 點擊右上角 **「確定」**
7. 點擊 **「寫入 / XX Bytes」**
8. 將 NFC 卡放在 **iPhone 頂部**（靠近相機的位置）
9. 聽到 **「叮」** 的提示音 = 寫入成功！

#### Android 寫入方式

1. 確認手機 NFC 功能已開啟（設定 → 連接 → NFC）
2. 開啟 **NFC Tools** App
3. 點擊 **「WRITE」** 分頁
4. 點擊 **「Add a record」**
5. 選擇 **「URL/URI」**
6. 貼上對應角色的 URL
7. 點擊 **「Write / XX Bytes」**
8. 將 NFC 卡放在 **手機背面中央**
9. 感受到 **震動** = 寫入成功！

---

## 👑 喬治三世專用卡片

喬治三世是特殊角色，只需要 **1 張卡片**：

| 卡片 ID | 角色 | URL 格式 |
|---------|------|----------|
| `george_iii_01` | 👑 喬治三世 | `parliament1812://role?id=george_iii_01&secret=XXXXXXXX` |

> ⚠️ **注意**: 每次執行 `generate_nfc_urls.py` 會產生新的 secret，請確保寫入的 URL 與 App 後端資料一致！

---

## 📋 完整卡片清單

| 角色 | 數量 | 卡片 ID |
|------|------|---------|
| 👑 喬治三世 | 1 | george_iii_01 |
| 湯瑪斯（工人） | 3 | worker_01, worker_02, worker_03 |
| 理查·威爾森（工廠主） | 2 | factory_01, factory_02 |
| 喬治（盧德派） | 3 | luddite_01, luddite_02, luddite_03 |
| 羅伯特·烏爾文（改革者） | 2 | reformer_01, reformer_02 |
| 威廉·菲茨傑拉德（議員） | 2 | mp_01, mp_02 |

**總計: 13 張卡片**

---

## 🔧 疑難排解

### 寫入失敗？

1. **卡片放置位置不對**
   - iPhone: 放在手機頂部（相機附近）
   - Android: 放在手機背面中央

2. **卡片已被鎖定**
   - 部分 NFC 卡出廠時可能被鎖定
   - 嘗試使用「格式化」功能

3. **URL 太長**
   - NTAG213 只有 144 bytes
   - 建議使用 NTAG215 (504 bytes) 或 NTAG216 (888 bytes)

4. **手機 NFC 功能問題**
   - iOS: 確認是 iPhone 7 以上且 iOS 13+
   - Android: 到設定中確認 NFC 已啟用

### 讀取失敗？

1. 確認 App 已安裝且有 URL Scheme 設定
2. 確認寫入的 URL 格式正確
3. 嘗試重新寫入

---

## 📱 App 端設定

要讓 Flutter App 能夠響應 NFC 讀取，需要設定 URL Scheme：

### iOS (Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>parliament1812</string>
        </array>
    </dict>
</array>
```

### Android (AndroidManifest.xml)
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="parliament1812" />
</intent-filter>
```

---

## 🎮 遊戲流程

1. **發卡**: GM 將 NFC 卡片發給玩家
2. **掃卡**: 玩家用手機掃描自己的卡片
3. **揭示**: App 自動開啟，播放開卡動畫
4. **角色**: 顯示角色資訊與秘密任務
5. **開始**: 玩家進入角色，開始國會辯論！

---

## 🔐 安全說明

- 每張卡片都有唯一的 `secret` 驗證碼
- 玩家無法透過掃描其他人的卡片來偷看角色
- 建議每場遊戲重新生成 URL（更新 secret）

---

## 📞 需要幫助？

- 檢查 `nfc_urls_for_writing.txt` 確認 URL
- 確認手機和卡片相容性
- 在 App 中測試 Deep Link 是否正常

祝遊戲愉快！🎭👑
