class_name PlayerData
extends Resource
## 玩家資料模型
## 儲存玩家基本資訊、統計數據

# === 基本資訊 ===
@export var id: String = ""
@export var username: String = ""
@export var display_name: String = ""
@export var avatar_url: String = ""
@export var level: int = 1
@export var experience: int = 0

# === 排名資訊 ===
@export var rank: int = 0
@export var rating: int = 1000  # ELO 分數
@export var season_rank: int = 0

# === 統計數據 ===
@export var total_games: int = 0
@export var wins: int = 0
@export var losses: int = 0
@export var draws: int = 0

# === 貨幣 ===
@export var coins: int = 0
@export var gems: int = 0

# === 線上狀態 ===
@export var is_online: bool = false
@export var is_in_game: bool = false
@export var current_room: String = ""


## 從 API JSON 資料建立
static func from_dict(data: Dictionary) -> PlayerData:
	var player: PlayerData = PlayerData.new()
	player.id = data.get("id", "")
	player.username = data.get("username", "")
	player.display_name = data.get("display_name", "")
	player.avatar_url = data.get("avatar_url", "")
	player.level = data.get("level", 1) as int
	player.experience = data.get("experience", 0) as int
	player.rank = data.get("rank", 0) as int
	player.rating = data.get("rating", 1000) as int
	player.season_rank = data.get("season_rank", 0) as int
	player.total_games = data.get("total_games", 0) as int
	player.wins = data.get("wins", 0) as int
	player.losses = data.get("losses", 0) as int
	player.draws = data.get("draws", 0) as int
	player.coins = data.get("coins", 0) as int
	player.gems = data.get("gems", 0) as int
	player.is_online = data.get("is_online", false) as bool
	player.is_in_game = data.get("is_in_game", false) as bool
	player.current_room = data.get("current_room", "")
	return player


## 轉換為 Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"username": username,
		"display_name": display_name,
		"avatar_url": avatar_url,
		"level": level,
		"experience": experience,
		"rank": rank,
		"rating": rating,
		"season_rank": season_rank,
		"total_games": total_games,
		"wins": wins,
		"losses": losses,
		"draws": draws,
		"coins": coins,
		"gems": gems,
	}


## 計算勝率
func get_win_rate() -> float:
	if total_games == 0:
		return 0.0
	return float(wins) / float(total_games) * 100.0


## 取得顯示名稱（優先 display_name）
func get_display_name() -> String:
	if display_name != "":
		return display_name
	return username


## 取得等級進度（百分比）
func get_level_progress() -> float:
	# 簡單的經驗公式：每級需要 level * 100 經驗
	var needed: int = level * 100
	var current_exp: int = experience % needed
	return float(current_exp) / float(needed) * 100.0
