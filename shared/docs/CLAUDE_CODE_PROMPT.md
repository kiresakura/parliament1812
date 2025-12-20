# 1812 國會風雲 - Claude Code 開發 Prompt

## 🎯 專案啟動指令

請在 Claude Code 中執行以下指令開始開發：

```
cd /Users/zhongliyuanshiqi/Documents/parliament1812
```

然後貼上以下 Prompt：

---

## 📋 Claude Code Prompt (複製這個)

```
你現在要幫我開發「1812 國會風雲」角色扮演遊戲 App。

請先閱讀 CLAUDE.md 了解完整專案規格。

這是一個模擬 1812 年英國國會辯論的多人即時連線遊戲，特色功能包括：
- NFC 卡片掃描選角色
- 每個玩家有秘密任務（只有自己看得到）
- 玩家間可以私訊密謀
- 主持人可以觸發突發事件
- 兩輪投票（第一輪匿名、第二輪記名）

技術棧：
- 後端：FastAPI + PostgreSQL + Redis + WebSocket
- 前端：Flutter (iOS + Android)
- 部署：Railway

專案結構已經建好，請從後端開始：

1. 先在 backend/ 建立 FastAPI 專案結構
2. 設定 SQLAlchemy + PostgreSQL 連線
3. 建立資料庫模型 (models/)
4. 實作房間管理 API
5. 實作 WebSocket 即時同步

開發時請注意：
- 使用 async/await 非同步處理
- WebSocket 用 Redis Pub/Sub 處理多房間廣播
- 所有 API 都要有 Pydantic schema 驗證
- 寫好 docstring 和型別註解

現在請開始建立後端的 main.py 和基礎結構。
```

---

## 🔄 開發階段 Prompts

### 階段一完成後（後端 API）
```
後端基礎 API 完成了，現在請：
1. 實作 WebSocket 連線管理 (websocket/)
2. 實作 Redis Pub/Sub 多房間廣播
3. 加入私訊系統的 API 和 WebSocket 事件
4. 測試 WebSocket 連線是否正常
```

### 階段二開始（Flutter）
```
後端完成了，現在開始 Flutter 前端：
1. 在 frontend/ 初始化 Flutter 專案
2. 設定必要的套件 (nfc_manager, web_socket_channel, provider)
3. 建立首頁 UI（建立房間 / 輸入房間碼加入）
4. 實作 NFC 掃描功能
5. 建立 WebSocket 服務類
```

### 階段三（投票系統）
```
現在實作投票系統：
1. 後端：多輪投票 API（round 1 匿名、round 2 記名）
2. 後端：投票結果統計（第一輪只回傳百分比）
3. 前端：投票頁面 UI
4. 前端：即時投票進度更新
5. 前端：投票結果動畫展示
```

### 最終整合
```
最後整合階段：
1. 主持人控制面板（切換階段、觸發事件、控制計時器）
2. 突發事件系統
3. 秘密任務揭曉頁面
4. 歷史對照頁面
5. 整體 UI 美化
6. 準備 Railway 部署配置
```

---

## ⚙️ Railway 部署 Prompt

```
專案開發完成，請幫我準備 Railway 部署：
1. 建立 backend/Dockerfile
2. 建立 backend/railway.toml
3. 設定環境變數範本 (.env.example)
4. 建立資料庫 migration 腳本
5. 給我 Railway CLI 部署指令
```

---

## 🐛 Debug Prompts

### WebSocket 連線問題
```
WebSocket 連線有問題，請幫我：
1. 檢查 WebSocket 路由設定
2. 確認 CORS 設定正確
3. 加入連線日誌方便除錯
4. 測試心跳機制
```

### Flutter NFC 問題
```
Flutter NFC 掃描有問題，請幫我：
1. 檢查 iOS/Android 權限設定
2. 確認 NDEF 訊息解析邏輯
3. 加入錯誤處理
4. 測試不同 NFC 卡片格式
```

---

## 📁 專案目錄

```
/Users/zhongliyuanshiqi/Documents/parliament1812/
├── CLAUDE.md          ← 完整開發規格（必讀）
├── README.md          ← 專案說明
├── backend/           ← FastAPI 後端
├── frontend/          ← Flutter App
├── nfc_tools/         ← NFC 卡片工具
├── docs/              ← 文件
└── scripts/           ← 腳本
```
