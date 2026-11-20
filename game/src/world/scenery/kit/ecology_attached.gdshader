shader_type canvas_item;
uniform float clock = 0.0;
uniform float phase = 0.0;
uniform float period = 11.0;
uniform float amplitude_pixels = 3.5;
uniform float glow_strength = 0.07;
varying vec4 painted_tint;
void vertex(){ painted_tint = COLOR; }
void fragment(){
 vec2 uv = UV;
 // Bottom 25% of the painted colony is rigid, not a floating whole sprite.
 float weight = pow(1.0-smoothstep(0.2,0.75,uv.y),1.6);
 float q = clock*6.28318530718/period;
 uv.x += (sin(q+phase-uv.y*2.4)-sin(phase-uv.y*2.4))*weight*amplitude_pixels*TEXTURE_PIXEL_SIZE.x;
 vec4 source = texture(TEXTURE,uv);
 float bulb = smoothstep(0.64,0.9,max(source.r,source.g))*(1.0-smoothstep(0.55,0.75,uv.y));
 source.rgb *= 1.0+sin(q*0.5+phase)*glow_strength*bulb;
 float inside = step(0.0,uv.x)*step(uv.x,1.0);
 COLOR = source*painted_tint*vec4(1.0,1.0,1.0,inside);
}
