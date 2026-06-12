class_name RankingsScreen
extends Control
## 排行榜介面
## 顯示全球排名與本季排名

# === 節點參考 ===
@onready var tab_container: TabContainer = $VBox/TabContainer
@onready var global_list: VBoxContainer = $VBox/TabContainer/GlobalTab/Scroll/RankList
@onready var season_list: VBoxContainer = $VBox/TabContainer/SeasonTab/Scroll/RankList
@onready var back_button: Button = $VBox/BackButton

# === 狀態 ===
var _global_data: Array[Dictionary] = []
var _season_data: Array[Dictionary] = []


func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	_load_rankings()


# === 內部方法 ===

## 載入排行榜資料
func _load_rankings() -> void:
	# 全球排行
	var global_result: Dictionary = await ApiService.get_rankings("global")
	if global_result.get("success", false):
		_global_data = global_result.get("data", {}).get("rankings", [])
		_populate_list(global_list, _global_data)

	# 本季排行
	var season_result: Dictionary = await ApiService.get_rankings("season")
	if season_result.get("success", false):
		_season_data = season_result.get("data", {}).get("rankings", [])
		_populate_list(season_list, _season_data)


## 填充排名列表
func _populate_list(container: VBoxContainer, data: Array[Dictionary]) -> void:
	if not container:
		return

	for child: Node in container.get_children():
		child.queue_free()

	if data.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "暫無排名資料"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(empty_lbl)
		return

	for i: int in range(data.size()):
		var player: Dictionary = data[i]
		var entry: HBoxContainer = HBoxContainer.new()
		entry.add_theme_constant_override("separation", 12)

		# 名次
		var rank_lbl: Label = Label.new()
		var rank_num: int = i + 1
		if rank_num <= 3:
			rank_lbl.text = ["🥇", "🥈", "🥉"][rank_num - 1]
		else:
			rank_lbl.text = "#%d" % rank_num
		rank_lbl.custom_minimum_size = Vector2(50, 0)
		entry.add_child(rank_lbl)

		# 玩家名稱
		var name_lbl: Label = Label.new()
		name_lbl.text = player.get("username", "未知")
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_child(name_lbl)

		# ELO
		var elo_lbl: Label = Label.new()
		elo_lbl.text = str(player.get("elo", 0))
		elo_lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1))
		elo_lbl.custom_minimum_size = Vector2(60, 0)
		elo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		entry.add_child(elo_lbl)

		# 標記自己
		var local_id: String = AuthService.get_user_id()
		if player.get("id", "") == local_id:
			name_lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1))

		container.add_child(entry)


## 返回按鈕回調
func _on_back_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	SceneManager.go_to_lobby()
