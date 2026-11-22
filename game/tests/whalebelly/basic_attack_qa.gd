extends SceneTree
## 正式入口真实J键专项；只隔离初始进度，不触碰玩家试玩档。
class ProbeHost extends WhalebellyMain:
	func save_path() -> String: return "user://whalebelly/basic-attack-qa.json"
class Envelope extends Node2D:
	var player: TideCombatPlayer
	func _draw() -> void:
		var c: TideSkillController=player.skill_controller
		if not c.active or c.visual_key not in ["strike1","strike2"]: return
		var reach: float=float(c.data.reach)
		var height: float=float(c.data.height)
		draw_rect(Rect2(Vector2(0 if player.facing>0 else -reach,float(c.data.bottom)-height),Vector2(reach,height)),Color(1,0.6,0.1,0.8),false,1.0)
var host: WhalebellyMain
var failures: int=0
func _initialize() -> void: run.call_deferred()
func press(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func run() -> void:
	root.size=Vector2i(1280,720)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(ProbeHost)
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	for frame: int in 45: await physics_frame
	var p: TideCombatPlayer=host.player
	var left: bool=OS.get_cmdline_user_args().has("--left")
	p.facing=-1.0 if left else 1.0
	var overlay:=Envelope.new()
	overlay.player=p
	overlay.z_index=20
	p.add_child(overlay)
	var sequence: Array[String]=[]
	var maxima: Array[int]=[]
	var seen: int=-1
	var captured: Dictionary={}
	for frame: int in 150:
		if frame<100 and frame%6==0: press(KEY_J,true)
		if frame%6==1: press(KEY_J,false)
		await physics_frame
		overlay.queue_redraw()
		var c: TideSkillController=p.skill_controller
		if not c.active: continue
		if c.attack_id!=seen:
			sequence.append(c.visual_key)
			maxima.append(0)
			seen=c.attack_id
		maxima[-1]=maxi(maxima[-1],p.action_visual.frame_index)
		print("BASIC_FRAME tick=",frame," key=",c.visual_key," time=",c.elapsed," frame=",p.action_visual.frame_index)
		var label: String=c.visual_key+"-"+str(p.action_visual.frame_index)
		if DisplayServer.get_name()!="headless" and p.action_visual.frame_index in [6,8,12] and not captured.has(label):
			captured[label]=true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/qa/basic-attack-"+("left-" if left else "")+label+".png")
	for i: int in sequence.size():
		if sequence[i]!=("strike1" if i%2==0 else "strike2") or maxima[i]<12: failures+=1
	print("BASIC_FORMAL sequence=",sequence," max_frames=",maxima," failures=",failures)
	await host.graceful_quit()
