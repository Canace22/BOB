shader_type canvas_item;
// Original bitmap colour only. Hide native top edges and side overhangs below
// a frozen landing; this decoration must never introduce a false walking top.
uniform vec4 bounds = vec4(0.0);
uniform vec2 stream_room_offset=vec2(0.0);
varying vec2 room_position;
void vertex(){room_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy-stream_room_offset;}
void fragment(){
	float side=min(room_position.x-bounds.x,bounds.x+bounds.z-room_position.x);
	float below=room_position.y-bounds.y;
	float bottom=bounds.y+bounds.w-room_position.y;
	COLOR.a*=smoothstep(0.0,18.0,side)*smoothstep(0.0,12.0,below)*smoothstep(0.0,32.0,bottom)*smoothstep(0.32,0.44,UV.y);
}
