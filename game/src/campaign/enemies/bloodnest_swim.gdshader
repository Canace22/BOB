shader_type canvas_item;
// Compact glass-shrimp UV contract; no displacement of its eye / cephalothorax.
uniform float clock=0.0;
uniform float phase=0.0;
uniform float motion_strength=1.0;
uniform float hit_strength=0.0;
varying vec4 sprite_tint;
void vertex(){sprite_tint=COLOR;}
void fragment(){
	vec2 uv=UV;
	float t=clock*6.2+phase;
	float legs=smoothstep(0.53,0.69,uv.y)*(1.0-smoothstep(0.73,0.84,uv.x));
	float tail=smoothstep(0.72,0.89,uv.x)*smoothstep(0.35,0.55,uv.y);
	float feeler=(1.0-smoothstep(0.17,0.27,uv.x))*smoothstep(0.04,0.09,uv.x);
	uv.x+=legs*sin(t+uv.x*30.0)*0.007*motion_strength;
	uv.y+=(legs*sin(t+uv.x*30.0+1.4)*0.005+tail*sin(t*0.72)*0.008+feeler*sin(t*0.51+uv.x*9.0)*0.008)*motion_strength;
	vec4 painted=texture(TEXTURE,uv);
	float shell=smoothstep(0.44,0.56,uv.x)*(1.0-smoothstep(0.8,0.87,uv.x));
	painted.rgb*=1.0+shell*0.04*sin(clock*1.8+phase);
	float rim=smoothstep(0.28,0.7,dot(painted.rgb,vec3(0.3,0.5,0.2)));
	painted.rgb=mix(painted.rgb,vec3(1.0,0.95,0.87),hit_strength*0.65*rim);
	COLOR=painted*sprite_tint;
}
