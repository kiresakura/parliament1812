class_name GameBoard
extends Control
## 遊戲場景邏輯
## 負責回合制狀態機、卡牌出牌、計時器、玩家顯示
## 支援兩種模式：
##   - 多人模式（WebSocket 驅動）
##   - 單人模式（HTTP request-response + mock fallback）

# === 信號 ===
signal phase_changed(phase: GameStateData.Phase)
signal round_started(round_number: int)
@warning_ignore("unused_signal")
signal turn_changed(player_id: String)

# === 節點參考 ===
@onready var player_hand: PlayerHand = $MainVBox/PlayerHand
@onready var voting_panel: VotingPanel = $VotingPanel
@onready var hud: HUD = $HUD
@onready var play_area: Control = $MainVBox/PlayArea
@onready var play_area_label: Label = $MainVBox/PlayArea/PlayAreaLabel
@onready var player_slots: Control = $MainVBox/PlayerSlots
@onready var player_hud_bar: Control = $MainVBox/PlayerHUDBar
@onready var target_select_panel: TargetSelectPanel = $TargetSelectPanel

# === 遊戲狀態 ===
var game_state: GameStateData = GameStateData.new()
var _timer: Timer = null
var _time_remaining: float = 0.0

# === 動效 ===
var _vote_effects: VoteResultEffects = null
var _vote_streak: int = 0  ## 連續通過次數（streak）
const _ImpactRippleScene: PackedScene = preload("res://scenes/game/impact_ripple.tscn")

# === 目標選擇 ===
var _pending_card: Card = null  ## 等待目標選擇的暫存卡牌

# === 模式 ===
var _is_single_player: bool = false
var _is_mock: bool = false  # 離線 mock 模式
var _session_id: String = ""
var _difficulty: String = "normal"
var _is_ai_turn: bool = false

# === 派系 + 四維度 + 遺產（Phase 1 核心循環） ===
var _faction: FactionData = null
var _dimensions: DimensionState = DimensionState.new()
var _legacies: LegacyCollection = LegacyCollection.new()
var _action_points: int = 4
var _max_action_points: int = 4
var _card_pool: Array[Dictionary] = []  ## 抽牌池
var _dimension_hud: DimensionHUD = null


func _ready() -> void:
	print("[GameBoard] _ready() 開始！")
	# 設定本地玩家 ID
	var user_id: String = AuthService.get_user_id()
	game_state.local_player_id = user_id if user_id != "" else "local_player"

	# 建立計時器
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_timer_tick)
	add_child(_timer)

	# 建立投票結果動效管理器
	_vote_effects = VoteResultEffects.new()
	add_child(_vote_effects)

	# 初始隱藏投票面板
	if voting_panel:
		voting_panel.visible = false

	# 判斷遊戲模式
	var game_data: Dictionary = GameManager.current_game_data
	_is_single_player = game_data.get("mode", "") == "single"
	_is_mock = bool(game_data.get("is_mock", false))
	_session_id = str(game_data.get("session_id", ""))
	_difficulty = str(game_data.get("difficulty", "normal"))

	if _is_single_player:
		_setup_single_player()
		_setup_faction_systems()
	else:
		_setup_multiplayer()

	# 連接手牌事件
	if player_hand:
		player_hand.card_played_from_hand.connect(_on_card_played_from_hand)

	# 連接目標選擇事件
	if target_select_panel:
		target_select_panel.target_selected.connect(_on_target_selected)
		target_select_panel.selection_cancelled.connect(_on_target_cancelled)

	# 連接投票事件
	if voting_panel:
		voting_panel.vote_submitted.connect(_on_vote_submitted)

	# 延遲載入初始遊戲狀態（等所有子場景 _ready 完成）
	_load_initial_state.call_deferred()


func _process(delta: float) -> void:
	# 更新計時器顯示
	if _time_remaining > 0:
		_time_remaining -= delta
		_update_timer_display()


# === 公開方法 ===

## 取得目前遊戲狀態
func get_game_state() -> GameStateData:
	return game_state


# === 模式設定 ===

## 設定單人模式
func _setup_single_player() -> void:
	print("[GameBoard] 單人模式（%s / %s）" % [_difficulty, "mock" if _is_mock else "online"])
	# 單人不需要 WebSocket


## 設定多人模式
func _setup_multiplayer() -> void:
	print("[GameBoard] 多人模式")
	# 連接 WebSocket 事件
	WsService.phase_changed.connect(_on_ws_phase_changed)
	WsService.card_played.connect(_on_ws_card_played)
	WsService.vote_received.connect(_on_ws_vote_received)
	WsService.vote_result.connect(_on_ws_vote_result)
	WsService.timer_updated.connect(_on_ws_timer_updated)
	WsService.game_ended.connect(_on_ws_game_ended)
	WsService.turn_changed.connect(_on_ws_turn_changed)
	WsService.hand_updated.connect(_on_ws_hand_updated)
	WsService.reputation_changed.connect(_on_ws_reputation_changed)
	WsService.challenge_event.connect(_on_ws_challenge_event)
	WsService.counter_event.connect(_on_ws_counter_event)
	WsService.skill_used.connect(_on_ws_skill_used)


# ============================================================
# === 派系 + 四維度 + 遺產系統（Phase 1 核心循環） ===
# ============================================================

## 設定派系相關系統
func _setup_faction_systems() -> void:
	var game_data: Dictionary = GameManager.current_game_data
	var faction_id: String = str(game_data.get("selected_faction_id", ""))

	if faction_id == "":
		print("[GameBoard] 無派系資料，跳過派系系統初始化")
		return

	# 載入派系
	_faction = FactionData.get_faction_by_id(faction_id)
	if _faction == null:
		push_warning("[GameBoard] 找不到派系: %s" % faction_id)
		return

	print("[GameBoard] 派系: %s（%s）" % [_faction.faction_name, _faction.playstyle])

	# 初始化四維度
	var dim_data: Dictionary = game_data.get("dimensions", {})
	if not dim_data.is_empty():
		_dimensions.load_from_dict(dim_data)
	else:
		_dimensions.reset()

	# 初始化遺產——加入派系起始遺產
	_legacies.clear()
	if not _faction.starting_legacy.is_empty():
		var starting: LegacyData = LegacyData.from_dict(_faction.starting_legacy)
		_legacies.add_legacy(starting)

	# 計算行動點
	_max_action_points = _dimensions.get_budget_level() + _legacies.get_extra_action_points()
	_action_points = _max_action_points

	# 建立抽牌池
	_card_pool = CardDatabase.build_full_pool(faction_id)

	# 建立四維度 HUD
	_create_dimension_hud()

	# 初始顯示
	_update_dimension_display()


## 建立四維度 HUD（直立模式：放在底部 PlayerHUDBar 內，橫向排列）
func _create_dimension_hud() -> void:
	_dimension_hud = DimensionHUD.new()
	_dimension_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dimension_hud.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if player_hud_bar:
		player_hud_bar.add_child(_dimension_hud)
	else:
		add_child(_dimension_hud)

	# 初始設定
	_dimension_hud.set_dimensions(_dimensions)
	_dimension_hud.update_action_points(_action_points, _max_action_points)


## 更新維度 HUD 顯示
func _update_dimension_display() -> void:
	if _dimension_hud:
		_dimension_hud.update_dimensions(_dimensions)
		_dimension_hud.update_action_points(_action_points, _max_action_points)


## 回合開始時套用遺產被動效果
func _apply_turn_start_legacies() -> void:
	if _faction == null:
		return

	# 計算行動點（基於財政維度 + 遺產加成）
	_max_action_points = _dimensions.get_budget_level() + _legacies.get_extra_action_points()
	_action_points = _max_action_points

	# 套用被動效果
	var applied: Array[Dictionary] = _legacies.apply_passives_to_turn(_dimensions)
	for result: Dictionary in applied:
		var msg: String = "遺產「%s」：%s %+d" % [
			result.get("legacy_name", ""),
			DimensionState.dimension_names.get(str(result.get("target", "")), ""),
			result.get("value", 0),
		]
		if hud:
			hud.show_notification(msg, Color(0.78, 0.66, 0.31))

	_update_dimension_display()

	# 檢查破產
	if _dimensions.is_any_dimension_zero():
		_trigger_dimension_bankruptcy()


## 出牌時消耗行動點並套用卡牌效果
func _apply_card_dimension_effects(card: Card) -> void:
	if _faction == null or card.card_data == null:
		return

	# 消耗行動點
	var cost: int = card.card_data.cost
	if _action_points < cost:
		if hud:
			hud.show_notification("行動點不足！需要 %d 點" % cost, Color(0.8, 0.2, 0.2))
		return

	_action_points -= cost

	# 根據玩家人數縮放效果（4 人基準 1.0x）
	var player_count: int = game_state.players.size()
	var scale: float = _get_player_count_scale(player_count)
	var scaled_effects: Array[Dictionary] = []
	for effect: Dictionary in card.card_data.effects:
		var scaled: Dictionary = effect.duplicate()
		scaled["value"] = int(float(effect.get("value", 0)) * scale)
		scaled_effects.append(scaled)

	# 套用卡牌效果到四維度
	var results: Array[Dictionary] = _dimensions.apply_effects(scaled_effects)
	for result: Dictionary in results:
		if result.get("applied", false):
			var dim_name: String = DimensionState.dimension_names.get(str(result.get("dimension", "")), "")
			var delta: int = result.get("delta", 0) as int
			var sign_str: String = "+" if delta >= 0 else ""
			if hud:
				var color: Color = Color(0.3, 0.9, 0.3) if delta >= 0 else Color(0.9, 0.3, 0.3)
				hud.show_notification("%s %s%d" % [dim_name, sign_str, delta], color)

	_update_dimension_display()

	# 檢查閾值事件
	var threshold_events: Array[Dictionary] = _dimensions.check_threshold_events()
	for event: Dictionary in threshold_events:
		if event.get("type", "") == "bankrupt":
			_trigger_dimension_bankruptcy()
			return
		elif event.get("type", "") in ["danger_low", "danger_high"]:
			if hud:
				hud.show_notification(str(event.get("message", "")), Color(0.8, 0.6, 0.2))


## RESOLUTION 階段：結算四維度變化 + 檢查遺產獲得 + 預算審計
func _resolve_dimension_effects() -> void:
	if _faction == null:
		return

	# 預算審計：根據 treasury 重新計算行動點上限
	var new_budget: int = _dimensions.get_budget_level()
	if new_budget != _max_action_points - _legacies.get_extra_action_points():
		var old_budget: int = _max_action_points
		_max_action_points = new_budget + _legacies.get_extra_action_points()
		if hud:
			if _max_action_points > old_budget:
				hud.show_notification("預算增加！行動點上限 → %d" % _max_action_points, Color(0.3, 0.9, 0.3))
			elif _max_action_points < old_budget:
				hud.show_notification("預算縮減！行動點上限 → %d" % _max_action_points, Color(0.9, 0.3, 0.3))

	# 檢查是否獲得新遺產（法案通過時）
	var vote_counts: Dictionary = game_state.get_vote_counts()
	var yea: int = vote_counts.get(GameStateData.VoteOption.YEA, 0)
	var nay: int = vote_counts.get(GameStateData.VoteOption.NAY, 0)
	if yea > nay and game_state.current_proposal.size() > 0:
		_check_legacy_award()

	_update_dimension_display()


## 檢查是否因法案通過獲得遺產
func _check_legacy_award() -> void:
	# 每 3 回合通過法案可獲得遺產（簡單規則）
	if game_state.current_round % 3 != 0:
		return

	# 根據當前維度狀態生成遺產
	var legacy_candidates: Array[Dictionary] = [
		{
			"id": "legacy_r%d_pop" % game_state.current_round,
			"legacy_name": "民心所向",
			"description": "民意維度每回合 +2",
			"effect": {"type": "passive", "target": "public_opinion", "value": 2},
			"source": "bill_passed",
			"rarity": 0,
		},
		{
			"id": "legacy_r%d_tre" % game_state.current_round,
			"legacy_name": "開源節流",
			"description": "財政維度每回合 +2",
			"effect": {"type": "passive", "target": "treasury", "value": 2},
			"source": "bill_passed",
			"rarity": 0,
		},
		{
			"id": "legacy_r%d_mil" % game_state.current_round,
			"legacy_name": "軍威赫赫",
			"description": "軍事維度每回合 +2",
			"effect": {"type": "passive", "target": "military", "value": 2},
			"source": "bill_passed",
			"rarity": 0,
		},
		{
			"id": "legacy_r%d_dip" % game_state.current_round,
			"legacy_name": "縱橫捭闔",
			"description": "外交維度每回合 +2",
			"effect": {"type": "passive", "target": "diplomacy", "value": 2},
			"source": "bill_passed",
			"rarity": 0,
		},
	]

	var chosen: Dictionary = legacy_candidates[randi() % legacy_candidates.size()]
	var legacy: LegacyData = LegacyData.from_dict(chosen)
	_legacies.add_legacy(legacy)
	if hud:
		hud.show_notification("獲得遺產：%s" % legacy.legacy_name, Color(0.78, 0.66, 0.31))


## 維度破產觸發
func _trigger_dimension_bankruptcy() -> void:
	# 找到歸零的維度
	var bankrupt_dims: Array[String] = []
	for dim_key: String in ["public_opinion", "treasury", "military", "diplomacy"]:
		if _dimensions.get_dimension(dim_key) <= 0:
			bankrupt_dims.append(DimensionState.dimension_names.get(dim_key, dim_key))

	if bankrupt_dims.size() > 0:
		var msg: String = "%s 崩潰！遊戲結束！" % "、".join(bankrupt_dims)
		if hud:
			hud.show_notification(msg, Color(0.9, 0.2, 0.2))

	# 延遲進入 GAME_OVER
	await get_tree().create_timer(1.5).timeout
	_change_phase(GameStateData.Phase.GAME_OVER)


## 檢查出牌行動點是否足夠
func _can_play_card(card: Card) -> bool:
	if _faction == null:
		return true  # 無派系系統時不限制
	if card.card_data == null:
		return true
	return _action_points >= card.card_data.cost


## 根據玩家人數計算效果縮放倍率（4 人為基準 1.0x）
static func _get_player_count_scale(player_count: int) -> float:
	match player_count:
		2: return 1.5
		3: return 1.25
		4: return 1.0
		5: return 0.9
		6: return 0.85
		7: return 0.8
		8: return 0.75
		_: return 1.0


## 從牌池抽牌（替代原本的 mock 抽牌）
func _draw_from_pool(count: int) -> Array[Dictionary]:
	var drawn: Array[Dictionary] = []
	var extra_draw: int = _legacies.get_extra_draw_count() if _faction != null else 0
	var total_draw: int = count + extra_draw

	for i: int in range(total_draw):
		if _card_pool.is_empty():
			break
		var card_dict: Dictionary = CardDatabase.draw_card_from_pool(_card_pool)
		if not card_dict.is_empty():
			drawn.append(card_dict)

	return drawn


# === 狀態機 ===

## 切換遊戲階段
func _change_phase(new_phase: GameStateData.Phase) -> void:
	var old_phase: GameStateData.Phase = game_state.current_phase
	game_state.current_phase = new_phase

	# 更新 HUD
	if hud:
		hud.update_phase(game_state.get_phase_name())

	# 根據階段設定 UI
	match new_phase:
		GameStateData.Phase.PROPOSAL:
			_enter_proposal_phase()
		GameStateData.Phase.DEBATE:
			_enter_debate_phase()
		GameStateData.Phase.VOTING:
			_enter_voting_phase()
		GameStateData.Phase.RESOLUTION:
			_enter_resolution_phase()
		GameStateData.Phase.GAME_OVER:
			_enter_game_over()

	phase_changed.emit(new_phase)
	print("[GameBoard] 階段: %s → %s" % [
		GameStateData.phase_names.get(old_phase, "?"),
		GameStateData.phase_names.get(new_phase, "?"),
	])


## 提案階段
func _enter_proposal_phase() -> void:
	if voting_panel:
		voting_panel.visible = false
	if player_hand:
		player_hand.set_interactable(game_state.is_local_player_turn())
	if play_area_label:
		if _faction != null:
			play_area_label.text = "拖曳卡牌到此處出牌（行動點：%d/%d）" % [_action_points, _max_action_points]
		else:
			play_area_label.text = "拖曳卡牌到此處出牌"
	_start_phase_timer(60.0)

	# 單人模式：如果是 AI 回合，自動處理
	if _is_single_player and not game_state.is_local_player_turn():
		_handle_ai_turn()


## 討論階段
func _enter_debate_phase() -> void:
	if player_hand:
		player_hand.set_interactable(true)
	if play_area_label:
		play_area_label.text = "討論中 — 可使用辯論卡"
	_start_phase_timer(90.0)


## 投票階段
func _enter_voting_phase() -> void:
	if voting_panel:
		voting_panel.visible = true
		voting_panel.reset()
		if game_state.current_proposal.size() > 0:
			voting_panel.set_proposal(game_state.current_proposal.get("name", "議案"))
	if player_hand:
		player_hand.set_interactable(false)
	if play_area_label:
		play_area_label.text = "投票進行中"
	_start_phase_timer(30.0)


## 結算階段
func _enter_resolution_phase() -> void:
	if voting_panel:
		voting_panel.visible = false
	if player_hand:
		player_hand.set_interactable(false)
	if play_area_label:
		play_area_label.text = "結算中..."
	_timer.stop()

	# 結算四維度變化 + 遺產檢查
	if _is_single_player and _faction != null:
		_resolve_dimension_effects()
		# 破產檢查
		if _dimensions.is_any_dimension_zero():
			return  # _trigger_dimension_bankruptcy 會處理 GAME_OVER

	# 單人模式：自動進入下一回合或結束
	if _is_single_player:
		await get_tree().create_timer(2.0).timeout
		_advance_single_player_round()
	else:
		await get_tree().create_timer(2.0).timeout


## 遊戲結束
func _enter_game_over() -> void:
	_timer.stop()
	if player_hand:
		player_hand.set_interactable(false)
	if voting_panel:
		voting_panel.visible = false

	# 判斷勝負
	var local_score: int = game_state.get_player_score(game_state.local_player_id)
	var is_winner: bool = true
	for i: int in range(game_state.players.size()):
		var player: Dictionary = game_state.players[i]
		var pid: String = str(player.get("id", ""))
		if pid != game_state.local_player_id:
			if game_state.get_player_score(pid) >= local_score:
				is_winner = false

	# 設定結果數據
	var result_data: Dictionary = GameManager.current_game_data.duplicate(true)
	result_data["winner_id"] = game_state.local_player_id if is_winner else "ai_opponent"
	result_data["rankings"] = _build_rankings()
	result_data["rewards"] = {"coins": 50 if is_winner else 10, "experience": 30 if is_winner else 10}
	result_data["rating_change"] = 15 if is_winner else -5
	GameManager.current_game_data = result_data
	GameManager.set_state(GameManager.GameState.GAME_OVER)

	# 播放結算音效
	if is_winner:
		AudioManager.play_sfx(AudioManagerClass.SFX.VICTORY)
		AudioManager.play_music(AudioManagerClass.MusicTrack.NONE)
	else:
		AudioManager.play_sfx(AudioManagerClass.SFX.DEFEAT)
		AudioManager.play_music(AudioManagerClass.MusicTrack.GAME_OVER)

	# 延遲後跳轉結算畫面
	await get_tree().create_timer(1.5).timeout
	if is_winner:
		SceneManager.go_to_victory_result()
	else:
		SceneManager.go_to_defeat_result()


## 建立排名數據
func _build_rankings() -> Array:
	var rankings: Array = []
	for i: int in range(game_state.players.size()):
		var player: Dictionary = game_state.players[i]
		var pid: String = str(player.get("id", ""))
		rankings.append({
			"id": pid,
			"username": str(player.get("username", "")),
			"score": game_state.get_player_score(pid),
		})
	# 按分數排序（降序）
	rankings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("score", 0) > b.get("score", 0)
	)
	return rankings


# === 計時器 ===

## 開始階段計時器
func _start_phase_timer(duration: float) -> void:
	_time_remaining = duration
	_timer.start()
	_update_timer_display()


## 計時器每秒回調
func _on_timer_tick() -> void:
	if _time_remaining <= 0:
		_timer.stop()
		# 單人模式：計時器到期自動推進
		if _is_single_player:
			_on_single_player_timer_expired()
		return

	# 緊急提示（最後 10 秒）
	if _time_remaining <= 10.0:
		AudioManager.play_sfx(AudioManagerClass.SFX.TIMER_URGENT)


## 更新計時器顯示
func _update_timer_display() -> void:
	var minutes: int = int(max(_time_remaining, 0.0)) / 60
	var seconds: int = int(max(_time_remaining, 0.0)) % 60
	var time_text: String = "%d:%02d" % [minutes, seconds]
	var urgent: bool = _time_remaining <= 10.0

	if hud:
		hud.update_timer(time_text, urgent)


# === 單人模式邏輯 ===

## 單人模式計時器到期
func _on_single_player_timer_expired() -> void:
	match game_state.current_phase:
		GameStateData.Phase.PROPOSAL:
			# 時間到但沒出牌 → 跳到投票（用第一張手牌）
			if player_hand and player_hand.get_card_count() > 0:
				var first_card: Card = player_hand.cards[0] as Card
				if first_card:
					_play_card_single_player(first_card)
		GameStateData.Phase.DEBATE:
			_change_phase(GameStateData.Phase.VOTING)
		GameStateData.Phase.VOTING:
			# 沒投票 → 自動棄權
			_change_phase(GameStateData.Phase.RESOLUTION)


## 處理 AI 回合（mock 模式）
func _handle_ai_turn() -> void:
	if _is_ai_turn:
		return
	_is_ai_turn = true

	if hud:
		hud.show_notification("AI 正在思考...", Color(0.788, 0.659, 0.298))

	if _is_mock:
		# Mock 模式：AI 延遲後隨機出牌
		await get_tree().create_timer(randf_range(1.0, 2.5)).timeout
		_mock_ai_play_card()
	else:
		# 線上模式：呼叫 API
		var result: Dictionary = await ApiService.single_action(_session_id, {
			"type": "ai_turn",
		})
		if result.get("success", false):
			var data: Dictionary = result.get("data", {})
			game_state.update_from_dict(data)
			_sync_ui_from_state()
		else:
			# API 失敗 → fallback 到 mock
			_mock_ai_play_card()

	_is_ai_turn = false


## Mock AI 出牌
func _mock_ai_play_card() -> void:
	var ai_card_names: Array[String] = ["反對提案", "軍費削減", "外交施壓", "議事阻撓", "秘密協商"]
	var card_name: String = ai_card_names[randi() % ai_card_names.size()]

	# 顯示 AI 出牌通知
	if hud:
		var ai_name: String = "AI"
		for i: int in range(game_state.players.size()):
			var p: Dictionary = game_state.players[i]
			if p.get("is_ai", false):
				ai_name = str(p.get("username", "AI"))
				break
		hud.show_card_played(ai_name, card_name)

	AudioManager.play_sfx(AudioManagerClass.SFX.CARD_PLAY)

	# 設定為提案
	game_state.current_proposal = {"name": card_name, "player": "ai_opponent"}

	# AI 出完牌 → 進入辯論階段
	await get_tree().create_timer(1.0).timeout
	_change_phase(GameStateData.Phase.DEBATE)


## 單人模式出牌
func _play_card_single_player(card: Card) -> void:
	# 行動點檢查（派系系統啟用時）
	if _faction != null and not _can_play_card(card):
		if hud:
			hud.show_notification("行動點不足！需要 %d 點，剩餘 %d 點" % [card.card_data.cost, _action_points], Color(0.8, 0.2, 0.2))
		return

	if player_hand:
		player_hand.set_interactable(false)

	# 套用卡牌的四維度效果（派系系統啟用時）
	if _faction != null:
		_apply_card_dimension_effects(card)

	# 設定為當前提案
	if card.card_data:
		game_state.current_proposal = card.card_data.to_dict()
	else:
		game_state.current_proposal = {"name": "提案", "id": card.card_id}

	# 從手牌移除
	if player_hand:
		player_hand.remove_card(card)

	AudioManager.play_sfx(AudioManagerClass.SFX.CARD_PLAY)

	# 出牌落地波紋動效
	if play_area:
		var ripple: ImpactRipple = _ImpactRippleScene.instantiate() as ImpactRipple
		ripple.position = play_area.global_position + play_area.size / 2.0
		add_child(ripple)
		ripple.play_ripple()

	# 顯示出牌通知
	var player_name: String = str(AuthService.current_user.get("username", "你"))
	var card_name: String = game_state.current_proposal.get("name", "卡牌")
	if hud:
		hud.show_card_played(player_name, card_name)

	# 更新 play area 顯示
	if play_area_label:
		play_area_label.text = "已提出：%s" % card_name

	if _is_mock:
		# Mock：加分 + 進入投票
		var power: int = int(game_state.current_proposal.get("power", 1))
		var current_score: int = int(game_state.scores.get(game_state.local_player_id, 0))
		game_state.scores[game_state.local_player_id] = current_score + power
		_update_scores_display()

		await get_tree().create_timer(1.0).timeout
		_change_phase(GameStateData.Phase.VOTING)
	else:
		# 線上模式：呼叫 API
		var result: Dictionary = await ApiService.single_action(_session_id, {
			"type": "play_card",
			"card_id": card.card_id,
		})
		if result.get("success", false):
			game_state.update_from_dict(result.get("data", {}))
			_sync_ui_from_state()
		else:
			# Fallback
			await get_tree().create_timer(1.0).timeout
			_change_phase(GameStateData.Phase.VOTING)


## 推進單人模式回合
func _advance_single_player_round() -> void:
	# 清除提案
	game_state.current_proposal = {}
	game_state.votes.clear()

	# 下一回合
	game_state.current_round += 1
	if hud:
		hud.update_round(game_state.current_round, game_state.max_rounds)
	round_started.emit(game_state.current_round)

	# 檢查是否遊戲結束
	if game_state.current_round > game_state.max_rounds:
		_change_phase(GameStateData.Phase.GAME_OVER)
		return

	# 回合開始：套用遺產被動效果 + 重置行動點
	if _faction != null:
		_apply_turn_start_legacies()
		# 破產檢查
		if _dimensions.is_any_dimension_zero():
			return  # _trigger_dimension_bankruptcy 會處理

	# Mock 模式：補抽牌
	if _is_mock and player_hand:
		if player_hand.get_card_count() < 5:
			var new_cards: Array[Dictionary]
			if _faction != null and not _card_pool.is_empty():
				# 使用派系牌池抽牌
				new_cards = _draw_from_pool(1)
			else:
				# 原始 mock 抽牌
				new_cards = _generate_mock_draw_cards(1)
			for i: int in range(new_cards.size()):
				var card_data: CardData = CardData.from_dict(new_cards[i])
				if card_data:
					await player_hand.add_card(card_data, true)

	# 交替先手：奇數回合玩家先手，偶數回合 AI 先手
	if game_state.current_round % 2 == 1:
		game_state.current_player_index = 0  # 玩家
	else:
		game_state.current_player_index = 1  # AI

	# 進入提案階段
	_change_phase(GameStateData.Phase.PROPOSAL)


## 生成 mock 抽牌
func _generate_mock_draw_cards(count: int) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var names: Array[String] = ["稅制改革", "軍備提案", "外交交涉", "經濟振興", "民意調查", "預算審查"]
	var types: Array[int] = [0, 1, 2, 3, 4]
	for i: int in range(count):
		cards.append({
			"id": "draw_%d_%d" % [game_state.current_round, randi()],
			"name": names[randi() % names.size()],
			"description": "回合 %d 抽到的新卡。" % game_state.current_round,
			"type": types[randi() % types.size()],
			"rarity": randi() % 3,
			"cost": randi_range(1, 3),
			"power": randi_range(1, 4),
			"influence": randi_range(1, 3),
			"effects": [],
		})
	return cards


## 單人模式投票處理
func _handle_single_player_vote(vote: GameStateData.VoteOption) -> void:
	game_state.votes[game_state.local_player_id] = vote

	# AI 也投票（mock）
	if _is_mock:
		await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
		var ai_vote: GameStateData.VoteOption
		# AI 投票邏輯：根據難度
		var rand: float = randf()
		match _difficulty:
			"easy":
				ai_vote = GameStateData.VoteOption.YEA if rand < 0.6 else GameStateData.VoteOption.NAY
			"normal":
				ai_vote = GameStateData.VoteOption.YEA if rand < 0.4 else GameStateData.VoteOption.NAY
			"hard":
				ai_vote = GameStateData.VoteOption.YEA if rand < 0.25 else GameStateData.VoteOption.NAY
			_:
				ai_vote = GameStateData.VoteOption.YEA if rand < 0.4 else GameStateData.VoteOption.NAY

		game_state.votes["ai_opponent"] = ai_vote
		if voting_panel:
			voting_panel.update_vote_count(game_state.get_vote_counts())

		if hud:
			var ai_name: String = "AI"
			for i: int in range(game_state.players.size()):
				var p: Dictionary = game_state.players[i]
				if p.get("is_ai", false):
					ai_name = str(p.get("username", "AI"))
					break
			hud.show_vote_notification(ai_name)

		AudioManager.play_sfx(AudioManagerClass.SFX.VOTE_CAST)

		# 投票結果判定
		await get_tree().create_timer(1.0).timeout
		var counts: Dictionary = game_state.get_vote_counts()
		var yea_count: int = counts.get(GameStateData.VoteOption.YEA, 0)
		var nay_count: int = counts.get(GameStateData.VoteOption.NAY, 0)
		var passed: bool = yea_count > nay_count

		if voting_panel:
			voting_panel.show_result(passed, counts)

		# 加分
		if passed:
			var proposer_id: String = str(game_state.current_proposal.get("player", game_state.local_player_id))
			if proposer_id == "" or proposer_id == game_state.local_player_id:
				proposer_id = game_state.local_player_id
			var current: int = int(game_state.scores.get(proposer_id, 0))
			game_state.scores[proposer_id] = current + int(game_state.current_proposal.get("power", 1))

		_update_scores_display()

		# 播放投票結果動效（await 完成後才進入 RESOLUTION）
		await get_tree().create_timer(0.5).timeout
		if passed:
			_vote_streak += 1
			_vote_effects.play_pass_effect(_vote_streak)
			await _vote_effects.effect_finished
		else:
			_vote_streak = 0
			_vote_effects.play_fail_effect()
			await _vote_effects.effect_finished

		_change_phase(GameStateData.Phase.RESOLUTION)
	else:
		# 線上模式
		var vote_str: String = ""
		match vote:
			GameStateData.VoteOption.YEA:
				vote_str = "yea"
			GameStateData.VoteOption.NAY:
				vote_str = "nay"
			GameStateData.VoteOption.ABSTAIN:
				vote_str = "abstain"

		var result: Dictionary = await ApiService.single_action(_session_id, {
			"type": "vote",
			"vote": vote_str,
		})
		if result.get("success", false):
			game_state.update_from_dict(result.get("data", {}))
			_sync_ui_from_state()


## 更新分數顯示（portrait 模式：PlayerSlots 為 HBoxContainer，水平排列）
func _update_scores_display() -> void:
	# 更新 PlayerSlots
	if player_slots:
		# 清除舊的 slot（保留 SlotsTitle）
		var children: Array[Node] = []
		for child: Node in player_slots.get_children():
			children.append(child)
		for child: Node in children:
			if child.name != "SlotsTitle":
				child.queue_free()

		# 重建 slot（每個玩家用 VBox：名字+分數 堆疊）
		for i: int in range(game_state.players.size()):
			var player: Dictionary = game_state.players[i]
			var pid: String = str(player.get("id", ""))
			var slot: VBoxContainer = VBoxContainer.new()
			slot.alignment = BoxContainer.ALIGNMENT_CENTER
			slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var name_lbl: Label = Label.new()
			name_lbl.text = str(player.get("username", "???"))
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.add_theme_font_size_override("font_size", 14)
			if pid == game_state.local_player_id:
				name_lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298))
			else:
				name_lbl.add_theme_color_override("font_color", Color(0.91, 0.835, 0.718))
			slot.add_child(name_lbl)

			var score_lbl: Label = Label.new()
			score_lbl.text = str(game_state.scores.get(pid, 0))
			score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			score_lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298))
			score_lbl.add_theme_font_size_override("font_size", 18)
			slot.add_child(score_lbl)

			player_slots.add_child(slot)


## 同步 UI 和 game_state
func _sync_ui_from_state() -> void:
	# 同步階段
	_change_phase(game_state.current_phase)

	# 同步回合
	if hud:
		hud.update_round(game_state.current_round, game_state.max_rounds)

	# 同步手牌
	if player_hand and game_state.hand_cards.size() > 0:
		await player_hand.set_hand(game_state.hand_cards)

	# 同步分數
	_update_scores_display()


# === WebSocket 事件處理（多人模式）===

## 伺服器 phase string → GameStateData.Phase
func _parse_server_phase(phase_str: String) -> GameStateData.Phase:
	match phase_str:
		"waiting":
			return GameStateData.Phase.WAITING
		"player_turn":
			return GameStateData.Phase.PROPOSAL  # player_turn 對應提案/行動階段
		"voting":
			return GameStateData.Phase.VOTING
		"result":
			return GameStateData.Phase.RESOLUTION
		"finished":
			return GameStateData.Phase.GAME_OVER
		_:
			push_warning("[GameBoard] 未知階段: %s" % phase_str)
			return GameStateData.Phase.WAITING


## phase_changed: {type, phase, duration_secs, round}
func _on_ws_phase_changed(data: Dictionary) -> void:
	var phase_str: String = str(data.get("phase", ""))
	var new_phase: GameStateData.Phase = _parse_server_phase(phase_str)

	# 更新回合
	var round_num: int = int(data.get("round", game_state.current_round))
	if round_num != game_state.current_round:
		game_state.current_round = round_num
		if hud:
			hud.update_round(game_state.current_round, game_state.max_rounds)
		round_started.emit(game_state.current_round)

	# 更新計時器
	var duration: int = int(data.get("duration_secs", 0))
	if duration > 0:
		_start_phase_timer(float(duration))

	_change_phase(new_phase)


## card_used: {type, player_id, player_name, card_id, card_name, target_id, target_name, effect_description, value}
func _on_ws_card_played(data: Dictionary) -> void:
	var player_name: String = str(data.get("player_name", ""))
	var card_name: String = str(data.get("card_name", "卡牌"))
	var target_name: String = str(data.get("target_name", ""))
	var effect_desc: String = str(data.get("effect_description", ""))
	var value: int = int(data.get("value", 0))

	var msg: String = "%s 打出了「%s」" % [player_name, card_name]
	if target_name != "":
		msg += " → %s" % target_name
	if effect_desc != "":
		msg += "：%s" % effect_desc

	if hud:
		hud.show_notification(msg, Color(0.788, 0.659, 0.298))
		if value != 0:
			var val_color: Color = Color(0.9, 0.3, 0.3) if value < 0 else Color(0.3, 0.9, 0.3)
			hud.show_notification("效果: %s%d" % ["+" if value > 0 else "", value], val_color)

	AudioManager.play_sfx(AudioManagerClass.SFX.CARD_PLAY)

	# 出牌落地波紋動效
	if play_area:
		var ripple: ImpactRipple = _ImpactRippleScene.instantiate() as ImpactRipple
		ripple.position = play_area.global_position + play_area.size / 2.0
		add_child(ripple)
		ripple.play_ripple()


## vote_received: {type, player_id, votes_count, total_players}
func _on_ws_vote_received(data: Dictionary) -> void:
	var votes_count: int = int(data.get("votes_count", 0))
	var total_players: int = int(data.get("total_players", 0))

	if hud:
		hud.show_notification("投票進度: %d/%d" % [votes_count, total_players], Color(0.78, 0.66, 0.31))

	AudioManager.play_sfx(AudioManagerClass.SFX.VOTE_CAST)


## vote_result: {type, votes, winner}
func _on_ws_vote_result(data: Dictionary) -> void:
	var winner: String = str(data.get("winner", ""))
	var votes_dict: Dictionary = data.get("votes", {})

	if hud:
		hud.show_notification("投票結果: 選項 %s 獲勝" % winner.to_upper(), Color(0.78, 0.66, 0.31))

	print("[GameBoard] 投票結果: winner=%s, votes=%s" % [winner, str(votes_dict)])


## timer_update: {type, remaining_secs}
func _on_ws_timer_updated(data: Dictionary) -> void:
	_time_remaining = float(data.get("remaining_secs", 0.0))
	_update_timer_display()


## game_result: {type, winner_faction, votes, rankings}
func _on_ws_game_ended(data: Dictionary) -> void:
	# 儲存結果數據到 GameManager
	GameManager.current_game_data["winner_faction"] = data.get("winner_faction", "")
	GameManager.current_game_data["votes"] = data.get("votes", {})
	GameManager.current_game_data["rankings"] = data.get("rankings", [])
	_change_phase(GameStateData.Phase.GAME_OVER)


## turn_changed: {type, current_player_id, current_player_name, action_points, turn_order}
func _on_ws_turn_changed(data: Dictionary) -> void:
	var current_player_id: String = str(data.get("current_player_id", ""))
	var current_player_name: String = str(data.get("current_player_name", ""))
	var action_pts: int = int(data.get("action_points", 0))

	if hud:
		if current_player_id == game_state.local_player_id:
			hud.show_notification("輪到你行動！（行動點: %d）" % action_pts, Color(0.3, 0.9, 0.3))
		else:
			hud.show_notification("輪到 %s 行動" % current_player_name, Color(0.78, 0.66, 0.31))

	if player_hand:
		player_hand.set_interactable(current_player_id == game_state.local_player_id)

	turn_changed.emit(current_player_id)


## hand_updated: {type, cards: [{id, name, description, card_type, ...}]}
func _on_ws_hand_updated(data: Dictionary) -> void:
	var cards: Array = data.get("cards", [])
	if player_hand and cards.size() > 0:
		var hand_data: Array[Dictionary] = []
		for c: Variant in cards:
			if c is Dictionary:
				hand_data.append(c as Dictionary)
		game_state.hand_cards = hand_data
		await player_hand.set_hand(hand_data)


## reputation_changed: {type, player_id, new_reputation, change, reason}
func _on_ws_reputation_changed(data: Dictionary) -> void:
	var player_id: String = str(data.get("player_id", ""))
	var new_rep: int = int(data.get("new_reputation", 0))
	var change_val: int = int(data.get("change", 0))
	var reason: String = str(data.get("reason", ""))

	# 更新本地玩家數據
	for i: int in range(game_state.players.size()):
		if str(game_state.players[i].get("id", "")) == player_id:
			game_state.players[i]["reputation"] = new_rep
			break

	if hud:
		var sign_str: String = "+" if change_val > 0 else ""
		var color: Color = Color(0.3, 0.9, 0.3) if change_val > 0 else Color(0.9, 0.3, 0.3)
		hud.show_notification("聲望 %s%d（%s）" % [sign_str, change_val, reason], color)


## challenge_event: {type, attacker_id, attacker_name, target_id, target_name, damage, countered}
func _on_ws_challenge_event(data: Dictionary) -> void:
	var attacker_name: String = str(data.get("attacker_name", ""))
	var target_name: String = str(data.get("target_name", ""))
	var damage: int = int(data.get("damage", 0))
	var countered: bool = data.get("countered", false)

	if hud:
		if countered:
			hud.show_notification("%s 質詢 %s 被反駁！" % [attacker_name, target_name], Color(0.78, 0.66, 0.31))
		else:
			hud.show_notification("%s 質詢 %s，造成 %d 傷害！" % [attacker_name, target_name, damage], Color(0.9, 0.3, 0.3))

	AudioManager.play_sfx(AudioManagerClass.SFX.CARD_PLAY)


## counter_event: {type, defender_id, defender_name, damage_blocked}
func _on_ws_counter_event(data: Dictionary) -> void:
	var defender_name: String = str(data.get("defender_name", ""))
	var damage_blocked: int = int(data.get("damage_blocked", 0))

	if hud:
		hud.show_notification("%s 反駁成功！抵消 %d 傷害" % [defender_name, damage_blocked], Color(0.3, 0.9, 0.3))


## skill_used: {type, player_id, player_name, skill_name, target_id, target_name, effect_description}
func _on_ws_skill_used(data: Dictionary) -> void:
	var player_name: String = str(data.get("player_name", ""))
	var skill_name: String = str(data.get("skill_name", ""))
	var effect: String = str(data.get("effect_description", ""))

	if hud:
		hud.show_notification("%s 使用技能「%s」：%s" % [player_name, skill_name, effect], Color(0.78, 0.66, 0.31))


# === 本地事件處理 ===

func _on_card_played_from_hand(card: Card) -> void:
	if _is_single_player:
		# 行動點預檢（避免進入出牌流程後才報錯）
		if _faction != null and not _can_play_card(card):
			if hud:
				hud.show_notification("行動點不足！", Color(0.8, 0.2, 0.2))
			return
		_play_card_single_player(card)
	else:
		# 多人模式：檢查是否需要目標
		var card_data: CardData = card.card_data
		if card_data and card_data.requires_target():
			_pending_card = card
			if target_select_panel:
				target_select_panel.show_targets(card, game_state.players, game_state.local_player_id)
			return
		# 無需目標：直接發送
		_send_play_card(card, "")


## 多人模式：發送出牌到伺服器（抽取重複邏輯）
func _send_play_card(card: Card, target_id: String) -> void:
	WsService.send_play_card(card.card_id, target_id)
	if player_hand:
		player_hand.remove_card(card)
	AudioManager.play_sfx(AudioManagerClass.SFX.CARD_PLAY)

	# 出牌落地波紋動效
	if play_area:
		var ripple: ImpactRipple = _ImpactRippleScene.instantiate() as ImpactRipple
		ripple.position = play_area.global_position + play_area.size / 2.0
		add_child(ripple)
		ripple.play_ripple()


## 目標選擇完成
func _on_target_selected(player_id: String) -> void:
	if _pending_card:
		_send_play_card(_pending_card, player_id)
		_pending_card = null
	if target_select_panel:
		target_select_panel.visible = false


## 目標選擇取消
func _on_target_cancelled() -> void:
	_pending_card = null
	if target_select_panel:
		target_select_panel.visible = false


func _on_vote_submitted(vote: GameStateData.VoteOption) -> void:
	if _is_single_player:
		_handle_single_player_vote(vote)
	else:
		# Server expects VoteChoice: "a", "b", "c"
		var vote_str: String = ""
		match vote:
			GameStateData.VoteOption.YEA:
				vote_str = "a"
			GameStateData.VoteOption.NAY:
				vote_str = "b"
			GameStateData.VoteOption.ABSTAIN:
				vote_str = "c"
		WsService.send_vote(vote_str)
		AudioManager.play_sfx(AudioManagerClass.SFX.VOTE_CAST)


## 載入初始遊戲狀態（由 call_deferred 呼叫，確保子場景已就緒）
func _load_initial_state() -> void:
	var game_data: Dictionary = GameManager.current_game_data
	if game_data.is_empty():
		print("[GameBoard] 無遊戲數據")
		return

	# 從 GameManager 取得遊戲資料
	game_state.update_from_dict(game_data)

	# 設定階段（先設定 UI 再設定手牌）
	_change_phase(game_state.current_phase)

	# 更新回合顯示
	if hud:
		hud.update_round(game_state.current_round, game_state.max_rounds)

	# 更新玩家分數
	_update_scores_display()

	# 設定手牌（最後做，因為有 await 動畫）
	if player_hand and game_state.hand_cards.size() > 0:
		await player_hand.set_hand(game_state.hand_cards)
	else:
		print("[GameBoard] 無手牌數據")
