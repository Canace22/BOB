extends Node2D
## Two bounded instances: mode 0 = low-contrast middle depth, mode 1 =
## separate foreground/environment sprites. No decoration has collision.
## Texture anchor conventions: plant/cargo bottom-center, lamp top-center,
## baleen top-center, gate bottom-center, water left-center.
var level: Node2D
var mode:=0
var elapsed:=0.0
var textures: Dictionary={}
var mist_texture: GradientTexture2D
var lights: Array[PointLight2D]=[]
var lamp_points: Array[Vector2]=[]
var dots: Array[Vector2]=[]

func setup(owner_level: Node2D,layer_mode: int) -> void:
	level=owner_level
	mode=layer_mode
	z_index=-10 if mode==0 else 5
	for asset in ["plant","lamp","gate","water","baleen","cargo"]:
		var file="res://assets/runtime/v02/"+asset+".png"
		if ResourceLoader.exists(file): textures[asset]=load(file)
	var gradient=Gradient.new()
	gradient.offsets=PackedFloat32Array([0.0,0.3,0.7,1.0])
	gradient.colors=PackedColorArray([Color(1,1,1,0.8),Color(1,1,1,0.45),Color(1,1,1,0.08),Color(1,1,1,0)])
	mist_texture=GradientTexture2D.new()
	mist_texture.width=128
	mist_texture.height=128
	mist_texture.gradient=gradient
	mist_texture.fill=GradientTexture2D.FILL_RADIAL
	mist_texture.fill_from=Vector2(0.5,0.5)
	mist_texture.fill_to=Vector2(1,0.5)
	for i in range(36): dots.append(Vector2(fposmod(i*367.43,level.room_width),fposmod(i*157.31,level.death_y)))
	if mode==1:
		var main_platforms: Array=level.platforms.filter(func(p):return str(p.id).begins_with("P"))
		lamp_points.append(Vector2(3*64,float(main_platforms[0].y)*64-135))
		lamp_points.append(Vector2(level.room_width-140,float(main_platforms[-1].y)*64-135))
		for point in lamp_points:
			var light=PointLight2D.new()
			light.position=point+Vector2(0,34)
			light.texture=mist_texture
			light.texture_scale=2.0
			light.color=Color("eeb564")
			light.energy=0.22
			light.shadow_enabled=false
			add_child(light)
			lights.append(light)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed+=delta
	for i in range(lights.size()): lights[i].energy=0.22+0.045*sin(elapsed*1.7+i*1.4)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(level) or not is_instance_valid(level.camera): return
	var center: Vector2=level.camera.get_screen_center_position()
	var half_view=Vector2(640,360)/level.camera.zoom
	if mode==0:
		draw_middle(center)
	else:
		draw_foreground(center,half_view)

func draw_middle(center: Vector2) -> void:
	# Organic folds overlap at different parallax ratios. They are never
	# walkable architectural pillars or ribs invented inside the pharynx.
	for i in range(3):
		var x=200+i*850.0+center.x*0.14
		var p=PackedVector2Array([Vector2(x,-300),Vector2(x+80,-300),Vector2(x+360,level.death_y),Vector2(x-260,level.death_y)])
		draw_colored_polygon(p,Color(0.39,0.62,0.65,0.025))
	# Fixed count of drifting far organisms. The lantern-colored center
	# is reserved for interactive objects; these remain cool and dim.
	for i in range(0 if level.game.room_index==5 else 9):
		var p=Vector2(fposmod(i*373.0+elapsed*(5+i%3),level.room_width+400)-200,330+i%3*86+sin(elapsed*0.6+i)*15)+center*Vector2(0.12,0.10)
		draw_set_transform(p,0,Vector2(1.5,0.7))
		draw_circle(Vector2.ZERO,5+i%3,Color(0.48,0.78,0.78,0.22))
		draw_set_transform(Vector2.ZERO)
		draw_line(p+Vector2(-7,2),p+Vector2(-17-sin(elapsed+i)*3,6),Color(0.5,0.78,0.76,0.12),1,true)
	# Slow broad fog, always behind the interactive layer.
	for i in range(4):
		var fog=Vector2(center.x-900+i*600+sin(elapsed*0.08+i)*130,center.y-90+i%2*180)
		draw_texture_rect(mist_texture,Rect2(fog,Vector2(1100,190)),false,Color(0.42,0.64,0.68,0.13))

func draw_foreground(center: Vector2,half_view: Vector2) -> void:
	# Edge-only canopy: its maximum extent is the top 145 world pixels,
	# keeping telegraphs and landing ledges unobscured even in combat zoom.
	for i in range(dots.size()):
		var pos=dots[i]
		pos.y=fposmod(pos.y-elapsed*(6+i%4),level.death_y)
		pos.x+=sin(elapsed*0.4+i)*12
		draw_circle(pos,0.8+i%3*0.4,Color(0.60,0.83,0.80,0.10+i%3*0.025))
	for p in level.platforms:
		if not str(p.id).begins_with("P"): continue
		var x=float(p.x)*64+32
		var y=float(p.y)*64
		if level.game.room_index==3 and x>400 and x<2000: continue
		var opacity=0.58
		if is_instance_valid(level.player) and level.player.position.distance_to(Vector2(x,y))<135: opacity=0.15
		if textures.has("plant"):
			draw_set_transform(Vector2(x,y+6),sin(elapsed*0.9+x)*0.06)
			draw_texture_rect(textures.plant,Rect2(-39,-67,78,67),false,Color(0.52,0.69,0.67,opacity))
			draw_set_transform(Vector2.ZERO)
		if textures.has("water"):
			var width=minf(240,float(p.w)*64-25)
			draw_texture_rect(textures.water,Rect2(x-15+sin(elapsed*1.3+x)*7,y+215,width,20+sin(elapsed*1.6)*3),false,Color(0.45,0.75,0.78,0.38))
			var ripple=PackedVector2Array()
			for n in range(21):
				var rx=width*n/20.0
				ripple.append(Vector2(x-15+rx,y+225+sin(rx*0.045-elapsed*2.1)*2.5))
			draw_polyline(ripple,Color(0.57,0.83,0.85,0.24),1.2,true)
	for i in range(lamp_points.size()):
		var point=lamp_points[i]
		if textures.has("lamp"):
			draw_set_transform(point,sin(elapsed*0.8+i)*0.025)
			draw_texture_rect(textures.lamp,Rect2(-18,0,36,66),false,Color(1,0.94,0.82,0.95))
			draw_set_transform(Vector2.ZERO)
			draw_texture_rect(mist_texture,Rect2(point-Vector2(47,14),Vector2(94,94)),false,Color(1,0.66,0.27,0.12+sin(elapsed*1.7+i)*0.025))
	if level.game.room_index==2 and textures.has("cargo"):
		var drop=float(level.latch_anim)*50
		var point=Vector2(25.7*64,11.3*64-60+drop)
		draw_line(Vector2(25.7*64,10.2*64),point-Vector2(0,20),Color("a88365"),2,true)
		draw_texture_rect(textures.cargo,Rect2(point-Vector2(24,24),Vector2(48,48)),false,Color(0.80,0.87,0.85))

func get_effect_state() -> Dictionary:
	return {"layer":"middle" if mode==0 else "foreground","seconds":elapsed,"node_light_count":lights.size(),"light_energy":lights[0].energy if lights.size()>0 else 0.0,"baleen_angle":sin(elapsed*0.65+1)*0.035,"fog_offset":sin(elapsed*0.08)*130,"organism_offset":sin(elapsed*0.6)*15,"water_offset":sin(elapsed*1.3)*7,"sprites_loaded":textures.keys()}

