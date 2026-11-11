shader_type canvas_item;
uniform bool perimeter_only = false;
uniform float clean_from_y = 0.0;
uniform float cut_after_y = 0.0;

// R1-01 extraction matte only: remove water baked into these static cutouts.
// Keep warm bone/coral and deep foreground shadows. Never apply to actors,
// fish, foliage animation, or the screen as a whole.
void fragment() {
	float blue = max(COLOR.b, 0.001);
	float water = (1.0 - smoothstep(0.62, 0.83, COLOR.r / blue))
		* smoothstep(0.03, 0.06, blue);
	float pixel_y = UV.y / TEXTURE_PIXEL_SIZE.y;
	water *= smoothstep(clean_from_y, clean_from_y + 24.0, pixel_y);
	COLOR.a *= 1.0 - water;
	if (cut_after_y > 0.0) {
		COLOR.a *= 1.0 - smoothstep(cut_after_y - 15.0, cut_after_y, pixel_y);
	}
	if (perimeter_only) {
		vec2 p = UV * vec2(1227.0, 720.0);
		float road = mix(470.0, 400.0, smoothstep(250.0, 640.0, p.x));
		road = mix(road, 505.0, smoothstep(720.0, 1020.0, p.x));
		float open_water = smoothstep(120.0, 180.0, p.x)
			* (1.0 - smoothstep(1080.0, 1160.0, p.x))
			* smoothstep(75.0, 110.0, p.y)
			* (1.0 - smoothstep(road - 90.0, road - 65.0, p.y));
		COLOR.a *= 1.0 - open_water;
	}
}
