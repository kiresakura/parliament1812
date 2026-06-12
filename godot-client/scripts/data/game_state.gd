class_name GameStateData
extends Resource
## 遊戲狀態模型
## 管理一場遊戲的完整狀態

# === 遊戲階段列舉 ===
enum Phase {
	WAITING,    # 等待玩家
	PROPOSAL,   # 提案階段
	DEBATE,     # 討論階段
	VOTING,     # 投票階段
	RESOLUTION, # 結算階段
	GAME_OVER,  # 遊戲結束
}

# === 投票選項 ===
enum VoteOption {
	NONE,
	YEA,    # 贊成
	NAY,    # 反對
	ABSTAIN,# 棄權
}

# === 遊戲狀態 ===
@export var session_id: String = ""
@export var room_code: String = ""
@export var current_phase: Phase = Phase.WAITING
@export var current_round: int = 0
@export var max_rounds: int = 10
@export var time_remaining: float = 0.0

# === 玩家列表 ===
@export var players: Array[Dictionary] = []
@export var current_player_index: int = -1
@export var local_player_id: String = ""

# === 提案相關 ===
@export var current_proposal: Dictionary = {}
@export var proposal_player_id: String = ""

# === 投票相關 ===
@export var votes: Dictionary = {}  # player_id -> VoteOption
@export var vote_results: Dictionary = {}

# === 手牌 ===
@export var hand_cards: Array[Dictionary] = []
@export var played_cards: Array[Dictionary] = []

# === 分數 ===
@export var scores: Dictionary = {}  # player_id -> score

# === 階段名稱映射 ===
static var phase_names: Dictionary = {
	Phase.WAITING: "等待中",
	Phase.PROPOSAL: "提案",
	Phase.DEBATE: "討論",
	Phase.VOTING: "投票",
	Phase.RESOLUTION: "結算",
	Phase.GAME_OVER: "遊戲結束",
}

# === 投票名稱映射 ===
static var vote_names: Dictionary = {
	VoteOption.NONE: "未投票",
	VoteOption.YEA: "贊成",
	VoteOption.NAY: "反對",
	VoteOption.ABSTAIN: "棄權",
}


## 從 API JSON 資料更新狀態
func update_from_dict(data: Dictionary) -> void:
	if data.has("session_id"):
		session_id = str(data["session_id"])
	if data.has("room_code"):
		room_code = str(data["room_code"])
	if data.has("phase"):
		current_phase = int(data["phase"]) as Phase
	if data.has("round"):
		current_round = int(data["round"])
	if data.has("max_rounds"):
		max_rounds = int(data["max_rounds"])
	if data.has("time_remaining"):
		time_remaining = float(data["time_remaining"])
	if data.has("players"):
		# 安全轉換為 Array[Dictionary]，避免 typed array 賦值 crash
		players.clear()
		var raw_players: Array = data["players"]
		for p: Variant in raw_players:
			if p is Dictionary:
				players.append(p as Dictionary)
	if data.has("current_player_index"):
		current_player_index = int(data["current_player_index"])
	if data.has("proposal"):
		current_proposal = data["proposal"] as Dictionary
	if data.has("proposal_player_id"):
		proposal_player_id = str(data["proposal_player_id"])
	if data.has("votes"):
		votes = data["votes"] as Dictionary
	if data.has("vote_results"):
		vote_results = data["vote_results"] as Dictionary
	if data.has("hand"):
		# 安全轉換為 Array[Dictionary]，避免 typed array 賦值 crash
		hand_cards.clear()
		var raw_hand: Array = data["hand"]
		for c: Variant in raw_hand:
			if c is Dictionary:
				hand_cards.append(c as Dictionary)
	if data.has("played_cards"):
		# 安全轉換為 Array[Dictionary]
		played_cards.clear()
		var raw_played: Array = data["played_cards"]
		for c: Variant in raw_played:
			if c is Dictionary:
				played_cards.append(c as Dictionary)
	if data.has("scores"):
		scores = data["scores"] as Dictionary


## 取得目前階段名稱
func get_phase_name() -> String:
	return phase_names.get(current_phase, "未知")


## 是否輪到本地玩家
func is_local_player_turn() -> bool:
	if current_player_index < 0 or current_player_index >= players.size():
		return false
	var current_p: Dictionary = players[current_player_index]
	return current_p.get("id", "") == local_player_id


## 取得本地玩家資料
func get_local_player() -> Dictionary:
	for player: Dictionary in players:
		if player.get("id", "") == local_player_id:
			return player
	return {}


## 取得玩家分數
func get_player_score(player_id: String) -> int:
	return int(scores.get(player_id, 0))


## 本地玩家是否已投票
func has_local_player_voted() -> bool:
	return votes.has(local_player_id) and votes[local_player_id] != VoteOption.NONE


## 取得投票統計
func get_vote_counts() -> Dictionary:
	var counts: Dictionary = {
		VoteOption.YEA: 0,
		VoteOption.NAY: 0,
		VoteOption.ABSTAIN: 0,
	}
	for raw_vote: Variant in votes.values():
		var vote_val: int = int(raw_vote)
		if counts.has(vote_val):
			counts[vote_val] += 1
	return counts


## 遊戲是否結束
func is_game_over() -> bool:
	return current_phase == Phase.GAME_OVER


## 重置狀態
func reset() -> void:
	session_id = ""
	room_code = ""
	current_phase = Phase.WAITING
	current_round = 0
	time_remaining = 0.0
	players.clear()
	current_player_index = -1
	current_proposal = {}
	proposal_player_id = ""
	votes.clear()
	vote_results = {}
	hand_cards.clear()
	played_cards.clear()
	scores.clear()
