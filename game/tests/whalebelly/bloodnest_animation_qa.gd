extends "res://tests/whalebelly/world_skeleton.gd"
## Camera/time fixtures for appearance; separate real Input fight for combat flow.

func frame() -> Image:
	await process_frame
	RenderingServer.force_draw()
	return root.get_texture().get_image()

func run() -> void:
	output="res://build/qa/bloodnest-animation-v5"
	await setup()
	host.abilities={"dash":true,"float":true,"anchor":true}
	host.defeated={}
	await host.flow_setup(room_index("R2-04"),[1920,1520])
	host.player.invulnerable=99999.0
	await tick(8)
	var actor: KitEncounter=host.enemies[0].actor
	verify("actual room uses a vortex Boss",actor.body is KitBloodnestVisual)
	var health: int=actor.data.hp
	var hurt: Vector2=actor.hurt_rect().size
	paused=true
	host.set_process(false)
	actor.data.pos=Vector2(2250,1520)
	actor.position=actor.data.pos
	host.zoomed=true
	host.update_camera()
	host.camera.force_update_scroll()
	for layer: KitParallaxLayer in host.scenery.find_children("*","KitParallaxLayer",true,false):
		layer.position=layer.offset_for(host.camera.get_screen_center_position())
	await frame()
	var frozen: Transform2D=root.canvas_transform
	host.camera.enabled=false
	var clock: float=0.0
	var phases: Array=[ ["rest",1.9], ["tell",1.0], ["act",1.5], ["recover",0.7], ["rest",1.0] ]
	var folder: String=output.path_join("frames")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var index: int=0
	var core_pixels: int=0
	for phase: Array in phases:
		var state_: String=phase[0]
		var duration: float=phase[1]
		actor.body.facing=-1.0
		for i: int in int(duration*20):
			clock+=0.05
			root.canvas_transform=frozen
			# Fixed actor position isolates formation from the existing lane translation.
			actor.Visuals.update(actor.body,actor.core,state_,i/20.0,duration,clock)
			var captured: Image=await frame()
			if "--clip" in OS.get_cmdline_user_args(): captured.save_png(folder.path_join("%04d.png"%index))
			if i==int(duration*10): captured.save_png(output.path_join(state_+".png"))
			captured=null
			index+=1
		verify(state_+" keeps finite original health and hurt geometry",actor.data.hp==health and actor.hurt_rect().size==hurt)
	verify("pool remains bounded after the full sequence",actor.body.members.size()==44)
	if "--combat-v6" in OS.get_cmdline_user_args():await impact_clip(actor,frozen)
	var a: Image=await frame()
	actor.core.hide()
	var b: Image=await frame()
	for y: int in range(0,a.get_height(),2):
		for x: int in range(0,a.get_width(),2):
			if a.get_pixel(x,y)!=b.get_pixel(x,y): core_pixels+=1
	verify("core visibly contributes at gameplay scale",core_pixels>50,core_pixels)
	actor.core.show()
	a=null
	b=null
	# Hold every node transform: only the bitmap's appendages / shell highlights move.
	var held_positions: Array=actor.body.members.map(func(m: Dictionary)->Vector2:return m.node.position)
	a=await frame()
	for member: Dictionary in actor.body.members:
		(member.node.material as ShaderMaterial).set_shader_parameter("clock",clock+0.37)
	b=await frame()
	var moving_pixels: int=0
	for y: int in range(0,a.get_height(),2):
		for x: int in range(0,a.get_width(),2):
			if a.get_pixel(x,y)!=b.get_pixel(x,y): moving_pixels+=1
	verify("local shrimp motion is visible independently of its route",moving_pixels>10,moving_pixels)
	verify("local motion does not translate the held shrimp",held_positions==actor.body.members.map(func(m: Dictionary)->Vector2:return m.node.position))
	a=null
	b=null
	host.camera.enabled=true
	host.set_process(true)
	paused=false
	# Reset the actual encounter after the appearance fixture.
	host.defeated={}
	host.abilities.erase("pressure")
	await host.flow_setup(room_index("R2-04"),[1400,1520])
	host.player.invulnerable=0.0
	await takes_hit("unchanged real lane sweep damages once",12.0)
	host.player.invulnerable=99999.0
	await fight("real attack inputs defeat the redesigned Boss",9000)
	if "--combat-v6" in OS.get_cmdline_user_args():
		verify("real Input damage reaches the local presentation hook",host.enemies[0].actor.body.impact.hit_count>0)
	verify("defeat grants pressure through existing save flow",host.abilities.get("pressure",false) and host.defeated.get("R2-04:0",false) and host.last_save_ok)
	await shot("defeated")
	verify("no visible Boss remains after defeat",not host.enemies[0].actor.body.visible)
	await pass_door("R2-03")
	verify("normal swarm uses its original presentation",not host.enemies[0].actor.body is KitBloodnestVisual)
	print("BLOODNEST_ANIMATION_COMPLETE failed=",failed)
	await host.graceful_quit(1 if failed else 0)

func impact_clip(actor: KitEncounter, frozen: Transform2D) -> void:
	var folder: String=output.path_join("impact-frames")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var hp: int=actor.data.hp
	var hurt: Rect2=actor.hurt_rect()
	var initial: Image=await frame()
	var hud: PackedByteArray=initial.get_region(Rect2i(0,0,1280,150)).get_data()
	initial=null
	var held_camera: bool=true
	for i: int in 126:
		root.canvas_transform=frozen
		var state_: String="rest" if i<60 else ("act" if i<105 else "recover")
		var duration: float=1.9 if state_=="rest" else (1.5 if state_=="act" else 0.7)
		if i==24 or i==82:actor.on_damaged() # Declared timing fixture; real Input is checked below.
		var state_time: float=i/30.0 if i<60 else ((i-60)/30.0 if i<105 else (i-105)/30.0)
		KitEncounterVisual.update(actor.body,actor.core,state_,state_time,duration,7.0+i/30.0)
		var captured: Image=await frame()
		if i==28 or i==86:captured.save_png(output.path_join("hurt-rest.png" if i<60 else "hurt-charge.png"))
		if i==26 or i==84:captured.save_png(output.path_join("hit-peak-rest.png" if i<60 else "hit-peak-charge.png"))
		if i==28:verify("local impact cannot flash HUD or background",captured.get_region(Rect2i(0,0,1280,150)).get_data()==hud)
		if "--clip" in OS.get_cmdline_user_args():captured.save_png(folder.path_join("%04d.png"%i))
		captured=null
		held_camera=held_camera and root.canvas_transform==frozen
	verify("damage fixture holds the camera",held_camera)
	verify("visual damage leaves exact health and hurt geometry unchanged",actor.data.hp==hp and actor.hurt_rect()==hurt)
	verify("impact pool stays bounded across rest and charge",actor.body.impact.sparks.size()==8 and actor.body.impact.arcs.size()==2)
	verify("legacy full-body flash is suppressed for the local reaction",actor.body.modulate==Color.WHITE)
