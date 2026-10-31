extends Node
var host: Node
var checks: Array=[]

func run(main: Node) -> Dictionary:
	host=main
	process_mode=Node.PROCESS_MODE_ALWAYS
	host.game.reset_game()
	host.change_room(1)
	await wait(0.4)
	var middle=host.level.environment_layers[1]
	var front=host.level.environment_layers[2]
	var a=middle.get_effect_state()
	var la=front.get_effect_state()
	await wait(0.7)
	var b=middle.get_effect_state()
	var lb=front.get_effect_state()
	check("all_six_assets",lb.sprites_loaded.size()==6)
	check("environment_moves",a.fog_offset!=b.fog_offset and a.organism_offset!=b.organism_offset and la.water_offset!=lb.water_offset and la.baleen_angle!=lb.baleen_angle and la.light_energy!=lb.light_energy)
	await capture("sample-idle")
	host.set_overlay("pause")
	await wait(0.1)
	var frozen=middle.elapsed
	await wait(0.2)
	check("environment_pauses",middle.elapsed==frozen)
	host.set_overlay("")
	host.tap("lamp")
	await wait(0.12)
	check("lamp_switch_off",host.level.player.lamp_light.energy==0)
	host.tap("lamp")
	await wait(0.12)
	check("lamp_switch_on",host.level.player.lamp_light.energy>0)
	var elapsed=0.0
	var captured=false
	while host.game.room_index==1 and elapsed<40:
		host.drive_e2e(1.0/60)
		if not captured and host.level.player.position.x>11*64:
			captured=true
			await capture("sample-combat")
		elapsed+=1.0/60
		await get_tree().physics_frame
	release()
	check("sample_room_traversed",host.game.room_index==2)
	check("attack_hit_fx",host.effect_counts.get("hit",0)>0)
	check("enemy_death_fx",host.effect_counts.get("death",0)>0)
	host.change_room(0)
	await wait(0.4)
	host.tap("heavy")
	await wait(0.35)
	await capture("heavy-pulse")
	check("heavy_event_fx",host.effect_counts.get("heavy",0)>0)
	await wait(0.6)
	# Death fixture is explicitly separate from normal room traversal.
	host.game.hp=1
	host.level.player.invulnerable=0
	host.level.player.take_hit(host.level.player.position.x+50)
	await wait(0.08)
	await capture("player-death")
	await wait(0.4)
	check("death_respawn",host.game.hp==4 and not host.level.player.respawning)
	return {"passed":checks.all(func(c):return c.passed),"checks":checks,"before":a,"after":b,"foreground_before":la,"foreground_after":lb,"effect_counts":host.effect_counts,"fixture_note":"Actual R1-02 Input traversal. Heavy and player death are isolated recovery fixtures; no claim they prove full-game traversal."}

func wait(seconds: float) -> void: await get_tree().create_timer(seconds,true).timeout
func check(id: String,passed: bool) -> void:
	checks.append({"id":id,"passed":passed})
	print("SAMPLE_CHECK ",id," ",passed)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(host.evidence_dir+"/"+name+".png")
func release() -> void:
	for action in ["left","right","jump","attack","heavy","heal","dash","interact"]: Input.action_release(action)
