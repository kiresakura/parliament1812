# 負面特質卡美術規格
## Negative Trait Card Art Specification

**版本：v1.0**  
**日期：2026-02-02**  
**設計：羅塞蒂（宮廷畫師）**

---

## 1. 負面特質卡基礎規格

### 1.1 設計理念

負面特質卡與一般卡牌不同——它們是**詛咒的印記**，代表角色無法擺脫的弱點。

**視覺語言**：
- 比一般卡牌更**暗沉**
- 帶有**裂痕、污漬、腐蝕**的質感
- 邊框是**荊棘、鎖鏈、陰影**
- 整體氛圍：**宿命、枷鎖、人性弱點**

### 1.2 尺寸規範

| 規格 | 數值 |
|------|------|
| 設計尺寸 | 750 × 1050 px (5:7 比例) |
| @1x 輸出 | 375 × 525 px |
| @2x 輸出 | 750 × 1050 px |
| @3x 輸出 | 1125 × 1575 px |
| 格式 | PNG with alpha |

### 1.3 版面結構

```
┌──────────────────────────────────────┐ ← 荊棘邊框
│                                      │
│         ☠️ 【特質圖標】              │ ← 頂部圖標 (100px)
│                                      │
├──────────────────────────────────────┤
│                                      │
│       【 暗 黑 插 圖 】              │ ← 插圖區 (500px)
│        (象徵性意象)                  │
│                                      │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │      ⛓️ 特質名稱               │  │ ← 名稱欄 (80px)
│  └────────────────────────────────┘  │
├──────────────────────────────────────┤
│                                      │
│       「觸發條件」                   │ ← 條件區 (100px)
│                                      │
├──────────────────────────────────────┤
│                                      │
│       「負面效果」                   │ ← 效果區 (150px)
│                                      │
├──────────────────────────────────────┤
│  [角色歸屬]                          │ ← 底欄 (60px)
└──────────────────────────────────────┘
```

### 1.4 通用配色

| 元素 | 色值 | 用途 |
|------|------|------|
| 主背景 | #1a1a1a | 深黑底色 |
| 次背景 | #2d2d2d | 卡面內層 |
| 邊框 | #3d3d3d | 荊棘/鎖鏈 |
| 強調色 | #8B0000 | 血紅點綴 |
| 文字 | #c0c0c0 | 灰白文字 |
| 警告 | #ff4444 | 觸發提示 |

---

## 2. 負面特質卡設計

### 2.1 工人湯瑪斯 — 文盲

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 📖 文盲 (Illiterate) |
| 觸發條件 | 使用情報類卡牌時 |
| 效果 | 情報卡效果減半（揭露/調查只能看部分資訊） |

**視覺設計**
- **主視覺**：一雙粗糙的手捧著一本書，書頁上的文字模糊扭曲成無意義的符號
- **象徵元素**：被墨水污染的文字、破損的書頁邊緣
- **色調**：灰棕色調，帶有無力感
- **氛圍**：無奈、階級限制、知識的門檻
- **特效**：文字像煙霧般消散

**AI Prompt**
```
Rough calloused hands holding open book, text on pages blurred and 
distorted into meaningless symbols, ink stains spreading, torn page edges,
gray brown tones, feeling of helplessness, Victorian era, Darkest Dungeon 
style, dark atmospheric, illiteracy symbolism, class barrier
```

---

### 2.2 工廠主理查 — 眾矢之的

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 🎯 眾矢之的 (Target of Hatred) |
| 觸發條件 | 被動持續 |
| 效果 | 受到的所有傷害 +5 |

**視覺設計**
- **主視覺**：一個穿著華麗的背影，身後有無數憤怒的眼睛在黑暗中注視
- **象徵元素**：箭靶標記疊加在人影上、紅色的眼睛
- **色調**：深紅與黑色，壓迫感
- **氛圍**：被仇恨包圍、四面楚歌
- **特效**：眼睛微微發光

**AI Prompt**
```
Wealthy figure from behind in fine coat, countless angry eyes watching 
from darkness behind, target mark overlay on silhouette, red glowing eyes,
deep red and black tones, surrounded by hatred, oppressive atmosphere,
Victorian era industrialist, Darkest Dungeon style, dark threatening
```

---

### 2.3 工廠主理查 — 貪婪

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 💸 貪婪 (Greed) |
| 觸發條件 | 金幣低於 20 時 |
| 效果 | 無法使用任何專屬卡 |

**視覺設計**
- **主視覺**：一隻手緊握著最後幾枚金幣，手指因用力而發白，金幣在指縫間滑落
- **象徵元素**：空蕩的錢袋、破碎的金幣
- **色調**：暗金色漸變為灰色
- **氛圍**：執著、失去、依賴
- **特效**：金幣失去光澤

**AI Prompt**
```
Hand gripping last few gold coins desperately, fingers white from tension,
coins slipping through fingers, empty money pouch, broken coins,
dark gold fading to gray, obsessive clinging, loss and dependency,
Victorian era, Darkest Dungeon style, greed symbolism
```

---

### 2.4 盧德派喬治 — 衝動

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 🔥 衝動 (Impulsive) |
| 觸發條件 | 聲望低於 40 時 |
| 效果 | 無法使用防禦類卡牌 |

**視覺設計**
- **主視覺**：一個人的剪影被火焰包圍，盾牌在火中融化
- **象徵元素**：燃燒的理智、碎裂的盾牌
- **色調**：火紅與黑色的強烈對比
- **氛圍**：失控、燃燒、無法自保
- **特效**：火焰向外蔓延

**AI Prompt**
```
Silhouette of man surrounded by flames, shield melting in fire,
burning rationality, shattered shield fragments, fire red and black 
strong contrast, loss of control, burning rage, unable to defend,
Victorian era, Darkest Dungeon style, impulsive fury
```

---

### 2.5 盧德派喬治 — 暴躁

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 😠 暴躁 (Hot-Tempered) |
| 觸發條件 | 被攻擊時 |
| 效果 | 必須在下個行動機會使用攻擊卡（若有） |

**視覺設計**
- **主視覺**：一張扭曲的憤怒面孔，血管暴起，背景是紅色的漩渦
- **象徵元素**：握緊的拳頭、破碎的理性面具
- **色調**：深紅、暗紅、黑色
- **氛圍**：失控的憤怒、無法抑制
- **特效**：紅色脈動

**AI Prompt**
```
Distorted angry face, veins bulging, red swirl background,
clenched fist, shattered mask of reason, deep red dark red black,
uncontrollable rage, cannot suppress anger, Victorian era man,
Darkest Dungeon style, hot tempered fury, pulsing red energy
```

---

### 2.6 改革者羅伯特 — 優柔寡斷

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | ⚖️ 優柔寡斷 (Indecisive) |
| 觸發條件 | 投票階段 |
| 效果 | 必須最後投票，且投票前所有人可看到你的選擇 |

**視覺設計**
- **主視覺**：一個人站在分岔路口，天平在頭頂搖擺不定，兩邊各有不同的道路
- **象徵元素**：搖晃的天平、模糊的路標
- **色調**：灰藍色調，朦朧感
- **氛圍**：猶豫、被觀察、暴露
- **特效**：天平持續搖擺

**AI Prompt**
```
Man standing at crossroads, scales swaying above head, two different 
paths ahead, swaying balance scales, blurry road signs, gray blue tones,
hazy atmosphere, hesitation exposed, being watched, Victorian era,
Darkest Dungeon style, indecision symbolism
```

---

### 2.7 記者愛德華 — 大嘴巴

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 🗣️ 大嘴巴 (Loose Lips) |
| 觸發條件 | 使用情報卡獲得資訊時 |
| 效果 | 40% 機率自動公開給所有人 |

**視覺設計**
- **主視覺**：一張嘴，話語化為飛鳥四散，無法收回
- **象徵元素**：從嘴中飛出的字母、撕裂的信封
- **色調**：灰黑與白色，文字飄散
- **氛圍**：無法控制、秘密洩露
- **特效**：字母如鳥群飛散

**AI Prompt**
```
Mouth speaking with words transforming into birds flying away,
letters escaping from lips, torn envelope, gray black and white,
scattered text, unable to control, secrets leaking, Victorian era,
Darkest Dungeon style, loose lips symbolism, words as birds
```

---

### 2.8 記者愛德華 — 易受攻擊

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 🎯 易受攻擊 (Vulnerable) |
| 觸發條件 | 被動持續 |
| 效果 | 初始聲望較低（50），且無法超過 70 |

**視覺設計**
- **主視覺**：一個單薄的身影站在聚光燈下，周圍是陰影中的威脅
- **象徵元素**：玻璃般脆弱的光環、裂縫
- **色調**：蒼白的光對比深黑的陰影
- **氛圍**：脆弱、暴露、被限制
- **特效**：光環有細微裂紋

**AI Prompt**
```
Thin figure standing in spotlight, threats lurking in shadows around,
fragile glass-like aura, cracks in the light, pale light contrasting 
deep black shadows, vulnerability exposed, limited, Victorian era 
journalist, Darkest Dungeon style, fragile symbolism
```

---

### 2.9 議員威廉 — 牆頭草

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 🤝 牆頭草 (Fence-Sitter) |
| 觸發條件 | 背叛盟友時 |
| 效果 | 背叛傷害減半，且自己損失 10 聲望 |

**視覺設計**
- **主視覺**：一個人影站在牆頭，兩邊都有手在拉扯，牆正在崩塌
- **象徵元素**：搖擺的風向標、兩面的面具
- **色調**：灰紫色調，不穩定感
- **氛圍**：搖擺、背叛的代價、不被信任
- **特效**：牆磚崩落

**AI Prompt**
```
Figure standing on crumbling wall, hands pulling from both sides,
wall collapsing beneath, swaying weathervane, two-faced masks,
gray purple tones, instability, cost of betrayal, untrustworthy,
Victorian era politician, Darkest Dungeon style, fence-sitter
```

---

### 2.10 國王喬治三世 — 精神不穩

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 😵 精神不穩 (Mental Instability) |
| 觸發條件 | 每個回合開始 |
| 效果 | 20% 機率進入「瘋狂狀態」，本回合行動隨機化 |

**視覺設計**
- **主視覺**：一頂皇冠，倒映的影子是扭曲破碎的，眼睛空洞而迷失
- **象徵元素**：破碎的鏡子、扭曲的皇冠影子
- **色調**：皇室紫轉為病態的灰紫
- **氛圍**：瘋狂、尊貴與脆弱的對比
- **特效**：影子不斷扭曲變形

**AI Prompt**
```
Royal crown with distorted broken reflection, empty lost eyes,
shattered mirror fragments, twisted crown shadow, royal purple 
fading to sickly gray purple, madness contrasting nobility,
King George III, Darkest Dungeon style, mental instability, 
royal madness symbolism
```

---

### 2.11 國王喬治三世 — 高處不勝寒

**基本資料**
| 欄位 | 內容 |
|------|------|
| 特質名稱 | 👑 高處不勝寒 (Lonely at the Top) |
| 觸發條件 | 被動持續 |
| 效果 | 無法與任何人建立正式同盟 |

**視覺設計**
- **主視覺**：孤獨的王座立於懸崖之巔，周圍是寒冷的虛空，無人接近
- **象徵元素**：冰霜覆蓋的王座、伸出但無人握的手
- **色調**：冰藍與暗紫，寒冷孤寂
- **氛圍**：孤獨、權力的代價、高不可攀
- **特效**：寒氣繚繞

**AI Prompt**
```
Lonely throne on cliff edge, cold void surrounding, no one approaching,
frost-covered throne, reaching hand with no one to hold, ice blue and 
dark purple, cold isolation, loneliness of power, unapproachable,
King George III throne, Darkest Dungeon style, lonely crown symbolism
```

---

## 3. 邊框設計

### 3.1 荊棘邊框規格

負面特質卡使用統一的**荊棘鎖鏈邊框**：

- **材質**：黑鐵荊棘纏繞
- **寬度**：外框 30px，內框 15px
- **顏色**：#3d3d3d 主體，#8B0000 刺尖
- **角落**：四角有枯萎的玫瑰裝飾

### 3.2 邊框 AI Prompt

```
Black iron thorny vine frame, gothic style, dark thorns with blood red tips,
withered roses in corners, Victorian dark aesthetic, frame border design,
transparent center, Darkest Dungeon style ornamental frame
```

---

## 4. 字體規範

### 4.1 負面特質卡專用字體

| 用途 | 英文字體 | 中文字體 | 風格 |
|------|----------|----------|------|
| 特質名稱 | IM Fell English | 思源宋體 Heavy | 厚重感 |
| 觸發條件 | Libre Baskerville Italic | 思源黑體 Regular | 斜體警告 |
| 效果文字 | Libre Baskerville | 思源黑體 Regular | 可讀 |

### 4.2 顏色

| 元素 | 顏色 | Hex |
|------|------|-----|
| 特質名稱 | 血紅 | #8B0000 |
| 觸發條件 | 警告紅 | #ff4444 |
| 效果文字 | 灰白 | #c0c0c0 |
| 角色歸屬 | 派系色 | 依角色 |

---

## 5. 製作清單

### 5.1 負面特質卡總覽

| # | 角色 | 特質名稱 | 圖標 |
|---|------|----------|------|
| 1 | 湯瑪斯 | 文盲 | 📖 |
| 2 | 理查 | 眾矢之的 | 🎯 |
| 3 | 理查 | 貪婪 | 💸 |
| 4 | 喬治 | 衝動 | 🔥 |
| 5 | 喬治 | 暴躁 | 😠 |
| 6 | 羅伯特 | 優柔寡斷 | ⚖️ |
| 7 | 愛德華 | 大嘴巴 | 🗣️ |
| 8 | 愛德華 | 易受攻擊 | 🎯 |
| 9 | 威廉 | 牆頭草 | 🤝 |
| 10 | 國王 | 精神不穩 | 😵 |
| 11 | 國王 | 高處不勝寒 | 👑 |

**總計：11 張**

### 5.2 製作優先順序

1. **荊棘邊框**（所有卡共用）
2. **國王的兩張**（最具視覺戲劇性）
3. **各角色一張**

### 5.3 預估時程

| 階段 | 內容 | 工時 |
|------|------|------|
| 邊框設計 | 荊棘鎖鏈邊框 | 2 天 |
| 11 張插圖 | 每張 0.5 天 | 5.5 天 |
| 組裝調整 | 合成完整卡牌 | 2 天 |
| **總計** | | **約 10 天** |

---

## 6. AI 生成注意事項

### 6.1 負面特質卡專用前綴

```
Dark Victorian era, Darkest Dungeon art style, gothic atmosphere,
dramatic shadows, symbolic imagery, character flaw visualization,
moody oppressive feeling, curse-like aesthetic,
```

### 6.2 色調指導

所有負面特質卡應比普通卡牌更**暗沉**：
- 降低整體明度 20-30%
- 增加對比度
- 減少飽和度（除了血紅強調色）

### 6.3 避免

- ❌ 過於寫實的恐怖元素
- ❌ 血腥直接描繪
- ❌ 過於明亮的顏色
- ❌ 可愛或卡通風格

---

*「每個人都有陰影，陰影是光的代價。」— 羅塞蒂*
