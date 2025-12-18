# 1812 國會風雲 (Parliament 1812)

> 🏛️ 一個模擬1812年英國國會辯論的角色扮演遊戲 App

## 📁 專案結構

```
parliament1812/
├── backend/                 # FastAPI 後端
│   ├── app/
│   │   ├── api/            # API 路由
│   │   ├── models/         # SQLAlchemy ORM 模型
│   │   ├── schemas/        # Pydantic 資料結構
│   │   ├── services/       # 業務邏輯
│   │   └── websocket/      # WebSocket 處理
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/               # Flutter App
│   ├── lib/
│   │   ├── screens/        # 頁面
│   │   ├── widgets/        # 元件
│   │   ├── services/       # API 服務
│   │   ├── models/         # 資料模型
│   │   └── providers/      # 狀態管理
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── nfc_tools/              # NFC 卡片工具
├── docs/                   # 文件
└── scripts/                # 腳本
```

## 🎮 功能列表

- [x] NFC 卡片角色分配
- [ ] 房間建立/加入
- [ ] 即時 WebSocket 同步
- [ ] 秘密任務系統
- [ ] 私訊功能
- [ ] 突發事件系統
- [ ] 多輪投票（匿名 + 記名）
- [ ] 結果統計與歷史揭曉

## 🚀 開發時程

- **Week 1** (12/17-24): 後端 API + NFC 卡片
- **Week 2** (12/25-31): Flutter UI + WebSocket
- **Week 3** (1/1-7): 投票系統 + 測試
- **1/7**: 學術部部會 Demo

## 🛠️ 技術棧

- **後端**: FastAPI + PostgreSQL + Redis
- **前端**: Flutter (iOS + Android)
- **部署**: Railway
- **即時通訊**: WebSocket + Redis Pub/Sub
