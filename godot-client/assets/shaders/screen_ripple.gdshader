shader_type canvas_item;
// 螢幕波紋效果 Shader（MOTION_SPEC §4 — 法案失敗）
// 從中心擴散的暗色圓形波紋
// 用法：套用在全畫面 ColorRect 上，透過 Tween 控制 ripple_progress

uniform float ripple_progress : hint_range(0.0, 1.0) = 0.0;
uniform float ripple_count : hint_range(1.0, 5.0) = 3.0;
uniform float ripple_width : hint_range(0.005, 0.05) = 0.015;
uniform vec4 ripple_color : source_color = vec4(0.15, 0.1, 0.1, 0.6);
uniform float max_radius : hint_range(0.5, 2.0) = 1.2;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 uv_corrected = vec2(UV.x, UV.y * aspect);
	vec2 center_corrected = vec2(center.x, center.y * aspect);

	float dist = length(uv_corrected - center_corrected);

	float alpha = 0.0;

	// 多道波紋
	for (float i = 0.0; i < ripple_count; i++) {
		float delay = i * 0.15;
		float progress = clamp(ripple_progress - delay, 0.0, 1.0);

		// 波紋半徑隨時間擴大
		float radius = progress * max_radius;

		// 波紋環帶
		float ring = smoothstep(ripple_width, 0.0, abs(dist - radius));

		// 隨時間衰減
		float fade = 1.0 - progress;

		alpha += ring * fade;
	}

	alpha = clamp(alpha, 0.0, 1.0) * ripple_color.a;

	COLOR = vec4(ripple_color.rgb, alpha);
}
