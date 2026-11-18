shader_type canvas_item;
render_mode unshaded;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	// Fragment COLOR already contains texture RGBA and CanvasItem modulation.
	vec4 source = COLOR;
	COLOR = vec4(mix(source.rgb, vec3(1.0, 0.95, 0.78), flash * 0.78), source.a);
}
