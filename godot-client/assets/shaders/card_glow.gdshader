shader_type canvas_item;
// 卡牌光暈效果 shader
// 根據稀有度顯示不同顏色的光暈

uniform vec4 glow_color : source_color = vec4(0.788, 0.659, 0.298, 1.0); // 預設金色
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float glow_size : hint_range(0.0, 20.0) = 5.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform bool enable_pulse = true;

void fragment() {
	vec4 original = texture(TEXTURE, UV);

	// 計算邊緣距離
	float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float glow_threshold = glow_size / 100.0;

	// 光暈強度（邊緣越近越強）
	float glow_factor = smoothstep(glow_threshold, 0.0, edge_dist);

	// 脈衝效果
	float pulse = 1.0;
	if (enable_pulse) {
		pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
	}

	// 混合光暈
	vec4 glow = glow_color * glow_factor * glow_intensity * pulse;

	// 輸出：原始 + 光暈（加法混合）
	COLOR = original + glow * original.a;
	COLOR.a = original.a;
}
