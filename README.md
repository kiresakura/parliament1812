# 1812 國會風雲 Parliament Debate

> 一款以 1812 年英國盧德運動為背景的國會辯論角色扮演遊戲

## 🏗️ 專案結構

```
parliament1812/
├── platforms/           # 各平台獨立開發環境
│   ├── ios/            # iOS 版本 (Swift/Flutter)
│   ├── android/        # Android 版本 (Kotlin/Flutter)
│   └── web/            # Web 版本 (Flutter/React)
│
├── shared/             # 共用資源
│   ├── backend/        # FastAPI 後端 (Railway 部署)
│   ├── nfc_tools/      # NFC 工具和卡片資料
│   ├── docs/           # 文檔
│   ├── scripts/        # 腳本工具
│   ├── flutter_original/  # Flutter 原始專案備份
│   └── Mobile_Game_UI_Design/  # UI 設計參考
│
├── CLAUDE.md           # Claude AI 開發指南
├── DEPLOYMENT.md       # 部署說明
└── README.md           # 本文件
```

## 🎭 角色系統

| 角色 | 卡片 ID | 陣營 |
|------|---------|------|
| 👑 喬治三世 | GEORGEIII01~04 | 皇室 |
| 🔨 工人 | WORKER01~04 | 勞工 |
| 🏭 工廠主 | FACTORY01~04 | 資方 |
| ⚔️ 盧德派 | LUDDITE01~04 | 激進派 |
| 📜 改革者 | REFORMER01~04 | 改革派 |
| 🎩 議員 | MP01~04 | 國會 |

## 🔗 後端 API

- **生產環境**: https://1812-production.up.railway.app
- **API 文檔**: https://1812-production.up.railway.app/docs

## 📱 NFC 防作弊系統

- 本地 NFC 服務: `shared/nfc_local_service.py`
- NFC 卡片資料: `shared/nfc_tools/nfc_cards.json`
- 讀卡器: ACR122U

## 🚀 快速開始

### iOS
```bash
cd platforms/ios
flutter pub get
flutter run -d ios
```

### Android
```bash
cd platforms/android
flutter pub get
flutter run -d android
```

### Web
```bash
cd platforms/web
flutter pub get
flutter run -d chrome
```

### 後端
```bash
cd shared/backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## 📅 里程碑

- **Alpha Demo**: 2026/01/07
- **目標**: 6 人遊玩完整流程

---
*開發工具: Claude AI, Claude Code, Xcode, Android Studio*
