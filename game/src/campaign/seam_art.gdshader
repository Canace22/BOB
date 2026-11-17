shader_type canvas_item;
uniform vec4 patch_rect;
uniform vec4 room_a;
uniform vec4 room_b;
uniform vec4 protected_rooms[19];
uniform int protected_count=0;
varying vec2 world_pixel;
void vertex(){world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
float inside_depth(vec4 room){
	vec2 edge=min(world_pixel-room.xy,room.xy+room.zw-world_pixel);
	return min(edge.x,edge.y);
}
void fragment(){
	// CanvasItem的COLOR已含纹理采样，不能再次相乘，否则画面被平方压暗。
	vec4 pixel=COLOR;
	vec2 border=min(world_pixel-patch_rect.xy,patch_rect.xy+patch_rect.zw-world_pixel);
	float perimeter=smoothstep(0.0,100.0,min(border.x,border.y));
	// 只替换原房边界重叠带，内部结构和动态仍由原房负责。
	float owner=1.0-smoothstep(140.0,280.0,max(inside_depth(room_a),inside_depth(room_b)));
	for(int room_i=0;room_i<19;room_i++){
		if(room_i>=protected_count)break;
		owner*=1.0-smoothstep(-80.0,0.0,inside_depth(protected_rooms[room_i]));
	}
	pixel.a*=perimeter*owner;
	COLOR=pixel;
}
