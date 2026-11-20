shader_type canvas_item;
render_mode unshaded;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float danger : hint_range(0.0, 1.0) = 0.0;
uniform float weak_glow : hint_range(0.0, 1.0) = 0.0;
uniform vec2 weak_center=vec2(0.0);
uniform vec2 weak_radius=vec2(0.01);
void fragment() {
	// 预警只作用于敌人位图；与共用受击闪白共存，不改变伤害或图集。
	vec4 source = COLOR;
	vec3 warning = mix(source.rgb, vec3(1.0, 0.10, 0.035), danger * 0.65);
	warning += vec3(0.22, 0.018, 0.006) * danger;
	float neighbor = max(texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x * 2.0, 0.0)).a,
		texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x * 2.0, 0.0)).a);
	neighbor = max(neighbor, max(texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y * 2.0)).a,
		texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y * 2.0)).a));
	float rim = max(0.0, neighbor - source.a) * danger * 0.65;
	vec3 color = mix(warning, vec3(1.0, 0.25, 0.08), rim);
	// 弱点只染压囊的既有像素，保持原Alpha，不将整只敌人染黄。
	float weak_mask=1.0-smoothstep(0.72,1.0,length((UV-weak_center)/weak_radius));
	float weak=weak_glow*weak_mask*step(0.03,source.a);
	color=mix(color,vec3(1.0,0.86,0.20),weak*0.80);
	color+=vec3(0.14,0.09,0.0)*weak;
	COLOR = vec4(mix(color, vec3(1.0, 0.95, 0.78), flash * 0.78), max(source.a, rim));
}
