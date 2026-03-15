# 1812 國會風雲 - Godot Client

策略卡牌對戰遊戲的前端客戶端，使用 Godot 4.6 開發。

## 技術架構

- **引擎**: Godot 4.6.1
- **語言**: GDScript (Static Typed)
- **後端**: Rust Axum (`https://parliament1812.fly.dev`)
- **通訊**: REST API + WebSocket

## 專案結構

```
godot-client/
├── scenes/      # 場景檔案 (.tscn)
├── scripts/     # GDScript 腳本
│   ├── autoload/  # 全域單例
│   ├── game/      # 遊戲邏輯
│   ├── ui/        # UI 控制
│   └── data/      # 資料模型
├── resources/   # 主題、字型等
├── assets/      # 美術資源
└── addons/      # 插件
```

## Autoload 服務

| 服務 | 用途 |
|------|------|
| `GameManager` | 全域遊戲狀態管理 |
| `ApiService` | HTTP API 客戶端 |
| `WsService` | WebSocket 即時通訊 |
| `AuthService` | 認證管理 |
| `AudioManager` | 音效管理 |
| `SceneManager` | 場景切換管理 |

## 開發

1. 安裝 Godot 4.6+
2. 開啟專案：`godot --path .`
3. 設定環境：修改 `ApiService.BASE_URL`

## 匯出平台

- Web (HTML5)
- iOS
- Android
