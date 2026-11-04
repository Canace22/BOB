shader_type canvas_item;
uniform float clock=0.0;
uniform sampler2D guard_mask;
uniform vec2 room_size=vec2(1672.0,941.0);
varying vec2 world_pixel;
void vertex(){world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	float quiet_water=smoothstep(0.13,0.25,UV.y)*(1.0-smoothstep(0.72,0.89,UV.y));
	c.rgb*=1.0+quiet_water*0.018*sin(clock*0.35+UV.x*8.0+UV.y*6.0);
	c.a*=texture(guard_mask,world_pixel/room_size).a*0.82;
	COLOR=c;
}
