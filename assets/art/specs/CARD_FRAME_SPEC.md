# 卡框設計規格
## Card Frame Design Specification

**版本：v1.0**  
**日期：2026-02-02**  
**設計：羅塞蒂（宮廷畫師）**

---

## 1. 卡框系統概述

### 1.1 設計理念

卡框是卡牌的「**骨架**」，承載著：
- **稀有度識別** — 一眼區分 N/R/SR/SSR
- **時代氛圍** — 1812 年維多利亞哥德風格
- **品質感** — 手工藝、貴族、議會莊嚴

**核心元素**：
- 羊皮紙質感背景
- 金屬（銅/金/銀）邊框
- 蠟封裝飾
- 議會/皇室紋章

### 1.2 卡框類型

| 類型 | 用途 | 數量 |
|------|------|------|
| 通用卡框 | 通用對策卡 (24張) | 4 種稀有度 |
| 角色卡框 | 角色專屬卡 (21張) | 4 種稀有度 × 派系變體 |
| 負面卡框 | 負面特質卡 (11張) | 1 種（荊棘風格） |
| **總計** | | **9 種卡框** |

---

## 2. 通用卡框設計

### 2.1 基礎結構（所有稀有度共用）

```
┌─────────────────────────────────────────┐
│ ╔═══════════════════════════════════╗   │ ← 外框邊緣
│ ║  ┌─────────────────────────────┐  ║   │
│ ║  │      [消耗區]    [稀有度]   │  ║   │ ← 頂欄
│ ║  ├─────────────────────────────┤  ║   │
│ ║  │                             │  ║   │
│ ║  │                             │  ║   │
│ ║  │       【插圖區域】          │  ║   │ ← 主視覺
│ ║  │                             │  ║   │
│ ║  │                             │  ║   │
│ ║  ├─────────────────────────────┤  ║   │
│ ║  │        卡牌名稱             │  ║   │ ← 名稱條
│ ║  ├─────────────────────────────┤  ║   │
│ ║  │                             │  ║   │
│ ║  │       「效果文字」          │  ║   │ ← 效果區
│ ║  │                             │  ║   │
│ ║  ├─────────────────────────────┤  ║   │
│ ║  │  [類型]           [編號]   │  ║   │ ← 底欄
│ ║  └─────────────────────────────┘  ║   │
│ ╚═══════════════════════════════════╝   │
└─────────────────────────────────────────┘
```

### 2.2 尺寸細節（@2x 基準）

| 區域 | 高度 | 說明 |
|------|------|------|
| 外框邊緣 | 20px | 最外層裝飾邊 |
| 頂欄 | 100px | 消耗 + 稀有度標記 |
| 插圖區 | 500px | 主視覺區域 |
| 名稱條 | 80px | 卡牌名稱 |
| 效果區 | 200px | 效果描述文字 |
| 底欄 | 60px | 類型圖標 + 編號 |
| 內邊距 | 15px | 內容與邊框間距 |

---

## 3. 稀有度卡框詳細設計

### 3.1 ⚪ N 級（Normal）— 羊皮紙卷軸

**設計概念**：最基礎的議會文件，簡樸實用

**邊框設計**
- **材質**：原色羊皮紙邊緣，輕微捲曲效果
- **邊框寬度**：8px
- **顏色**：#D2B48C (駝色) 主調
- **裝飾**：無特殊裝飾，僅簡單線條
- **角落**：圓角，無額外元素

**背景**
- **材質**：淺色羊皮紙
- **顏色**：#F5F5DC → #E8DCC8 漸層
- **紋理**：輕微纖維紋理，可見羊皮紙質感
- **老化效果**：輕微泛黃邊緣

**名稱條**
- **背景**：深駝色條帶 #8B7355
- **文字**：米白 #FAF0E6
- **無額外裝飾**

**AI Prompt（卡框）**
```
Simple parchment scroll card frame, light tan color, slightly curled edges,
subtle fiber texture, aged paper effect, minimal decoration, Victorian era
document style, clean lines, no ornate elements, game card border design,
transparent center for art placement
```

---

### 3.2 🔵 R 級（Rare）— 木質精裝

**設計概念**：議會正式文件，帶有木質書封質感

**邊框設計**
- **材質**：深色胡桃木紋邊框
- **邊框寬度**：12px
- **顏色**：#654321 (深棕) + #8B4513 (馬鞍棕) 木紋
- **裝飾**：四角有簡單的金屬角扣（黃銅色 #B8860B）
- **角落**：直角，金屬角扣 20×20px

**背景**
- **材質**：優質羊皮紙
- **顏色**：#FAEBD7 (古白) → #DEB887 漸層
- **紋理**：細緻羊皮紋理
- **老化效果**：邊緣有輕微墨漬

**名稱條**
- **背景**：木質條帶，帶金屬嵌邊
- **文字**：燙金效果 #DAA520
- **裝飾**：兩側有小蠟封印記

**蠟封設計**
- **位置**：名稱條兩側
- **尺寸**：24×24px
- **顏色**：深紅 #8B0000
- **圖案**：簡單議會標記

**AI Prompt（卡框）**
```
Wooden book cover card frame, dark walnut wood grain texture, brass corner
brackets, quality parchment background, subtle ink stains at edges,
Victorian era formal document style, small red wax seals on sides,
gold text banner, elegant but not ornate, game card border design,
transparent center for art placement
```

---

### 3.3 🟣 SR 級（Super Rare）— 銅質浮雕

**設計概念**：議會重要文件，銅質裝飾框架

**邊框設計**
- **材質**：拋光銅質邊框，浮雕紋飾
- **邊框寬度**：18px
- **顏色**：#B87333 (銅色) + #CD7F32 (青銅) 漸層
- **裝飾**：
  - 邊框有維多利亞花紋浮雕
  - 四角有橡樹葉裝飾
  - 頂部中央有小皇冠
- **角落**：精緻橡樹葉浮雕 30×30px

**背景**
- **材質**：高級羊皮紙，帶暗紋
- **顏色**：#FFF8DC (玉米絲) 中央 → #DEB887 邊緣
- **紋理**：隱約可見的徽章水印
- **光效**：微微的紫色暗光從邊緣透出

**名稱條**
- **背景**：銅質條帶，拱形設計
- **文字**：浮雕金字效果
- **裝飾**：兩側有議會徽章

**蠟封設計**
- **位置**：底部中央
- **尺寸**：40×40px
- **顏色**：皇家紫 #7851A9 + 金邊
- **圖案**：議會完整紋章
- **特效**：輕微光澤

**AI Prompt（卡框）**
```
Polished copper card frame with Victorian embossed floral patterns,
oak leaf decorations in corners, small crown at top center, bronze
gradient, quality parchment with subtle coat of arms watermark,
faint purple glow at edges, copper arched name banner with embossed
gold text, parliament emblem wax seal at bottom, ornate but dignified,
game card border design, transparent center for art placement
```

---

### 3.4 🟡 SSR 級（Super Super Rare）— 燙金雕花

**設計概念**：皇家御用文件，極致奢華

**邊框設計**
- **材質**：純金色邊框，精細雕花
- **邊框寬度**：24px
- **顏色**：#FFD700 (金) + #FFA500 (橙金) 漸層
- **裝飾**：
  - 全邊框維多利亞巴洛克雕花
  - 四角有皇冠與橡樹葉組合
  - 頂部有完整皇冠
  - 底部有獅子紋章
- **角落**：皇冠橡葉組合 40×40px

**背景**
- **材質**：最高級羊皮紙，金絲暗紋
- **顏色**：#FFFAF0 (花白) 中央，金色光暈邊緣
- **紋理**：金絲編織紋理，皇家徽章水印
- **光效**：
  - 金色微光粒子環繞
  - 四角有光芒放射
  - 整體發出溫暖金光

**名稱條**
- **背景**：純金浮雕條帶，華麗拱形
- **文字**：立體燙金效果，帶陰影
- **裝飾**：皇冠 + 橡葉環繞

**蠟封設計**
- **位置**：底部中央，較大
- **尺寸**：50×50px
- **顏色**：皇家紫 #7851A9 + 金邊 + 寶石鑲嵌效果
- **圖案**：皇家完整紋章（獅子+皇冠+橡葉）
- **特效**：發光效果

**特殊粒子效果**
- 金色光點緩慢飄浮
- 邊框微微發光脈動
- 角落光芒閃爍

**AI Prompt（卡框）**
```
Luxurious gold card frame with intricate Victorian Baroque carved 
patterns, crown and oak leaf combinations in corners, full crown at top,
lion crest at bottom, pure gold gradient with orange gold highlights,
finest parchment with gold thread patterns and royal watermark,
golden particle effects floating around, radiant glow from corners,
elaborate gold arched name banner with 3D embossed text, large royal
purple wax seal with gemstone effect at bottom, extremely ornate and
majestic, fit for royalty, game card border design, transparent center
```

---

## 4. 角色專屬卡框變體

### 4.1 派系色彩疊加

角色專屬卡使用通用卡框 + 派系色彩強調：

| 派系 | 強調色 | 應用位置 |
|------|--------|----------|
| ⚒️ 勞工派 | #8B0000 深紅 | 名稱條背景、蠟封 |
| 💰 資方派 | #DAA520 金色 | 邊框金屬部分加強 |
| 📜 改革派 | #4682B4 鋼藍 | 名稱條、裝飾線條 |
| 👑 皇室 | #7851A9 皇家紫 | 全邊框紫金色調 |

### 4.2 角色徽章

每個角色有專屬小徽章，顯示在卡牌底部：

| 角色 | 徽章設計 |
|------|----------|
| 湯瑪斯 | 錘子與麥穗 |
| 理查 | 齒輪與金幣 |
| 喬治 | 破碎的紡織機 |
| 羅伯特 | 羽毛筆與天平 |
| 愛德華 | 報紙與放大鏡 |
| 威廉 | 議事槌 |
| 國王 | 皇冠 |

---

## 5. 負面特質卡框

### 5.1 荊棘鎖鏈風格

**設計概念**：詛咒的枷鎖，無法擺脫的弱點

**邊框設計**
- **材質**：黑鐵荊棘纏繞
- **邊框寬度**：20px
- **顏色**：#1a1a1a (黑) + #3d3d3d (深灰)
- **裝飾**：
  - 荊棘藤蔓纏繞整個邊框
  - 刺尖為血紅色 #8B0000
  - 四角有枯萎的黑玫瑰
- **角落**：枯萎黑玫瑰 35×35px

**背景**
- **材質**：染血的舊羊皮紙
- **顏色**：#2d2d2d (深灰) + 血紅暗紋
- **紋理**：裂痕、污漬、腐蝕痕跡
- **光效**：無光效，反而有陰影籠罩

**名稱條**
- **背景**：黑鐵條帶，帶鏽蝕質感
- **文字**：血紅色 #8B0000
- **裝飾**：兩側有小骷髏或鎖鏈

**AI Prompt（卡框）**
```
Dark iron thorny vine card frame, black metal with deep gray shadows,
thorns with blood red tips, withered black roses in corners, cursed
aesthetic, old bloodstained parchment background with cracks and
corruption marks, no glow only shadows, rusted iron name banner with
blood red text, small skulls or chains as decoration, gothic horror
Victorian style, ominous and oppressive, game card border design,
transparent center for art placement
```

---

## 6. 卡框元件清單

### 6.1 需要製作的元件

| 類別 | 元件 | 數量 |
|------|------|------|
| **完整卡框** | | |
| | N 級通用卡框 | 1 |
| | R 級通用卡框 | 1 |
| | SR 級通用卡框 | 1 |
| | SSR 級通用卡框 | 1 |
| | 負面特質卡框 | 1 |
| **派系變體** | | |
| | 勞工派強調層 | 1 |
| | 資方派強調層 | 1 |
| | 改革派強調層 | 1 |
| | 皇室強調層 | 1 |
| **裝飾元件** | | |
| | 角落裝飾（N/R/SR/SSR）| 4 |
| | 蠟封（紅/紫/金）| 3 |
| | 皇冠裝飾 | 2 |
| | 角色徽章 | 7 |
| **名稱條** | | |
| | N/R/SR/SSR 名稱條 | 4 |
| | 負面特質名稱條 | 1 |
| **特效** | | |
| | SSR 金色粒子 | 1 (動畫序列) |
| | SSR 光芒效果 | 1 |
| **總計** | | **約 30 個元件** |

### 6.2 輸出規格

| 元件類型 | 格式 | 尺寸 |
|----------|------|------|
| 完整卡框 | PNG (alpha) | 750 × 1050 @2x |
| 角落裝飾 | PNG (alpha) | 80 × 80 @2x |
| 蠟封 | PNG (alpha) | 80 × 80 @2x |
| 徽章 | PNG (alpha) | 48 × 48 @2x |
| 名稱條 | PNG (alpha) | 670 × 80 @2x |
| 粒子效果 | PNG sequence | 750 × 1050 @2x |

---

## 7. 製作時程

| 階段 | 內容 | 工時 |
|------|------|------|
| 基礎卡框 | 5 種完整卡框 | 5 天 |
| 派系變體 | 4 種強調層 | 2 天 |
| 裝飾元件 | 角落、蠟封、皇冠 | 3 天 |
| 角色徽章 | 7 個徽章 | 2 天 |
| 名稱條 | 5 種名稱條 | 1 天 |
| SSR 特效 | 粒子動畫 | 2 天 |
| 整合測試 | 組裝與調整 | 2 天 |
| **總計** | | **約 17 天** |

---

## 8. 視覺參考

### 8.1 風格參考

- **Slay the Spire** — 卡牌框架結構
- **Gwent** — 金屬質感邊框
- **Legends of Runeterra** — 稀有度視覺區分
- **Darkest Dungeon** — 哥德氛圍

### 8.2 時代參考

- 維多利亞時期書籍裝幀
- 議會官方文件樣式
- 皇家御用文書格式
- 蠟封與紋章設計

---

## 9. 技術備註

### 9.1 圖層結構（Figma/PS）

```
📁 Card_Frame_SSR
├── 📁 Effects
│   ├── particle_glow
│   └── corner_radiance
├── 📁 Frame
│   ├── outer_border
│   ├── inner_border
│   └── corner_ornaments
├── 📁 Decorations
│   ├── crown_top
│   ├── lion_bottom
│   └── wax_seal
├── 📁 Name_Banner
│   ├── banner_base
│   └── text_effect
└── 📁 Background
    ├── parchment_base
    └── watermark
```

### 9.2 可替換區域

- 插圖區：750 × 500 px 透明區域
- 名稱文字：預留文字層
- 效果文字：預留文字框
- 類型圖標：48 × 48 px 位置標記

---

*「框架是畫作的衣裳，不應喧賓奪主，卻要彰顯內涵。」— 羅塞蒂*
