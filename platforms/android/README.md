# 1812 國會風雲 - Android 版

## 開發環境
- 語言: Kotlin / Jetpack Compose (或 Flutter for Android)
- 最低版本: Android API 24 (Android 7.0)
- 開發工具: Android Studio

## 目錄結構
```
android/
├── flutter_android/  # Flutter Android 原生配置
├── lib/              # Dart 源代碼（從 Flutter 遷移）
├── assets/           # 資源文件
├── releases/         # APK 發布版本
├── pubspec.yaml      # Flutter 配置
└── README.md
```

## 已發布版本
- parliament1812-release.apk (v1)
- parliament1812-release-v2.apk
- parliament1812-release-v3.apk
- parliament1812-release-v4.apk (最新)

## 後端 API
- 生產環境: https://1812-production.up.railway.app
- 參考: ../shared/backend/

## NFC 功能
Android 使用 android.nfc 框架
- 需要 NFC 硬體支援
- 已配置權限: android.permission.NFC

## 開始開發
```bash
cd platforms/android
flutter pub get
flutter run -d android
```

## 打包 APK
```bash
flutter build apk --release
```
