shader_type canvas_item;
uniform sampler2D water_mask;
uniform float clock=0.0;
uniform float period=13.0;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float weight=texture(water_mask,UV).a;
 float q=clock*6.28318530718/period;
 // Exposure drift on the existing distant water only; no displacement of bone/road.
 float shimmer=sin(q+UV.y*7.0)-sin(UV.y*7.0);
 c.rgb*=1.0+shimmer*weight*0.025;
 COLOR=c;
}
