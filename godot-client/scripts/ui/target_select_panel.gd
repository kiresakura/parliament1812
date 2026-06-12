class_name TargetSelectPanel
extends PanelContainer
## 目標選擇面板
## 在 MP 出牌需要 target 時彈出，讓玩家選擇目標

signal target_selected(player_id: String)
signal selection_cancelled()

var _card: Card = null

@onready var _target_list: VBoxContainer = $MarginContainer/VBox/TargetList
@onready var _title_label: Label = $MarginContainer/VBox/TitleLabel
@onready var _cancel_button: Button = $MarginContainer/VBox/CancelButton


func _ready() -> void:
	visible = false
	if _cancel_button:
		_cancel_button.pressed.connect(_on_cancel_pressed)


## 顯示目標選擇面板
func show_targets(card: Card, players: Array[Dictionary], local_id: String) -> void:
	_card = card
	_clear_targets()

	var target_type: String = ""
	if card.card_data:
		target_type = card.card_data.target_type

	if _title_label:
		_title_label.text = "選擇目標"

	for i: int in range(players.size()):
		var player: Dictionary = players[i]
		var pid: String = str(player.get("id", ""))

		# 過濾目標
		match target_type:
			"single_enemy", "single_any":
				if pid == local_id:
					continue
			"single_ally":
				if pid == local_id:
					continue
			_:
				if pid == local_id:
					continue

		var player_name: String = str(player.get("username", str(player.get("name", "???"))))
		var reputation: int = int(player.get("reputation", 0))

		var btn: Button = Button.new()
		btn.text = "%s（聲望: %d）" % [player_name, reputation]
		btn.custom_minimum_size = Vector2(280, 48)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		# 按鈕樣式
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color(0.91, 0.835, 0.718))

		var captured_id: String = pid
		btn.pressed.connect(func() -> void:
			target_selected.emit(captured_id)
		)

		_target_list.add_child(btn)

	visible = true


## 清除動態生成的按鈕
func _clear_targets() -> void:
	if _target_list == null:
		return
	for child: Node in _target_list.get_children():
		child.queue_free()


func _on_cancel_pressed() -> void:
	visible = false
	_card = null
	selection_cancelled.emit()
