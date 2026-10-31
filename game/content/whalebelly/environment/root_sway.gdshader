shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
uniform float phase = 0.0;
uniform float strength = 1.0;
uniform bool root_at_bottom = false;
uniform bool curtain = false;
uniform vec2 source_origin = vec2(0.0);
void fragment() {
 float v = root_at_bottom ? 1.0-UV.y : UV.y;
 float weight = smoothstep(0.28,1.0,v);
 if(curtain){
  vec2 source=source_origin+UV/TEXTURE_PIXEL_SIZE;
  // The upper roof/side attachment pixels are rigid. Only hanging tips sway.
  weight*=smoothstep(278.0,315.0,source.x)*(1.0-smoothstep(1150.0,1180.0,source.x));
  weight*=smoothstep(70.0,150.0,source.y)*(1.0-smoothstep(300.0,330.0,source.y));
 }
 // Two continuous waves give each cluster a different tip motion; roots stay pinned.
 float wave = (sin(clock*0.78+phase+v*1.7)-sin(phase+v*1.7))*0.38;
 wave += (sin(clock*1.17+phase*1.3+UV.x*3.0)-sin(phase*1.3+UV.x*3.0))*0.12;
 float dx = wave*weight*strength;
 vec2 uv = UV-vec2(dx*TEXTURE_PIXEL_SIZE.x,0.0);
 COLOR = texture(TEXTURE,uv);
 if(uv.x<0.0 || uv.x>1.0) COLOR.a=0.0;
}
