class_name ImpactRipple
extends Control
## 出牌落地擴散波紋
## 用 draw() 畫圓 + Tween 控制 scale 和 alpha
## MOTION_SPEC: scale 0.1→1.5, fade out 200ms, EASE_OUT

const RIPPLE_DURATION: float = 0.2
const RIPPLE_START_SCALE: float = 0.1
const RIPPLE_END_SCALE: float = 1.5
const RIPPLE_COLOR: Color = Color(1.0, 0.9, 0.6, 0.6)
const RIPPLE_RADIUS: float = 80.0
const RIPPLE_LINE_WIDTH: float = 3.0

var _alpha: float = 0.6
var _current_scale: float = RIPPLE_START_SCALE


func _ready() -> void:
	# 不攔截輸入
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 初始不可見
	modulate.a = 0.0
	# 使尺寸足以容納波紋
	custom_minimum_size = Vector2(RIPPLE_RADIUS * 2, RIPPLE_RADIUS * 2) * RIPPLE_END_SCALE
	size = custom_minimum_size
	# 以中心為錨點
	pivot_offset = size / 2.0


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = RIPPLE_RADIUS * _current_scale
	var color: Color = RIPPLE_COLOR
	color.a = _alpha
	# 繪製外圈
	draw_arc(center, radius, 0.0, TAU, 64, color, RIPPLE_LINE_WIDTH, true)
	# 繪製內部半透明填充
	var fill_color: Color = color
	fill_color.a *= 0.2
	draw_circle(center, radius, fill_color)


## 播放波紋動畫，完成後自動銷毀
func play_ripple() -> void:
	_current_scale = RIPPLE_START_SCALE
	_alpha = RIPPLE_COLOR.a
	modulate.a = 1.0
	queue_redraw()

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Scale 0.1 → 1.5, EASE_OUT（嚴格遵守 MOTION_SPEC）
	tween.tween_method(_set_scale_and_redraw, RIPPLE_START_SCALE, RIPPLE_END_SCALE, RIPPLE_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Alpha fade out, EASE_OUT
	tween.tween_method(_set_alpha_and_redraw, RIPPLE_COLOR.a, 0.0, RIPPLE_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await tween.finished
	queue_free()


func _set_scale_and_redraw(value: float) -> void:
	_current_scale = value
	queue_redraw()


func _set_alpha_and_redraw(value: float) -> void:
	_alpha = value
	queue_redraw()
