shader_type canvas_item;
uniform float clock = 0.0;
uniform float strength = 1.0;
uniform float part = 0.0;
uniform float side = 1.0;
uniform float water_only = 0.0;
uniform vec2 scene_origin = vec2(0.0);
uniform float scene_width = 1672.0;
uniform float portal_ground = 715.0;
uniform float render_part = 0.0;
varying vec2 world_pixel;
void vertex() {
	world_pixel = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
}
void fragment() {
	vec2 room_pixel=world_pixel-scene_origin;
	vec4 pixel = texture(TEXTURE, UV);
	float end_fade = smoothstep(0.03, 0.18, UV.x) * (1.0 - smoothstep(0.82, 0.97, UV.x));
	float y_fade = smoothstep(0.0, 0.09, UV.y) * (1.0 - smoothstep(0.83, 1.0, UV.y));
	// The central opening belongs to the real room, including all ground pixels.
	float arch = 1.0 - smoothstep(0.2, 0.6, abs(UV.x - 0.5));
	float top = 0.22 + 0.03 * sin(clock * 0.28);
	float ceiling = 1.0 - smoothstep(top, top + 0.20, UV.y);
	float lateral = 1.0 - smoothstep(0.12, 0.45, side > 0.0 ? UV.x : 1.0 - UV.x);
	float open_mask = part < 0.5 ? 1.0 : max(ceiling * 0.65, lateral * 0.75);
	if (part > 1.5) open_mask = 0.0;
	float caustic = 0.98 + 0.02 * sin(clock * 0.43 + UV.x * 9.0 + UV.y * 4.0);
	pixel.rgb *= caustic;
	pixel.a *= end_fade * y_fade * open_mask * strength;
	pixel.a *= smoothstep(0.0,20.0,room_pixel.x) * (1.0-smoothstep(scene_width-20.0,scene_width,room_pixel.x));
	// Never paint a second ground plane across the real collision or reward platform.
	pixel.a *= 1.0-smoothstep(portal_ground-200.0,portal_ground-100.0,room_pixel.y);
	if (water_only > 0.5) pixel.a *= arch;
	COLOR = pixel;
}
