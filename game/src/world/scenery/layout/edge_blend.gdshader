shader_type canvas_item;
// Blend existing painted edge crops into their own room; no generated scenery.
uniform float fade_start = 0.8;
uniform float fade_end = 1.0;
uniform bool keep_top = false;
void fragment(){
	vec4 painted = COLOR;
	float blend = smoothstep(fade_start,fade_end,UV.y);
	painted.a *= keep_top ? 1.0-blend : blend;
	COLOR = painted;
}
