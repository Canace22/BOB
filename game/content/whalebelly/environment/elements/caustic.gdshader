shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float clock=0.0;
uniform float period=12.0;
uniform float phase=0.0;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 float t=clock*6.28318530718/period;
 vec2 flow=vec2(sin(t+UV.y*5.0+phase)*0.018,cos(t+UV.x*5.0+phase)*0.014);
 vec4 ribbon=texture(TEXTURE,UV+flow);
 float edge=smoothstep(0.0,0.10,UV.x)*smoothstep(0.0,0.10,1.0-UV.x)*smoothstep(0.0,0.10,UV.y)*smoothstep(0.0,0.10,1.0-UV.y);
 COLOR=tint*vec4(ribbon.rgb,ribbon.a*edge*(0.72+0.28*sin(t+UV.x*7.0+phase)));
}
