class_name EnemyLabPumpVisual
extends Node2D
## 膜泵状态与水流只读取场景压力；固定骨架/场地不参与运动时钟。
var court: EnemyLabPumpCourt
var pump: Sprite2D
var valve: Sprite2D
var jet: Sprite2D
var streams: Array[Sprite2D]=[]
var frames: Array[Texture2D]=[]
var flow_material: ShaderMaterial
const SHEET: Texture2D=preload("res://art/enemy-lab-pump-court-v2/pump_actions.png")

func _ready() -> void:
	var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/enemy-lab-pump-court-v2/atlas.json"))
	for i: int in range(8,16):
		var r: Array=meta.props[str(i)]
		var texture := AtlasTexture.new()
		texture.atlas=SHEET
		texture.region=Rect2(r[0],r[1],r[2],r[3])
		texture.filter_clip=true
		frames.append(texture)
	pump=_sprite(frames[0],Vector2(1005,451.4),Vector2(268.8,179.2),-1)
	valve=_sprite(frames[4],court.VALVE,Vector2(184.32,122.88),0)
	jet=_sprite(frames[7],Vector2(980,410),Vector2(80,220),5)
	flow_material=ShaderMaterial.new()
	flow_material.shader=preload("pump_flow.gdshader")
	jet.material=flow_material
	for i: int in 2:
		var stream: Sprite2D=_sprite(frames[6],Vector2(770+i*180,490),Vector2(180,42),5)
		stream.flip_h=i==0
		stream.material=flow_material
		streams.append(stream)
	present()

func _sprite(texture: Texture2D, at: Vector2, size: Vector2, layer: int) -> Sprite2D:
	var item := Sprite2D.new()
	item.texture=texture
	item.position=at
	item.scale=size/texture.get_size()
	item.z_index=layer
	add_child(item)
	return item

func present() -> void:
	if not is_instance_valid(pump): return
	var pose: int=0
	if court.phase=="fill": pose=1 if court.timer>1.20 else 0
	elif court.phase=="stroke": pose=2
	else: pose=3
	pump.texture=frames[pose]
	# 泵体四状态保留同一像素比例，不能每换状态就重新适配包围盒。
	valve.texture=frames[5] if court.vent_left>0.0 else frames[4]
	jet.visible=not court.stopped and court.vent_left<=0.0 and (court.phase=="stroke" or (court.phase=="fill" and court.timer>1.50))
	jet.modulate.a=1.0 if court.phase=="stroke" else 0.35
	for stream: Sprite2D in streams:
		stream.visible=not court.stopped and court.vent_left<=0.0 and (court.pull_left>0.0 or court.pull_delay>0.0)
		stream.modulate.a=0.3 if court.pull_delay>0.0 else 1.0
	flow_material.set_shader_parameter("clock",court.clock)
