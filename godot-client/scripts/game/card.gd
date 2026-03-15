class_name Card
extends Control
## 卡牌邏輯
## 負責卡牌視覺、翻轉動畫、拖曳交互、光暈特效
## MOTION_SPEC 動效系統：觸碰→懸停→確認搖晃→出牌飛行→落地衝擊→安定

# === 信號 ===
signal card_clicked(card: Card)
signal card_played(card: Card)
signal card_drag_started(card: Card)
signal card_drag_ended(card: Card)
signal card_hovered(card: Card)
signal card_unhovered(card: Card)
signal haptic_feedback_requested(intensity: float)  ## 觸覺回饋（平台層處理）

# === 常數 ===
const FLIP_DURATION: float = 0.4  # MOTION_SPEC: 200ms + 200ms
const FLIP_HALF_DURATION: float = 0.2  # 每半段 200ms
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const PREVIEW_SCALE: Vector2 = Vector2(1.8, 1.8)
const DRAG_THRESHOLD: float = 10.0

# --- MOTION_SPEC 常數 ---
# 觸碰（第三章）
const TOUCH_SCALE: Vector2 = Vector2(1.05, 1.05)
const TOUCH_DURATION: float = 0.08  # 80ms
const TOUCH_SHADOW_SCALE: float = 1.3

# 懸停確認搖晃（第四章）
const SHAKE_ANGLE_DEG: float = 3.0
const SHAKE_DURATION: float = 0.15  # 150ms

# 出牌飛行（第五章）
const PLAY_FLY_DURATION: float = 0.3  # 300ms
const PLAY_ROTATION_RANGE: float = 5.0  # -5~+5 度

# 落地前壓縮（第六章）
const SQUASH_SCALE_Y: float = 0.95
const SQUASH_DURATION: float = 0.05  # 50ms

# 落地衝擊（第六章）
const IMPACT_SCALE_DURATION: float = 0.08  # 80ms

# 安定光暈（第七章）
const GLOW_FADE_IN_DURATION: float = 0.2  # 200ms

# 卡牌翻轉增強（MOTION_SPEC §5 — 圖鑑/揭示）
const FLIP_GLOW_FADE_DURATION: float = 0.2  # 光暈 fade in 200ms
const SSR_SWEEP_DURATION: float = 0.6  # 金色掃光 600ms
const SSR_SWEEP_COLOR: Color = Color(0.788, 0.659, 0.298, 0.4)
const SSR_SWEEP_WIDTH_RATIO: float = 0.2  # 掃光寬度 = 卡牌寬度的 20%
const SSR_PARTICLE_AMOUNT: int = 20
const SSR_PARTICLE_LIFETIME: float = 0.3  # 300ms
const SSR_PARTICLE_COLOR: Color = Color(0.788, 0.659, 0.298, 1.0)  # #C9A84C
const SSR_PARTICLE_DELAY: float = 0.2  # 掃光開始後 200ms 觸發粒子

# Hover 微動效（第八章）
const HOVER_OFFSET_Y: float = -20.0
const HOVER_DURATION: float = 0.2  # 200ms
const HOVER_SCALE: Vector2 = Vector2(1.08, 1.08)
const UNHOVER_DURATION: float = 0.15  # 150ms

# === 節點參考 ===
@onready var card_front: Panel = $CardFront
@onready var card_back: Panel = $CardBack
@onready var name_label: Label = $CardFront/NameLabel
@onready var desc_label: Label = $CardFront/DescLabel
@onready var cost_label: Label = $CardFront/CostLabel
@onready var power_label: Label = $CardFront/PowerLabel
@onready var rarity_bar: ColorRect = $CardFront/RarityBar
@onready var type_label: Label = $CardFront/TypeLabel
@onready var art_rect: TextureRect = $CardFront/ArtRect
@onready var glow_rect: ColorRect = $CardFront/GlowRect
@onready var back_texture: TextureRect = $CardBack/BackTexture

# === 卡牌資料 ===
var card_data: CardData = null
var card_id: String = ""

# === 狀態 ===
var is_face_up: bool = true
var is_dragging: bool = false
var is_hovering: bool = false
var is_playable: bool = true
var is_previewing: bool = false
var is_animating_play: bool = false  ## 出牌動畫進行中

# === 拖曳 ===
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _original_z_index: int = 0

# === 內部 ===
var _hover_tween: Tween = null
var _touch_tween: Tween = null
var _rest_position_y: float = 0.0  ## hover 前的 Y 座標


func _ready() -> void:
	# 設定互動
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	# 預設隱藏背面
	if card_back:
		card_back.visible = false
	# 動態載入卡牌素材（避免 .tscn ext_resource UID 問題）
	_load_card_textures()
	# 記錄初始 Y
	_rest_position_y = position.y
	# 如果 setup() 在 _ready() 之前被呼叫，@onready 變數當時是 null
	# 需要在這裡重新套用資料
	if card_data != null:
		_update_visuals()


func _load_card_textures() -> void:
	var placeholder_path := "res://assets/ui/cards/card-art-placeholder.png"
	var back_path := "res://assets/ui/cards/card-back.png"
	if art_rect and art_rect.texture == null and ResourceLoader.exists(placeholder_path):
		art_rect.texture = load(placeholder_path)
	if back_texture and back_texture.texture == null and ResourceLoader.exists(back_path):
		back_texture.texture = load(back_path)


## 設定卡牌資料
func setup(data: CardData) -> void:
	card_data = data
	card_id = data.id
	_update_visuals()


## 更新視覺顯示
func _update_visuals() -> void:
	if card_data == null:
		return

	if name_label:
		name_label.text = card_data.card_name
	if desc_label:
		desc_label.text = card_data.description
	if cost_label:
		cost_label.text = str(card_data.cost)
	if power_label:
		power_label.text = str(card_data.power)
	if type_label:
		type_label.text = card_data.get_type_name()

	# 稀有度顏色條
	if rarity_bar:
		rarity_bar.color = card_data.get_rarity_color()

	# 程式化邊框（根據稀有度動態修改 StyleBoxFlat）
	_update_frame_style()

	# 插畫（優先使用 art_path，否則保持 placeholder）
	if art_rect and card_data.art_path != "":
		var art_tex: Texture2D = load(card_data.art_path) as Texture2D
		if art_tex:
			art_rect.texture = art_tex

	# 光暈效果（史詩以上才有）
	if glow_rect:
		glow_rect.visible = card_data.rarity >= CardData.Rarity.EPIC
		if glow_rect.visible:
			glow_rect.color = card_data.get_rarity_color()
			glow_rect.color.a = 0.3


# === 稀有度邊框色表 ===
const RARITY_BORDER_COLORS: Dictionary = {
	CardData.Rarity.COMMON: Color(0.55, 0.42, 0.25),      # #8C6A3F 銅褐
	CardData.Rarity.RARE: Color(0.66, 0.72, 0.78),        # #A8B8C8 銀藍
	CardData.Rarity.EPIC: Color(0.61, 0.35, 0.71),        # #9B59B6 紫色
	CardData.Rarity.LEGENDARY: Color(0.78, 0.66, 0.31),   # #C8A84E 金色
}

const RARITY_BG_COLORS: Dictionary = {
	CardData.Rarity.COMMON: Color(0.1, 0.08, 0.06, 0.95),     # #1A1410
	CardData.Rarity.RARE: Color(0.063, 0.078, 0.094, 0.95),    # #101418
	CardData.Rarity.EPIC: Color(0.078, 0.063, 0.1, 0.95),      # #14101A
	CardData.Rarity.LEGENDARY: Color(0.1, 0.094, 0.063, 0.95), # #1A1810
}


## 根據稀有度動態修改 CardFront 的 StyleBoxFlat 邊框顏色與背景色
func _update_frame_style() -> void:
	if card_front == null or card_data == null:
		return
	var base_style: StyleBox = card_front.get_theme_stylebox("panel")
	if base_style == null or not base_style is StyleBoxFlat:
		return
	var style: StyleBoxFlat = (base_style as StyleBoxFlat).duplicate()
	style.border_color = _get_rarity_border_color()
	style.bg_color = _get_rarity_bg_color()
	card_front.add_theme_stylebox_override("panel", style)


## 取得稀有度對應的邊框顏色
func _get_rarity_border_color() -> Color:
	if card_data == null:
		return Color(0.55, 0.42, 0.25)  # 預設 COMMON
	return RARITY_BORDER_COLORS.get(card_data.rarity, Color(0.55, 0.42, 0.25))


## 取得稀有度對應的背景顏色
func _get_rarity_bg_color() -> Color:
	if card_data == null:
		return Color(0.1, 0.08, 0.06, 0.95)  # 預設 COMMON
	return RARITY_BG_COLORS.get(card_data.rarity, Color(0.1, 0.08, 0.06, 0.95))


# ============================================================
# === 動畫方法 ===
# ============================================================

## 翻牌動畫 (MOTION_SPEC §5 增強版)
## 前半 Ease In 200ms → 換面 → 後半 Ease Out 200ms → 光暈 fade in
func flip(show_front: bool = true) -> void:
	var tween: Tween = create_tween()
	# 第一階段：壓扁（Ease In — 先慢後快）
	tween.tween_property(self, "scale:x", 0.0, FLIP_HALF_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# T+200ms：瞬間切換面
	tween.tween_callback(func() -> void:
		is_face_up = show_front
		if card_front:
			card_front.visible = show_front
		if card_back:
			card_back.visible = not show_front
	)
	# 第二階段：展開（Ease Out — 先快後慢）
	tween.tween_property(self, "scale:x", 1.0, FLIP_HALF_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 音效
	tween.tween_callback(_play_flip_sound)
	await tween.finished
	# 翻轉完成後觸發光暈 fade in
	_fade_in_glow()


## 圖鑑/揭示專用翻牌動畫 (MOTION_SPEC §5 完整序列)
## 翻轉 → 光暈 → (SSR) 金色掃光 → (SSR) 粒子
func flip_reveal(show_front: bool = true, is_ssr: bool = false) -> void:
	# --- Phase 1-2: 翻轉 (0–400ms) ---
	var tween: Tween = create_tween()
	# 前半：scale.x 1.0→0.0，Ease In，200ms
	tween.tween_property(self, "scale:x", 0.0, FLIP_HALF_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# T+200ms：換面
	tween.tween_callback(func() -> void:
		is_face_up = show_front
		if card_front:
			card_front.visible = show_front
		if card_back:
			card_back.visible = not show_front
	)
	# 後半：scale.x 0.0→1.0，Ease Out，200ms
	tween.tween_property(self, "scale:x", 1.0, FLIP_HALF_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 音效
	tween.tween_callback(_play_flip_sound)
	await tween.finished

	# --- Phase 3: T+400ms 光暈亮起 (200ms fade in) ---
	_fade_in_glow()

	# --- Phase 4-5: SSR 限定效果 ---
	if is_ssr:
		# T+400ms: 金色掃光 600ms（與光暈同時啟動）
		_play_ssr_sweep()
		# T+600ms: 粒子（掃光開始後 200ms）
		await get_tree().create_timer(SSR_PARTICLE_DELAY).timeout
		_spawn_ssr_particles()


## 觸碰按壓動效 (MOTION_SPEC §3)
## scale 1.0→1.05 Ease Out 80ms + shadow_scale 1.0→1.3
func touch_press() -> void:
	_kill_tween(_touch_tween)
	_touch_tween = create_tween()
	_touch_tween.set_parallel(true)
	_touch_tween.tween_property(self, "scale", TOUCH_SCALE, TOUCH_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# shadow_scale 透過 material shader 或自訂屬性
	# 如果 GlowRect 存在，用它模擬陰影擴散
	if glow_rect:
		_touch_tween.tween_property(glow_rect, "scale", Vector2(TOUCH_SHADOW_SCALE, TOUCH_SHADOW_SCALE), TOUCH_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await _touch_tween.finished


## 觸碰釋放——回到正常 scale
func touch_release() -> void:
	_kill_tween(_touch_tween)
	_touch_tween = create_tween()
	_touch_tween.set_parallel(true)
	_touch_tween.tween_property(self, "scale", NORMAL_SCALE, TOUCH_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if glow_rect:
		_touch_tween.tween_property(glow_rect, "scale", Vector2.ONE, TOUCH_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await _touch_tween.finished


## 懸停確認搖晃 (MOTION_SPEC §4)
## rot -3→+3度，來回一次，150ms
func confirm_shake() -> void:
	var shake_rad: float = deg_to_rad(SHAKE_ANGLE_DEG)
	var step_duration: float = SHAKE_DURATION / 3.0  # 三段：左→右→回中

	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation", -shake_rad, step_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "rotation", shake_rad, step_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "rotation", 0.0, step_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished


## 出牌動畫（飛向目標位置）— 完整 MOTION_SPEC 序列
## 1. 確認搖晃 → 2. 拋物線飛行 300ms → 3. 落地前壓縮 → 4. 落地衝擊+波紋 → 5. 安定光暈 → 6. 音效+觸覺
func play_to(target_pos: Vector2) -> void:
	is_playable = false
	is_animating_play = true

	# --- Phase 1: 確認搖晃 ---
	await confirm_shake()

	# --- Phase 2: 拋物線飛行 300ms ---
	var start_pos: Vector2 = global_position
	var random_rot: float = deg_to_rad(randf_range(-PLAY_ROTATION_RANGE, PLAY_ROTATION_RANGE))

	# 拋物線弧度——用 method tween 同時控制 X 和 Y（避免 position tween 衝突）
	var arc_height: float = -80.0  # 弧線最高點偏移
	var mid_y: float = (start_pos.y + target_pos.y) / 2.0 + arc_height

	var fly_tween: Tween = create_tween()
	fly_tween.set_parallel(true)

	# 拋物線飛行：透過 method tween 同時控制 X 和 Y（二次貝茲曲線）
	fly_tween.tween_method(
		func(t: float) -> void:
			# X：線性插值
			var pos_x: float = lerpf(start_pos.x, target_pos.x, t)
			# Y：二次貝茲曲線（起點→弧線高點→終點）
			var p0_y: float = start_pos.y
			var p1_y: float = mid_y
			var p2_y: float = target_pos.y
			var bezier_y: float = (1.0 - t) * (1.0 - t) * p0_y + 2.0 * (1.0 - t) * t * p1_y + t * t * p2_y
			global_position = Vector2(pos_x, bezier_y),
		0.0, 1.0, PLAY_FLY_DURATION
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 隨機旋轉
	fly_tween.tween_property(self, "rotation", random_rot, PLAY_FLY_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# 縮小到場上尺寸
	fly_tween.tween_property(self, "scale", Vector2(0.8, 0.8), PLAY_FLY_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await fly_tween.finished

	# --- Phase 3: 落地前壓縮預備 ---
	# scale Y 1.0→0.95 (以當前 0.8 為基底: 0.8→0.76)
	var current_scale: Vector2 = scale
	var squash_scale: Vector2 = Vector2(current_scale.x, current_scale.y * SQUASH_SCALE_Y)

	var squash_tween: Tween = create_tween()
	squash_tween.tween_property(self, "scale", squash_scale, SQUASH_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await squash_tween.finished

	# --- Phase 4: 落地衝擊 ---
	# scale Y 恢復 Ease Out 80ms
	var impact_tween: Tween = create_tween()
	impact_tween.tween_property(self, "scale", current_scale, IMPACT_SCALE_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await impact_tween.finished

	# 擴散波紋
	_spawn_impact_ripple()

	# 音效：落地時播放 card_flip.ogg（透過 AudioManager autoload）
	_play_impact_sound()

	# 觸覺回饋
	haptic_feedback_requested.emit(0.6)

	# --- Phase 5: 安定光暈 ---
	_fade_in_glow()

	is_animating_play = false
	card_played.emit(self)


## 抽牌動畫（從指定位置飛入）
func draw_from(from_pos: Vector2) -> void:
	var final_pos: Vector2 = global_position
	global_position = from_pos
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", final_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", NORMAL_SCALE, 0.5)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished
	# 記錄落位 Y
	_rest_position_y = position.y


## 放大預覽
func show_preview() -> void:
	if is_previewing:
		return
	is_previewing = true
	_original_z_index = z_index
	z_index = 100
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", PREVIEW_SCALE, 0.2).set_ease(Tween.EASE_OUT)
	await tween.finished


## 結束預覽
func hide_preview() -> void:
	if not is_previewing:
		return
	is_previewing = false
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", NORMAL_SCALE, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		z_index = _original_z_index
	)
	await tween.finished


# ============================================================
# === 交互處理 ===
# ============================================================

func _on_gui_input(event: InputEvent) -> void:
	if not is_playable or is_animating_play:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_drag_start_pos = mouse_event.global_position
				_original_position = global_position
				_drag_offset = global_position - mouse_event.global_position
				# MOTION_SPEC §3: 觸碰按壓
				touch_press()
			else:
				# MOTION_SPEC §3: 觸碰釋放
				touch_release()
				if is_dragging:
					_end_drag()
				else:
					# 點擊（非拖曳）
					card_clicked.emit(self)

		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			# 右鍵放大預覽
			if is_previewing:
				hide_preview()
			else:
				show_preview()

	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		if not is_dragging:
			var distance: float = motion_event.global_position.distance_to(_drag_start_pos)
			if distance > DRAG_THRESHOLD:
				_start_drag()
		if is_dragging:
			global_position = motion_event.global_position + _drag_offset


## Hover 微動效 (MOTION_SPEC §8)
## hover: position Y -20px, 200ms Ease Out; scale 1.0→1.08
func _on_mouse_entered() -> void:
	if is_dragging or is_previewing or is_animating_play:
		return
	is_hovering = true
	_rest_position_y = position.y

	_kill_tween(_hover_tween)
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", HOVER_SCALE, HOVER_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "position:y", _rest_position_y + HOVER_OFFSET_Y, HOVER_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	card_hovered.emit(self)


## Unhover (MOTION_SPEC §8)
## unhover: 回原位, 150ms Ease In
func _on_mouse_exited() -> void:
	if is_dragging or is_previewing or is_animating_play:
		return
	is_hovering = false

	_kill_tween(_hover_tween)
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", NORMAL_SCALE, UNHOVER_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "position:y", _rest_position_y, UNHOVER_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	card_unhovered.emit(self)


func _start_drag() -> void:
	is_dragging = true
	_original_z_index = z_index
	z_index = 100
	card_drag_started.emit(self)


func _end_drag() -> void:
	is_dragging = false
	z_index = _original_z_index
	card_drag_ended.emit(self)
	# 如果拖到上半區域，視為出牌
	var viewport_size: Vector2 = get_viewport_rect().size
	if global_position.y < viewport_size.y * 0.4:
		card_played.emit(self)
	else:
		# 回到原位
		var tween: Tween = create_tween()
		tween.tween_property(self, "global_position", _original_position, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# ============================================================
# === 內部輔助 ===
# ============================================================

## 生成落地波紋
func _spawn_impact_ripple() -> void:
	var ripple: ImpactRipple = ImpactRipple.new()
	# 加到父節點（場景層），避免跟隨卡牌 scale
	var parent_node: Node = get_parent()
	if parent_node == null:
		parent_node = self
	parent_node.add_child(ripple)
	# 定位到卡牌中心
	ripple.global_position = global_position + (size * scale) / 2.0 - ripple.size / 2.0
	ripple.play_ripple()


## 播放落地音效（透過 AudioManager autoload，走 Audio Bus）
func _play_impact_sound() -> void:
	# AudioManager 是 autoload 單例
	if Engine.has_singleton("AudioManager"):
		var audio_mgr: Node = Engine.get_singleton("AudioManager")
		if audio_mgr.has_method("play_sfx"):
			audio_mgr.play_sfx("card_flip")
	else:
		# 降級：嘗試透過場景樹取得 AudioManager
		var audio_mgr: Node = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_sfx"):
			audio_mgr.play_sfx("card_flip")


## 安定光暈 fade in (MOTION_SPEC §7)
func _fade_in_glow() -> void:
	if glow_rect == null:
		return
	glow_rect.visible = true
	var target_alpha: float = 0.5
	if card_data and card_data.rarity >= CardData.Rarity.EPIC:
		target_alpha = 0.6
	glow_rect.color.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(glow_rect, "color:a", target_alpha, GLOW_FADE_IN_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## 播放翻牌音效 (MOTION_SPEC §5)
func _play_flip_sound() -> void:
	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_sfx"):
		audio_mgr.play_sfx("card_flip")


## SSR 金色掃光 (MOTION_SPEC §5)
## 動態建立一個金色 ColorRect，從左往右掃過卡牌，600ms
func _play_ssr_sweep() -> void:
	var card_size: Vector2 = size
	var sweep_w: float = card_size.x * SSR_SWEEP_WIDTH_RATIO
	var sweep_h: float = card_size.y

	var sweep_rect: ColorRect = ColorRect.new()
	sweep_rect.name = "SSR_SweepRect"
	sweep_rect.color = SSR_SWEEP_COLOR
	sweep_rect.size = Vector2(sweep_w, sweep_h)
	sweep_rect.position = Vector2(-sweep_w, 0.0)
	sweep_rect.z_index = 5  # 在卡面之上
	sweep_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sweep_rect)

	# Tween: position.x 從 -sweep_w 到 card_width，同時 alpha fade out
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sweep_rect, "position:x", card_size.x, SSR_SWEEP_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sweep_rect, "modulate:a", 0.0, SSR_SWEEP_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# 掃完後移除
	tween.chain().tween_callback(sweep_rect.queue_free)


## SSR 金色粒子 (MOTION_SPEC §5)
## 動態建立 GPUParticles2D，金色，amount=20，one_shot，300ms
func _spawn_ssr_particles() -> void:
	var card_size: Vector2 = size

	# --- ParticleProcessMaterial ---
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 45.0
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 120.0
	mat.gravity = Vector3(0.0, 80.0, 0.0)
	mat.color = SSR_PARTICLE_COLOR
	# 發射區域：卡牌邊緣 (BOX)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(card_size.x / 2.0, card_size.y / 2.0, 0.0)
	# 縮放：粒子從小到大再消失
	mat.scale_min = 1.0
	mat.scale_max = 2.5

	# --- GPUParticles2D ---
	var particles: GPUParticles2D = GPUParticles2D.new()
	particles.name = "SSR_Particles"
	particles.process_material = mat
	particles.amount = SSR_PARTICLE_AMOUNT
	particles.lifetime = SSR_PARTICLE_LIFETIME
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 0.8  # 大部分粒子同時噴出
	# 定位到卡牌中心
	particles.position = card_size / 2.0
	particles.z_index = 6
	add_child(particles)

	# 播完後自動移除
	await get_tree().create_timer(SSR_PARTICLE_LIFETIME + 0.5).timeout
	if is_instance_valid(particles):
		particles.queue_free()


## 安全殺掉 tween
func _kill_tween(tween: Tween) -> void:
	if tween and tween.is_valid():
		tween.kill()
