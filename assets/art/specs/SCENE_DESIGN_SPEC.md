# 場景設計規格
## Scene Design Specification

**版本：v1.0**  
**日期：2026-02-02**  
**設計：羅塞蒂（宮廷畫師）**

---

## 1. 場景系統概述

### 1.1 設計理念

**核心場景**：1812 年英國議會——威斯敏斯特宮

場景是遊戲的「舞台」，承載：
- **時代氛圍**：攝政時期的議會建築風格
- **戲劇張力**：政治角力的視覺表現
- **功能分區**：遊戲各區域的視覺區隔

### 1.2 場景清單

| # | 場景名稱 | 用途 | 優先級 |
|---|----------|------|--------|
| 1 | 議會大廳 | 主遊戲場景 | ⭐⭐⭐ |
| 2 | 密室/走廊 | 密謀階段背景 | ⭐⭐ |
| 3 | 主選單背景 | 開始畫面 | ⭐⭐⭐ |
| 4 | 角色選擇室 | 角色選擇 | ⭐⭐ |
| 5 | 投票大廳 | 投票階段 | ⭐⭐ |
| 6 | 勝利/失敗 | 結算畫面 | ⭐ |

---

## 2. 主場景：議會大廳

### 2.1 場景概述

**威斯敏斯特宮下議院**（House of Commons）

這是遊戲的核心舞台——辯論、攻防、投票都在這裡發生。

**歷史參考**：
- 1812 年的舊議會廳（1834 年火災前）
- 木質長椅對排
- 議長席居中
- 油燈與蠟燭照明
- 哥德式拱窗

### 2.2 視覺設計

**整體構圖**

```
┌─────────────────────────────────────────────────────────┐
│                    【拱形天花板】                        │
│                   哥德式肋拱，深棕木                      │
├─────────────────────────────────────────────────────────┤
│     │                                        │          │
│  左 │              【議長席】                │ 右       │
│  側 │          (中央高台，權威)              │ 側       │
│  長 │                                        │ 長       │
│  椅 │    ┌──────────────────────────┐       │ 椅       │
│  區 │    │                          │       │ 區       │
│     │    │      【中央辯論區】       │       │          │
│  (反│    │      (玩家互動區域)       │       │(執政     │
│  對 │    │                          │       │ 黨)      │
│  黨)│    └──────────────────────────┘       │          │
│     │                                        │          │
├─────────────────────────────────────────────────────────┤
│                    【前景：木質圍欄】                     │
│                   (手牌顯示區域)                         │
└─────────────────────────────────────────────────────────┘
```

**色調與光線**

| 元素 | 色調 | 說明 |
|------|------|------|
| 整體 | 暖棕 | 木質為主的溫暖感 |
| 光源 | 橙黃 | 油燈與蠟燭光 |
| 陰影 | 深棕 | 戲劇性明暗對比 |
| 點綴 | 深紅+金 | 議會傳統色 |

**光線設計**
- 主光源：高窗透入的自然光（日間場景）
- 補光：牆上燭台、吊燈
- 氛圍：煙霧繚繞（油燈/蠟燭）
- 時段變化：可切換日/夜氛圍

### 2.3 場景分層

**Layer 結構（從後到前）**

```
Layer 5 (最後): 背景牆壁 + 窗戶
    └── 哥德式拱窗，透光
    └── 牆上掛毯、紋章

Layer 4: 議長席 + 高台
    └── 議長座椅（華麗木雕）
    └── 權杖架

Layer 3: 兩側長椅
    └── 左側（反對黨席）
    └── 右側（執政黨席）
    └── NPC 議員剪影

Layer 2: 中央區域
    └── 辯論檯
    └── 角色立繪位置

Layer 1: 前景圍欄
    └── 木質欄杆
    └── 手牌顯示區

Layer 0 (最前): UI 覆蓋層
    └── 資源條、按鈕等
```

### 2.4 尺寸規格

| 規格 | 數值 |
|------|------|
| 設計尺寸 | 2048 × 1536 px (4:3) |
| 輸出尺寸 | @1x @2x @3x |
| 安全區域 | 內縮 100px |
| 格式 | PNG (分層) + 合成 |

### 2.5 AI 生成提示

**主場景 Prompt**

```
Interior of British House of Commons 1812, wooden Gothic architecture,
two rows of green leather benches facing each other, Speaker's chair 
at the center back, arched windows with dramatic light rays, oil lamps
and candles, warm brown wood tones with deep red and gold accents,
atmospheric smoke haze, Darkest Dungeon art style, dramatic lighting,
Victorian parliament, highly detailed, painterly style
```

**夜間變體**

```
Interior of British House of Commons 1812 at night, candlelit atmosphere,
wooden Gothic architecture, two rows of benches in shadow, Speaker's chair
illuminated by candlelight, warm orange glow from oil lamps, deep shadows,
mysterious atmosphere, Darkest Dungeon art style, dramatic chiaroscuro,
Victorian parliament night session
```

---

## 3. 密室場景

### 3.1 場景概述

**議會走廊 / 密室**

密謀階段的背景——私下交易、結盟、背叛的地方。

### 3.2 視覺設計

**整體構圖**

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│        【陰暗走廊】                                      │
│                                                         │
│    ┌─────┐                              ┌─────┐        │
│    │     │     燭光                      │     │        │
│    │ 門  │       ○                       │ 門  │        │
│    │     │                              │     │        │
│    └─────┘                              └─────┘        │
│                                                         │
│              【神秘人物剪影位置】                        │
│                                                         │
│    ════════════════════════════════════════════        │
│                    木質地板                             │
└─────────────────────────────────────────────────────────┘
```

**色調**
- 整體：深灰棕，壓抑
- 光源：單點燭光，強烈對比
- 氛圍：神秘、緊張、不信任

### 3.3 AI 生成提示

```
Dark Victorian parliament corridor 1812, single candle light source,
wooden paneled walls, mysterious shadows, two doors on sides, 
atmospheric tension, secret meeting place, Darkest Dungeon art style,
dramatic chiaroscuro, conspiracy atmosphere, dimly lit hallway
```

---

## 4. 主選單背景

### 4.1 場景概述

**威斯敏斯特宮外觀 + 遊戲標題**

玩家打開遊戲看到的第一個畫面，需要：
- 建立時代感
- 展示遊戲調性
- 視覺衝擊力

### 4.2 視覺設計

**構圖**

```
┌─────────────────────────────────────────────────────────┐
│                     【陰暗天空】                         │
│                    烏雲密布，透光                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                                                         │
│               ╔═══════════════════════╗                │
│               ║   1812                ║                │
│               ║   國會風雲            ║ ← 遊戲標題     │
│               ╚═══════════════════════╝                │
│                                                         │
│         【威斯敏斯特宮剪影】                            │
│          哥德式尖塔，莊嚴壯觀                           │
│                                                         │
├─────────────────────────────────────────────────────────┤
│     ～～～～【泰晤士河】～～～～                         │
│           河面倒影，微波                                │
└─────────────────────────────────────────────────────────┘
```

**色調**
- 天空：深藍灰 + 橙紅夕陽光
- 建築：黑色剪影 + 金色窗光
- 河面：深藍 + 倒影

**氛圍**
- 史詩感
- 風雲變色
- 權力的重量

### 4.3 AI 生成提示

```
Westminster Palace silhouette 1812, dramatic stormy sky with orange 
sunset light breaking through clouds, Gothic spires against sky,
Thames River in foreground with reflections, epic atmosphere,
political tension, Darkest Dungeon art style, painterly,
cinematic composition, moody and dramatic
```

---

## 5. 角色選擇室

### 5.1 場景概述

**議會休息室 / 會客廳**

玩家選擇角色的場景，需要展示 7 個角色的位置。

### 5.2 視覺設計

**構圖**

```
┌─────────────────────────────────────────────────────────┐
│                    【壁爐上方肖像】                      │
│                      (裝飾用)                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│    ┌───┐    ┌───┐    ┌───┐    ┌───┐    ┌───┐          │
│    │ 1 │    │ 2 │    │ 3 │    │ 4 │    │ 5 │          │
│    └───┘    └───┘    └───┘    └───┘    └───┘          │
│                                                         │
│              ┌───┐              ┌───┐                  │
│              │ 6 │              │ 7 │                  │
│              └───┘              └───┘                  │
│                                                         │
│    ═══════【華麗地毯】═══════                           │
│                                                         │
│              【壁爐】                                   │
│              火焰跳動                                   │
└─────────────────────────────────────────────────────────┘
```

**色調**
- 溫暖舒適：壁爐光 + 燭光
- 高級感：深紅地毯、木質牆板
- 期待感：角色位置發光提示

### 5.3 AI 生成提示

```
Victorian parliament lounge 1812, warm fireplace glow, ornate wooden
panels, rich red carpet, portrait paintings on wall, comfortable
aristocratic atmosphere, character selection room, warm and inviting,
Darkest Dungeon art style, dramatic firelight, elegant interior
```

---

## 6. 投票大廳

### 6.1 場景概述

**投票特寫場景**

投票階段的專用背景，聚焦於投票箱和選票。

### 6.2 視覺設計

**構圖**

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                  【聚光燈效果】                          │
│                       ↓                                │
│                                                         │
│                 ┌─────────────┐                        │
│                 │             │                        │
│                 │  【投票箱】  │                        │
│                 │   木質精緻   │                        │
│                 │             │                        │
│                 └─────────────┘                        │
│                                                         │
│           【選票】  【選票】  【選票】                   │
│            A 支持   B 反對    C 棄權                    │
│                                                         │
│    ════════════════════════════════════════════        │
│                    【長桌】                             │
└─────────────────────────────────────────────────────────┘
```

**色調**
- 聚焦：投票箱高亮
- 周圍：暗淡虛化
- 緊張：深色調 + 金色點綴

### 6.3 AI 生成提示

```
Victorian ballot box 1812, dramatic spotlight on wooden ornate ballot
box, voting papers on table, dark vignette around edges, tense
atmosphere, important decision moment, parliament voting scene,
Darkest Dungeon art style, focused composition, dramatic lighting
```

---

## 7. 勝利/失敗場景

### 7.1 勝利場景

**議會外的歡呼群眾**

```
Victorious scene outside Westminster 1812, cheering crowd, raised
fists, celebration atmosphere, warm golden light, triumphant mood,
Darkest Dungeon art style, dramatic composition, political victory
```

### 7.2 失敗場景

**陰暗的牢房 / 流放**

```
Dark prison cell 1812, iron bars, single shaft of light from window,
defeated atmosphere, political downfall, Darkest Dungeon art style,
dramatic shadows, melancholy mood, Victorian dungeon
```

---

## 8. 場景元件

### 8.1 可複用元件

| 元件 | 用途 | 格式 |
|------|------|------|
| 哥德式拱窗 | 多場景共用 | PNG |
| 油燈/燭台 | 光源裝飾 | PNG |
| 議會徽章 | 牆面裝飾 | PNG |
| 木質欄杆 | 前景遮擋 | PNG |
| 長椅 | 座位區 | PNG |
| 蠟燭光暈 | 光效疊加 | PNG (加法混合) |
| 煙霧效果 | 氛圍 | PNG (透明) |
| 窗戶光束 | 體積光 | PNG (疊加) |

### 8.2 動態元素

| 元素 | 動畫類型 | 用途 |
|------|----------|------|
| 燭火搖曳 | 循環動畫 | 氛圍 |
| 光束塵埃 | 粒子效果 | 氛圍 |
| 煙霧飄動 | 緩慢循環 | 氛圍 |
| 河面波紋 | 循環動畫 | 主選單 |

---

## 9. 技術規格

### 9.1 輸出規格

| 場景 | 尺寸 | 格式 |
|------|------|------|
| 主遊戲場景 | 2048×1536 | 分層 PSD + 合成 PNG |
| 主選單背景 | 2048×2732 (豎屏) | PNG |
| 其他場景 | 2048×1536 | PNG |
| 場景元件 | 各異 | PNG with alpha |

### 9.2 性能考量

- 背景使用靜態圖
- 動態元素單獨分層
- 提供低解析度備用版本
- 粒子效果可關閉

---

## 10. 製作清單

### 10.1 場景清單

| # | 場景 | 變體 | 優先級 |
|---|------|------|--------|
| 1 | 議會大廳 | 日間/夜間 | ⭐⭐⭐ |
| 2 | 主選單背景 | 靜態 | ⭐⭐⭐ |
| 3 | 密室走廊 | 靜態 | ⭐⭐ |
| 4 | 角色選擇室 | 靜態 | ⭐⭐ |
| 5 | 投票大廳 | 靜態 | ⭐⭐ |
| 6 | 勝利場景 | 靜態 | ⭐ |
| 7 | 失敗場景 | 靜態 | ⭐ |

### 10.2 元件清單

| 類別 | 數量 |
|------|------|
| 建築元件 | 8 |
| 傢俱元件 | 6 |
| 光效元件 | 4 |
| 氛圍元件 | 3 |
| **總計** | **21 個元件** |

---

## 11. 製作時程

| 階段 | 內容 | 工時 |
|------|------|------|
| 議會大廳（日間） | 主場景 | 5 天 |
| 議會大廳（夜間） | 變體 | 2 天 |
| 主選單背景 | 標題畫面 | 3 天 |
| 密室/走廊 | 密謀場景 | 3 天 |
| 角色選擇室 | 選角場景 | 3 天 |
| 投票大廳 | 投票場景 | 2 天 |
| 勝利/失敗 | 結算場景 | 2 天 |
| 場景元件 | 可複用元件 | 4 天 |
| 動態效果 | 動畫元素 | 3 天 |
| **總計** | | **約 27 天** |

---

## 12. 風格參考

### 12.1 建築參考
- 威斯敏斯特宮內部照片（火災前）
- 哥德復興式建築
- 英國議會傳統

### 12.2 藝術參考
- Darkest Dungeon 背景美術
- 油畫風格議會場景
- 維多利亞時代版畫

### 12.3 氛圍參考
- 電影《乔治国王的疯狂》
- 電影《乱世佳人》議會場景
- 遊戲《Pentiment》建築風格

---

*「場景是無聲的演員，它的每一道光影都在訴說故事。」— 羅塞蒂*
