class_name CodexScreen
extends Control
## 圖鑑介面
## 以 GridContainer 顯示所有卡牌，點擊可放大查看

# === 常數 ===
const CARD_SCENE_PATH: String = "res://scenes/game/card.tscn"

# === 節點參考 ===
@onready var grid: GridContainer = $VBox/ScrollContainer/Grid
@onready var detail_panel: PanelContainer = $DetailOverlay
@onready var detail_name: Label = $DetailOverlay/MarginContainer/VBox/DetailName
@onready var detail_desc: Label = $DetailOverlay/MarginContainer/VBox/DetailDesc
@onready var detail_type: Label = $DetailOverlay/MarginContainer/VBox/DetailType
@onready var detail_stats: Label = $DetailOverlay/MarginContainer/VBox/DetailStats
@onready var close_detail: Button = $DetailOverlay/MarginContainer/VBox/CloseButton
@onready var back_button: Button = $VBox/BackButton

# === 狀態 ===
var _card_scene: PackedScene = null
var _all_cards: Array[Dictionary] = []


func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if close_detail:
		close_detail.pressed.connect(_on_close_detail)
	if detail_panel:
		detail_panel.visible = false

	# 響應式 grid 列數（portrait 模式適配）
	if grid:
		var vp_w: float = UIScaleClass.get_viewport_size().x
		if vp_w < 500.0:
			grid.columns = 2
		elif vp_w < 800.0:
			grid.columns = 3
		else:
			grid.columns = 4

	# 預載卡牌場景
	if ResourceLoader.exists(CARD_SCENE_PATH):
		_card_scene = load(CARD_SCENE_PATH) as PackedScene

	_load_codex()


# === 內部方法 ===

## 從 API 載入所有卡牌
func _load_codex() -> void:
	var result: Dictionary = await ApiService.get_all_cards()
	if result.get("success", false):
		_all_cards = result.get("data", {}).get("cards", [])
		_populate_grid()


## 填充 GridContainer
func _populate_grid() -> void:
	if not grid:
		return

	for child: Node in grid.get_children():
		child.queue_free()

	for card_dict: Dictionary in _all_cards:
		var card_data: CardData = CardData.from_dict(card_dict)
		var card_node: Control = null

		if _card_scene:
			card_node = _card_scene.instantiate() as Control
			if card_node is Card:
				(card_node as Card).setup(card_data)
				(card_node as Card).is_playable = false
				(card_node as Card).card_clicked.connect(_on_card_clicked)
		else:
			# 備用：純按鈕
			var btn: Button = Button.new()
			btn.text = card_data.card_name
			btn.custom_minimum_size = Vector2(120, 180)
			btn.pressed.connect(func() -> void: _show_detail(card_data))
			card_node = btn

		grid.add_child(card_node)


## 卡牌被點擊
func _on_card_clicked(card: Card) -> void:
	if card.card_data:
		_show_detail(card.card_data)


## 顯示卡牌詳細資訊
func _show_detail(data: CardData) -> void:
	if detail_panel:
		detail_panel.visible = true
	if detail_name:
		detail_name.text = data.card_name
	if detail_desc:
		detail_desc.text = data.description
	if detail_type:
		detail_type.text = "類型：%s" % data.get_type_name()
	if detail_stats:
		detail_stats.text = "費用: %d ｜ 影響力: %d" % [data.cost, data.power]


## 關閉詳細面板
func _on_close_detail() -> void:
	if detail_panel:
		detail_panel.visible = false


## 返回大廳
func _on_back_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	SceneManager.go_to_lobby()
