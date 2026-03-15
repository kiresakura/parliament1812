shader_type canvas_item;
// SSR 金色掃光 Shader（MOTION_SPEC §5 — 卡牌翻轉揭示）
// 金色漸層從左到右掃過卡牌，600ms
// 用法：將此 shader 套用在 ColorRect 上，透過 Tween 控制 sweep_progress

uniform float sweep_progress : hint_range(0.0, 1.0) = 0.0;    // 掃光進度 0→1
uniform float sweep_width : hint_range(0.01, 0.5) = 0.2;       // 掃光寬度（佔比）
uniform vec4 sweep_color : source_color = vec4(0.788, 0.659, 0.298, 0.6); // 金色半透明
uniform float edge_softness : hint_range(0.01, 0.2) = 0.05;    // 邊緣柔化
uniform float highlight_intensity : hint_range(0.0, 2.0) = 1.5; // 高光強度

void fragment() {
	// 計算掃光位置（考慮寬度，讓掃光從畫面外進入到畫面外離開）
	float sweep_center = mix(-sweep_width, 1.0 + sweep_width, sweep_progress);

	// 掃光漸層（中心最亮，邊緣柔化）
	float dist = abs(UV.x - sweep_center);
	float half_w = sweep_width * 0.5;

	// 漸層計算
	float gradient = smoothstep(half_w + edge_softness, half_w - edge_softness, dist);

	// 高光峰值（中心更亮）
	float peak = exp(-pow(dist / (half_w * 0.3), 2.0)) * highlight_intensity;

	// 混合
	float alpha = (gradient + peak * 0.5) * sweep_color.a;
	vec3 color = sweep_color.rgb + vec3(peak * 0.3);

	COLOR = vec4(color, alpha);
}
