class_name ButtonMotion
extends RefCounted
## MOTION_SPEC §8 — 按鈕微動效工具類
## 為任意 Button 節點注入 hover / press / release 動效
##
## 用法：
##   ButtonMotion.apply(my_button)
##   ButtonMotion.apply_all(get_tree().get_nodes_in_group("buttons"))

# === MOTION_SPEC 常數 ===
const HOVER_SCALE := Vector2(1.03, 1.03)
const PRESS_SCALE := Vector2(0.97, 0.97)
const REST_SCALE := Vector2(1.0, 1.0)
const HOVER_DURATION: float = 0.08   # 80ms Ease Out
const PRESS_DURATION: float = 0.05   # 50ms Ease In
const RELEASE_DURATION: float = 0.08 # 80ms Ease Out


## 為單一按鈕套用微動效
static func apply(btn: Button) -> void:
	if btn == null:
		return
	# 確保 pivot 在中心
	btn.pivot_offset = btn.size / 2.0

	# 連接信號（使用 lambda 捕捉 btn 參考）
	btn.mouse_entered.connect(func() -> void:
		if btn.disabled:
			return
		var tw: Tween = btn.create_tween()
		tw.tween_property(btn, "scale", HOVER_SCALE, HOVER_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	)

	btn.mouse_exited.connect(func() -> void:
		if btn.disabled:
			return
		var tw: Tween = btn.create_tween()
		tw.tween_property(btn, "scale", REST_SCALE, HOVER_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	)

	btn.button_down.connect(func() -> void:
		if btn.disabled:
			return
		var tw: Tween = btn.create_tween()
		tw.tween_property(btn, "scale", PRESS_SCALE, PRESS_DURATION) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	)

	btn.button_up.connect(func() -> void:
		if btn.disabled:
			return
		var tw: Tween = btn.create_tween()
		tw.tween_property(btn, "scale", REST_SCALE, RELEASE_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	)


## 為多個按鈕套用微動效
static func apply_all(buttons: Array) -> void:
	for node: Variant in buttons:
		if node is Button:
			apply(node as Button)


## 為容器內所有 Button 子節點套用微動效（遞迴）
static func apply_recursive(root: Node) -> void:
	if root is Button:
		apply(root as Button)
	for child: Node in root.get_children():
		apply_recursive(child)
