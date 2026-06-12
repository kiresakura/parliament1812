# 1812 國會風雲 — 動效時序規格 v1.0

> Art Director：羅塞蒂
> 目標引擎：Godot 4.6
> 動效系統：Tween + GPUParticles2D + Rive（外部動畫）

---

## 一、卡牌出牌（核心多巴胺觸發點）

| 時間點 | 事件 | 動效 | 音效 | 觸覺 |
|--------|------|------|------|------|
| T+0ms | 手指觸碰 | scale 1.0→1.05（Ease Out, 80ms），shadow_scale 1.0→1.3 | — | 輕觸（HapticFeedback.light） |
| T+80ms | 懸停確認 | 輕微搖晃（rot -3→+3度，來回一次，150ms） | — | — |
| T+0ms（放開） | 出牌開始 | 飛行拋物線：起點→落點，300ms，Ease In-Out，帶 -5~+5度隨機旋轉 | — | — |
| T+280ms | 落地前 | 壓縮預備：scale Y 1.0→0.95（50ms） | — | — |
| T+300ms | 落地衝擊 | scale Y 0.95→1.0（Ease Out, 80ms）+ 擴散波紋（Circle2D 從 scale 0.1→1.5，fade out 200ms） | card_flip.ogg | HapticFeedback.medium |
| T+350ms | 安定 | 卡牌光暈 shader 亮起，0.2秒 fade in | — | — |

**Godot 實現提示：**
```gdscript
# 出牌 Tween
var tween = create_tween().set_parallel()
tween.tween_property(card, "position", target_pos, 0.3).set_ease(Tween.EASE_IN_OUT)
tween.tween_property(card, "rotation", randf_range(-0.087, 0.087), 0.3)
# 落地衝擊
tween.chain().tween_property(card, "scale:y", 0.95, 0.05)
tween.chain().tween_property(card, "scale:y", 1.0, 0.08).set_ease(Tween.EASE_OUT)
```

---

## 二、投票系統動效

| 時間點 | 事件 | 動效 | 音效 | 觸覺 |
|--------|------|------|------|------|
| T+0ms | 投票按鈕按下 | 按鈕 scale 1.0→0.95（50ms Ease In） | — | 輕觸 |
| T+50ms | 確認 | 按鈕 scale 0.95→1.0（80ms Ease Out），按鈕邊框金色閃爍 | quill_writing.ogg（0.5秒截取） | — |
| T+100ms | 計票開始 | 票數 Label 數字滾動（每50ms跳一次） | — | — |
| T+800ms | 最終票數 | 數字停止，frame shake（±2px，3次，100ms） | gavel.ogg | HapticFeedback.heavy |
| T+1000ms | 結果判定 | → 見「法案通過」或「法案失敗」動效 | — | — |

---

## 三、法案通過（多巴胺爆發）

**streak=1（基礎）：**

| 時間點 | 事件 | 動效 | 音效 | 觸覺 |
|--------|------|------|------|------|
| T+0ms | 判定通過 | 全畫面輕微閃光（白色 overlay，alpha 0→0.15→0 200ms） | vote_pass_1.ogg | HapticFeedback.medium |
| T+50ms | 金色粒子 | GPUParticles2D：amount=30，radius=150px，向上噴發，持續1.5s | — | — |
| T+100ms | 通過文字 | 「法案通過！」label 從畫面下方 slide up 80px，fade in，Ease Out | — | — |

**streak=2：**

| 時間點 | 事件 | 動效 | 音效 | 觸覺 |
|--------|------|------|------|------|
| T+0ms | 判定通過 | 全畫面閃光（alpha 0→0.25→0，250ms）+ 光暈 shader 擴散（radius 0→300px，400ms） | vote_pass_2.ogg（更響亮版本，可用相同音效加音量） | HapticFeedback.heavy |
| T+0ms | 連段文字 | 「連線！×2」文字從畫面底部飛入，Ease Out 300ms，停留1秒，fade out | — | — |
| T+50ms | 強化粒子 | GPUParticles2D：amount=60，radius=250px | — | — |

**streak=3+（全屏爆發）：**

| 時間點 | 事件 | 動效 | 音效 | 觸覺 |
|--------|------|------|------|------|
| T+0ms | 全屏爆發 | 白色 overlay fade in（alpha 0→0.4，150ms），後快速 fade out（0.4→0，300ms） | vote_pass_3.ogg（疊加管弦樂高音） | HapticFeedback.heavy × 2（間隔 100ms） |
| T+100ms | 粒子暴雨 | GPUParticles2D：amount=150，全畫面隨機飛散，持續3s | — | — |
| T+150ms | 螢幕震動 | camera.offset 做 ±5px 快速震動，8次，持續400ms | — | — |
| T+200ms | 連段文字 | 「傳奇連線！×N」大字，scale 0.5→1.2→1.0 彈跳動畫，500ms | — | — |

---

## 四、法案失敗

| 時間點 | 事件 | 動效 | 音效 | 觸覺 |
|--------|------|------|------|------|
| T+0ms | 判定失敗 | 畫面緩慢暗化：Color overlay，black，alpha 0→0.3，800ms | vote_fail.ogg（低沉管弦樂，可用免費素材） | HapticFeedback.light |
| T+200ms | 失敗文字 | 「法案否決」label fade in，顏色 #8B0000（暗紅），無動畫 | — | — |
| T+500ms | 漣漪 | 從畫面中心擴散的暗色圓形波紋，3道，每道間隔200ms | — | — |

---

## 五、卡牌翻轉（圖鑑/揭示）

| 時間點 | 事件 | 動效 |
|--------|------|------|
| T+0–200ms | 翻轉前半 | rotation_y 0→90度，Ease In，卡背可見 |
| T+200ms | 換面 | 瞬間切換到正面貼圖 |
| T+200–400ms | 翻轉後半 | rotation_y 90→0度，Ease Out，正面出現 |
| T+400ms | 光暈亮起 | card_glow.gdshader intensity 0→1.0，200ms |
| T+400ms（SSR限定） | 金色掃光 | gradient shader 從左到右掃過，600ms |
| T+600ms（SSR） | 粒子 | 少量金色粒子從卡牌邊緣噴出，amount=20，300ms |

---

## 六、場景切換

| 切換類型 | 動效 | 時長 |
|----------|------|------|
| 一般切換 | 全畫面 fade out（300ms）→ 場景載入 → fade in（300ms） | 總計 600ms+ |
| 進入遊戲 | 書頁翻轉效果（AnimationPlayer，羊皮紙質感 shader） | 500ms |
| 勝利進結算 | 白色光爆，持續 400ms，切換 | 400ms |
| 失敗進結算 | 緩慢暗化 600ms，切換 | 600ms |

---

## 七、勝利結算

| 時間點 | 事件 | 動效 |
|--------|------|------|
| T+0ms | 金色光爆從畫面中央 | GPUParticles2D：amount=200，向四周爆散，radius=全畫面，持續2s |
| T+200ms | 管弦樂高潮 | BGM 切換到勝利版本（Fantasy Choir 3 其中一段） |
| T+500ms | 勝利標題 | scale 0→1.3→1.0（彈跳，300ms） |
| T+800ms | 戰績 | 各項數值逐一計數顯示（每項間隔 300ms） |

---

## 八、UI 微動效

| 元素 | 觸發 | 動效 |
|------|------|------|
| 按鈕 hover | 滑鼠進入 | scale 1.0→1.03，80ms Ease Out |
| 按鈕 press | 點擊 | scale 1.03→0.97，50ms Ease In |
| 按鈕 release | 放開 | scale 0.97→1.0，80ms Ease Out |
| 通知滑入 | 觸發 | 從右側 +300px → 0px，150ms Ease Out |
| 通知消失 | 計時結束 | opacity 1.0→0，500ms |
| 卡牌 hover | 手牌懸停 | position Y -20px，200ms Ease Out；scale 1.0→1.08 |
| 卡牌 unhover | 離開 | 回原位，150ms Ease In |

---

## 九、Rive streak 變數映射

```gdscript
# 每次法案通過後呼叫
func trigger_vote_pass(streak: int):
    # Rive state machine
    _rive_controller.set_number_input("streak", float(streak))
    # 精確時序
    await get_tree().create_timer(0.0).timeout
    _play_haptic(streak)
    await get_tree().create_timer(0.05).timeout
    _spawn_particles(streak)
    await get_tree().create_timer(0.1).timeout
    _play_sfx("vote_pass_%d" % min(streak, 3))
```

---

## 十、禁止事項

- ❌ 動畫持續超過 600ms（除結算外）——玩家不等待
- ❌ 同時觸發超過 3 個粒子系統——效能殺手
- ❌ 連續兩個 HapticFeedback.heavy 間隔 < 80ms——手機會過熱
- ❌ 音效音量沒有 Audio Bus 統一管理——玩家會靜音整個遊戲

---

*動效即節奏。節奏即多巴胺。每一毫秒都是設計。*
*羅塞蒂 🎨*
