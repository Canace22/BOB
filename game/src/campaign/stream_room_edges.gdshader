shader_type canvas_item;
uniform vec2 stream_room_origin = vec2(0.0);
uniform vec2 stream_room_size = vec2(1.0);
uniform float stream_fade_width : hint_range(1.0, 300.0) = 100.0;
uniform bool stream_preserve_outline = false;
uniform bool stream_soft_beam = false;
uniform sampler2D stream_content_mask : filter_linear, repeat_disable;
uniform bool stream_use_content_mask = false;
uniform bool stream_mask_keep_endpoints = false;
uniform vec4 seam_patches[4];
uniform int seam_count=0;
varying vec2 stream_world_pixel;

void vertex() {
	stream_world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if(stream_use_content_mask) {
		float keep=stream_mask_keep_endpoints ? 1.0-smoothstep(0.025,0.055,min(UV.x,1.0-UV.x)) : 0.0;
		COLOR.a*=mix(texture(stream_content_mask,UV).a,1.0,keep);
	}
	if(stream_soft_beam) {
		float beam_left=mix(0.39,0.03,UV.y);
		float beam_right=mix(0.52,0.94,UV.y);
		COLOR.a*=smoothstep(0.0,0.06,min(UV.x-beam_left,beam_right-UV.x))*smoothstep(0.0,0.18,UV.y)*smoothstep(0.0,0.22,1.0-UV.y);
	}
	// 保留绘图节点自身的纹理、顶点色和调制色，只改变房间外沿透明度。
	vec2 edge_distance = min(stream_world_pixel - stream_room_origin, stream_room_origin + stream_room_size - stream_world_pixel);
	if(!stream_preserve_outline) COLOR.a *= smoothstep(0.0, max(stream_fade_width, 1.0), min(edge_distance.x, edge_distance.y));
	float seam_owner=1.0-smoothstep(140.0,280.0,min(edge_distance.x,edge_distance.y));
	for(int i=0;i<4;i++){
		if(i>=seam_count)break;
		vec4 patch=seam_patches[i];
		vec2 edge=min(stream_world_pixel-patch.xy,patch.xy+patch.zw-stream_world_pixel);
		COLOR.a*=1.0-seam_owner*smoothstep(0.0,100.0,min(edge.x,edge.y));
	}
}
