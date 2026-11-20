shader_type canvas_item;
render_mode unshaded;
void fragment() {
	// COLOR已包含源位图；只染色与调透明，保留逐帧原画的完整轮廓。
	vec4 source=COLOR;
	vec3 spectral=mix(source.rgb,vec3(0.45,0.87,1.0),0.62);
	COLOR=vec4(spectral+vec3(0.08,0.13,0.15),source.a*0.78);
}
