# App Store Review Guidelines — 合規檢查清單

**1812 國會風雲 | Parliament 1812**

> 參考：[App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## 1. Safety

- [ ] **1.1 Objectionable Content**: 無令人反感的內容（暴力、色情、仇恨言論）
- [ ] **1.2 User-Generated Content**: 如有 UGC（聊天功能），已實作內容過濾與檢舉機制
- [ ] **1.3 Kids Category**: 不適用（非兒童類別，12+ 評級）

---

## 2. Performance

- [ ] **2.1 App Completeness**: App 功能完整，非 beta / demo / 測試版本
- [ ] **2.2 Beta Testing**: 不包含 TestFlight 或其他測試工具的參考
- [ ] **2.3 Accurate Metadata**: App 描述、截圖、預覽與實際功能一致
- [ ] **2.4 Hardware Compatibility**: 在目標裝置上正常運作（iPhone + iPad）
- [ ] **2.5 Software Requirements**: 最低 iOS 版本設定合理

---

## 3. Business

- [ ] **3.1.1 In-App Purchase**: 所有數位商品（金幣、卡牌包、擴充包）必須使用 Apple IAP
- [ ] **3.1.1 IAP Restore**: 實作「Restore Purchases」功能
- [ ] **3.1.2 Subscriptions**: 如有訂閱制，已遵守自動續訂規範（目前無）
- [ ] **3.1.7 Advertising**: 如有廣告，清楚標示（目前無廣告計畫）
- [ ] **3.2 Other Business Model Issues**: 無引導用戶至外部購買的行為

---

## 4. Design

- [ ] **4.0 Design — General**: 無 crash、無嚴重 bug
- [ ] **4.0 Design — UI**: 不模仿系統 UI 或 Apple 產品設計
- [ ] **4.1 Copycats**: 遊戲為原創設計，非抄襲
- [ ] **4.2 Minimum Functionality**: App 有足夠且有意義的功能
- [ ] **4.3 Spam**: 非重複提交、非重新包裝的內容
- [ ] **4.4 Extensions**: 不適用
- [ ] **4.5 Apple Sites and Services**: 正確使用 Game Center API
- [ ] **4.7 HTML5 Games / Bots**: 不適用（原生 Flutter app）

---

## 5. Legal / Privacy

- [ ] **5.1 Privacy — General**: 已建立完整隱私權政策
- [ ] **5.1 Privacy — URL**: 隱私權政策 URL 已設定在 App Store Connect
- [ ] **5.1.1 Data Collection and Storage**: 明確揭露所有收集的資料
- [ ] **5.1.1 App Tracking Transparency (ATT)**: 如使用追蹤功能，已實作 ATT 彈窗
- [ ] **5.1.1 Purpose String**: Info.plist 中的所有 Usage Description 已填寫
- [ ] **5.1.2 Data Use and Sharing**: 資料使用目的已在 App Privacy 中揭露
- [ ] **5.2 Intellectual Property**: 無侵犯第三方智慧財產權
- [ ] **5.3 Gaming, Gambling**: 卡牌機制不涉及真實金錢賭博
- [ ] **5.4 VPN Apps**: 不適用
- [ ] **5.6 Developer Code of Conduct**: 遵守開發者行為準則

---

## 登入相關

- [ ] **Sign in with Apple**: 已實作（如有提供第三方登入選項則為**必要**）
- [ ] **Guest Mode**: 考慮提供訪客模式讓審核人員快速體驗（非必要但建議）
- [ ] **Demo Account**: 提交審核時附上測試帳號密碼

---

## App Privacy（App Store Connect 隱私標籤）

### 資料類型揭露

| 資料類型 | 是否收集 | 連結至身份 | 用於追蹤 |
|----------|---------|-----------|---------|
| Contact Info (Email) | 選填 | 否 | 否 |
| Identifiers (User ID) | 是 | 是 | 否 |
| Usage Data (Game progress) | 是 | 是 | 否 |
| Diagnostics (Crash data) | 是 | 否 | 否 |
| Purchases (IAP history) | 是 | 是 | 否 |

---

## 提交前最終檢查

- [ ] `flutter build ipa` 成功
- [ ] 在實機上完整測試所有流程
- [ ] 所有截圖為最新版本
- [ ] 審核備註已填寫（說明遊戲玩法、提供測試帳號）
- [ ] 版本號與 build number 正確
- [ ] 所有 IAP 產品已建立並通過審核
- [ ] Game Center 成就與排行榜已設定
- [ ] 隱私權政策 URL 可存取
- [ ] App Privacy 標籤已填寫

---

## 常見被拒原因（預防）

| 被拒原因 | 預防措施 |
|----------|---------|
| Crash on launch | 充分測試所有裝置 |
| Incomplete info | 提供完整審核備註與測試帳號 |
| IAP 問題 | 確保 Restore Purchases 正常運作 |
| Misleading screenshots | 截圖需為真實遊戲畫面 |
| Missing privacy policy | 確認 URL 可存取 |
| No Sign in with Apple | 如有任何第三方登入就必須支援 |
| Placeholder content | 移除所有 TODO / Lorem ipsum |
