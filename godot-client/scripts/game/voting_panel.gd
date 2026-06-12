class_name VotingPanel
extends PanelContainer
## 投票介面邏輯
## 負責投票按鈕、倒數計時、票數顯示、MOTION_SPEC 動效

# === 信號 ===
signal vote_submitted(vote: GameStateData.VoteOption)
@warning_ignore("unused_signal")
signal vote_changed(vote: GameStateData.VoteOption)
signal vote_result_ready(passed: bool, streak: int)

# === 節點參考 ===
@onready var title_label: Label = $VBox/TitleLabel
@onready var proposal_label: Label = $VBox/ProposalLabel
@onready var yea_button: Button = $VBox/ButtonBox/YeaButton
@onready var nay_button: Button = $VBox/ButtonBox/NayButton
@onready var abstain_button: Button = $VBox/ButtonBox/AbstainButton
@onready var yea_count: Label = $VBox/CountBox/YeaCount
@onready var nay_count: Label = $VBox/CountBox/NayCount
@onready var abstain_count: Label = $VBox/CountBox/AbstainCount
@onready var status_label: Label = $VBox/StatusLabel

# === 狀態 ===
var _current_vote: GameStateData.VoteOption = GameStateData.VoteOption.NONE
var _has_voted: bool = false
var _proposal_text: String = ""

# === 動效狀態 ===
var _vote_tween: Tween
var _count_tween: Tween
var _shake_tween: Tween
var _is_counting: bool = false
var _pending_abstain: int = 0

# === MOTION_SPEC 常數 ===
const BUTTON_HOVER_SCALE := Vector2(1.03, 1.03)
const BUTTON_PRESS_SCALE := Vector2(0.97, 0.97)
const BUTTON_REST_SCALE := Vector2.ONE
const VOTE_PRESS_SCALE := Vector2(0.95, 0.95)

const HOVER_DURATION := 0.08  # 80ms
const PRESS_DURATION := 0.05  # 50ms
const RELEASE_DURATION := 0.08  # 80ms
const CONFIRM_DURATION := 0.08  # 80ms

const COUNT_TICK_INTERVAL := 0.05  # 50ms per digit jump
const COUNT_TOTAL_DURATION := 0.7  # 700ms counting (T+100 to T+800)

const SHAKE_OFFSET := 2.0  # ±2px
const SHAKE_COUNT := 3
const SHAKE_DURATION := 0.1  # 100ms total for 3 shakes

const GOLD_FLASH_COLOR := Color(1.0, 0.84, 0.0, 1.0)  # 金色


func _ready() -> void:
	# 連接按鈕信號
	if yea_button:
		yea_button.pressed.connect(_on_yea_pressed)
		_setup_button_micro_motion(yea_button)
	if nay_button:
		nay_button.pressed.connect(_on_nay_pressed)
		_setup_button_micro_motion(nay_button)
	if abstain_button:
		abstain_button.pressed.connect(_on_abstain_pressed)
		_setup_button_micro_motion(abstain_button)


# === 公開方法 ===

## 設定提案內容
func set_proposal(text: String) -> void:
	_proposal_text = text
	if proposal_label:
		proposal_label.text = text


## 重置投票面板
func reset() -> void:
	_current_vote = GameStateData.VoteOption.NONE
	_has_voted = false
	_enable_buttons(true)
	_clear_button_styles()
	update_vote_count({
		GameStateData.VoteOption.YEA: 0,
		GameStateData.VoteOption.NAY: 0,
		GameStateData.VoteOption.ABSTAIN: 0,
	})
	if status_label:
		status_label.text = "請投下你的一票"


## 更新票數顯示
func update_vote_count(counts: Dictionary) -> void:
	if yea_count:
		yea_count.text = "贊成: %d" % counts.get(GameStateData.VoteOption.YEA, 0)
	if nay_count:
		nay_count.text = "反對: %d" % counts.get(GameStateData.VoteOption.NAY, 0)
	if abstain_count:
		abstain_count.text = "棄權: %d" % counts.get(GameStateData.VoteOption.ABSTAIN, 0)


## 顯示投票結果
func show_result(passed: bool, counts: Dictionary) -> void:
	update_vote_count(counts)
	_enable_buttons(false)
	if status_label:
		if passed:
			status_label.text = "✓ 議案通過"
			status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			status_label.text = "✗ 議案否決"
			status_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))


## 鎖定投票（時間到）
func lock_votes() -> void:
	_enable_buttons(false)
	if not _has_voted:
		if status_label:
			status_label.text = "投票時間結束"


# === 內部方法 ===

## 贊成按鈕回調
func _on_yea_pressed() -> void:
	_submit_vote(GameStateData.VoteOption.YEA)


## 反對按鈕回調
func _on_nay_pressed() -> void:
	_submit_vote(GameStateData.VoteOption.NAY)


## 棄權按鈕回調
func _on_abstain_pressed() -> void:
	_submit_vote(GameStateData.VoteOption.ABSTAIN)


## 提交投票
func _submit_vote(vote: GameStateData.VoteOption) -> void:
	_current_vote = vote
	_has_voted = true
	_enable_buttons(false)
	_highlight_selected(vote)

	if status_label:
		status_label.text = "已投票: %s" % GameStateData.vote_names.get(vote, "")

	vote_submitted.emit(vote)


## 啟用/停用按鈕
func _enable_buttons(enabled: bool) -> void:
	if yea_button:
		yea_button.disabled = not enabled
	if nay_button:
		nay_button.disabled = not enabled
	if abstain_button:
		abstain_button.disabled = not enabled


## 清除按鈕樣式
func _clear_button_styles() -> void:
	if yea_button:
		yea_button.modulate = Color.WHITE
	if nay_button:
		nay_button.modulate = Color.WHITE
	if abstain_button:
		abstain_button.modulate = Color.WHITE


## 高亮選中的按鈕
func _highlight_selected(vote: GameStateData.VoteOption) -> void:
	_clear_button_styles()
	var dim_color: Color = Color(0.5, 0.5, 0.5, 0.7)

	match vote:
		GameStateData.VoteOption.YEA:
			if nay_button:
				nay_button.modulate = dim_color
			if abstain_button:
				abstain_button.modulate = dim_color
		GameStateData.VoteOption.NAY:
			if yea_button:
				yea_button.modulate = dim_color
			if abstain_button:
				abstain_button.modulate = dim_color
		GameStateData.VoteOption.ABSTAIN:
			if yea_button:
				yea_button.modulate = dim_color
			if nay_button:
				nay_button.modulate = dim_color


# ============================================================
# MOTION_SPEC 動效系統
# ============================================================

# === 按鈕微動效（MOTION_SPEC 第八章） ===

## 為按鈕設定 hover / press / release 微動效
func _setup_button_micro_motion(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(_on_button_hover.bind(btn))
	btn.mouse_exited.connect(_on_button_unhover.bind(btn))
	btn.button_down.connect(_on_button_down.bind(btn))
	btn.button_up.connect(_on_button_up.bind(btn))


func _on_button_hover(btn: Button) -> void:
	if btn.disabled:
		return
	var tw := create_tween()
	tw.tween_property(btn, "scale", BUTTON_HOVER_SCALE, HOVER_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _on_button_unhover(btn: Button) -> void:
	if btn.disabled:
		return
	var tw := create_tween()
	tw.tween_property(btn, "scale", BUTTON_REST_SCALE, HOVER_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _on_button_down(btn: Button) -> void:
	if btn.disabled:
		return
	var tw := create_tween()
	tw.tween_property(btn, "scale", BUTTON_PRESS_SCALE, PRESS_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func _on_button_up(btn: Button) -> void:
	if btn.disabled:
		return
	var tw := create_tween()
	tw.tween_property(btn, "scale", BUTTON_REST_SCALE, RELEASE_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


# === 投票動畫（MOTION_SPEC 投票系統） ===

## 玩家投票動畫
## T+0ms:   按鈕 scale 1.0→0.95 (50ms Ease In)
## T+50ms:  按鈕 scale 0.95→1.0 (80ms Ease Out) + 金色閃爍 + 音效 quill_writing
func animate_vote_cast(_player_id: String) -> void:
	# 找到玩家選擇的按鈕
	var btn := _get_selected_button()
	if not btn:
		return

	# 清除舊 tween
	if _vote_tween and _vote_tween.is_valid():
		_vote_tween.kill()

	btn.pivot_offset = btn.size / 2.0
	_vote_tween = create_tween()

	# T+0ms: 按鈕按下 scale 1.0→0.95 (50ms Ease In)
	_vote_tween.tween_property(btn, "scale", VOTE_PRESS_SCALE, PRESS_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# T+50ms: 確認回彈 scale 0.95→1.0 (80ms Ease Out)
	_vote_tween.tween_property(btn, "scale", BUTTON_REST_SCALE, CONFIRM_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# T+50ms 同步: 金色閃爍 + 音效
	_vote_tween.parallel().tween_callback(_flash_gold_border.bind(btn))
	_vote_tween.parallel().tween_callback(func() -> void:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("quill_writing")
	)

	# 金色閃爍回退 (150ms 漸退)
	_vote_tween.tween_property(btn, "self_modulate", Color.WHITE, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## 計票滾動動畫
## T+100ms: 票數 Label 數字滾動（每 50ms 跳一次）
## T+800ms: 最終票數 + frame shake + 音效 gavel + HapticFeedback
func animate_vote_counting(for_count: int, against_count: int, abstain_count_val: int = 0) -> void:
	if _count_tween and _count_tween.is_valid():
		_count_tween.kill()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	_pending_abstain = abstain_count_val
	_is_counting = true
	_count_tween = create_tween()

	# 計算滾動步數（700ms / 50ms = 14 ticks）
	var tick_count: int = int(COUNT_TOTAL_DURATION / COUNT_TICK_INTERVAL)

	# 前 100ms 延遲（T+100 才開始計票）
	_count_tween.tween_interval(0.1)

	# 數字滾動：每 50ms 更新一次隨機中間值
	for i in range(tick_count):
		var progress: float = float(i + 1) / float(tick_count)
		_count_tween.tween_callback(_update_rolling_count.bind(
			for_count, against_count, progress, i == tick_count - 1
		))
		if i < tick_count - 1:
			_count_tween.tween_interval(COUNT_TICK_INTERVAL)

	# T+800ms: 最終票數定格 + frame shake + 音效 + 觸覺
	_count_tween.tween_callback(func() -> void:
		_is_counting = false
		# 設定最終票數
		_set_final_count(for_count, against_count, abstain_count_val)
		# 音效
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("gavel")
		# 觸覺回饋
		if Engine.has_singleton("HapticFeedback"):
			Engine.get_singleton("HapticFeedback").heavy()
	)

	# Frame shake: ±2px, 3 次, 100ms
	_count_tween.tween_callback(_do_frame_shake)


## 結果判定動畫
## T+1000ms: 發出信號讓法案通過/失敗動效接手
func animate_vote_result(passed: bool, streak: int) -> void:
	var result_tween := create_tween()

	# 從計票結束 (T+800) 到結果判定 (T+1000) 間隔 200ms
	result_tween.tween_interval(0.2)

	# 更新狀態 Label
	result_tween.tween_callback(func() -> void:
		if status_label:
			if passed:
				status_label.text = "✓ 議案通過"
				status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			else:
				status_label.text = "✗ 議案否決"
				status_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

		# 發出信號讓外部法案動效接手
		vote_result_ready.emit(passed, streak)
	)


# === 動效輔助方法 ===

## 取得目前選中的按鈕
func _get_selected_button() -> Button:
	match _current_vote:
		GameStateData.VoteOption.YEA:
			return yea_button
		GameStateData.VoteOption.NAY:
			return nay_button
		GameStateData.VoteOption.ABSTAIN:
			return abstain_button
	return null


## 金色閃爍邊框
func _flash_gold_border(btn: Button) -> void:
	btn.self_modulate = GOLD_FLASH_COLOR


## 更新滾動中的計票數字
func _update_rolling_count(target_for: int, target_against: int, progress: float, is_final: bool) -> void:
	if is_final:
		_set_final_count(target_for, target_against, _pending_abstain)
		return

	# 漸進逼近最終值 + 隨機擾動
	var noise_range: int = maxi(1, int((1.0 - progress) * 10))
	var rolling_for: int = int(target_for * progress) + randi_range(-noise_range, noise_range)
	var rolling_against: int = int(target_against * progress) + randi_range(-noise_range, noise_range)
	var rolling_abstain: int = randi_range(0, noise_range)

	rolling_for = maxi(0, rolling_for)
	rolling_against = maxi(0, rolling_against)
	rolling_abstain = maxi(0, rolling_abstain)

	if yea_count:
		yea_count.text = "贊成: %d" % rolling_for
	if nay_count:
		nay_count.text = "反對: %d" % rolling_against
	if abstain_count:
		abstain_count.text = "棄權: %d" % rolling_abstain


## 設定最終票數
func _set_final_count(for_count: int, against_count: int, abstain_val: int = 0) -> void:
	if yea_count:
		yea_count.text = "贊成: %d" % for_count
	if nay_count:
		nay_count.text = "反對: %d" % against_count
	if abstain_count:
		abstain_count.text = "棄權: %d" % abstain_val


## Frame shake 動效（±2px, 3次, 100ms）
## 使用 Control.position offset，不動 Camera
func _do_frame_shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	var original_pos: Vector2 = position
	var single_shake_time: float = SHAKE_DURATION / float(SHAKE_COUNT * 2)
	_shake_tween = create_tween()

	for i in range(SHAKE_COUNT):
		# 偏移 +
		_shake_tween.tween_property(self, "position",
			original_pos + Vector2(SHAKE_OFFSET, 0), single_shake_time) \
			.set_trans(Tween.TRANS_SINE)
		# 偏移 -
		_shake_tween.tween_property(self, "position",
			original_pos - Vector2(SHAKE_OFFSET, 0), single_shake_time) \
			.set_trans(Tween.TRANS_SINE)

	# 回歸原位
	_shake_tween.tween_property(self, "position", original_pos, single_shake_time) \
		.set_trans(Tween.TRANS_SINE)
