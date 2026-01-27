# 1812 國會風雲 Parliament Storm

多人線上政治辯論遊戲，以英國工業革命為背景。

## 專案結構

```
parliament1812/
├── server/               # Rust 後端（主要）
├── backend/              # Node.js + Socket.IO 後端（舊版）
├── platforms/flutter/    # Flutter 跨平台客戶端
├── docs/                 # 設計文檔
├── .github/workflows/    # GitHub Actions CI/CD
├── CLAUDE.md            # 開發指引
├── DEPLOY.md            # 部署指南
└── README.md            # 本文件
```

## 快速開始

### Rust 後端
```bash
cd server
cp .env.example .env
# 編輯 .env 設定資料庫和 Redis
cargo run
```

### Flutter 客戶端
```bash
cd platforms/flutter
flutter pub get
flutter run
```

## 開發

詳見 [CLAUDE.md](./CLAUDE.md) 開發指引

### 執行測試
```bash
cd server
cargo test
```

### 程式碼檢查
```bash
cd server
cargo fmt --check
cargo clippy
```

## 部署

### Fly.io 部署（Rust 後端）

#### 前置需求
- [Fly CLI](https://fly.io/docs/hands-on/install-flyctl/)
- Fly.io 帳號

#### 首次部署
```bash
cd server

# 登入 Fly.io
fly auth login

# 建立應用程式
fly launch --no-deploy

# 建立 Postgres 資料庫
fly postgres create --name parliament1812-db --region nrt
fly postgres attach parliament1812-db

# 建立 Redis（可選，用於跨實例通訊）
fly redis create --name parliament1812-redis --region nrt

# 設定 JWT Secret
fly secrets set JWT_SECRET="$(openssl rand -hex 32)"

# 部署
fly deploy
```

#### 後續部署
```bash
cd server
fly deploy
```

#### 查看日誌
```bash
fly logs
```

### GitHub Actions 自動部署

推送到 `main` 分支的 `server/` 目錄變更會自動觸發部署。

#### 設定 GitHub Secrets
在 Repository Settings > Secrets and variables > Actions 中設定：

| Secret | 說明 |
|--------|------|
| `FLY_API_TOKEN` | Fly.io API Token（執行 `fly tokens create deploy`） |

### CI/CD 工作流程

| Workflow | 觸發條件 | 說明 |
|----------|----------|------|
| `deploy-server.yml` | Push to main (server/**) | 測試 + 部署到 Fly.io |
| `rust-check.yml` | PR (server/**) | 格式檢查 + Clippy + 測試 |

## API 文檔

### 健康檢查
```
GET /health
```

### WebSocket
```
WS /ws?token={jwt_token}
```

詳細 API 文檔請參考 [server/README.md](./server/README.md)

## 授權

MIT License
