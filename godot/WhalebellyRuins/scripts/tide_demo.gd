extends Node2D
@export var camera_smooth_time: float = 0.08
@export var camera_lookahead: float = 120.0
@export var shake_amplitude: float = 6.0
@export var dash_zoom_factor: float = 1.05
@export var base_zoom: float = 1.4
@export var bounds:=Rect2(0,0,1200,1100)
@export var automatic_camera_bounds: bool = true
@export var show_guide: bool = true
var player: TidePlayer
var camera: Camera2D
var hud: CanvasLayer
var shake_left: float = 0
var interaction_hint: Label
var lamp: Node2D
var targets: Array[Node] = []
var interact_count: int = 0

func _ready() -> void:
	RenderingServer.viewport_set_snap_2d_transforms_to_pixel(get_viewport().get_viewport_rid(),true)
	var background:=Sprite2D.new();background.texture=load("res://assets/runtime/v04/oral-depth.png");background.position=bounds.get_center();background.scale=Vector2.ONE*maxf(bounds.size.x/background.texture.get_width(),bounds.size.y/background.texture.get_height());background.modulate=Color(.5,.6,.68);background.z_index=-10;add_child(background)
	_floor(Vector2(100,850),Vector2(1000,70))
	_floor(Vector2(70,150),Vector2(30,770))
	_floor(Vector2(1100,150),Vector2(30,770))
	_floor(Vector2(320,620),Vector2(140,25))
	_floor(Vector2(700,410),Vector2(140,25))
	_floor(Vector2(450,200),Vector2(140,25))
	if automatic_camera_bounds:bounds=_geometry_bounds()
	player=load("res://scenes/Player.tscn").instantiate()
	player.position=Vector2(220,850);player.world_bounds=bounds;add_child(player)
	camera=Camera2D.new();camera.position=player.position+Vector2(0,-180);camera.zoom=Vector2.ONE*base_zoom;add_child(camera)
	camera.limit_left=int(bounds.position.x);camera.limit_top=int(bounds.position.y);camera.limit_right=int(bounds.end.x);camera.limit_bottom=int(bounds.end.y)
	for i in range(3):
		var target:=preload("res://scripts/tide_target.gd").new();target.position=Vector2(490+i*200,850);target.player=player;target.hostile=i==2;targets.append(target);add_child(target)
	lamp=Node2D.new();lamp.position=Vector2(325,850);add_child(lamp)
	var art:=Sprite2D.new();art.texture=load("res://assets/runtime/v02/lamp.png");art.scale=Vector2.ONE*45/maxf(art.texture.get_width(),art.texture.get_height());art.position.y=-25;lamp.add_child(art)
	interaction_hint=Label.new();interaction_hint.text="按 E 交互";interaction_hint.position=Vector2(-48,-88);interaction_hint.add_theme_font_size_override("font_size",16);lamp.add_child(interaction_hint)
	hud=preload("res://scripts/tide_hud.gd").new();hud.player=player;hud.guide_enabled=show_guide;add_child(hud)
	player.hit_confirmed.connect(func():shake_left=.12)
	player.damaged.connect(func():shake_left=.18)
	player.interaction_requested.connect(func(_target):interact_count+=1;hud.show_notice("潮灯记录了你的回声"))

func _floor(pos:Vector2,dimensions:Vector2) -> void:
	var body:=StaticBody2D.new();body.position=pos;body.collision_layer=1;body.collision_mask=0
	body.set_meta("level_rect",Rect2(pos,dimensions));body.add_to_group("tide_level_bounds")
	var shape:=CollisionShape2D.new();var rect:=RectangleShape2D.new();rect.size=dimensions;shape.shape=rect;shape.position=dimensions/2;body.add_child(shape);add_child(body)
	# Debug arena surfaces use the project's existing 2D ledge, tiled without stretching.
	if dimensions.y>dimensions.x:
		# Explicit debug walls, not a replacement for production environment artwork.
		var wall:=ColorRect.new();wall.color=Color(.18,.35,.4,.8);wall.position=pos;wall.size=dimensions;wall.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(wall)
	else:
		var texture:Texture2D=load("res://assets/runtime/v04/ledge.png")
		var surface:=Sprite2D.new();surface.texture=texture;surface.centered=false;surface.region_enabled=true;surface.region_rect=Rect2(17,250,1993,480)
		var factor:=dimensions.x/1993.0
		surface.scale=Vector2.ONE*factor;surface.position=pos-Vector2(0,35*factor);add_child(surface)

func _geometry_bounds() -> Rect2:
	var result:=Rect2()
	for body in get_tree().get_nodes_in_group("tide_level_bounds"):
		var region:Rect2=body.get_meta("level_rect")
		result=region if result.size==Vector2.ZERO else result.merge(region)
	if result.size==Vector2.ZERO:return bounds
	var begin:=result.position-Vector2(70,150)
	var end:=result.end+Vector2(70,150)
	end.y=ceilf(end.y/100)*100
	return Rect2(begin,end-begin)

func _process(dt:float) -> void:
	if not is_instance_valid(player):return
	var near:bool=player.global_position.distance_to(lamp.global_position)<75 and player.health>0
	interaction_hint.visible=near
	player.interacted_target=lamp if near else null
	var desired:=player.position+Vector2(player.facing*camera_lookahead,-150)
	var zoom:=base_zoom/(dash_zoom_factor if player.state in ["A1_dash","A5_slit"] else 1.0)
	camera.zoom=camera.zoom.lerp(Vector2.ONE*zoom,1-exp(-dt/camera_smooth_time))
	var half:=get_viewport_rect().size/(2*camera.zoom)
	desired.x=clampf(desired.x,bounds.position.x+half.x,maxf(bounds.position.x+half.x,bounds.end.x-half.x))
	desired.y=clampf(desired.y,bounds.position.y+half.y,maxf(bounds.position.y+half.y,bounds.end.y-half.y))
	camera.position=camera.position.lerp(desired,1-exp(-dt/camera_smooth_time))
	shake_left=maxf(0,shake_left-dt)
	camera.offset=Vector2(randf_range(-shake_amplitude,shake_amplitude),randf_range(-shake_amplitude,shake_amplitude))*(shake_left/.18) if shake_left>0 else Vector2.ZERO
