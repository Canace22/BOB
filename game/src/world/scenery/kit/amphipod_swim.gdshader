shader_type canvas_item;
// Articulates the existing left-facing amphipod bitmap only. The rigid eye /
// carapace remain still; antennas and lower appendages have different phases.
uniform float clock = 0.0;
uniform float phase = 0.0;
uniform float motion_strength = 1.0;
varying vec4 sprite_tint;
void vertex(){sprite_tint=COLOR;}
void fragment(){
	vec2 uv = UV;
	float t = clock * 7.5 + phase;
	float feeler = (1.0-smoothstep(0.21,0.35,uv.x)) * smoothstep(0.045,0.09,uv.x);
	float legs = smoothstep(0.49,0.63,uv.y) * (1.0-smoothstep(0.87,0.97,uv.x));
	float tail = smoothstep(0.79,0.91,uv.x) * smoothstep(0.53,0.70,uv.y);
	uv.y += motion_strength * (feeler * sin(t*0.72+uv.x*12.0)*0.008 + tail*sin(t*0.64)*0.004);
	uv.x += motion_strength * legs * sin(t+uv.x*31.0) * 0.009;
	uv.y += motion_strength * legs * sin(t+uv.x*31.0+1.2) * 0.004;
	vec4 painted = texture(TEXTURE,uv);
	float inside = step(0.0,uv.x)*step(uv.x,1.0)*step(0.0,uv.y)*step(uv.y,1.0);
	COLOR = painted * sprite_tint * vec4(1.0,1.0,1.0,inside);
}
