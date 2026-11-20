shader_type canvas_item;
render_mode unshaded;
uniform float clock=0.0;
varying vec4 tint;
void vertex() { tint=COLOR; }
void fragment() {
	vec2 drift=vec2(sin(UV.y*25.0-clock*13.0),sin(UV.x*21.0+clock*17.0))*0.006;
	vec4 sample_color=texture(TEXTURE,clamp(UV+drift,vec2(0.001),vec2(0.999)));
	float mask=texture(TEXTURE,UV).a;
	COLOR=vec4(sample_color.rgb*tint.rgb,min(mask,sample_color.a)*tint.a);
}
