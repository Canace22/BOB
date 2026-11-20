shader_type canvas_item;
render_mode unshaded, blend_add;
varying vec4 effect_tint;
void vertex() {
	// 独立传递调制色，避免fragment的COLOR已采样后再次乘Alpha。
	effect_tint = COLOR;
}
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(effect_tint.rgb, min(1.0, source.a * 2.4) * effect_tint.a);
}
