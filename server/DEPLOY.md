# 部署檢查清單

## 首次部署

1. 安裝 Fly CLI: `brew install flyctl`
2. 登入: `fly auth login`
3. 初始化: `fly launch`
4. 建立 PostgreSQL: `fly postgres create --name parliament1812-db`
5. 附加資料庫: `fly postgres attach parliament1812-db`
6. 建立 Redis: `fly redis create`
7. 設定 secrets:
   - `fly secrets set JWT_SECRET="your-secret"`
   - `fly secrets set REDIS_URL="redis://..."`
8. 部署: `fly deploy`

## 日常部署

1. 確認測試通過: `cargo test`
2. 部署: `fly deploy`
3. 檢查狀態: `fly status`
4. 查看日誌: `fly logs`

## 擴展

- 增加機器: `fly scale count 3`
- 升級規格: `fly scale vm shared-cpu-2x`

## 除錯

- SSH 進入: `fly ssh console`
- 本地連接資料庫: `fly proxy 5432 -a parliament1812-db`

## 環境變數

| 變數 | 說明 | 設定方式 |
|------|------|----------|
| `DATABASE_URL` | PostgreSQL 連線字串 | 自動（attach 後）|
| `REDIS_URL` | Redis 連線字串 | `fly secrets set` |
| `JWT_SECRET` | JWT 簽名密鑰 | `fly secrets set` |
| `RUST_LOG` | 日誌等級 | `fly.toml [env]` |

## 健康檢查

應用程式提供 `/health` 端點，Fly.io 會定期檢查：

```bash
curl https://parliament1812-api.fly.dev/health
```

## 回滾

如需回滾到上一個版本：

```bash
# 查看部署歷史
fly releases

# 回滾到特定版本
fly deploy --image registry.fly.io/parliament1812-api:v{version}
```

## 監控

```bash
# 即時日誌
fly logs

# 機器狀態
fly status

# 資源使用
fly dashboard
```
