shader_type canvas_item;
// Retain the native near painting, with soft clearance around authored landings.
uniform int zone_count = 0;
uniform vec4 clear_zones[32];
varying vec2 room_position;
void vertex(){
	room_position = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
}
void fragment(){
	vec4 painted = COLOR;
	float edge_alpha = 0.0;
	for(int y=-1;y<=1;y++){
		for(int x=-1;x<=1;x++){
			edge_alpha += texture(TEXTURE,UV+vec2(float(x),float(y))*TEXTURE_PIXEL_SIZE*18.0).a;
		}
	}
	float clearance = 1.0;
	for(int i=0;i<zone_count;i++){
		vec4 zone = clear_zones[i];
		vec2 half_size = zone.zw*0.5;
		vec2 distance_out = abs(room_position-(zone.xy+half_size))-half_size;
		float edge = max(distance_out.x,distance_out.y);
		clearance = min(clearance,smoothstep(-8.0,52.0,edge));
	}
	painted.a *= clearance*smoothstep(0.72,0.84,UV.y)*edge_alpha/9.0;
	COLOR = painted;
}
