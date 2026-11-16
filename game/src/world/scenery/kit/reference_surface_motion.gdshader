shader_type canvas_item;
uniform bool glow_mode = false;
uniform float clock = 0.0;
uniform float phase = 0.0;
uniform float amplitude_pixels = 4.0;
varying vec4 painted_tint;
void vertex(){painted_tint=COLOR;}
void fragment(){
 vec2 uv=UV;
 if(!glow_mode){
  // Top 30% is the attached rigid root; downstream tips lag behind it.
  float weight=pow(smoothstep(0.30,0.95,uv.y),1.7);
  float q=clock*6.28318530718/12.0;
  uv.x+=(sin(q+phase-uv.y*3.2)-sin(phase-uv.y*3.2))*weight*amplitude_pixels*TEXTURE_PIXEL_SIZE.x;
 }
 vec4 source=texture(TEXTURE,uv);
 if(glow_mode){
  float bulb=smoothstep(0.36,0.72,max(source.r,source.g))*(1.0-smoothstep(0.64,0.86,uv.y));
  source.rgb*=1.0+sin(clock*6.28318530718/8.0+phase)*0.12*bulb;
 }
 float inside=step(0.0,uv.x)*step(uv.x,1.0)*step(0.0,uv.y)*step(uv.y,1.0);
 COLOR=source*painted_tint*vec4(1.0,1.0,1.0,inside);
}
