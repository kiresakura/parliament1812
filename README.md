# 1812 國會風雲 | 1812: Parliament Storm

多人線上社交推理遊戲，以英國工業革命為背景。
核心玩法：**同時出牌資訊戰** — 資訊戰 × 策略卡牌 × 社交推理，10 分鐘一局。

## 📖 開發手冊（從這裡開始）

| 順序 | 文件 | 角色 |
|------|------|------|
| 1 | [`CLAUDE.md`](./CLAUDE.md) | **開發手冊**：技術棧、v3 核心數值、專案結構、開發原則、路線圖 |
| 2 | [`docs/GDD_v3_Design_Response.md`](./docs/GDD_v3_Design_Response.md) | **設計權威**：v3 數值經濟、社交機制、課金設計、驗收門檻。與 GDD_v2 衝突時以此為準 |
| 3 | [`docs/GDD_v2.md`](./docs/GDD_v2.md) | 遊戲設計文件（完整框架） |
| 4 | [`DEV_SETUP.md`](./DEV_SETUP.md) | 開發環境設定 |

## 專案結構

```
parliament1812/
├── app/                  # Flutter 客戶端（主要，iOS/Android）
├── server/               # Rust 後端（Axum + Tokio，權威伺服器）
├── docs/                 # 設計文檔（GDD、評測、商店素材、封存）
├── assets/               # 遊戲素材（卡牌、角色、音樂；PNG/OGG 通用）
├── parliament_assets/    # UI 主題、元件參考
├── shared/               # UI 設計稿（React/Vite mockup，僅參考）
├── scripts/              # 測試腳本（fulltest.sh）
├── godot-client/         # 【封存】Godot 4.6 試作，停止開發
├── backend/              # 【封存】Node.js 舊版後端
└── .github/workflows/    # CI/CD（rust-check、deploy-server → Fly.io）
```

## 快速開始

### 後端（Rust）
```bash
# 本地資料庫（Postgres 16）
docker-compose up -d db

cd server
cp .env.example .env   # 設定 DATABASE_URL / REDIS_URL / JWT_SECRET
cargo run
```

### 客戶端（Flutter）
```bash
cd app
flutter pub get
flutter run
```

### 測試與檢查
```bash
cd server && cargo test && cargo fmt --check && cargo clippy
cd app && flutter test && flutter analyze
./scripts/fulltest.sh   # 全套測試
```

## 部署（Fly.io）

推送到 `main` 的 `server/**` 變更自動觸發部署（需設定 GitHub Secret `FLY_API_TOKEN`）。

```bash
cd server
fly deploy          # 手動部署
fly logs            # 查看日誌
```

| Workflow | 觸發 | 說明 |
|----------|------|------|
| `deploy-server.yml` | Push to main (server/**) | 測試 + 部署到 Fly.io |
| `rust-check.yml` | PR (server/**) | fmt + Clippy + 測試 |
| `ci.yml` / `deploy.yml` | — | 其他 CI |

## 📂 文件索引（docs/）

| 類別 | 文件 | 狀態 |
|------|------|------|
| 設計 | `GDD_v3_Design_Response.md` | ★ 現行權威 |
| 設計 | `GDD_v2.md` | 現行框架（數值以 v3 為準） |
| 設計 | `Design_Review_v2_Critique.md` | v2 評測（v3 的問題來源） |
| 定位 | `Product_Positioning_v1.docx` / `.pdf` | 產品定位書 |
| 成長 | `Viral_Growth_Roadmap.md`、`OpenClaw_Viral_Growth_Prompt.md`、`OPENCLAW_PROMPT.md` | 行銷/成長企劃 |
| 商店 | `appstore/`（app-info、隱私、審核清單、截圖規格） | 上架素材 |
| 商店 | `steam/`（成就、Steamworks 計畫、商店描述） | 上架素材 |
| 素材 | `preview-1.jpg` ~ `preview-9.jpg` | 商店預覽圖 |
| 封存 | `archive/`（GDD_v1、Node.js 部署/測試文件、Railway 設定、初建期開發指令） | 僅歷史參考 |

## API 文檔

- 健康檢查：`GET /health`
- WebSocket：`WS /ws?token={jwt}`
- 詳細 API：[`server/README.md`](./server/README.md)

## 授權

MIT License
