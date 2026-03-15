shader_type canvas_item;
// 羊皮紙覆蓋效果 shader
// 用於 BOOK_FLIP 場景轉場時的紋理效果（MOTION_SPEC §6）
// 模擬古老羊皮紙的質感：纖維紋理 + 邊緣暗化

uniform vec4 parchment_color : source_color = vec4(0.831, 0.773, 0.663, 1.0); // #D4C5A9
uniform float noise_scale : hint_range(1.0, 50.0) = 20.0;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float burn_edge : hint_range(0.0, 0.5) = 0.05;

// 簡易雜訊函數（pseudo noise）
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 base = parchment_color;

	// 纖維紋理（多層雜訊疊加）
	float n = noise(UV * noise_scale) * 0.5
			+ noise(UV * noise_scale * 2.0) * 0.3
			+ noise(UV * noise_scale * 4.0) * 0.2;
	base.rgb += (n - 0.5) * noise_intensity;

	// 邊緣暗化（vignette）
	vec2 center_dist = abs(UV - 0.5) * 2.0;
	float vignette = smoothstep(0.5, 1.0, max(center_dist.x, center_dist.y));
	base.rgb -= vignette * vignette_strength;

	// 焦邊效果
	float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float burn = smoothstep(burn_edge, 0.0, edge_dist);
	base.rgb = mix(base.rgb, vec3(0.3, 0.2, 0.1), burn);

	COLOR = base;
}
