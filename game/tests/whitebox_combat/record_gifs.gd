extends Node
## 固定60Hz操作回放，每3帧导出一次真实GPU画面；GIF按20fps还原，不受PNG写盘拖慢。

const OUT: String = "res://build/qa/skill-gifs/"
const CLIPS: Array[Array] = [
	["01-basic","普攻连击","J → J：地面站定出手",132],
	["02-rise","挑潮 · 上挑","W+J：近身挑空起手",132],
	["03-triple","逐潮 · 三段斩","D+K → K → A+K：逐次出招换向",144],
	["04-wide","断潮 · 范围横扫","地面 S+J：双侧击退清场",132],
	["05-charge","破浪 · 撞击升空","A/D+L：单次接近，停步撞击，高挑空",132],
	["06-flurry","叠潮 · 五段连斩","点 E 后 J：原地连续压制，末段击倒",144],
	["07-dash","向前冲刺","L（不按A/D）：接近与避伤",132],
	["08-guard","时机格挡","I：挡住来袭攻击，打开反击窗口",144],
	["09-cancel","后跳撤招 · 原姿势白影","攻击中 S+L：原地留下被打断动作当前帧",144],
	["10-backcut","退潮 · 后跳回斩","S+L → J：退开同时补上一击",132],
	["11-cyclone","旋潮 · 回旋斩","点 E 后 K：周身多段攻击",144],
	["12-orb","叉鸣弹","点 E 后 L：向前发射共鸣弹",132],
	["13-heavy","重鸣","点 Q、E 后 I：近身范围攻击",132],
	["14-heal","调息恢复","点 E 后只按住 I：恢复生命",168],
	["15-charged","蓄潮 · 蓄力重劈","长按 J 后松开",156],
	["16-dashslash","奔潮 · 冲刺劈砍","L → J：冲刺中接斩击",132],
	["17-upspell","潮声 · 上涌","点 E 松开后 W+L：向上释放潮术",132],
	["18-dive","坠潮 · 下潜重击","点 E 松开后空中 S+L：落地范围冲击",156],
	["19-crystal","凝流 · 蓄力长冲","点 Q、E 后只按住 L 再松开",180],
	["20-slit","潜隙穿行","点 Q、E 后 K：快速穿越",132],
	["21-pogo","空中下刺反弹","空中 S + J：命中后向上反弹",156],
	["22-doublejump","空中二段跳","空格 → 空格",144],
	["23-scan","照见 · 骨音探潮","点 Q、E 后 J：短暂探查周围",132],
	["24-upper","方向上挑","W + J：方向派生攻击",132]
]
var arena: Node2D
var camera: Camera2D
var overlay: CombatWhiteboxShareOverlay
var observed: PackedStringArray = []
var index: Array[Dictionary] = []
var output_root: String = OUT
var only_clip: String = ""

func _ready() -> void:
	arena = get_parent()
	arena.player.animation_tag.connect(func(tag: String) -> void: observed.append(tag))
	_run.call_deferred()

func _process(_dt: float) -> void:
	if camera != null: camera.position.x = clampf(arena.player.position.x+50.0,600.0,1000.0)

func release_inputs() -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)

func frames(count: int) -> void:
	for i: int in count: await get_tree().process_frame

func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--gif-only="): only_clip = argument.trim_prefix("--gif-only=")
		if argument.begins_with("--gif-output="): output_root = argument.trim_prefix("--gif-output=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(output_root)
	arena.hud.hide()
	arena.event_hud.hide()
	arena.timeline.hide()
	camera = Camera2D.new()
	camera.position = Vector2(600,420)
	camera.zoom = Vector2(2.0,2.0)
	arena.add_child(camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	overlay = CombatWhiteboxShareOverlay.new()
	overlay.arena = arena
	layer.add_child(overlay)
	for clip: Array in CLIPS:
		if not only_clip.is_empty() and str(clip[0]) != only_clip: continue
		release_inputs()
		arena.reset_arena()
		arena.enemy.auto_attack = false
		arena.enemy.armored = false
		arena.enemy.health = 60
		if clip[0] == "04-wide":
			arena.toggle_group()
			arena.extra_targets[0].position.x = 430
			arena.extra_targets[1].position.x = 720
		if clip[0] == "05-charge": arena.player.position.x = 450
		if clip[0] == "14-heal": arena.player.health = 3
		await frames(6)
		observed.clear()
		overlay.headline = str(clip[1])
		overlay.hint = str(clip[2])
		overlay.counter = "%02d / %02d" % [index.size()+1,1 if not only_clip.is_empty() else CLIPS.size()]
		var directory: String = output_root+str(clip[0])+"/"
		DirAccess.make_dir_recursive_absolute(directory)
		var saved: int = 0
		for tick: int in int(clip[3]):
			act(str(clip[0]),tick)
			await get_tree().process_frame
			if tick % 3 == 0:
				await RenderingServer.frame_post_draw
				var path: String = directory+"%04d.png" % saved
				if get_viewport().get_texture().get_image().save_png(path) != OK: push_error("GIF frame write failed")
				saved += 1
		# 保存快照，避免后续 clear 修改已经记录的技能事件。
		index.append({"id":clip[0],"title":clip[1],"hint":clip[2],"frames":saved,"fps":20,"tags":observed.duplicate()})
		print("GIF CLIP: ",clip[0]," frames=",saved," tags=",JSON.stringify(observed))
	release_inputs()
	var file := FileAccess.open(output_root+"index.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(index,"  "))
	print("GIF RECORDING COMPLETE: ",index.size()," clips")
	get_tree().quit()

func request(key: String) -> void:
	if not arena.player.request_action(key): push_error("GIF skill request rejected: "+key)

func press(key: String, down: bool) -> void:
	if down: Input.action_press(key)
	else: Input.action_release(key)

func act(id: String, tick: int) -> void:
	var singles: Dictionary = {"02-rise":"wb_rise","04-wide":"wb_draw","05-charge":"wb_charge","06-flurry":"wb_flurry","07-dash":"A1_dash","11-cyclone":"cyclone","12-orb":"A4_parry","13-heavy":"heavy","17-upspell":"up_spell","20-slit":"A5_slit","23-scan":"scan","24-upper":"upper"}
	if tick == 12 and singles.has(id): request(str(singles[id]))
	match id:
		"01-basic":
			if tick in [12,30]: press("tp_attack",true)
			if tick in [14,32]: press("tp_attack",false)
		"03-triple":
			if tick in [12,32,52]:
				if tick == 52: press("tp_left",true)
				request("wb_drive")
			if tick == 54: press("tp_left",false)
		"08-guard":
			if tick == 12: arena.enemy.begin_attack()
			if tick == 52: request("parry")
		"09-cancel":
			if tick == 12: request("wb_draw")
			if tick == 21 and not arena.player.try_backstep(): push_error("GIF backstep rejected")
			if tick == 70: arena.reset_arena()
			if tick == 78: request("wb_flurry")
			if tick == 92 and not arena.player.try_backstep(): push_error("GIF second backstep rejected")
		"10-backcut":
			if tick == 12: arena.player.try_backstep()
			if tick == 17: request("wb_backcut")
		"14-heal":
			if tick == 12: press("tp_heal",true)
			if tick == 112: press("tp_heal",false)
		"15-charged":
			if tick == 12: press("tp_attack",true)
			if tick == 50: press("tp_attack",false)
		"16-dashslash":
			if tick == 12: request("A1_dash")
			if tick == 18: request("dash_slash")
		"18-dive", "21-pogo":
			if tick == 6: press("tp_jump",true)
			if tick == 22:
				request("dive" if id=="18-dive" else "A3_anchor")
			if tick == 24: press("tp_jump",false)
		"19-crystal":
			if tick == 12: press("tp_long_dash",true)
			if tick == 56: press("tp_long_dash",false)
		"22-doublejump":
			if tick in [6,26]: press("tp_jump",true)
			if tick in [20,40]: press("tp_jump",false)
