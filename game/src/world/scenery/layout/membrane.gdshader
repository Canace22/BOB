shader_type canvas_item;
uniform float membrane_drop = 0.0;
uniform float world_width = 270.0;
uniform float world_height = 80.0;
uniform float local_per_world = 1.0;
uniform float u_left = 0.0;
uniform float u_right = 1.0;
void vertex(){
	float fixed_ends = sin(clamp((UV.x-u_left)/max(u_right-u_left,0.001),0.0,1.0)*3.14159265);
	VERTEX.y += membrane_drop * local_per_world * fixed_ends;
}
void fragment(){
	vec4 painted = COLOR;
	if(painted.a < 0.08){ discard; }
	COLOR = painted;
}
