shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform sampler2D backing;
void fragment(){
 COLOR=mix(texture(TEXTURE,UV),texture(backing,UV),1.0-smoothstep(280.0/720.0,360.0/720.0,UV.y));
}
