# 1812 國會風雲 - UI 素材包
## Parliament Debates - Design Assets

這個素材包包含從 Figma 導出的完整 UI 設計系統。

---

## 📁 目錄結構

```
parliament1812_assets/
├── images/
│   ├── backgrounds/
│   │   └── parliament_chamber.png    # 議會大廳背景
│   └── characters/
│       ├── tory_elder_statesman.png  # 托利黨資深政治家
│       ├── tory_young_politician.png # 托利黨年輕政客
│       ├── whig_intellectual.png     # 輝格黨知識分子
│       ├── luddite_worker.png        # 盧德派工人
│       └── commoner_craftsman.png    # 平民工匠
├── components/
│   ├── HomeScreen1812.tsx            # 首頁 React 組件
│   ├── WaitingRoom1812.tsx           # 等候室組件
│   ├── VotingScreen1812.tsx          # 投票畫面組件
│   ├── RoleCardReveal1812.tsx        # 角色揭示組件
│   ├── VictorianOrnament.tsx         # 維多利亞裝飾元素
│   └── HexagonPattern.tsx            # 六角形背景圖案
├── theme/
│   ├── Parliament1812Theme.swift     # iOS/SwiftUI 主題
│   └── Parliament1812Theme.kt        # Android/Compose 主題
└── docs/
    ├── DESIGN_DOCUMENTATION.md       # 完整設計規範
    └── characters.ts                 # 角色數據定義
```

---

## 🎨 色彩系統

| 用途 | 色碼 | 說明 |
|------|------|------|
| 主背景 | `#1a1a2e` | 深海軍藍 |
| 卡片背景 | `#16213e` | 次要深藍 |
| 主強調色 | `#d4af37` | 古董金 |
| 主要文字 | `#f5e6d3` | 羊皮紙奶油色 |
| 托利黨 | `#1e3a5f` | 皇家藍 |
| 輝格黨 | `#cc7722` | 橙黃色 |
| 贊成票 | `#2d5a27` | 議會綠 |
| 反對票 | `#8b2500` | 深紅色 |

---

## 📱 使用方式

### iOS (SwiftUI)
1. 將 `Parliament1812Theme.swift` 加入 Xcode 專案
2. 將圖片素材加入 Assets.xcassets
3. 使用 `Color.Parliament1812.xxx` 取用顏色

### Android (Compose)
1. 將 `Parliament1812Theme.kt` 加入專案
2. 將圖片放入 `res/drawable/`
3. 用 `Parliament1812Theme { }` 包裹 UI

### React/Web
1. 直接使用 `components/` 內的 TSX 檔案
2. 需要安裝: framer-motion, lucide-react

---

## 🎭 歷史角色

### 托利黨 (政府/保守派)
- Spencer Perceval 斯賓塞·珀西瓦爾 - 首相
- Lord Liverpool 利物浦伯爵 - 戰爭大臣
- Lord Castlereagh 卡斯爾雷子爵 - 外交大臣
- Lord Eldon 艾爾登勳爵 - 大法官
- Nicholas Vansittart 范西塔特 - 財政大臣

### 輝格黨 (反對派/改革派)
- Earl Grey 格雷伯爵 - 輝格黨領袖
- Lord Holland 霍蘭勳爵 - 輝格黨元老
- Samuel Whitbread 惠特布雷德 - 激進派議員
- Henry Brougham 布魯厄姆 - 改革派律師
- Lord Grenville 格倫維爾勳爵 - 前首相

---

Generated from Figma export, December 2024
