shader_type canvas_item;
#include "res://src/world/scenery/layout/water_drift.gdshaderinc"
// Feather the existing extraction boundary; all colour comes from the painting.
uniform float feather_pixels = 14.0;
uniform bool fade_lower = false;
uniform float fade_from = 0.16;
uniform float fade_to = 0.42;
void fragment(){
	vec2 step_uv = TEXTURE_PIXEL_SIZE*feather_pixels;
	float alpha_sum = 0.0;
	for(int y=-1;y<=1;y++){
		for(int x=-1;x<=1;x++){
			alpha_sum += texture(TEXTURE,UV+vec2(float(x),float(y))*step_uv).a;
		}
	}
	COLOR.a *= alpha_sum/9.0;
	if(fade_lower){COLOR.a *= 1.0-smoothstep(fade_from,fade_to,UV.y);}
	if(water_strength>0.0){COLOR.rgb=drifting_water(COLOR.rgb,UV);}
}
