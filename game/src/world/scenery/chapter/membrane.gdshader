shader_type canvas_item;
uniform float membrane_drop=0.0;
void fragment(){
 vec2 size=1.0/TEXTURE_PIXEL_SIZE;
 vec2 p=UV*size-vec2(16.0);
 float w=sin(clamp((p.x-680.0)/320.0,0.0,1.0)*3.14159265);
 float zone=smoothstep(530.0,590.0,p.y)*(1.0-smoothstep(690.0,740.0,p.y));
 COLOR=texture(TEXTURE,UV-vec2(0.0,membrane_drop*w*zone)/size);
}
