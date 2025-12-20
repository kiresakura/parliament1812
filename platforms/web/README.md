# 1812 國會風雲 - Web 版

## 開發環境
- 框架: Flutter Web / React / Vue (選擇一種)
- 語言: Dart / TypeScript
- 開發工具: VS Code / WebStorm

## 目錄結構
```
web/
├── flutter_web/      # Flutter Web 原生配置
├── lib/              # Dart 源代碼（從 Flutter 遷移）
├── assets/           # 資源文件
├── pubspec.yaml      # Flutter 配置
└── README.md
```

## 後端 API
- 生產環境: https://1812-production.up.railway.app
- 參考: ../shared/backend/

## NFC 功能
⚠️ Web 平台 NFC 支援有限
- 需要 Web NFC API (Chrome 89+, Android only)
- 建議使用 QR Code 作為替代方案
- 或透過本地 NFC 服務代理

## 開始開發
```bash
cd platforms/web
flutter pub get
flutter run -d chrome
```

## 部署
```bash
flutter build web
# 輸出到 build/web/
```
