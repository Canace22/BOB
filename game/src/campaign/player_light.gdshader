shader_type canvas_item;
render_mode blend_add, unshaded;
uniform float strength : hint_range(0.0, 1.0) = 0.25;
uniform bool beam = true;
// An explicit pausable clock: built-in TIME also advances while menus are open.
uniform float effect_time = 0.0;

float band_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 h = fract(sin(vec4(dot(cell,vec2(127.1,311.7)),
		dot(cell+vec2(1.0,0.0),vec2(127.1,311.7)),
		dot(cell+vec2(0.0,1.0),vec2(127.1,311.7)),
		dot(cell+vec2(1.0),vec2(127.1,311.7)))) * 43758.5453);
	return mix(mix(h.x,h.y,f.x),mix(h.z,h.w,f.x),f.y);
}

void fragment() {
	// Keep the library bitmap's painted detail and alpha; shade its intensity.
	float fade;
	if (beam) {
		float t = effect_time;
		float lane = (UV.x - 0.5 + UV.y * 0.04) / mix(0.45,1.0,UV.y);
		float broad = band_noise(vec2(lane*7.0+t*0.07,UV.y*0.8-t*0.05));
		float fine = band_noise(vec2(lane*24.0-t*0.11,UV.y*1.5+t*0.09));
		float shafts = 0.2 + pow(broad,1.8) + pow(fine,3.0)*0.45;
		float sides = 1.0 - smoothstep(0.13,0.46,abs(UV.x-0.5));
		fade = sides * smoothstep(0.0,0.18,UV.y);
		fade *= 1.0 - smoothstep(0.56,1.0,UV.y);
		fade *= shafts;
	} else {
		vec2 q = (UV-0.5)*2.0;
		fade = pow(max(0.0,1.0-dot(q,q)),1.8);
	}
	COLOR.rgb *= vec3(0.8,0.94,1.0);
	COLOR.a *= strength * fade;
}
