# 角色專屬卡美術規格
## Character Card Art Specification

**版本：v1.0**  
**日期：2026-02-02**  
**設計：羅塞蒂（宮廷畫師）**

---

## 1. 卡牌基礎規格

### 1.1 尺寸規範

| 規格 | 數值 |
|------|------|
| 設計尺寸 | 750 × 1050 px (5:7 比例) |
| @1x 輸出 | 375 × 525 px |
| @2x 輸出 | 750 × 1050 px |
| @3x 輸出 | 1125 × 1575 px |
| 安全區域 | 內縮 40px |
| 出血區域 | 外擴 20px |
| 圓角半徑 | 24px |
| 格式 | PNG with alpha |

### 1.2 版面結構

```
┌──────────────────────────────────────┐ ← 卡框頂部
│  ┌──────────┐                        │
│  │ 消耗     │           [稀有度]    │ ← 頂欄 (100px)
│  │ 🌟💰     │                        │
│  └──────────┘                        │
├──────────────────────────────────────┤
│                                      │
│                                      │
│         【 主 視 覺 】               │ ← 插圖區 (550px)
│          (角色動作)                  │
│                                      │
│                                      │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │        ⚔️ 卡牌名稱             │  │ ← 名稱欄 (80px)
│  └────────────────────────────────┘  │
├──────────────────────────────────────┤
│                                      │
│          「效果描述文字」            │ ← 效果區 (200px)
│                                      │
├──────────────────────────────────────┤
│  [類型圖標]        [角色歸屬圖標]   │ ← 底欄 (60px)
└──────────────────────────────────────┘
```

---

## 2. 稀有度視覺系統

### 2.1 稀有度等級

| 稀有度 | 標記 | 卡框風格 | 特效 |
|--------|------|----------|------|
| 🟡 SSR | 皇冠 | 燙金雕花邊框 | 金色微光粒子 |
| 🟣 SR | 寶石 | 銅質浮雕邊框 | 紫色暗光 |
| 🔵 R | 蠟封 | 木質精緻邊框 | 無特效 |
| ⚪ N | 無 | 簡約羊皮紙邊框 | 無特效 |

### 2.2 稀有度配色

| 稀有度 | 主色 | 輔色 | 光效色 |
|--------|------|------|--------|
| SSR | #FFD700 (金) | #8B4513 (深棕) | #FFF8DC (象牙光) |
| SR | #7851A9 (紫) | #483D8B (暗紫) | #DDA0DD (淡紫光) |
| R | #4682B4 (藍灰) | #36454F (炭灰) | — |
| N | #D2B48C (駝色) | #8B7355 (深駝) | — |

---

## 3. 卡牌類型圖標

### 3.1 類型圖標設計

| 類型 | 圖標 | 風格描述 |
|------|------|----------|
| ⚔️ 攻擊 | 交叉的劍 | 維多利亞軍刀，銅質 |
| 🛡️ 防禦 | 盾牌 | 議會徽章盾，莊嚴 |
| 💚 治療 | 藥草瓶 | 玻璃藥瓶，綠色液體 |
| 🔒 控制 | 鎖鏈 | 鐵製鎖鏈，沉重 |
| 🔍 情報 | 放大鏡 | 黃銅手柄放大鏡 |
| 🤝 社交 | 握手 | 紳士握手剪影 |
| ⬆️ 增益 | 上升箭頭 | 羽毛筆勾勒箭頭 |
| ⭐ 特殊 | 議會徽章 | 橡樹葉環繞星星 |

### 3.2 圖標規格

- 尺寸：48 × 48 px (@1x)
- 風格：黃銅/銅質浮雕效果
- 背景：深色圓形底座

---

## 4. 角色專屬卡設計

### 4.1 工人湯瑪斯（Thomas）— 勞工派

**角色配色**
| 元素 | 色值 |
|------|------|
| 主色 | #8B0000 (深紅) |
| 輔色 | #CD853F (土黃) |
| 強調色 | #4A2311 (深棕) |

**專屬卡視覺**

#### T01 勞工團結 (SR)
- **主視覺**：湯瑪斯高舉拳頭，身後是工人群眾剪影
- **色調**：深紅暖調，火把光線
- **氛圍**：團結、力量、底層覺醒
- **AI Prompt**：`Victorian worker raising fist, crowd silhouettes behind, torch light, red warm tones, Darkest Dungeon style, dramatic lighting, labor movement, 1812 England`

#### T02 街頭演說 (R)
- **主視覺**：湯瑪斯站在木箱上對群眾演講
- **色調**：灰暗街景，暖黃油燈
- **氛圍**：激昂、街頭、草根力量
- **AI Prompt**：`Victorian worker giving speech on wooden crate, crowd listening, oil lamp light, cobblestone street, foggy London, Darkest Dungeon style, dramatic shadows`

#### T03 互助會 (N)
- **主視覺**：工人們圍成圈遞交硬幣
- **色調**：暖棕色調，室內油燈
- **氛圍**：溫馨、互助、簡樸
- **AI Prompt**：`Victorian workers in circle passing coins, humble indoor scene, oil lamp, warm brown tones, mutual aid society, Darkest Dungeon style`

---

### 4.2 工廠主理查（Richard）— 資方派

**角色配色**
| 元素 | 色值 |
|------|------|
| 主色 | #DAA520 (金色) |
| 輔色 | #2F4F4F (深灰綠) |
| 強調色 | #8B4513 (馬鞍棕) |

**專屬卡視覺**

#### R01 金錢攻勢 (SR)
- **主視覺**：理查將金幣撒向前方，金幣反射光芒
- **色調**：金色為主，奢華感
- **氛圍**：傲慢、財富、壓迫
- **AI Prompt**：`Victorian industrialist throwing gold coins, arrogant expression, luxury office background, golden light, Darkest Dungeon style, capitalist power`

#### R02 經濟威脅 (R)
- **主視覺**：理查在帳本前，陰影籠罩工廠
- **色調**：冷金色，工廠剪影
- **氛圍**：威脅、計算、冷酷
- **AI Prompt**：`Victorian factory owner with ledger book, factory silhouette in window, cold golden tones, calculating expression, Darkest Dungeon style, economic threat`

#### R03 產業聯盟 (N)
- **主視覺**：多位紳士握手，背景是工廠煙囪
- **色調**：暗金棕色
- **氛圍**：聯盟、商業、交易
- **AI Prompt**：`Victorian gentlemen handshake, factory chimneys background, dark golden brown tones, business alliance, top hats, Darkest Dungeon style`

---

### 4.3 盧德派喬治（George）— 勞工派激進

**角色配色**
| 元素 | 色值 |
|------|------|
| 主色 | #B22222 (火磚紅) |
| 輔色 | #2F2F2F (炭黑) |
| 強調色 | #FF4500 (橙紅火焰) |

**專屬卡視覺**

#### G01 暴力抗議 (SR)
- **主視覺**：喬治揮舞鐵錘砸向機器，火花四濺
- **色調**：火紅與黑色對比
- **氛圍**：狂暴、破壞、不計代價
- **AI Prompt**：`Luddite worker smashing machine with hammer, sparks flying, fire red and black contrast, rage expression, industrial destruction, Darkest Dungeon style, violent protest`

#### G02 煽動群眾 (R)
- **主視覺**：喬治舉火把帶領暴動人群
- **色調**：夜色中的火光
- **氛圍**：煽動、混亂、群體狂熱
- **AI Prompt**：`Luddite leader with torch, angry mob behind, night scene with fire light, chaotic energy, Darkest Dungeon style, inciting crowd`

#### G03 破壞機器 (N)
- **主視覺**：破碎的紡織機殘骸
- **色調**：暗調，鐵鏽色
- **氛圍**：破壞後的沉寂
- **AI Prompt**：`Destroyed textile machine, broken gears and wood, dark rust tones, aftermath of destruction, Darkest Dungeon style, Luddite sabotage`

---

### 4.4 改革者羅伯特（Robert）— 改革派

**角色配色**
| 元素 | 色值 |
|------|------|
| 主色 | #4682B4 (鋼藍) |
| 輔色 | #F5F5DC (米黃) |
| 強調色 | #2E8B57 (海綠) |

**專屬卡視覺**

#### B01 和平倡議 (SR)
- **主視覺**：羅伯特張開雙手站在兩派之間
- **色調**：柔和藍灰，和平光暈
- **氛圍**：調停、和平、理性
- **AI Prompt**：`Victorian reformer with open arms between two groups, soft blue gray tones, peaceful aura, mediator pose, Darkest Dungeon style, peace initiative`

#### B02 跨派結盟 (R)
- **主視覺**：不同派系的人在羅伯特見證下握手
- **色調**：暖藍混合
- **氛圍**：外交、結盟、希望
- **AI Prompt**：`Different faction members shaking hands, reformer witnessing, warm blue tones, diplomatic scene, Darkest Dungeon style, cross-party alliance`

#### B03 折衷方案 (N)
- **主視覺**：羅伯特在書桌前起草文件
- **色調**：書房暖光，藍色點綴
- **氛圍**：思考、妥協、智慧
- **AI Prompt**：`Victorian reformer drafting document at desk, warm study light, blue accents, thoughtful expression, Darkest Dungeon style, compromise proposal`

---

### 4.5 記者愛德華（Edward）— 中立派

**角色配色**
| 元素 | 色值 |
|------|------|
| 主色 | #36454F (炭灰) |
| 輔色 | #F5F5DC (新聞紙黃) |
| 強調色 | #8B0000 (墨紅) |

**專屬卡視覺**

#### E01 獨家報導 (SR)
- **主視覺**：愛德華舉起報紙頭版，標題震驚
- **色調**：黑白報紙對比，紅色標題
- **氛圍**：揭露、震撼、真相
- **AI Prompt**：`Victorian journalist holding newspaper headline, shocking revelation, black white newspaper contrast, red headline, Darkest Dungeon style, exclusive story`

#### E02 深入調查 (R)
- **主視覺**：愛德華在暗處用放大鏡檢視文件
- **色調**：暗調，單點光源
- **氛圍**：調查、秘密、謹慎
- **AI Prompt**：`Victorian journalist examining documents with magnifying glass, dark room single light source, secretive investigation, Darkest Dungeon style, deep investigation`

#### E03 輿論風暴 (N)
- **主視覺**：報紙飛舞如風暴，中心是墨水瓶
- **色調**：黑白灰旋轉
- **氛圍**：輿論、混亂、言論力量
- **AI Prompt**：`Newspapers swirling like storm, ink bottle in center, black white gray swirl, media chaos, Darkest Dungeon style, public opinion storm`

---

### 4.6 議員威廉（William）— 中立派

**角色配色**
| 元素 | 色值 |
|------|------|
| 主色 | #483D8B (暗灰紫) |
| 輔色 | #C0C0C0 (銀灰) |
| 強調色 | #8B4513 (胡桃棕) |

**專屬卡視覺**

#### W01 政治交易 (SR)
- **主視覺**：威廉與另一人交換卡片/文件
- **色調**：暗紫灰，神秘感
- **氛圍**：交易、秘密、雙面
- **AI Prompt**：`Victorian politician exchanging documents with another, dark purple gray tones, mysterious atmosphere, political deal, Darkest Dungeon style, secret exchange`

#### W02 人脈網絡 (R)
- **主視覺**：威廉站在蜘蛛網般的人際關係圖中央
- **色調**：灰紫色調，連線發光
- **氛圍**：網絡、情報、中樞
- **AI Prompt**：`Victorian politician at center of web-like network diagram, gray purple tones, glowing connections, social network, Darkest Dungeon style, political connections`

#### W03 議長權威 (N)
- **主視覺**：威廉手持議事槌
- **色調**：莊嚴灰紫
- **氛圍**：權威、秩序、程序
- **AI Prompt**：`Victorian parliamentarian holding gavel, solemn gray purple, authoritative pose, parliamentary authority, Darkest Dungeon style, speaker of house`

---

### 4.7 國王喬治三世（King George III）— 皇室

**角色配色**
| 元素 | 色值 |
|------|------|
| 主色 | #7851A9 (皇家紫) |
| 輔色 | #FFD700 (皇冠金) |
| 強調色 | #DC143C (深紅) |

**專屬卡視覺**

#### K01 王權宣言 (SSR)
- **主視覺**：喬治三世站立，手持權杖，皇冠發光
- **色調**：金紫華麗，神聖光芒
- **氛圍**：絕對權威、神聖、終結
- **特效**：金色粒子環繞
- **AI Prompt**：`King George III standing with scepter, glowing crown, gold and royal purple, divine light rays, absolute authority, Darkest Dungeon style, royal decree, majestic`

#### K02 皇家裁決 (SR)
- **主視覺**：國王坐在王座上舉手示意停止
- **色調**：莊嚴紫金
- **氛圍**：裁決、終結、王權
- **AI Prompt**：`King George III on throne raising hand to halt, solemn purple and gold, royal judgment, Darkest Dungeon style, royal verdict`

#### K03 龍恩浩蕩 (R)
- **主視覺**：國王將手放在臣子肩上，金光籠罩
- **色調**：溫暖金色光芒
- **氛圍**：恩典、保護、皇恩
- **AI Prompt**：`King George III placing hand on subject shoulder, warm golden glow protection, royal blessing, Darkest Dungeon style, royal grace`

---

## 5. 字體規範

### 5.1 字體選擇

| 用途 | 英文字體 | 中文字體 | 備註 |
|------|----------|----------|------|
| 卡牌名稱 | IM Fell English | 思源宋體 Heavy | 維多利亞感 |
| 效果文字 | Libre Baskerville | 思源黑體 Regular | 可讀性優先 |
| 數值顯示 | Playfair Display | — | 數字專用 |
| 類型標籤 | Cormorant Garamond | 思源黑體 Medium | 小字清晰 |

### 5.2 字體大小

| 元素 | @1x 大小 | @2x 大小 | 行高 |
|------|----------|----------|------|
| 卡牌名稱 | 24px | 48px | 1.2 |
| 效果文字 | 14px | 28px | 1.4 |
| 消耗數值 | 20px | 40px | 1.0 |
| 類型標籤 | 12px | 24px | 1.0 |

---

## 6. 視覺風格指南

### 6.1 整體風格

- **時代感**：1812 年英國攝政時期
- **藝術風格**：Darkest Dungeon × 維多利亞哥德
- **色調**：暖棕主調，搭配派系色彩
- **光影**：強烈明暗對比，戲劇化
- **質感**：羊皮紙、蠟封、銅質、燙金

### 6.2 卡牌氛圍層級

| 稀有度 | 氛圍描述 |
|--------|----------|
| SSR | 史詩、神聖、決定性時刻 |
| SR | 戲劇化、高潮、轉折點 |
| R | 重要、有分量、值得注意 |
| N | 日常、實用、基礎 |

### 6.3 禁忌元素

- ❌ 過於現代的設計元素
- ❌ 卡通化或 Q 版風格
- ❌ 鮮豔螢光色
- ❌ 科幻或魔幻元素
- ❌ 血腥暴力的直接描繪

---

## 7. 製作清單

### 7.1 專屬卡總覽

| 角色 | SSR | SR | R | N | 小計 |
|------|-----|----|----|---|------|
| 湯瑪斯 | — | 1 | 1 | 1 | 3 |
| 理查 | — | 1 | 1 | 1 | 3 |
| 喬治 | — | 1 | 1 | 1 | 3 |
| 羅伯特 | — | 1 | 1 | 1 | 3 |
| 愛德華 | — | 1 | 1 | 1 | 3 |
| 威廉 | — | 1 | 1 | 1 | 3 |
| 喬治三世 | 1 | 1 | 1 | — | 3 |
| **總計** | **1** | **7** | **7** | **6** | **21** |

### 7.2 製作優先順序

1. **第一批（核心）**：每角色 SR 卡 × 7 張
2. **第二批（補充）**：每角色 R 卡 × 7 張
3. **第三批（基礎）**：每角色 N 卡 × 6 張
4. **最終**：SSR 王權宣言 × 1 張

### 7.3 預估時程

| 階段 | 內容 | 工時 |
|------|------|------|
| 卡框設計 | 4 種稀有度卡框 | 1 週 |
| 圖標設計 | 8 種類型圖標 | 3 天 |
| SR 插圖 | 7 張 | 2 週 |
| R 插圖 | 7 張 | 2 週 |
| N 插圖 | 6 張 | 1.5 週 |
| SSR 插圖 | 1 張 | 3 天 |
| 組裝 & 調整 | 21 張完整卡牌 | 1 週 |
| **總計** | | **約 8 週** |

---

## 8. 附錄：AI 生成注意事項

### 8.1 通用 Prompt 前綴

```
Victorian era 1812 England, Darkest Dungeon art style, 
dramatic lighting, strong contrast, painterly style, 
detailed illustration, moody atmosphere,
```

### 8.2 避免的詞彙

- fantasy, magic, supernatural
- modern, contemporary
- cartoon, anime, chibi
- neon, bright, colorful

### 8.3 建議的負面提示

```
--no modern elements, fantasy magic, cartoon style, 
bright colors, anime, chibi, neon, futuristic
```

---

*「每一張卡牌都是一個故事的定格。」— 羅塞蒂*
