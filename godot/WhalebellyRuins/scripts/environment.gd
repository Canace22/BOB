extends Node2D
## Native supplementary water motion. Source-image bubbles/light shafts remain
## painted illumination; these sparse motes are independently timed instances.
var host: Node2D
var phase: float = 0.0
var room_size: Vector2 = Vector2(1672, 941)
var room_seed: int = 1
var bubbles_node: Node2D
var dust_node: Node2D
var fish_node: Node2D
var light_node: Node2D
var event_node: Node2D
var fog_node: Node2D
var ambience: AudioStreamPlayer
var ambience_fade_in: float = 0.0
var ambience_released: bool = false
var pulses: Array[Dictionary] = []
var lamps: Array[Vector2] = []
var events_seen: int = 0
var last_event_sequence: int = 0
var enabled: bool = true
var bubbles: Array[Dictionary] = []
var dust: Array[Dictionary] = []
var fish: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bubbles_node = _part("AmbientBubbles", -12, _draw_bubbles)
	dust_node = _part("DriftingDust", 7, _draw_dust)
	fish_node = _part("DistantFish", -28, _draw_fish)
	light_node = _part("CampLight", 1, _draw_lights)
	event_node = _part("EventPulses", 8, _draw_events)
	fog_node = Node2D.new()
	fog_node.name = "DriftingMist"
	fog_node.z_index = -11
	add_child(fog_node)
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.36, 0.64, 0.68, 0.027))
	gradient.set_color(1, Color(0.36, 0.64, 0.68, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	texture.width = 256
	texture.height = 64
	for i: int in range(3):
		var mist: Sprite2D = Sprite2D.new()
		mist.name = "Mist" + str(i)
		mist.texture = texture
		mist.scale = Vector2(3.2, 1.1)
		fog_node.add_child(mist)
	ambience = AudioStreamPlayer.new()
	ambience.name = "WaterAmbience"
	ambience.volume_db = -80.0
	ambience.stream = make_ambience()
	add_child(ambience)
	on_room_loaded()

func _part(part_name: String, depth: int, callback: Callable) -> Node2D:
	var node: Node2D = Node2D.new()
	node.name = part_name
	node.z_index = depth
	add_child(node)
	node.draw.connect(callback)
	return node

func on_room_loaded() -> void:
	if host == null or host.room.is_empty(): return
	room_size = Vector2(float(host.room.size[0]), float(host.room.size[1]))
	room_seed = int(host.room_index) + 101
	phase = 0.0
	pulses.clear()
	bubbles.clear()
	dust.clear()
	fish.clear()
	lamps.clear()
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = room_seed
	for i: int in range(18):
		bubbles.append({"x":random.randf_range(180,room_size.x-180),"y":random.randf_range(80,room_size.y-120),"radius":random.randf_range(1.2,3.8),"speed":random.randf_range(11,24),"phase":random.randf_range(0,TAU)})
	for i: int in range(28):
		dust.append({"x":random.randf_range(0,room_size.x),"y":random.randf_range(100,room_size.y-70),"speed":random.randf_range(1.5,4.5),"phase":random.randf_range(0,TAU)})
	var fish_count: int = 0 if int(host.room_index) in [4,5] else 7
	for i: int in range(fish_count):
		fish.append({"x":random.randf_range(200,room_size.x-100),"y":random.randf_range(room_size.y*0.25,room_size.y*0.57),"size":random.randf_range(0.55,1.1),"speed":random.randf_range(5,9),"phase":random.randf_range(0,TAU)})
	# Only fixed lamps visibly present in the source; no fabricated room lighting.
	match int(host.room_index):
		0: lamps.append(Vector2(93,550))
		2:
			lamps.append(Vector2(75,526))
			lamps.append(Vector2(1605,558))
		3: lamps.append(Vector2(80,601))
		5: lamps.append(Vector2(100,754))
		6: lamps.append(Vector2(95,501))
	events_seen = host.events.size()
	last_event_sequence = int(host.events[-1].get("seq",0)) if not host.events.is_empty() else 0

func _process(dt: float) -> void:
	if host == null or not is_instance_valid(host): return
	var frozen: bool = get_tree().paused or host.reference_visible or not host.capture_path.is_empty()
	var solo: int = int(host.layer_solo)
	visible = enabled and not host.reference_visible and host.capture_path.is_empty()
	bubbles_node.visible = solo < 0 or solo == 1
	dust_node.visible = solo < 0 or solo == 3
	fish_node.visible = solo < 0 or solo == 0
	fog_node.visible = solo < 0 or solo == 1
	light_node.visible = solo < 0 or solo == 2
	event_node.visible = solo < 0 or solo == 2
	if is_instance_valid(ambience):
		if ambience.playing: ambience.stream_paused = frozen or not enabled
		elif not frozen and enabled: ambience.play()
	if frozen or not enabled: return
	if is_instance_valid(ambience):
		ambience_fade_in = minf(0.35, ambience_fade_in + dt)
		ambience.volume_db = lerpf(-80.0, -29.0, ambience_fade_in / 0.35)
	phase += dt
	for i: int in range(fog_node.get_child_count()):
		var mist: Sprite2D = fog_node.get_child(i)
		mist.position = Vector2(room_size.x*(0.2+0.3*i)+sin(phase*0.08+i)*38,room_size.y*(0.44+0.09*i)+sin(phase*0.13+i)*6)
	for i: int in range(pulses.size()-1,-1,-1):
		pulses[i].age = float(pulses[i].age) + dt
		if float(pulses[i].age) > float(pulses[i].life): pulses.remove_at(i)
	# Event log is authoritative; polling is idempotent within this instance.
	for item: Dictionary in host.events:
		var sequence: int = int(item.get("seq",0))
		if sequence <= last_event_sequence: continue
		last_event_sequence = sequence
		var kind: String = str(item.get("event",""))
		var origin: Vector2 = host.player.position - Vector2(0,35) if is_instance_valid(host.player) else Vector2.ZERO
		if kind in ["enemy_hit","enemy_defeated"]:
			for enemy: Dictionary in host.enemies:
				if str(enemy.key) == str(item.get("data",{}).get("id","")): origin = Vector2(enemy.pos)-Vector2(0,45)
		if kind in ["enemy_hit","enemy_defeated","player_death","reward","checkpoint","ability_unlocked"]: event_effect(kind,origin)
	events_seen = host.events.size()
	for part: Node2D in [bubbles_node,dust_node,fish_node,light_node,event_node]: part.queue_redraw()

func event_effect(kind: String, world_position: Vector2) -> void:
	var color: Color = Color(0.63,0.91,0.96)
	var lifetime: float = 0.45
	if kind in ["reward","checkpoint","ability_unlocked"]:
		color = Color(1.0,0.72,0.31)
		lifetime = 0.8
	if kind in ["enemy_defeated","player_death"]: lifetime = 0.85
	pulses.append({"kind":kind,"origin":world_position,"age":0.0,"life":lifetime,"color":color})
	if pulses.size()>16: pulses.pop_front()

func _draw_bubbles() -> void:
	for item: Dictionary in bubbles:
		var y: float = 60.0 + fposmod(float(item.y)-phase*float(item.speed),room_size.y-170)
		var x: float = float(item.x)+sin(phase*0.7+float(item.phase))*7
		var alpha: float = minf(1.0,(y-60)/40)*0.22
		bubbles_node.draw_arc(Vector2(x,y),float(item.radius),0.0,TAU,14,Color(0.48,0.82,0.93,alpha),0.75,true)
		bubbles_node.draw_arc(Vector2(x-0.3,y-0.3),float(item.radius)*0.7,3.8,5.0,4,Color(0.8,0.96,1,alpha*0.7),0.65,true)

func _draw_dust() -> void:
	for item: Dictionary in dust:
		var x: float = fposmod(float(item.x)+phase*float(item.speed),room_size.x)
		var y: float = float(item.y)+sin(phase*0.3+float(item.phase))*9
		dust_node.draw_circle(Vector2(x,y),0.75,Color(0.55,0.78,0.78,0.13))

func _draw_fish() -> void:
	for item: Dictionary in fish:
		var x: float = fposmod(float(item.x)+phase*float(item.speed),room_size.x+80)-40
		var y: float = float(item.y)+sin(phase*0.4+float(item.phase))*7
		var scale_factor: float = float(item.size)
		var points: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in [Vector2(8,0),Vector2(2,-2),Vector2(-4,-1),Vector2(-8,-4),Vector2(-7,0),Vector2(-8,4),Vector2(-4,1),Vector2(2,2)]:
			points.append(Vector2(x,y)+p*scale_factor)
		fish_node.draw_colored_polygon(points,Color(0.035,0.12,0.17,0.19))

func _draw_lights() -> void:
	for center: Vector2 in lamps:
		var pulse: float = 0.9+0.1*sin(phase*1.9)+0.03*sin(phase*4.7)
		for ring: int in range(12,0,-1):
			light_node.draw_circle(center,3+ring*3.2,Color(1,0.57,0.16,0.0038*pulse))

func _draw_events() -> void:
	for effect: Dictionary in pulses:
		var progress: float = float(effect.age)/float(effect.life)
		var origin: Vector2 = effect.origin
		var color: Color = effect.color
		color.a = (1-progress)*0.65
		for i: int in range(9):
			var direction: Vector2 = Vector2.from_angle(float(i)*TAU/9+0.2)
			var pos: Vector2 = origin+direction*(8+progress*48)+Vector2(0,progress*progress*24)
			event_node.draw_line(pos,pos-direction*(2+3*(1-progress)),color,1.5,true)
		if str(effect.kind) in ["reward","checkpoint","ability_unlocked"]:
			event_node.draw_arc(origin,8+progress*42,0,TAU,32,Color(color,0.3*(1-progress)),1.3,true)

func make_ambience() -> AudioStreamWAV:
	var master: AudioStreamWAV = load("res://assets/runtime/audio/water_bed.wav") as AudioStreamWAV
	if master != null:
		master.loop_mode = AudioStreamWAV.LOOP_FORWARD
		master.loop_begin = 0
		master.loop_end = int(master.get_length()*master.mix_rate)
		return master
	var rate: int = 22050
	var frames: int = rate*4
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(frames*2)
	# All carriers complete an integer number of periods in four seconds.
	# This yields a deterministic, seamlessly looped, low-level water drone.
	for index: int in range(frames):
		var t: float = float(index)/rate
		var value: float = sin(t*TAU*54.0)*0.20+sin(t*TAU*81.0)*0.09
		value += sin(t*TAU*137.0+sin(t*TAU*0.5)*0.7)*0.025
		value *= 0.88+sin(t*TAU*0.25)*0.08
		bytes.encode_s16(index*2,int(clampf(value,-1,1)*32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.data = bytes
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream

func runtime_report() -> Dictionary:
	return {"seed":room_seed,"phase":phase,"bubble_count":bubbles.size(),"dust_count":dust.size(),"fish_count":fish.size(),"mist_count":fog_node.get_child_count(),"lamp_count":lamps.size(),"event_count":pulses.size(),"ambience_playing":ambience.playing if is_instance_valid(ambience) else false,"ambience_paused":ambience.stream_paused if is_instance_valid(ambience) else true,"ambience_released":ambience_released,"muted":AudioServer.is_bus_mute(0),"visible":visible,"nodes":["AmbientBubbles","DriftingDust","DistantFish","CampLight","DriftingMist","EventPulses","WaterAmbience"]}

func release_ambience() -> void:
	if ambience_released or not is_instance_valid(ambience): return
	ambience_released = true
	var outgoing: AudioStreamPlayer = ambience
	ambience = null
	outgoing.name = "FadingRoomAmbience"
	outgoing.reparent(host)
	# The old room is about to be destroyed. Bind the tail to the persistent
	# host so the fade survives, then explicitly release its playback resource.
	var fade: Tween = host.create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(outgoing,"volume_db",-80.0,0.25)
	fade.tween_callback(outgoing.stop)
	fade.tween_callback(outgoing.set.bind("stream",null))
	fade.tween_callback(outgoing.queue_free)

func _exit_tree() -> void:
	# Explicitly release the looping playback before the audio server shuts down.
	# SceneTree.quit immediately after a test otherwise may outrun the final
	# deferred playback cleanup on the mixer thread.
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
