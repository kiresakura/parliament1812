class_name PlayerHand
extends HBoxContainer
## 手牌管理
## 負責排列、扇形展開、出牌、抽牌

# === 信號 ===
signal card_selected(card: Card)
signal card_played_from_hand(card: Card)
signal hand_updated()

# === 基準常數（依 viewport 縮放） ===
const BASE_CARD_SPACING: float = -30.0  # 卡牌重疊間距
const FAN_ANGLE: float = 3.0       # 扇形展開角度
const MAX_HAND_SIZE: int = 7
const CARD_SCENE_PATH: String = "res://scenes/game/card.tscn"

# === 狀態 ===
var cards: Array[Card] = []
var selected_card: Card = null
var is_interactable: bool = true

# === 預載場景 ===
var _card_scene: PackedScene = null


func _ready() -> void:
	# 設定容器屬性
	alignment = BoxContainer.ALIGNMENT_CENTER
	# 響應式卡牌間距
	var sf: float = UIScaleClass.scale_factor()
	add_theme_constant_override("separation", int(BASE_CARD_SPACING * sf))

	# 預載卡牌場景
	if ResourceLoader.exists(CARD_SCENE_PATH):
		_card_scene = load(CARD_SCENE_PATH) as PackedScene


# === 公開方法 ===

## 加入一張卡牌
func add_card(card_data: CardData, animate: bool = true) -> Card:
	if cards.size() >= MAX_HAND_SIZE:
		push_warning("[PlayerHand] 手牌已滿")
		return null

	var card: Card = _create_card(card_data)
	if card == null:
		return null

	cards.append(card)
	add_child(card)

	# 連接信號
	card.card_clicked.connect(_on_card_clicked)
	card.card_played.connect(_on_card_played)

	if animate:
		# 從畫面下方飛入
		var from_pos: Vector2 = Vector2(get_viewport_rect().size.x / 2.0, get_viewport_rect().size.y + 100.0)
		await card.draw_from(from_pos)

	_arrange_cards()
	hand_updated.emit()
	return card


## 移除一張卡牌
func remove_card(card: Card, animate: bool = true) -> void:
	if card not in cards:
		return

	cards.erase(card)

	if card == selected_card:
		selected_card = null

	card.card_clicked.disconnect(_on_card_clicked)
	card.card_played.disconnect(_on_card_played)

	if animate:
		# 淡出
		var tween: Tween = create_tween()
		tween.tween_property(card, "modulate:a", 0.0, 0.3)
		await tween.finished

	card.queue_free()
	_arrange_cards()
	hand_updated.emit()


## 從 API 資料設定整副手牌
func set_hand(card_datas: Array) -> void:
	# 清空現有手牌
	clear_hand()

	for i: int in range(card_datas.size()):
		var data: Variant = card_datas[i]
		if data is Dictionary:
			var card_data: CardData = CardData.from_dict(data as Dictionary)
			if card_data:
				await add_card(card_data, true)


## 清空手牌
func clear_hand() -> void:
	for card: Card in cards:
		card.queue_free()
	cards.clear()
	selected_card = null
	hand_updated.emit()


## 取得手牌數量
func get_card_count() -> int:
	return cards.size()


## 設定是否可互動
func set_interactable(interactable: bool) -> void:
	is_interactable = interactable
	for card: Card in cards:
		card.is_playable = interactable


## 取得選中的卡牌
func get_selected_card() -> Card:
	return selected_card


## 根據 ID 尋找卡牌
func find_card_by_id(card_id: String) -> Card:
	for card: Card in cards:
		if card.card_id == card_id:
			return card
	return null


# === 內部方法 ===

## 建立卡牌實例
func _create_card(card_data: CardData) -> Card:
	if _card_scene:
		var card: Card = _card_scene.instantiate() as Card
		card.setup(card_data)
		return card
	else:
		# 如果場景不存在，建立基本卡牌
		var card: Card = Card.new()
		card.setup(card_data)
		card.custom_minimum_size = Vector2(120, 180)
		return card


## 排列手牌（扇形展開）
func _arrange_cards() -> void:
	var count: int = cards.size()
	if count == 0:
		return

	for i: int in range(count):
		var card: Card = cards[i]
		# 計算扇形角度
		var angle_offset: float = (i - (count - 1) / 2.0) * FAN_ANGLE
		var target_rotation: float = deg_to_rad(angle_offset)

		# 計算垂直偏移（弧形效果）
		var vertical_offset: float = abs(i - (count - 1) / 2.0) * 5.0

		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "rotation", target_rotation, 0.3)
		tween.tween_property(card, "position:y", vertical_offset, 0.3)


## 卡牌點擊回調
func _on_card_clicked(card: Card) -> void:
	if not is_interactable:
		return

	# 取消之前的選中
	if selected_card and selected_card != card:
		var old_card: Card = selected_card
		var tween: Tween = create_tween()
		tween.tween_property(old_card, "position:y", old_card.position.y + 20, 0.15)

	# 選中/取消選中
	if selected_card == card:
		selected_card = null
		var tween: Tween = create_tween()
		tween.tween_property(card, "position:y", card.position.y + 20, 0.15)
	else:
		selected_card = card
		# 選中的卡牌上移
		var tween: Tween = create_tween()
		tween.tween_property(card, "position:y", card.position.y - 20, 0.15)
		card_selected.emit(card)


## 卡牌出牌回調
func _on_card_played(card: Card) -> void:
	if not is_interactable:
		return
	card_played_from_hand.emit(card)
