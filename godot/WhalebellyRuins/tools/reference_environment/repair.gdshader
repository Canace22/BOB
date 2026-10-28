shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform sampler2D moving_mask : filter_nearest;
void fragment(){
 vec4 original=texture(TEXTURE,UV);
 float mask=texture(moving_mask,UV).a;
 if(mask>0.01){
  vec3 sum=vec3(0.0);
  float total=0.0;
  for(int ring=1;ring<=4;ring++){
   for(int ray=0;ray<8;ray++){
    float angle=float(ray)*0.785398;
    vec2 p=UV+vec2(cos(angle),sin(angle))*float(ring)*3.0*TEXTURE_PIXEL_SIZE;
    float valid=1.0-step(0.01,texture(moving_mask,p).a);
    float w=valid/float(ring*ring);
    sum+=texture(TEXTURE,p).rgb*w;
    total+=w;
   }
  }
  if(total>0.0)original.rgb=mix(original.rgb,sum/total,smoothstep(0.01,0.15,mask));
 }
 COLOR=original;
}
