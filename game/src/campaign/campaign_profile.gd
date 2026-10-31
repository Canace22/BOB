@warning_ignore_start("untyped_declaration")
class_name WhalebellyCampaignProfile
extends RefCounted
# Active main.gd + legacy player.gd values take priority over standalone demo defaults.
static func apply(player:TidePlayer) -> void:
	player.max_speed=265
	player.acceleration=1800
	player.friction=1800
	player.gravity=1050
	player.terminal_speed=850
	player.jump_height=570.0*570.0/(2*1050)
	player.short_jump_height=player.jump_height*.65
	player.double_jump_speed=570*.7
	player.wall_slide_speed=850.0/4
	player.wall_jump_x=265*1.2
	player.wall_jump_height=player.jump_height
	player.dash_speed=800
	player.dash_duration=.2
	player.dash_cooldown=.7
	player.slit_speed=800*1.3
	player.slit_duration=.3
	player.slit_cooldown=2
	player.coyote_time=.12
	player.jump_buffer_time=.12
	player.collision_size=Vector2(28,65)
	player.capsule_collision=true
	player.max_health=5
	player.contact_damage=1
	player.melee_damage=1
	player.orb_damage=2
	player.heavy_damage=2
	player.heal_amount=5
	player.hurt_invulnerability=1.2
	player.hurt_stun=.25
	player.knockback=160
	player.melee_reach=125
	player.melee_height=125
	player.downward_reach=65*.5
	player.heavy_radius=28*2.5
	player.orb_speed=265*2.2
	player.pogo_height=player.jump_height
	player.visual_scale=94.0/280.0
	player.world_collision_mask=1
