# 1812 國會風雲 Parliament Storm

多人線上政治辯論遊戲，以英國工業革命為背景。

## 專案結構

```
parliament1812/
├── backend/              # Node.js + Socket.IO 後端
├── platforms/flutter/    # Flutter 跨平台客戶端
├── docs/                 # 設計文檔
├── CLAUDE.md            # 開發指引
├── DEPLOY.md            # 部署指南
└── README.md            # 本文件
```

## 快速開始

### 後端
```bash
cd backend
npm install
npm run dev
```

### Flutter
```bash
cd platforms/flutter
flutter pub get
flutter run
```

## 開發
詳見 CLAUDE.md 和 CLAUDE_CODE_STEPS.md

## 部署
詳見 DEPLOY.md
