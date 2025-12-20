# Parliament 1812 - iOS Platform

> iOS 版本 - 採用 Apple 原生配置的 Flutter 應用程式

## 📁 專案結構

```
platforms/ios/
├── flutter_ios/                 # Flutter iOS 專案
│   ├── Runner/                  # 主應用程式
│   │   ├── AppDelegate.swift    # 應用程式生命週期 + Deep Link
│   │   ├── Info.plist           # Apple 原生配置
│   │   ├── Runner.entitlements  # 功能權限
│   │   └── Assets.xcassets/     # App 圖示和資源
│   │
│   ├── Podfile                  # CocoaPods 依賴配置
│   ├── ExportOptions.plist      # 打包發布配置
│   ├── PrivacyInfo.xcprivacy    # iOS 17+ 隱私清單
│   └── Runner.xcworkspace       # Xcode 工作區
│
├── lib/                         # Dart 原始碼
├── assets/                      # 資源檔案
└── pubspec.yaml                 # Flutter 依賴
```

## 🛠️ 環境需求

- **macOS**: 14.0 (Sonoma) 或更高
- **Xcode**: 15.0 或更高
- **iOS**: 13.0 或更高（NFC 需求）
- **Flutter**: 3.x
- **CocoaPods**: 1.14.0 或更高

## 🚀 快速開始

### 1. 安裝依賴

```bash
cd platforms/ios
flutter pub get
cd flutter_ios
pod install
```

### 2. 開啟專案

```bash
open flutter_ios/Runner.xcworkspace
```

### 3. 執行

```bash
# 模擬器
flutter run -d ios

# 真機（需要開發者帳號）
flutter run -d <device-id>
```

## 📱 功能配置

### NFC 掃描
- 需要 iPhone 7 或更新機型
- iOS 13.0 或更高版本
- 已在 `Info.plist` 和 `Runner.entitlements` 中配置

### Deep Link
- URL Scheme: `parliament1812://`
- 範例: `parliament1812://role?id=WORKER01&secret=abc123`

### Universal Links
- Domain: `1812-production.up.railway.app`
- 需要在 Apple Developer Portal 配置 Associated Domains

## 🔐 權限說明

| 權限 | 用途 |
|------|------|
| NFC | 掃描角色卡片 |
| 網路 | 連接遊戲伺服器 |
| 推播通知 | 遊戲通知（可選） |

## 📦 打包發布

### Development (Ad-hoc)

```bash
flutter build ios --release
cd flutter_ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -sdk iphoneos \
  -configuration Release \
  archive -archivePath build/Runner.xcarchive

xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ipa
```

### App Store

1. 修改 `ExportOptions.plist`:
   ```xml
   <key>method</key>
   <string>app-store</string>
   ```

2. 使用 Xcode 的 Archive 功能
3. 透過 App Store Connect 上傳

## ⚙️ 配置說明

### Info.plist 重點配置

- `CFBundleDisplayName`: App 顯示名稱
- `CFBundleURLTypes`: Deep Link URL Scheme
- `NSAppTransportSecurity`: 網路安全設定
- `UIRequiredDeviceCapabilities`: 必要設備功能

### Entitlements 權限

- `com.apple.developer.nfc.readersession.formats`: NFC 讀取格式
- `com.apple.developer.associated-domains`: Universal Links
- `aps-environment`: 推播通知環境

## 🐛 常見問題

### CocoaPods 安裝失敗
```bash
sudo gem install cocoapods
pod repo update
pod install --repo-update
```

### 簽名問題
1. 確認已登入 Apple Developer 帳號
2. Xcode → Signing & Capabilities → 選擇正確的 Team
3. 確認 Bundle Identifier 正確

### NFC 無法使用
1. 確認設備支援 NFC（iPhone 7+）
2. 確認 iOS 版本 ≥ 13.0
3. 確認 `Runner.entitlements` 已正確配置

## 📄 相關文件

- [Flutter iOS 部署指南](https://docs.flutter.dev/deployment/ios)
- [Apple Developer 文件](https://developer.apple.com/documentation/)
- [Core NFC 文件](https://developer.apple.com/documentation/corenfc)

## 🔗 後端 API

- **生產環境**: https://1812-production.up.railway.app
- **API 文檔**: https://1812-production.up.railway.app/docs

---

*Parliament 1812 © 2024*
