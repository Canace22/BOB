shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform bool split_lower = false;
uniform bool legs_only = false;
uniform vec2 root_pixel = vec2(305.0,413.0);
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 vec2 p=UV/TEXTURE_PIXEL_SIZE;
 float lower=smoothstep(root_pixel.y-91.0,root_pixel.y-85.0,p.y);
 float side=1.0-smoothstep(78.0,84.0,abs(p.x-root_pixel.x));
 float region=lower*side;
 if(legs_only){c.a*=region;}else if(split_lower){c.a*=1.0-region;}
 COLOR=vec4(mix(c.rgb,vec3(1.0),flash*0.8),c.a)*COLOR;
}
