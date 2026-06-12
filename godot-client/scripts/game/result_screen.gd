class_name ResultScreen
extends Control
## 結算畫面邏輯
## 負責顯示遊戲結果、排名、獎勵

# === 信號 ===
signal continue_pressed()
signal rematch_requested()

# === 節點參考 ===
@onready var result_title: Label = $VBox/ResultTitle
@onready var player_list: VBoxContainer = $VBox/ScrollContainer/PlayerList
@onready var reward_label: Label = $VBox/RewardLabel
@onready var rating_change: Label = $VBox/RatingChange
@onready var continue_button: Button = $VBox/ButtonBox/ContinueButton  # ButtonBox is VBox in portrait
@onready var rematch_button: Button = $VBox/ButtonBox/RematchButton

# === 結果資料 ===
var _result_data: Dictionary = {}
var _is_winner: bool = false


func _ready() -> void:
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if rematch_button:
		rematch_button.pressed.connect(_on_rematch_pressed)

	# 載入結果
	_load_results()


# === 公開方法 ===

## 設定遊戲結果
func set_results(data: Dictionary) -> void:
	_result_data = data
	_display_results()


# === 內部方法 ===

## 載入結果（從 GameManager）
func _load_results() -> void:
	_result_data = GameManager.current_game_data
	_display_results()


## 顯示結果
func _display_results() -> void:
	if _result_data.is_empty():
		return

	var local_id: String = AuthService.get_user_id()
	var winner_id: String = _result_data.get("winner_id", "")
	_is_winner = (local_id == winner_id)

	# 標題
	if result_title:
		if _is_winner:
			result_title.text = "🎉 勝利！"
			result_title.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298))  # 金色
			AudioManager.play_sfx(AudioManagerClass.SFX.VICTORY)
		else:
			result_title.text = "惜敗..."
			result_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			AudioManager.play_sfx(AudioManagerClass.SFX.DEFEAT)

	# 排名列表
	_display_player_rankings()

	# 獎勵
	var rewards: Dictionary = _result_data.get("rewards", {})
	if reward_label:
		var coins: int = rewards.get("coins", 0)
		var exp: int = rewards.get("experience", 0)
		reward_label.text = "獲得 %d 金幣、%d 經驗" % [coins, exp]

	# 積分變化
	var rating_delta: int = _result_data.get("rating_change", 0)
	if rating_change:
		if rating_delta > 0:
			rating_change.text = "積分 +%d" % rating_delta
			rating_change.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		elif rating_delta < 0:
			rating_change.text = "積分 %d" % rating_delta
			rating_change.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		else:
			rating_change.text = "積分 ±0"

	# 單人模式：調整按鈕文字
	if _result_data.get("mode", "") == "single":
		if continue_button:
			continue_button.text = "返回主選單"
		if rematch_button:
			rematch_button.text = "再來一局"

	# 入場動畫
	_play_entrance_animation()


## 顯示玩家排名列表
func _display_player_rankings() -> void:
	if not player_list:
		return

	# 清除舊列表
	for child: Node in player_list.get_children():
		child.queue_free()

	var players: Array = _result_data.get("rankings", [])
	for i: int in range(players.size()):
		var player: Dictionary = players[i]
		var entry: HBoxContainer = HBoxContainer.new()

		# 名次
		var rank_label: Label = Label.new()
		rank_label.text = "#%d" % (i + 1)
		rank_label.custom_minimum_size = Vector2(50, 0)
		entry.add_child(rank_label)

		# 玩家名
		var name_lbl: Label = Label.new()
		name_lbl.text = player.get("username", "未知")
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_child(name_lbl)

		# 分數
		var score_lbl: Label = Label.new()
		score_lbl.text = str(player.get("score", 0))
		entry.add_child(score_lbl)

		# 標記本地玩家
		if player.get("id", "") == AuthService.get_user_id():
			name_lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298))

		player_list.add_child(entry)


## 入場動畫
func _play_entrance_animation() -> void:
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# 標題彈入
	if result_title:
		result_title.scale = Vector2(0.5, 0.5)
		var title_tween: Tween = create_tween()
		title_tween.tween_property(result_title, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## 繼續按鈕回調
func _on_continue_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	AudioManager.play_music(AudioManagerClass.MusicTrack.MAIN_MENU)
	continue_pressed.emit()
	# 單人模式返回主選單，多人模式返回大廳
	if _result_data.get("mode", "") == "single":
		GameManager.set_state(GameManager.GameState.IDLE)
		GameManager.current_game_data = {}
		SceneManager.go_to_main_menu()
	else:
		SceneManager.go_to_lobby()


## 再來一局按鈕回調
func _on_rematch_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	rematch_requested.emit()
	# 單人模式：回到難度選擇
	if _result_data.get("mode", "") == "single":
		GameManager.set_state(GameManager.GameState.IDLE)
		GameManager.current_game_data = {}
		SceneManager.change_scene("res://scenes/game/difficulty_select.tscn")
