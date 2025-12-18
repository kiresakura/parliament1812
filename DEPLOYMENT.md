# Parliament 1812 - 部署指南

## Railway 部署步驟

### 1. 前置準備

1. 建立 [Railway](https://railway.app) 帳號
2. 安裝 Railway CLI（可選）：
   ```bash
   npm install -g @railway/cli
   railway login
   ```

### 2. 建立專案

1. 在 Railway 控制台點擊 "New Project"
2. 選擇 "Deploy from GitHub repo"
3. 授權並選擇此專案的 GitHub repository

### 3. 新增資料庫服務

在同一個專案中：

#### PostgreSQL
1. 點擊 "New" → "Database" → "PostgreSQL"
2. Railway 會自動產生 `DATABASE_URL` 環境變數

#### Redis
1. 點擊 "New" → "Database" → "Redis"
2. Railway 會自動產生 `REDIS_URL` 環境變數

### 4. 配置後端服務

1. 點擊後端服務（parliament1812）
2. 進入 "Settings" 標籤
3. 設定 Root Directory: `backend`
4. 進入 "Variables" 標籤，新增以下環境變數：

```
APP_NAME=Parliament 1812
APP_VERSION=1.0.0
DEBUG=false
SECRET_KEY=<生成一個強隨機密鑰>
CORS_ORIGINS=*
WS_HEARTBEAT_INTERVAL=30
MAX_PLAYERS_PER_ROOM=20
```

注意：`DATABASE_URL` 和 `REDIS_URL` 會自動從資料庫服務注入

### 5. 生成 Secret Key

使用 Python 生成安全的 SECRET_KEY：
```python
import secrets
print(secrets.token_urlsafe(32))
```

或使用 OpenSSL：
```bash
openssl rand -base64 32
```

### 6. 部署

1. 推送程式碼到 GitHub，Railway 會自動部署
2. 或使用 Railway CLI：
   ```bash
   cd backend
   railway up
   ```

### 7. 執行資料庫遷移

部署後，在 Railway 控制台開啟 terminal 執行：
```bash
alembic upgrade head
```

或設定 build command：
```bash
alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### 8. 驗證部署

1. 取得服務 URL（例如：`https://parliament1812-production.up.railway.app`）
2. 訪問 `/docs` 確認 API 文件可存取
3. 訪問 `/health` 確認健康檢查通過

---

## 環境變數說明

| 變數名 | 說明 | 範例 |
|--------|------|------|
| `DATABASE_URL` | PostgreSQL 連線字串 | `postgresql+asyncpg://...` |
| `REDIS_URL` | Redis 連線字串 | `redis://...` |
| `SECRET_KEY` | JWT 和安全用密鑰 | 32 位元隨機字串 |
| `CORS_ORIGINS` | 允許的前端來源 | `*` 或 `https://app.example.com` |
| `DEBUG` | 除錯模式 | `false` (生產環境) |

---

## Flutter 前端建置

### iOS
```bash
cd frontend
flutter build ios --release
```

### Android
```bash
cd frontend
flutter build apk --release
```

### 更新 API URL

在 `frontend/lib/config/app_config.dart` 中更新：
```dart
static const String prodApiBaseUrl = 'https://your-railway-url.up.railway.app';
static const String prodWsBaseUrl = 'wss://your-railway-url.up.railway.app';
static const bool isDevelopment = false;  // 生產環境設為 false
```

---

## 監控與維護

### 查看日誌
```bash
railway logs
```

### 重新部署
```bash
railway redeploy
```

### 停止服務
```bash
railway down
```

---

## 常見問題

### WebSocket 連線失敗
- 確認使用 `wss://`（而非 `ws://`）
- 檢查 CORS 設定是否正確

### 資料庫連線錯誤
- 確認 `DATABASE_URL` 格式包含 `+asyncpg`
- 檢查 Railway 的資料庫服務是否正常運行

### Redis 連線超時
- 確認 Redis 服務已啟動
- 檢查 `REDIS_URL` 是否正確注入
