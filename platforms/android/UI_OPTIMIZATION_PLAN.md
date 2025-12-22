# Parliament 1812 - UI優化計劃（文明6風格）

## 一、整體風格定義

### 設計語言
- **風格**: 英國攝政時期 × 文明6策略遊戲風格
- **色調**: 深色背景 + 金色點綴 + 暖色燭光
- **材質**: 金屬、羊皮紙、蠟封、油畫

### 核心改進原則
1. 用高品質畫像取代 Emoji
2. 增加材質紋理層次
3. 加強金屬框架的立體感
4. 添加更多微動畫和粒子效果

---

## 二、具體組件優化

### 1. 角色頭像系統

**當前問題**：
```kotlin
// 現在用 Emoji
Text(text = roleEmoji, fontSize = 48.sp)  // "🔨"
```

**優化方案**：
- 為每個角色繪製油畫風格半身像
- 建議尺寸：512x512px PNG（帶透明背景）
- 風格參考：文明6領袖肖像、維多利亞時代油畫

**需要的角色畫像**：
1. `worker.png` - 紡織工人 湯瑪斯（38歲，粗獷面容，工人服裝）
2. `factory_owner.png` - 工廠主 理查·威爾森（45歲，富態，紳士裝束）
3. `luddite.png` - 盧德派 喬治（28歲，激進眼神，農民打扮）
4. `reformer.png` - 改革者 羅伯特·烏爾文（35歲，知識分子，書卷氣）
5. `mp.png` - 議員 威廉·菲茨傑拉德（52歲，威嚴，議員正裝）
6. `george_iii.png` - 喬治三世國王（官方肖像風格，王冠權杖）

**畫像外框設計**：
- 橢圓形金屬框架（類似文明6領袖框）
- 內圈金色浮雕邊框
- 外圈帶有角色陣營標誌的裝飾

---

### 2. 按鈕設計優化

**當前問題**：
```kotlin
Button(
    shape = CutCornerShape(bottomEnd = 16.dp),
    colors = ButtonDefaults.buttonColors(containerColor = Gold)
)
```

**優化方案** - 金屬按鈕效果：
```kotlin
// 建議新增 WaxSealButton 組件
@Composable
fun CivilizationButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            // 外層陰影
            .shadow(8.dp, CutCornerShape(12.dp))
            // 金屬漸層背景
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFFD4AF37),  // 亮金
                        Color(0xFFB8860B),  // 暗金
                        Color(0xFF8B7355),  // 青銅底
                    )
                ),
                CutCornerShape(12.dp)
            )
            // 浮雕效果邊框
            .border(
                width = 3.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFFFFD700),  // 上方高光
                        Color(0xFF8B6914),  // 下方陰影
                    )
                ),
                shape = CutCornerShape(12.dp)
            )
            // 內邊框
            .padding(2.dp)
            .border(
                width = 1.dp,
                color = Color(0xFF5D4E37),
                shape = CutCornerShape(10.dp)
            )
    ) {
        // 按鈕文字
    }
}
```

---

### 3. 卡片設計優化

**優化方案** - 羊皮紙效果：
```kotlin
@Composable
fun ParchmentCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Card(
        modifier = modifier
            .shadow(12.dp, RoundedCornerShape(8.dp)),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF2D2520)  // 深棕色
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Box(
            modifier = Modifier
                // 羊皮紙紋理疊加層（需要添加紋理圖片）
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            Color(0xFF3D3530),  // 中心稍亮
                            Color(0xFF2D2520),  // 邊緣暗
                        )
                    )
                )
        ) {
            // 金色角落裝飾
            // 內容
        }
    }
}
```

---

### 4. 角色卡片大改造

**新設計** - 文明6領袖風格：
```
┌──────────────────────────────────┐
│  ╔══════════════════════════╗   │
│  ║     【角色油畫肖像】       ║   │
│  ║      512x512px           ║   │
│  ║      橢圓形金框           ║   │
│  ╚══════════════════════════╝   │
│                                  │
│     ═══════ ◆ ═══════           │
│                                  │
│     威廉·菲茨傑拉德              │
│     WILLIAM FITZGERALD           │
│     ── 國會議員 ──               │
│                                  │
│  ┌────────────────────────────┐ │
│  │  ⚜ 秘密任務                │ │
│  │  在最終投票中倒戈...        │ │
│  └────────────────────────────┘ │
│                                  │
│     [蠟封印章按鈕: 進入會議]     │
└──────────────────────────────────┘
```

---

### 5. 新增視覺資源清單

**需要製作的圖片資源**：

#### 角色畫像（6張）
| 檔案名 | 尺寸 | 說明 |
|--------|------|------|
| `portrait_worker.png` | 512x512 | 紡織工人半身像 |
| `portrait_factory.png` | 512x512 | 工廠主半身像 |
| `portrait_luddite.png` | 512x512 | 盧德派半身像 |
| `portrait_reformer.png` | 512x512 | 改革者半身像 |
| `portrait_mp.png` | 512x512 | 議員半身像 |
| `portrait_george.png` | 512x512 | 喬治三世國王像 |

#### 裝飾元素
| 檔案名 | 尺寸 | 說明 |
|--------|------|------|
| `frame_gold_oval.png` | 600x700 | 橢圓形金框（九宮格切圖） |
| `frame_gold_rect.png` | 400x300 | 矩形金框 |
| `tex_parchment.png` | 512x512 | 羊皮紙紋理（可平鋪） |
| `tex_metal_gold.png` | 256x256 | 金屬紋理 |
| `wax_seal_red.png` | 200x200 | 紅色蠟封 |
| `corner_ornament.png` | 120x120 | 角落裝飾（四角對稱用） |
| `divider_gold.png` | 800x40 | 金色分隔線裝飾 |

#### 背景圖
| 檔案名 | 尺寸 | 說明 |
|--------|------|------|
| `bg_parliament_hd.png` | 2048x2048 | 高清國會背景 |
| `bg_parchment.png` | 1024x1024 | 羊皮紙背景 |

---

### 6. 動畫優化

**新增動畫效果**：

1. **角色卡片翻轉效果**
   - 初始顯示蠟封封印
   - 點擊後 3D 翻轉揭示角色

2. **金幣/權杖懸浮粒子**
   - 在重要按鈕周圍添加微小金色粒子

3. **打字機效果**
   - 重要文字逐字顯示，配合羽毛筆音效

4. **投票動畫**
   - 投票時顯示蠟封印章蓋下的動畫

---

### 7. 字體優化

**建議字體**：
- 中文標題：思源宋體（Noto Serif CJK）
- 英文標題：Cinzel Decorative
- 數字：Playfair Display

```kotlin
// Typography.kt 優化
val CinzelFont = FontFamily(/* 自定義字體 */)
val SerifFont = FontFamily.Serif

val Typography = Typography(
    displayLarge = TextStyle(
        fontFamily = SerifFont,
        fontSize = 48.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 4.sp
    ),
    // ...
)
```

---

## 三、優先級排序

### P0（必須立即優化）
1. ✅ 角色畫像 - 取代 Emoji（影響最大）
2. ✅ 高清背景圖
3. ✅ 角色卡片框架

### P1（重要優化）
4. 金屬質感按鈕
5. 羊皮紙卡片效果
6. 字體優化

### P2（錦上添花）
7. 蠟封動畫
8. 更多粒子效果
9. 音效配合

---

## 四、實施步驟

### 步驟 1：準備資源
- [ ] 生成/繪製 6 張角色油畫像
- [ ] 製作金框 PNG 資源
- [ ] 找/做高清國會背景圖

### 步驟 2：更新代碼
- [ ] 在 res/drawable 添加新圖片
- [ ] 修改 RoleCardScreen.kt 使用真實圖片
- [ ] 修改 PlayerCard 組件
- [ ] 更新 VictorianComponents.kt

### 步驟 3：優化動畫
- [ ] 添加卡片翻轉動畫
- [ ] 優化粒子效果
- [ ] 添加微互動

---

## 五、範例代碼：角色畫像組件

```kotlin
@Composable
fun CharacterPortrait(
    roleType: String,
    modifier: Modifier = Modifier,
    size: Dp = 200.dp
) {
    val portraitRes = when (roleType) {
        "worker" -> R.drawable.portrait_worker
        "factory_owner" -> R.drawable.portrait_factory
        "luddite" -> R.drawable.portrait_luddite
        "reformer" -> R.drawable.portrait_reformer
        "mp" -> R.drawable.portrait_mp
        "george_iii" -> R.drawable.portrait_george
        else -> R.drawable.portrait_default
    }

    Box(
        modifier = modifier.size(size),
        contentAlignment = Alignment.Center
    ) {
        // 外層金框
        Image(
            painter = painterResource(R.drawable.frame_gold_oval),
            contentDescription = null,
            modifier = Modifier.fillMaxSize()
        )

        // 角色畫像
        Image(
            painter = painterResource(portraitRes),
            contentDescription = "角色畫像",
            modifier = Modifier
                .size(size * 0.85f)
                .clip(OvalShape)
        )

        // 角落裝飾
        // ...
    }
}
```

---

## 結論

通過以上優化，Parliament 1812 將從「Emoji+簡單UI」提升到「文明6品質的策略遊戲」體驗。最關鍵的改變是：

1. **角色畫像** - 這是消除廉價感的第一要務
2. **材質紋理** - 金屬、羊皮紙質感
3. **細節打磨** - 框架、陰影、動畫

建議優先實施 P0 項目，可在 1-2 天內顯著提升視覺品質。
