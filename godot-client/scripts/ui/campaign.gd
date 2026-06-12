class_name CampaignMap
extends Control
## 故事戰役介面
## 以章節列表顯示關卡解鎖狀態與星數

# === 節點參考 ===
@onready var chapter_list: VBoxContainer = $VBox/ScrollContainer/ChapterList  # ScrollContainer 包裝
@onready var back_button: Button = $VBox/BackButton
@onready var title_label: Label = $VBox/TitleLabel

# === 狀態 ===
var _chapters: Array[Dictionary] = []


func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	_load_campaign()


# === 內部方法 ===

## 從 API 載入戰役資料
func _load_campaign() -> void:
	var result: Dictionary = await ApiService.get_campaign()
	if result.get("success", false):
		_chapters = result.get("data", {}).get("chapters", [])
		_populate_chapters()
	else:
		# 離線預設章節結構
		_chapters = _get_default_chapters()
		_populate_chapters()


## 填充章節列表
func _populate_chapters() -> void:
	if not chapter_list:
		return

	for child: Node in chapter_list.get_children():
		child.queue_free()

	for i: int in range(_chapters.size()):
		var chapter: Dictionary = _chapters[i]
		var entry: PanelContainer = _create_chapter_entry(i, chapter)
		chapter_list.add_child(entry)


## 建立章節項目
func _create_chapter_entry(index: int, chapter: Dictionary) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var is_unlocked: bool = chapter.get("unlocked", false)
	var stars: int = chapter.get("stars", 0) as int
	var chapter_name: String = chapter.get("name", "第 %d 章" % (index + 1))

	# 章節編號
	var num_lbl: Label = Label.new()
	num_lbl.text = "%d." % (index + 1)
	num_lbl.custom_minimum_size = Vector2(40, 0)
	num_lbl.add_theme_color_override("font_color",
		Color(0.788, 0.659, 0.298, 1) if is_unlocked else Color(0.4, 0.4, 0.4, 1)
	)
	hbox.add_child(num_lbl)

	# 章節名稱
	var name_lbl: Label = Label.new()
	name_lbl.text = chapter_name if is_unlocked else "???"
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color",
		Color(0.91, 0.835, 0.718, 1) if is_unlocked else Color(0.4, 0.4, 0.4, 1)
	)
	hbox.add_child(name_lbl)

	# 星數
	var star_lbl: Label = Label.new()
	if is_unlocked:
		var star_text: String = ""
		for s: int in range(3):
			star_text += "★" if s < stars else "☆"
		star_lbl.text = star_text
		star_lbl.add_theme_color_override("font_color", Color(0.788, 0.659, 0.298, 1))
	else:
		star_lbl.text = "🔒"
		star_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
	hbox.add_child(star_lbl)

	# 開始按鈕（觸控友善尺寸）
	if is_unlocked:
		var play_btn: Button = Button.new()
		play_btn.text = "開始"
		play_btn.custom_minimum_size = UIScaleClass.touch_min_size(80.0, 44.0)
		play_btn.pressed.connect(func() -> void: _start_chapter(index))
		hbox.add_child(play_btn)

	return panel


## 開始章節
func _start_chapter(index: int) -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	# TODO: 進入戰役關卡場景
	print("[Campaign] 開始章節 %d" % (index + 1))


## 預設章節結構（離線使用）
func _get_default_chapters() -> Array[Dictionary]:
	return [
		{"name": "初入議會", "unlocked": true, "stars": 0},
		{"name": "派系角力", "unlocked": false, "stars": 0},
		{"name": "預算攻防", "unlocked": false, "stars": 0},
		{"name": "外交風雲", "unlocked": false, "stars": 0},
		{"name": "軍事爭議", "unlocked": false, "stars": 0},
		{"name": "彈劾危機", "unlocked": false, "stars": 0},
		{"name": "最終表決", "unlocked": false, "stars": 0},
	]


## 返回大廳
func _on_back_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	SceneManager.go_to_lobby()
