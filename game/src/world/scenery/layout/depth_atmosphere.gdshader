shader_type canvas_item;
#include "res://src/world/scenery/layout/water_drift.gdshaderinc"
// Keep the source's hue and value hierarchy while recessing busy distant bone.
uniform float recess = 0.15;
void fragment(){
	vec4 painted=COLOR;
	float value=dot(painted.rgb,vec3(0.2126,0.7152,0.0722));
	vec3 water=vec3(0.055,0.14,0.19);
	painted.rgb=mix(painted.rgb,mix(vec3(value),water,0.35),recess);
	if(water_strength>0.0){painted.rgb=drifting_water(painted.rgb,UV);}
	COLOR=painted;
}
