shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float clock = 0.0;
uniform float period = 12.0;
uniform float phase = 0.0;
uniform float strength = 0.12;
void fragment() {
	float t = clock * 6.28318530718 / period + phase;
	vec2 uv = UV;
	uv.x += sin(UV.y * 8.0 + t) * 0.006 * sin(UV.y * 3.14159265);
	vec4 ray = texture(TEXTURE, uv);
	float boundary = smoothstep(0.0, 0.09, UV.x) * smoothstep(0.0, 0.09, 1.0 - UV.x);
	boundary *= smoothstep(0.0, 0.12, UV.y) * smoothstep(0.0, 0.15, 1.0 - UV.y);
	float breath = 0.86 + 0.14 * sin(t);
	COLOR = vec4(ray.rgb, ray.a * boundary * strength * breath);
}
