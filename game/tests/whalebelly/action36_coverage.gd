extends SceneTree
## Main actor integration coverage. Input actions/API calls and temporary fixtures are
## explicitly recorded; this is not OS-keyboard evidence or artistic approval.
const KEYS: Array[String] = ["idle","walk","run","jump","double_jump","wall_slide","wall_jump","dash","float","anchor","strike1","strike2","upper","pogo","orb","heavy","dive","parry","slit","heal","scan","interact","hurt","defeat","shadow_dash","great_slash","dash_slash","cyclone","crystal_dash","up_spell","abyss_scream","shadow_orb","dark_dive","swim","tram","turn"]
const DIRECT: Dictionary = {"dash":"A1_dash","strike1":"strike_01","strike2":"strike2","upper":"upper","pogo":"A3_anchor","orb":"A4_parry","heavy":"heavy","dive":"dive","parry":"parry","slit":"A5_slit","heal":"recover","scan":"scan","interact":"interact","shadow_dash":"shadow_dash","great_slash":"great_slash","dash_slash":"dash_slash","cyclone":"cyclone","crystal_dash":"crystal_dash","up_spell":"up_spell","abyss_scream":"abyss_scream","shadow_orb":"shadow_orb","dark_dive":"dark_dive","tram":"tram"}
const OUT: String = "res://build/qa/action36/coverage"
var host: Node2D
var p: WhalebellyCampaignPlayer
var rows: Array[Dictionary] = []
var fixtures: Array[Node] = []
var original_rings: Array = []
var events: Array[String] = []
var capture_enabled: bool = true
var logic_only: bool = false
var only_key: String = ""
var banner: Label

func case_context(key: String) -> Dictionary:
	var fixture_name: String={"wall_slide":"temporary collision wall","wall_jump":"temporary collision wall","anchor":"temporary ring coordinates","swim":"temporary water Area","tram":"temporary transit gate","hurt":"injected QA damage","defeat":"injected QA lethal damage"}.get(key,"reset position/resources between cases")
	var unlock: String={"dash":"dash","slit":"dash","float":"float","anchor":"anchor","swim":"chapter"}.get(key,"always")
	if TideSkillCatalog.ACTIONS.has(key):unlock=str(TideSkillCatalog.definition(key).unlock)
	return {"fixture":fixture_name,"formal_unlock":unlock,"practice_only_evidence":true}

func _initialize() -> void:
	capture_enabled=not "--no-capture" in OS.get_cmdline_user_args()
	logic_only="--logic-only" in OS.get_cmdline_user_args()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="): only_key=argument.trim_prefix("--only=")
	run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func release_inputs() -> void:
	for action: StringName in InputMap.get_actions():
		if str(action).begins_with("tp_") or str(action) in ["float","grapple","left","right","jump","interact"]: Input.action_release(action)
func movement(direction: float) -> String:
	return "tp_right" if direction>0 else "tp_left"
func atlas_contract(key: String) -> bool:
	var view: TideActionVisual=p.run_visual
	if not bool(view.available.get(key,false)): return false
	var spec: Dictionary=view.manifest[key]
	if int(spec.frame_count)<=0 or float(spec.fps)<=0.0 or spec.body.frames.size()!=int(spec.frame_count): return false
	var sequence: Array[Texture2D]=view.load_clip(key).body
	if sequence.size()!=int(spec.frame_count): return false
	for frame: AtlasTexture in sequence:
		if frame.atlas==null or frame.region.size.x<=0.0 or frame.region.size.y<=0.0: return false
		if not Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region): return false
	return true
func reset_actor(direction: float) -> void:
	release_inputs()
	for fixture: Node in fixtures:
		if is_instance_valid(fixture): fixture.queue_free()
	fixtures.clear()
	host.room.rings=original_rings.duplicate(true)
	p.skill_controller.cancel();p.skill_controller.input.clear();p.skill_controller.set_water(null)
	p.grapple_target=Vector2.INF;p.floating=false;p.transition_locked=false
	p.health=5;host.health=5;p.soul=99;host.player_soul=99
	p.controls_enabled=true;p.state="idle";p.state_duration=0.0;p.state_time=0.0
	p.dead_signal_sent=false;p.hitstop=0.0;p.damage_flash_left=0.0;p.invulnerable=99.0
	p.jump_count=0;p.jump_buffer=0.0;p.pending_action="";p.wall_lock=0.0
	for key: String in p.cooldowns: p.cooldowns[key]=0.0
	p.position=Vector2(650,520);p.velocity=Vector2.ZERO;p.facing=direction
	p.run_visual.last_facing=direction;p.run_visual.turn_left=0.0
	await tick(24)
	events.clear()

func add_wall(side: float) -> void:
	var wall:=StaticBody2D.new()
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new();box.size=Vector2(20,360)
	shape.shape=box;wall.add_child(shape)
	wall.position=p.position+Vector2(side*35,-150)
	host.add_child(wall);fixtures.append(wall)
	p.position.y-=150;p.velocity=Vector2(0,80)
	Input.action_press(movement(side))
	await tick(8)

func begin(key: String, direction: float) -> bool:
	match key:
		"idle": return true
		"walk","run":
			if key=="walk": Input.action_press("tp_walk")
			Input.action_press(movement(direction))
		"turn":
			p.facing=-direction;p.run_visual.last_facing=-direction;p.run_visual.previous_velocity=Vector2.ZERO
			Input.action_press(movement(direction))
		"jump","double_jump":
			Input.action_press("tp_jump")
			if key=="double_jump":
				await tick(6);Input.action_release("tp_jump");await tick(2);Input.action_press("tp_jump")
		"wall_slide": await add_wall(direction)
		"wall_jump":
			await add_wall(-direction)
			Input.action_release(movement(-direction));Input.action_press("tp_jump")
		"float":
			p.position.y-=150;p.velocity=Vector2(0,30);await tick(2);Input.action_press("float")
		"anchor":
			var target: Vector2=p.position+Vector2(direction*200,-150)
			host.room.rings=[[target.x,target.y-55]]
			Input.action_press("grapple")
		"hurt": return p.take_damage(1,p.global_position+Vector2(-direction*50,0),true)
		"defeat": return p.take_damage(99,Vector2.ZERO,true)
		"swim":
			var water:=TideSkillWater.new()
			var shape:=CollisionShape2D.new();var box:=RectangleShape2D.new();box.size=Vector2(240,180);shape.shape=box
			water.add_child(shape);water.position=p.position+Vector2(0,-110)
			host.add_child(water);fixtures.append(water)
			p.position=water.position+Vector2(0,10);p.velocity=Vector2.ZERO
			await tick(4)
		_:
			if key in ["pogo","dive","dark_dive"]:
				p.position.y-=100;p.velocity=Vector2.ZERO;await tick(2)
			if key=="heal":p.health=3;host.health=3
			if key=="interact":p.position=Vector2(150,600);await tick(3)
			if key=="tram":
				var gate:=TideTransitGate.new();gate.position=p.position
				host.add_child(gate);fixtures.append(gate);await tick(2)
			if key=="dash_slash":
				p.request_action("A1_dash");await tick(2)
			return p.request_action(str(DIRECT[key]))
	return true

func record_case(key: String, direction: float) -> void:
	await reset_actor(direction)
	var title: String=str(p.run_visual.manifest.get(key,{}).get("title",key))
	host.notify("F9: "+title+" / "+("D" if direction>0 else "A"))
	var context: Dictionary=case_context(key)
	banner.text="PRACTICE FIXTURE / "+key+" / "+("RIGHT" if direction>0 else "LEFT")+"\n"+str(context.fixture)+" | Formal unlock: "+str(context.formal_unlock)
	var start: Vector2=p.position
	var accepted: bool=await begin(key,direction)
	var seen: bool=false
	var logical_seen: bool=false
	var selected: Dictionary={}
	var single_body: bool=false
	var direction_ok: bool=false
	var frame_ids: Dictionary={}
	var first_index: int=1000000
	var last_index: int=-1
	var first_position: Vector2=p.position
	var capture_frame: Image
	var captured_events: int=0
	var duration: int=maxi(30,ceili(float(TideSkillCatalog.definition(str(DIRECT.get(key,key))).get("duration",0.0))*60.0)+8)
	if key in ["idle","walk","run","float","swim"]:
		var spec: Dictionary=p.run_visual.manifest.get(key,{})
		duration=maxi(duration,ceili(float(spec.get("frame_count",1))/maxf(float(spec.get("fps",12)),1.0)*120.0)+4)
	for frame: int in duration:
		await tick(1)
		var view: TideActionVisual=p.run_visual
		selected[view.current_key]=true
		logical_seen=logical_seen or view.current_key==key
		if view.current_key!=key or not view.active: continue
		seen=true
		single_body=view.sprite.visible and not p.body.visible and not p.get_node("Visual/Legs").visible
		direction_ok=signf(p.get_node("Visual").scale.x)==direction and not view.sprite.flip_h
		frame_ids[str(view.sprite.texture.get_instance_id())]=true
		first_index=mini(first_index,view.frame_index);last_index=maxi(last_index,view.frame_index)
		if capture_frame==null and frame>=2 and capture_enabled and DisplayServer.get_name()!="headless":
			await process_frame;await RenderingServer.frame_post_draw
			capture_frame=root.get_texture().get_image()
		if events.size()>captured_events and capture_enabled and DisplayServer.get_name()!="headless":
			captured_events=events.size()
			await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT.path_join(key+("-right" if direction>0 else "-left")+"-event-"+str(captured_events)+".png"))
	if capture_frame!=null:capture_frame.save_png(OUT.path_join(key+("-right.png" if direction>0 else "-left.png")))
	var row: Dictionary={"key":key,"direction":direction,"accepted":accepted,"atlas_available":p.run_visual.available.get(key,false),"observed_actual_body":seen,"single_body":single_body,"direction_transform":direction_ok,"distinct_frames":frame_ids.size(),"start":[start.x,start.y],"first":[first_position.x,first_position.y],"end":[p.position.x,p.position.y],"events":events.duplicate(),"method":"action input" if not DIRECT.has(key) else "request_action compatibility API"}
	row["logical_pose_reached"]=logical_seen
	row["context"]=context
	row["selected_keys"]=selected.keys()
	row["atlas_contract"]=atlas_contract(key)
	row["minimum_frame_index"]=first_index if seen else -1
	row["maximum_frame_index"]=last_index
	row["pass"]=accepted and logical_seen if logic_only else accepted and seen and single_body and direction_ok and row.atlas_contract
	if not logic_only and key=="wall_jump":row["pass"]=row["pass"] and last_index==int(p.run_visual.manifest[key].frame_count)-1
	rows.append(row)
	print("COVERAGE ",key," ",direction," ",row["pass"]," frames=",frame_ids.size())

func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_full_abilities=true;host.integration_external_test=true
	root.add_child(host);current_scene=host
	var overlay:=CanvasLayer.new();overlay.layer=100;root.add_child(overlay)
	banner=Label.new();banner.position=Vector2(16,50)
	banner.add_theme_font_size_override("font_size",18)
	banner.add_theme_color_override("font_outline_color",Color.BLACK)
	banner.add_theme_constant_override("outline_size",6);overlay.add_child(banner)
	await tick(45)
	host.practice=true
	p=host.player;p.automatic_doors=false
	original_rings=host.room.get("rings",[]).duplicate(true)
	p.animation_tag.connect(func(tag: String) -> void:events.append(tag))
	p.skill_effect.connect(func(key: String,event: String,_origin: Vector2,_direction: float) -> void:events.append(key+":"+event))
	for key: String in KEYS:
		if not only_key.is_empty() and not key in only_key.split(","): continue
		for direction: float in [1.0,-1.0]: await record_case(key,direction)
	release_inputs()
	var failures: int=rows.filter(func(row: Dictionary) -> bool:return not row["pass"]).size()
	var filename: String="report-"+only_key+".json" if not only_key.is_empty() else ("report-logic.json" if logic_only else "report.json")
	FileAccess.open(OUT.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify({"logic_only":logic_only,"selected_key":only_key,"method":"Formal main scene and shared player; isolated QA unlock; direct action API and engine InputMap actions; wall/water/gate/ring are temporary test fixtures; no OS-keyboard or artistic-approval claim","rows":rows,"failures":failures},"\t"))
	await host.graceful_quit(1 if failures else 0)
