shader_type canvas_item;
render_mode unshaded;
uniform float clock=0.0;
uniform float amplitude=5.0;
uniform float period=7.0;
uniform float phase=0.0;
uniform bool root_at_bottom=false;
uniform bool curtain=false;
uniform vec2 source_origin;
float root_y(float x) {
 if(x<275.0) return mix(155.0,104.0,clamp((x-180.0)/95.0,0.0,1.0));
 if(x<440.0) return mix(104.0,55.0,(x-275.0)/165.0);
 if(x<595.0) return mix(55.0,40.0,(x-440.0)/155.0);
 if(x<742.0) return mix(40.0,18.0,(x-595.0)/147.0);
 if(x<900.0) return mix(18.0,0.0,(x-742.0)/158.0);
 if(x<1040.0) return mix(0.0,5.0,(x-900.0)/140.0);
	if(x<1160.0) return mix(5.0,65.0,(x-1040.0)/120.0);
	return mix(65.0,240.0,clamp((x-1160.0)/120.0,0.0,1.0));
}
void fragment(){
 vec2 px=1.0/TEXTURE_PIXEL_SIZE;
 vec2 world=source_origin+UV*px;
 float v=root_at_bottom?1.0-UV.y:UV.y;
 float w=pow(smoothstep(0.12,1.0,v),1.6);
 if(curtain) w=pow(smoothstep(root_y(world.x)+25.0,300.0,world.y),1.4);
 float a=clock*6.28318530718/period;
 float wave=(sin(a+phase)-sin(phase))*0.78+(sin(2.0*a+UV.y*3.0+phase)-sin(UV.y*3.0+phase))*0.22;
 vec2 uv=UV-vec2(w*amplitude*wave*TEXTURE_PIXEL_SIZE.x,0.0);
 float inside=step(0.0,uv.x)*step(uv.x,1.0);
 COLOR=texture(TEXTURE,uv)*vec4(1.0,1.0,1.0,inside);
}
