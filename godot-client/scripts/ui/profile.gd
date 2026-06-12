class_name ProfileScreen
extends Control
## 個人檔案介面
## 顯示頭像、用戶名、ELO 段位、戰績統計

# === 節點參考 ===
@onready var avatar_rect: TextureRect = $ScrollContainer/VBox/TopSection/AvatarRect
@onready var username_label: Label = $ScrollContainer/VBox/TopSection/InfoBox/UsernameLabel
@onready var rank_label: Label = $ScrollContainer/VBox/TopSection/InfoBox/RankLabel
@onready var elo_label: Label = $ScrollContainer/VBox/TopSection/InfoBox/EloLabel
@onready var wins_label: Label = $ScrollContainer/VBox/StatsBox/WinsLabel
@onready var losses_label: Label = $ScrollContainer/VBox/StatsBox/LossesLabel
@onready var winrate_label: Label = $ScrollContainer/VBox/StatsBox/WinrateLabel
@onready var total_games_label: Label = $ScrollContainer/VBox/StatsBox/TotalGamesLabel
@onready var back_button: Button = $ScrollContainer/VBox/BackButton

# === 狀態 ===
var _profile_data: Dictionary = {}


func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	_load_profile()


# === 公開方法 ===

## 設定個人資料
func set_profile(data: Dictionary) -> void:
	_profile_data = data
	_update_display()


# === 內部方法 ===

## 從 API 載入個人資料
func _load_profile() -> void:
	var result: Dictionary = await ApiService.get_profile()
	if result.get("success", false):
		_profile_data = result.get("data", {})
		_update_display()


## 更新介面顯示
func _update_display() -> void:
	if _profile_data.is_empty():
		return

	if username_label:
		username_label.text = _profile_data.get("username", "未知用戶")

	var elo: int = _profile_data.get("elo", 1000) as int
	if elo_label:
		elo_label.text = "ELO: %d" % elo
	if rank_label:
		rank_label.text = _get_rank_name(elo)

	var wins: int = _profile_data.get("wins", 0) as int
	var losses: int = _profile_data.get("losses", 0) as int
	var total: int = wins + losses

	if wins_label:
		wins_label.text = "勝利: %d" % wins
	if losses_label:
		losses_label.text = "敗北: %d" % losses
	if total_games_label:
		total_games_label.text = "總場次: %d" % total
	if winrate_label:
		var rate: float = (float(wins) / float(total) * 100.0) if total > 0 else 0.0
		winrate_label.text = "勝率: %.1f%%" % rate


## 取得段位名稱
func _get_rank_name(elo: int) -> String:
	if elo >= 2000:
		return "🏛️ 議長"
	elif elo >= 1800:
		return "⚜️ 元老院"
	elif elo >= 1600:
		return "🎖️ 資深議員"
	elif elo >= 1400:
		return "📜 議員"
	elif elo >= 1200:
		return "📋 見習議員"
	else:
		return "🪶 新進議員"


## 返回按鈕回調
func _on_back_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	SceneManager.go_to_lobby()
