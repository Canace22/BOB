shader_type canvas_item;
render_mode unshaded;
uniform float clock=0.0;
uniform float period=10.0;
uniform float amplitude=2.4;
uniform float phase=0.0;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 float t=clock*6.28318530718/period;
 float wx=sin(t+UV.y*13.0+phase)-sin(UV.y*13.0+phase);
 float wy=sin(t*2.0+UV.x*18.0+phase)-sin(UV.x*18.0+phase);
 // Refraction of the already painted surface; never a floating additive decal.
 vec2 flow=vec2(wx*amplitude,wy*amplitude*0.34)*TEXTURE_PIXEL_SIZE;
 vec4 still=texture(TEXTURE,UV);
 vec4 moving=texture(TEXTURE,UV+flow);
 float coverage=min(still.a,moving.a);
 COLOR=tint*vec4(moving.rgb,coverage);
}
