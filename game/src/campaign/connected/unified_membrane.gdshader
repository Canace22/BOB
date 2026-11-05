shader_type canvas_item;
uniform float membrane_drop=0.0;
void vertex(){
 float w=sin(clamp((VERTEX.x-5047.0)/320.0,0.0,1.0)*3.14159265);
 VERTEX.y+=membrane_drop*w;
}
