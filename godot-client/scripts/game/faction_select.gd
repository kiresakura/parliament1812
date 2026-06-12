class_name FactionSelect
extends Control
## 派系選擇畫面
## 六張卡片排列，點擊選中 → 確認按鈕 → 進入遊戲
## 選中卡片時顯示該派系的代表角色肖像（手機端用覆蓋層）
## 純 GDScript 建構 UI（不依賴 .tscn 編輯器節點）
## 響應式：根據 viewport 動態計算所有尺寸

# === 信號 ===
signal faction_selected(faction: FactionData)
signal faction_confirmed(faction: FactionData)

# === 常數（基準值，會依 viewport 縮放） ===
const BASE_CARD_WIDTH: float = 180.0
const BASE_CARD_HEIGHT: float = 220.0
const BASE_CARD_SPACING_H: float = 24.0
const BASE_CARD_SPACING_V: float = 20.0
const HOVER_SCALE: Vector2 = Vector2(1.06, 1.06)
const SELECTED_SCALE: Vector2 = Vector2(1.10, 1.10)
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const GOLD_COLOR: Color = Color(0.788, 0.659, 0.298)   # #C9A84C
const BG_COLOR: Color = Color(0.067, 0.067, 0.118)      # 深藍黑

# === 狀態 ===
var _selected_faction: FactionData = null
var _faction_cards: Array[PanelContainer] = []
var _confirm_button: Button = null
var _title_label: Label = null
var _info_label: Label = null
var _back_button: Button = null
var _portrait_rect: TextureRect = null
var _portrait_panel: PanelContainer = null
var _portrait_overlay: Control = null  ## 手機端用覆蓋層
var _ability_label: Label = null
var _difficulty: String = "normal"
var _card_width: float = BASE_CARD_WIDTH
var _card_height: float = BASE_CARD_HEIGHT


func _ready() -> void:
	_difficulty = str(GameManager.current_game_data.get("difficulty", "normal"))
	_calculate_responsive_sizes()
	_build_ui()
	_play_entrance_animation()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# viewport 大小改變時重建 UI（例如旋轉螢幕）
		_calculate_responsive_sizes()


## 計算響應式尺寸
func _calculate_responsive_sizes() -> void:
	var vp: Vector2 = UIScaleClass.get_viewport_size()
	var sf: float = UIScaleClass.scale_factor()
	# Portrait 模式：2 列佈局，卡片寬度不超過螢幕寬度的 42%
	var max_card_w: float = vp.x * 0.42
	if vp.x >= 800.0:
		max_card_w = vp.x * 0.28
	_card_width = minf(BASE_CARD_WIDTH * sf, max_card_w)
	_card_height = _card_width * (BASE_CARD_HEIGHT / BASE_CARD_WIDTH)


# ============================================================
# === UI 建構 ===
# ============================================================

func _build_ui() -> void:
	var vp: Vector2 = UIScaleClass.get_viewport_size()
	var sf: float = UIScaleClass.scale_factor()
	var margin: float = UIScaleClass.safe_margin()

	# 背景
	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 主容器（帶安全邊距）
	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(margin))
	main_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	main_vbox.add_theme_constant_override("separation", int(6.0 * sf))
	add_child(main_vbox)

	# 標題
	_title_label = Label.new()
	_title_label.text = "選擇你的派系"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", UIScaleClass.font_size(32))
	_title_label.add_theme_color_override("font_color", GOLD_COLOR)
	main_vbox.add_child(_title_label)

	# 副標題
	var subtitle: Label = Label.new()
	subtitle.text = "每個派系擁有獨特的戰略風格與起始遺產"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", UIScaleClass.font_size(14))
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(subtitle)

	# 間距
	var spacer_top: Control = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 4.0 * sf)
	main_vbox.add_child(spacer_top)

	# === 中央區域 ===
	# 手機端：只有卡片 grid（肖像用覆蓋層）
	# 桌面端：卡片 grid + 右側肖像面板
	var center_hbox: HBoxContainer = HBoxContainer.new()
	center_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_hbox.add_theme_constant_override("separation", int(20.0 * sf))
	center_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(center_hbox)

	# 卡片用 ScrollContainer 包裝（手機端可滑動）
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_hbox.add_child(scroll)

	var grid_wrapper: VBoxContainer = VBoxContainer.new()
	grid_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	grid_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid_wrapper)

	# Portrait 模式：使用 2 列 3 行（適合直立螢幕）
	var grid_columns: int = 2
	if vp.x >= 800.0:
		grid_columns = 3  # 寬螢幕用 3 列

	var grid: GridContainer = GridContainer.new()
	grid.columns = grid_columns
	grid.add_theme_constant_override("h_separation", int(BASE_CARD_SPACING_H * sf))
	grid.add_theme_constant_override("v_separation", int(BASE_CARD_SPACING_V * sf))
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_wrapper.add_child(grid)

	# 建立六個派系卡片
	var factions: Array[FactionData] = FactionData.get_all_factions()
	for faction: FactionData in factions:
		var card: PanelContainer = _create_faction_card(faction)
		grid.add_child(card)
		_faction_cards.append(card)

	# === 角色肖像面板 ===
	# 桌面端：右側面板
	# 手機端：不加入這裡，改用覆蓋層
	if not UIScaleClass.is_mobile():
		_portrait_panel = _create_portrait_panel()
		center_hbox.add_child(_portrait_panel)
	else:
		# 手機端：建立覆蓋層（稍後選中時顯示）
		_create_portrait_overlay()

	# 間距
	var spacer_mid: Control = Control.new()
	spacer_mid.custom_minimum_size = Vector2(0, 4.0 * sf)
	main_vbox.add_child(spacer_mid)

	# 資訊標籤
	_info_label = Label.new()
	_info_label.text = "點擊卡片選擇你的派系"
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", UIScaleClass.font_size(16))
	_info_label.add_theme_color_override("font_color", Color(0.91, 0.835, 0.718))
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(minf(600.0, vp.x * 0.8), 0)
	_info_label.max_lines_visible = 2
	_info_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(_info_label)

	# 底部按鈕列
	var button_hbox: HBoxContainer = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", int(20.0 * sf))
	main_vbox.add_child(button_hbox)

	# 返回按鈕
	_back_button = Button.new()
	_back_button.text = "← 返回"
	_back_button.custom_minimum_size = UIScaleClass.touch_min_size(120.0, 50.0)
	_back_button.add_theme_font_size_override("font_size", UIScaleClass.font_size(18))
	_back_button.pressed.connect(_on_back_pressed)
	button_hbox.add_child(_back_button)

	# 確認按鈕
	_confirm_button = Button.new()
	_confirm_button.text = "確認選擇"
	_confirm_button.custom_minimum_size = UIScaleClass.touch_min_size(200.0, 55.0)
	_confirm_button.add_theme_font_size_override("font_size", UIScaleClass.font_size(22))
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm_pressed)
	button_hbox.add_child(_confirm_button)


## 建立角色肖像面板（桌面端使用）
func _create_portrait_panel() -> PanelContainer:
	var sf: float = UIScaleClass.scale_factor()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200.0 * sf, 0)
	panel.visible = false
	var portrait_style: StyleBoxFlat = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	portrait_style.border_color = GOLD_COLOR
	portrait_style.border_width_left = 2
	portrait_style.border_width_right = 2
	portrait_style.border_width_top = 2
	portrait_style.border_width_bottom = 2
	portrait_style.corner_radius_top_left = 10
	portrait_style.corner_radius_top_right = 10
	portrait_style.corner_radius_bottom_left = 10
	portrait_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", portrait_style)

	var portrait_margin: MarginContainer = MarginContainer.new()
	portrait_margin.name = "MarginContainer"
	var m: int = int(16.0 * sf)
	portrait_margin.add_theme_constant_override("margin_left", m)
	portrait_margin.add_theme_constant_override("margin_right", m)
	portrait_margin.add_theme_constant_override("margin_top", m)
	portrait_margin.add_theme_constant_override("margin_bottom", m)
	panel.add_child(portrait_margin)

	var portrait_vbox: VBoxContainer = VBoxContainer.new()
	portrait_vbox.name = "VBoxContainer"
	portrait_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_vbox.add_theme_constant_override("separation", int(8.0 * sf))
	portrait_margin.add_child(portrait_vbox)

	# 角色名稱標籤
	var char_name_lbl: Label = Label.new()
	char_name_lbl.name = "CharNameLabel"
	char_name_lbl.text = ""
	char_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_name_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(18))
	char_name_lbl.add_theme_color_override("font_color", GOLD_COLOR)
	portrait_vbox.add_child(char_name_lbl)

	# 角色肖像
	_portrait_rect = TextureRect.new()
	_portrait_rect.custom_minimum_size = Vector2(160.0 * sf, 160.0 * sf)
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait_vbox.add_child(_portrait_rect)

	# 角色屬性標籤
	var stats_lbl: Label = Label.new()
	stats_lbl.name = "StatsLabel"
	stats_lbl.text = ""
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(12))
	stats_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	portrait_vbox.add_child(stats_lbl)

	# 派系能力標籤
	_ability_label = Label.new()
	_ability_label.text = ""
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability_label.custom_minimum_size = Vector2(170.0 * sf, 0)
	_ability_label.add_theme_font_size_override("font_size", UIScaleClass.font_size(11))
	_ability_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
	portrait_vbox.add_child(_ability_label)

	return panel


## 建立手機端的角色肖像覆蓋層
func _create_portrait_overlay() -> void:
	var sf: float = UIScaleClass.scale_factor()
	_portrait_overlay = Control.new()
	_portrait_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_overlay.visible = false
	_portrait_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_portrait_overlay)

	# 半透明背景（點擊關閉）
	var overlay_bg: ColorRect = ColorRect.new()
	overlay_bg.color = Color(0, 0, 0, 0.7)
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_bg.gui_input.connect(_on_overlay_bg_input)
	_portrait_overlay.add_child(overlay_bg)

	# 中央面板
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_overlay.add_child(center)

	_portrait_panel = PanelContainer.new()
	_portrait_panel.custom_minimum_size = Vector2(minf(300.0, UIScaleClass.vw(70.0)), 0)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	panel_style.border_color = GOLD_COLOR
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	_portrait_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_portrait_panel)

	var portrait_margin: MarginContainer = MarginContainer.new()
	portrait_margin.name = "MarginContainer"
	var m: int = int(20.0 * sf)
	portrait_margin.add_theme_constant_override("margin_left", m)
	portrait_margin.add_theme_constant_override("margin_right", m)
	portrait_margin.add_theme_constant_override("margin_top", m)
	portrait_margin.add_theme_constant_override("margin_bottom", m)
	_portrait_panel.add_child(portrait_margin)

	var portrait_vbox: VBoxContainer = VBoxContainer.new()
	portrait_vbox.name = "VBoxContainer"
	portrait_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_vbox.add_theme_constant_override("separation", int(10.0 * sf))
	portrait_margin.add_child(portrait_vbox)

	# 角色名稱
	var char_name_lbl: Label = Label.new()
	char_name_lbl.name = "CharNameLabel"
	char_name_lbl.text = ""
	char_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_name_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(20))
	char_name_lbl.add_theme_color_override("font_color", GOLD_COLOR)
	portrait_vbox.add_child(char_name_lbl)

	# 角色肖像
	_portrait_rect = TextureRect.new()
	_portrait_rect.custom_minimum_size = Vector2(minf(180.0, UIScaleClass.vw(40.0)), minf(180.0, UIScaleClass.vw(40.0)))
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait_vbox.add_child(_portrait_rect)

	# 角色屬性
	var stats_lbl: Label = Label.new()
	stats_lbl.name = "StatsLabel"
	stats_lbl.text = ""
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(14))
	stats_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	portrait_vbox.add_child(stats_lbl)

	# 派系能力
	_ability_label = Label.new()
	_ability_label.text = ""
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability_label.custom_minimum_size = Vector2(minf(250.0, UIScaleClass.vw(60.0)), 0)
	_ability_label.add_theme_font_size_override("font_size", UIScaleClass.font_size(13))
	_ability_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
	portrait_vbox.add_child(_ability_label)

	# 關閉按鈕
	var close_btn: Button = Button.new()
	close_btn.text = "✕ 關閉"
	close_btn.custom_minimum_size = UIScaleClass.touch_min_size(100.0, 44.0)
	close_btn.add_theme_font_size_override("font_size", UIScaleClass.font_size(16))
	close_btn.pressed.connect(func() -> void: _portrait_overlay.visible = false)
	portrait_vbox.add_child(close_btn)


## 覆蓋層背景點擊關閉
func _on_overlay_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_portrait_overlay.visible = false


## 建立單張派系卡片
func _create_faction_card(faction: FactionData) -> PanelContainer:
	var sf: float = UIScaleClass.scale_factor()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(_card_width, _card_height)

	# panel 背景樣式
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.95)
	style.border_color = faction.color_primary
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	# pivot 到中心
	panel.pivot_offset = Vector2(_card_width / 2.0, _card_height / 2.0)

	# 內容容器
	var card_margin: MarginContainer = MarginContainer.new()
	var cm: int = int(10.0 * sf)
	card_margin.add_theme_constant_override("margin_left", cm)
	card_margin.add_theme_constant_override("margin_right", cm)
	card_margin.add_theme_constant_override("margin_top", cm)
	card_margin.add_theme_constant_override("margin_bottom", cm)
	panel.add_child(card_margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", int(6.0 * sf))
	card_margin.add_child(vbox)

	# 派系名稱
	var name_lbl: Label = Label.new()
	name_lbl.text = faction.faction_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(20))
	name_lbl.add_theme_color_override("font_color", faction.color_primary)
	vbox.add_child(name_lbl)

	# 英文名稱
	var en_lbl: Label = Label.new()
	en_lbl.text = faction.get_type_name_en()
	en_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	en_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(11))
	en_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(en_lbl)

	# 分隔線
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", int(4.0 * sf))
	vbox.add_child(sep)

	# 派系圖騰區域
	var icon_rect: ColorRect = ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(32.0 * sf, 32.0 * sf)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_rect.color = faction.color_primary
	icon_rect.color.a = 0.3
	vbox.add_child(icon_rect)

	# 戰略風格
	var playstyle_lbl: Label = Label.new()
	playstyle_lbl.text = "⚔ %s" % faction.playstyle
	playstyle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	playstyle_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(14))
	playstyle_lbl.add_theme_color_override("font_color", faction.color_secondary)
	vbox.add_child(playstyle_lbl)

	# 難度星級
	var diff_lbl: Label = Label.new()
	var stars: String = "★".repeat(faction.difficulty) + "☆".repeat(3 - faction.difficulty)
	diff_lbl.text = "難度：%s" % stars
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(13))
	diff_lbl.add_theme_color_override("font_color", GOLD_COLOR)
	vbox.add_child(diff_lbl)

	# 簡介
	var desc_lbl: Label = Label.new()
	var short_desc: String = faction.description
	if short_desc.length() > 30:
		short_desc = short_desc.substr(0, 30) + "..."
	desc_lbl.text = short_desc
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(11))
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	desc_lbl.custom_minimum_size = Vector2(0, 30.0 * sf)
	vbox.add_child(desc_lbl)

	# 起始遺產提示
	var legacy_lbl: Label = Label.new()
	var legacy_name: String = str(faction.starting_legacy.get("legacy_name", ""))
	legacy_lbl.text = "🏛 %s" % legacy_name
	legacy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legacy_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(11))
	legacy_lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	vbox.add_child(legacy_lbl)

	# 存儲 faction 資料
	panel.set_meta("faction_data", faction)

	# 交互事件
	panel.mouse_entered.connect(_on_card_hover.bind(panel))
	panel.mouse_exited.connect(_on_card_unhover.bind(panel))
	panel.gui_input.connect(_on_card_input.bind(panel))

	return panel


# ============================================================
# === 交互處理 ===
# ============================================================

func _on_card_hover(card: PanelContainer) -> void:
	if _selected_faction != null:
		var card_faction: FactionData = card.get_meta("faction_data") as FactionData
		if card_faction and card_faction.id == _selected_faction.id:
			return

	var tween: Tween = create_tween()
	tween.tween_property(card, "scale", HOVER_SCALE, 0.15).set_ease(Tween.EASE_OUT)


func _on_card_unhover(card: PanelContainer) -> void:
	var card_faction: FactionData = card.get_meta("faction_data") as FactionData
	if _selected_faction and card_faction and card_faction.id == _selected_faction.id:
		var tween: Tween = create_tween()
		tween.tween_property(card, "scale", SELECTED_SCALE, 0.15).set_ease(Tween.EASE_OUT)
		return

	var tween: Tween = create_tween()
	tween.tween_property(card, "scale", NORMAL_SCALE, 0.15).set_ease(Tween.EASE_IN)


func _on_card_input(event: InputEvent, card: PanelContainer) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_select_card(card)


func _select_card(card: PanelContainer) -> void:
	var faction: FactionData = card.get_meta("faction_data") as FactionData
	if faction == null:
		return

	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)

	# 取消之前的選中
	for other_card: PanelContainer in _faction_cards:
		var style: StyleBoxFlat = other_card.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			var other_faction: FactionData = other_card.get_meta("faction_data") as FactionData
			if other_faction:
				style.border_color = other_faction.color_primary
				style.border_width_left = 3
				style.border_width_right = 3
				style.border_width_top = 3
				style.border_width_bottom = 3
		var tween: Tween = create_tween()
		tween.tween_property(other_card, "scale", NORMAL_SCALE, 0.15)

	# 設定新選中
	_selected_faction = faction
	var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = GOLD_COLOR
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4

	# 選中放大 + 確認搖晃
	var tween: Tween = create_tween()
	tween.tween_property(card, "scale", SELECTED_SCALE, 0.15).set_ease(Tween.EASE_OUT)
	await tween.finished

	# 搖晃
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(card, "rotation", deg_to_rad(2.0), 0.05)
	shake_tween.tween_property(card, "rotation", deg_to_rad(-2.0), 0.05)
	shake_tween.tween_property(card, "rotation", 0.0, 0.05)

	# 更新資訊
	_info_label.text = "%s — %s\n%s" % [faction.faction_name, faction.playstyle, faction.description]
	_info_label.add_theme_color_override("font_color", faction.color_secondary)

	# 更新角色肖像面板
	_update_portrait_panel(faction)

	# 啟用確認按鈕
	_confirm_button.disabled = false

	faction_selected.emit(faction)


## 更新角色肖像面板
func _update_portrait_panel(faction: FactionData) -> void:
	var character: CharacterData = CharacterData.get_representative_character(faction.id)

	if character:
		# 顯示面板
		if UIScaleClass.is_mobile():
			if _portrait_overlay:
				_portrait_overlay.visible = true
		else:
			if _portrait_panel:
				_portrait_panel.visible = true

		# 更新角色名稱
		var char_name_lbl: Label = _portrait_panel.get_node("MarginContainer/VBoxContainer/CharNameLabel") as Label
		if char_name_lbl:
			char_name_lbl.text = character.character_name

		# 載入肖像圖片
		var texture: Texture2D = load(character.portrait_path) as Texture2D
		if texture:
			_portrait_rect.texture = texture
		else:
			_portrait_rect.texture = null

		# 更新屬性
		var stats_lbl: Label = _portrait_panel.get_node("MarginContainer/VBoxContainer/StatsLabel") as Label
		if stats_lbl:
			stats_lbl.text = "⚔%d 🛡%d 💬%d 🧠%d 🍀%d" % [
				character.attack, character.defense,
				character.charisma, character.intelligence, character.luck
			]

		# 更新派系能力
		var passive_name: String = str(faction.passive_ability.get("name", ""))
		var passive_desc: String = str(faction.passive_ability.get("description", ""))
		_ability_label.text = "【%s】\n%s" % [passive_name, passive_desc]

		# 面板邊框顏色跟隨派系
		var panel_style: StyleBoxFlat = _portrait_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if panel_style:
			panel_style.border_color = faction.color_primary

		# 淡入動畫
		if UIScaleClass.is_mobile():
			_portrait_overlay.modulate.a = 0.0
			var tween: Tween = create_tween()
			tween.tween_property(_portrait_overlay, "modulate:a", 1.0, 0.3)
		else:
			_portrait_panel.modulate.a = 0.0
			var tween: Tween = create_tween()
			tween.tween_property(_portrait_panel, "modulate:a", 1.0, 0.3)
	else:
		if UIScaleClass.is_mobile():
			if _portrait_overlay:
				_portrait_overlay.visible = false
		else:
			if _portrait_panel:
				_portrait_panel.visible = false


func _on_confirm_pressed() -> void:
	if _selected_faction == null:
		return

	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_confirm_button.disabled = true
	_back_button.disabled = true

	# 存儲到 GameManager
	GameManager.current_game_data["selected_faction_id"] = _selected_faction.id

	faction_confirmed.emit(_selected_faction)

	# 開始遊戲
	await _start_game_with_faction()


func _on_back_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	SceneManager.change_scene("res://scenes/game/difficulty_select.tscn")


# ============================================================
# === 遊戲啟動 ===
# ============================================================

func _start_game_with_faction() -> void:
	_info_label.text = "正在準備遊戲..."
	_info_label.add_theme_color_override("font_color", GOLD_COLOR)

	var game_data: Dictionary = _generate_faction_game_data()

	GameManager.current_game_data = game_data
	GameManager.set_state(GameManager.GameState.IN_GAME)

	AudioManager.play_music(AudioManagerClass.MusicTrack.IN_GAME)

	await get_tree().create_timer(0.5).timeout

	var err: int = get_tree().change_scene_to_file("res://scenes/game/game_board.tscn")
	if err != OK:
		push_error("[FactionSelect] 場景載入失敗! err=%d" % err)


func _generate_faction_game_data() -> Dictionary:
	var ai_name: String = "AI 議員"
	match _difficulty:
		"easy":
			ai_name = "菜鳥議員"
		"normal":
			ai_name = "資深議員"
		"hard":
			ai_name = "議長大人"

	# 取得選中派系的代表角色
	var character: CharacterData = CharacterData.get_representative_character(_selected_faction.id)
	var character_id: String = character.id if character else ""

	var players_array: Array[Dictionary] = [
		{
			"id": "local_player",
			"username": AuthService.current_user.get("username", "玩家"),
			"score": 0,
			"is_ai": false,
			"faction_id": _selected_faction.id,
			"character_id": character_id,
		},
		{
			"id": "ai_opponent",
			"username": ai_name,
			"score": 0,
			"is_ai": true,
		},
	]

	# 從 CardDatabase 建構起始手牌
	var starter_deck: Array[Dictionary] = CardDatabase.build_starter_deck(_selected_faction.id)
	var hand: Array[Dictionary] = []
	for i: int in range(mini(5, starter_deck.size())):
		hand.append(starter_deck[i])

	return {
		"mode": "single",
		"difficulty": _difficulty,
		"session_id": "faction_session_%d" % randi(),
		"phase": GameStateData.Phase.PROPOSAL,
		"round": 1,
		"max_rounds": 5,
		"players": players_array,
		"current_player_index": 0,
		"hand": hand,
		"scores": {"local_player": 0, "ai_opponent": 0},
		"time_remaining": 60.0,
		"is_mock": true,
		"selected_faction_id": _selected_faction.id,
		"selected_character_id": character_id,
		"dimensions": {
			"public_opinion": 50,
			"treasury": 50,
			"military": 50,
			"diplomacy": 50,
		},
	}


# ============================================================
# === 動畫 ===
# ============================================================

func _play_entrance_animation() -> void:
	# 標題淡入
	if _title_label:
		_title_label.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(_title_label, "modulate:a", 1.0, 0.5)

	# 卡片依序淡入 + 縮放彈入（不可用 position 動畫：GridContainer 管理子節點位置）
	for i: int in range(_faction_cards.size()):
		var card: PanelContainer = _faction_cards[i]
		card.modulate.a = 0.0
		card.scale = Vector2(0.8, 0.8)
		var tween: Tween = create_tween()
		tween.tween_interval(0.1 * i + 0.3)
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.35)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 確認按鈕淡入
	if _confirm_button:
		_confirm_button.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_interval(0.9)
		tween.tween_property(_confirm_button, "modulate:a", 1.0, 0.3)
