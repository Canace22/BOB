shader_type canvas_item;
uniform float clock = 0.0;
uniform vec2 chapter_origin = vec2(0.0);
varying vec2 world_pixel;
void vertex(){world_pixel=VERTEX+(MODEL_MATRIX[3].xy)+chapter_origin;}
void fragment(){
 float a=sin(world_pixel.x*.003+world_pixel.y*.006-clock*.35);
 float b=sin(world_pixel.x*.0013-world_pixel.y*.003+clock*.21);
 COLOR.rgb*=vec3(.72,.80,.86)*(1.0+.022*a+.012*b);
}
