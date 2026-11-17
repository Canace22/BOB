shader_type canvas_item;
uniform sampler2D content_mask : filter_linear, repeat_disable;
uniform bool use_mask=false;
uniform bool connector=false;
uniform vec4 rooms[19];
uniform int room_count=0;
uniform vec4 repaint_rectangles[24];
uniform int repaint_count=0;
varying vec2 world_pixel;
void vertex(){world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
	for(int i=0;i<24;i++){
		if(i>=repaint_count)break;
		vec4 rect=repaint_rectangles[i];
		if(world_pixel.x>=rect.x && world_pixel.y>=rect.y && world_pixel.x<rect.x+rect.z && world_pixel.y<rect.y+rect.w){COLOR.a=0.0;break;}
	}
	// 道路实体不做房间淡边；同一母版上的唯一所有权直接裁定像素。
	if(use_mask) {
		COLOR.a*=texture(content_mask,UV).a;
	}
	if(connector){
		for(int i=0;i<19;i++){
			if(i>=room_count)break;
			vec4 room=rooms[i];
			if(world_pixel.x>=room.x && world_pixel.y>=room.y && world_pixel.x<room.x+room.z && world_pixel.y<room.y+room.w){COLOR.a=0.0;break;}
		}
	}
}
