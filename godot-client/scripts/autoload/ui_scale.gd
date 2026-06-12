class_name UIScaleClass
extends Node
## 全域 UI 縮放工具
## 根據 viewport 大小提供響應式尺寸計算
## 設計基準：720×1280 portrait（canvas_items stretch mode）

# === 設計基準（直立模式） ===
const BASE_WIDTH: float = 720.0
const BASE_HEIGHT: float = 1280.0

# === 最小觸控尺寸（手指友善） ===
const MIN_TOUCH_SIZE: float = 44.0

# === 螢幕類型 ===
enum ScreenType { DESKTOP, TABLET, PHONE }


## 取得目前 viewport 尺寸
static func get_viewport_size() -> Vector2:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_visible_rect().size
	return Vector2(BASE_WIDTH, BASE_HEIGHT)


## 取得水平縮放比例
static func scale_x() -> float:
	return get_viewport_size().x / BASE_WIDTH


## 取得垂直縮放比例
static func scale_y() -> float:
	return get_viewport_size().y / BASE_HEIGHT


## 取得統一縮放比例（取較小值，保證不超出螢幕）
static func scale_factor() -> float:
	return minf(scale_x(), scale_y())


## 寬高比（越大越「寬」）
static func aspect_ratio() -> float:
	var vp: Vector2 = get_viewport_size()
	return vp.x / vp.y if vp.y > 0.0 else 0.5625


## 是否為直立（portrait）模式
static func is_portrait() -> bool:
	var vp: Vector2 = get_viewport_size()
	return vp.y > vp.x


## 判斷螢幕類型
static func screen_type() -> ScreenType:
	var vp: Vector2 = get_viewport_size()
	var shorter: float = minf(vp.x, vp.y)
	if shorter < 500.0:
		return ScreenType.PHONE
	elif shorter < 900.0:
		return ScreenType.TABLET
	return ScreenType.DESKTOP


## 是否為手機尺寸
static func is_mobile() -> bool:
	return screen_type() != ScreenType.DESKTOP


## 根據基準值動態計算像素大小（基於縮放比例）
static func px(base_value: float) -> float:
	return base_value * scale_factor()


## 根據 viewport 寬度的百分比計算像素
static func vw(percent: float) -> float:
	return get_viewport_size().x * percent / 100.0


## 根據 viewport 高度的百分比計算像素
static func vh(percent: float) -> float:
	return get_viewport_size().y * percent / 100.0


## 計算響應式字體大小（最小不低於 10）
static func font_size(base_size: int) -> int:
	return maxi(10, int(float(base_size) * scale_factor()))


## 計算觸控友善的最小尺寸
static func touch_min_size(base_w: float, base_h: float) -> Vector2:
	var scaled_w: float = maxf(MIN_TOUCH_SIZE, base_w * scale_factor())
	var scaled_h: float = maxf(MIN_TOUCH_SIZE, base_h * scale_factor())
	return Vector2(scaled_w, scaled_h)


## 是否為超寬螢幕（19.5:9 等）
static func is_ultrawide() -> bool:
	return aspect_ratio() > 2.0


## 是否為超高螢幕（19.5:9 portrait 等）
static func is_ultratall() -> bool:
	var vp: Vector2 = get_viewport_size()
	return vp.y / vp.x > 2.0 if vp.x > 0.0 else false


## 取得安全邊距（考慮瀏海/圓角）
static func safe_margin() -> float:
	if is_ultrawide():
		return vw(3.0)  # 超寬螢幕左右多留 3%
	return px(12.0)
