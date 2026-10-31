shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform sampler2D coverage : filter_linear;
void fragment(){
 // Extend the hidden backing beneath cut edges by three pixels. This is
 // occlusion padding, not a duplicate of moving foliage (removed in paint).
 float a=1.0;
 for(int x=-1;x<=1;x++)for(int y=-1;y<=1;y++){
  a=min(a,texture(coverage,UV+vec2(float(x),float(y))*vec2(3.0/1280.0,3.0/720.0)).a);
 }
 COLOR=vec4(texture(TEXTURE,UV).rgb,1.0-a);
}
