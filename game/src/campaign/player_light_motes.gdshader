shader_type canvas_item;
render_mode blend_add, unshaded;
uniform vec2 light_origin = vec2(0.0);
uniform float effect_time = 0.0;
uniform float strength = 0.7;
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
}

void fragment() {
	vec2 local = world_position-light_origin;
	float depth = clamp(-local.y/590.0,0.0,1.0);
	float width = mix(145.0,42.0,depth);
	float cone = 1.0-smoothstep(width*0.35,width,abs(local.x+depth*20.0));
	cone *= smoothstep(-620.0,-500.0,local.y);
	cone *= 1.0-smoothstep(-55.0,4.0,local.y);
	vec2 q = (UV-0.5)*2.0;
	float soft = pow(max(0.0,1.0-dot(q,q)),2.0);
	float shimmer = 0.78+0.22*sin(effect_time*0.7+world_position.x*0.09);
	COLOR.a *= soft*cone*strength*shimmer;
}
