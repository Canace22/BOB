shader_type canvas_item;
render_mode unshaded, blend_add;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(COLOR.rgb, source.a * COLOR.a);
}
