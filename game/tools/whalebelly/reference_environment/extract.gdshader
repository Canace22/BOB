shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform sampler2D selection : filter_linear;
uniform int mode = 0;
uniform vec2 canvas_size=vec2(1280.0,720.0);
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float a=texture(selection,UV).r;
 if(mode==1){a*=smoothstep(-0.018,0.040,c.r-c.b*0.64);}
 if(mode==2){
  vec2 px=1.0/canvas_size;
  vec3 mean=vec3(0.0);
  for(int x=-1;x<=1;x++){for(int y=-1;y<=1;y++){mean+=texture(TEXTURE,UV+vec2(float(x),float(y))*px*5.5).rgb/9.0;}}
  float d=dot(mean-c.rgb,vec3(.22,.56,.22));
  a*=smoothstep(.012,.055,d)*smoothstep(.012,.07,c.b-c.r);
 }
 if(mode==3){a*=smoothstep(.005,.045,c.g*.72-c.b)*(1.0-smoothstep(.58,.82,c.r));}
 if(mode==4){
  float ivory=smoothstep(-0.018,0.040,c.r-c.b*0.64);
  float dark=1.0-smoothstep(0.20,0.32,c.b);
  a*=max(ivory,dark);
 }
 COLOR=vec4(c.rgb,a);
}
