shader_type canvas_item;
render_mode unshaded;
uniform sampler2D water_0 : source_color, repeat_disable, filter_linear;
uniform sampler2D water_1 : source_color, repeat_disable, filter_linear;
uniform sampler2D water_2 : source_color, repeat_disable, filter_linear;
uniform sampler2D water_3 : source_color, repeat_disable, filter_linear;
uniform sampler2D water_4 : source_color, repeat_disable, filter_linear;
uniform sampler2D water_5 : source_color, repeat_disable, filter_linear;
uniform vec2 anchors[6];
uniform vec2 camera_world;
uniform vec4 rooms[19];
uniform int biomes[19];
uniform int room_count = 0;
varying vec2 world_pixel;
void vertex() { world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
vec4 water(sampler2D bitmap, int zone) {
	// 相机只推动统一视差相位，区域锚点在世界建立后固定，换房不重新起算。
	vec2 uv=(world_pixel-camera_world*0.75-anchors[zone]*0.25)/(vec2(textureSize(bitmap,0))*1.5)+0.5;
	uv=1.0-abs(mod(uv,2.0)-1.0);
	return texture(bitmap,uv);
}
void fragment() {
	float distances[6];
	for(int i=0;i<6;i++) distances[i]=1e9;
	for(int i=0;i<19;i++) {
		if(i>=room_count) break;
		vec4 room=rooms[i];
		vec2 outside=max(max(room.xy-world_pixel,world_pixel-room.xy-room.zw),vec2(0.0));
		int zone=biomes[i];
		distances[zone]=min(distances[zone],length(outside));
	}
	float weights[6];
	float total=0.0;
	for(int i=0;i<6;i++) {
		float d=distances[i]/500.0;
		weights[i]=1.0/(1.0+d*d*d*d);
		total+=weights[i];
	}
	vec4 base=water(water_0,0);
	COLOR=(base*weights[0]+water(water_1,1)*weights[1]+water(water_2,2)*weights[2]+water(water_3,3)*weights[3]+water(water_4,4)*weights[4]+water(water_5,5)*weights[5])/max(total,0.0001);
	COLOR.a=1.0;
}
