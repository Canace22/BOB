extends Node
var host: Node
var checks: Array=[]

func check(id: String,value: bool) -> void:
	checks.append({"id":id,"passed":value})
	print("MECHANISM_CHECK ",id," ",value)

func run(main: Node) -> Dictionary:
	host=main
	# These are deterministic local fixtures to inspect mechanisms, not a full traversal claim.
	host.change_room(2)
	await get_tree().create_timer(0.3).timeout
	var p=host.level.player
	p.position=Vector2(18,14)*64
	p.velocity=Vector2.ZERO
	await get_tree().create_timer(0.5).timeout
	check("membrane_waits_for_warning",host.level.route_system.membrane_offset<0.1)
	await get_tree().create_timer(1.2).timeout
	check("membrane_moves_contact_together",host.level.route_system.membrane_offset>15 and p.is_on_floor() and absf(p.position.y-host.level.route_system.membrane_body.position.y)<4)
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(host.evidence_dir+"/membrane.png")
	host.change_room(1)
	await get_tree().create_timer(0.3).timeout
	p=host.level.player
	p.position=Vector2(24,16)*64
	p.velocity=Vector2.ZERO
	p.invulnerable=0
	host.game.hp=4
	host.level.route_system.clock=0
	await get_tree().create_timer(0.65).timeout
	check("shrimp_warning_no_damage",host.game.hp==4)
	await get_tree().create_timer(0.35).timeout
	check("shrimp_active_hits_once",host.game.hp==3 and p.invulnerable>0)
	await get_tree().create_timer(0.3).timeout
	check("shrimp_recovery_no_chain_hit",host.game.hp==3)
	host.change_room(4)
	await get_tree().create_timer(0.3).timeout
	p=host.level.player
	var hp=host.game.hp
	p.position=Vector2(8,16.2)*64
	p.velocity=Vector2.ZERO
	await get_tree().create_timer(0.15).timeout
	check("teaching_bed_returns_without_damage",host.game.hp==hp and p.position.x<6*64 and p.position.y<15*64)
	return {"passed":checks.all(func(c):return c.passed),"checks":checks,"fixture":"Player placement and cycle reset only for mechanism isolation; no traversal claim."}
