shader_type canvas_item;
uniform sampler2D original : filter_linear, repeat_disable;
uniform vec2 canvas_size;
uniform vec4 patches[24];
uniform int patch_count=0;
uniform int patch_index=0;
varying vec2 world_pixel;
void vertex(){world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
float ownership(vec4 rect){
	vec2 edge=min(world_pixel-rect.xy,rect.xy+rect.zw-world_pixel);
	if(min(edge.x,edge.y)<0.0)return -1.0;
	// 选最靠近补绘中心的一个拥有者，不能让后绘制的旧参考覆盖另一张已修好的形体。
	return min(edge.x/rect.z,edge.y/rect.w);
}
void fragment(){
	float strength=ownership(patches[patch_index]);
	for(int i=0;i<24;i++){
		if(i>=patch_count)break;
		float other=ownership(patches[i]);
		if(other>strength+0.00001 || (abs(other-strength)<0.00001 && i>patch_index)){discard;}
	}
	vec4 old_pixel=texture(original,UV);
	vec4 new_pixel=texture(TEXTURE,UV);
	vec2 edge=min(UV,vec2(1.0)-UV)*canvas_size;
	// 外沿仍使用精确原像素，重绘在宽上下文内接回；中心形体完全由新画负责。
	float amount=smoothstep(0.0,180.0,edge.x)*smoothstep(0.0,100.0,edge.y);
	float alpha=mix(old_pixel.a,new_pixel.a,amount);
	vec3 premultiplied=mix(old_pixel.rgb*old_pixel.a,new_pixel.rgb*new_pixel.a,amount);
	COLOR=vec4(alpha>0.0001?premultiplied/alpha:vec3(0.0),alpha);
}
