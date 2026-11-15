shader_type canvas_item;
uniform float uv_start = 0.0;
uniform float uv_end = 1.0;
void fragment(){
	if(COLOR.a<0.08){discard;}
	float along=(UV.y-uv_start)/max(0.001,uv_end-uv_start);
	COLOR.a*=1.0-smoothstep(0.9,1.0,along);
}
