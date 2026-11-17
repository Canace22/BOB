shader_type canvas_item;
render_mode unshaded;
varying vec4 instance_color;

void vertex() {
	instance_color = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(vec3(1.0), source.a * instance_color.a);
}
