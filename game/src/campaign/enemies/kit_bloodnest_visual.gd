class_name KitBloodnestVisual
extends KitSwarmVisual
## Library bitmaps + local appendage shader; choreography follows combat, never drives it.
const Swim = preload("res://src/campaign/enemies/bloodnest_swim.gdshader")
const Wake = preload("res://src/campaign/enemies/kit_bloodnest_wake.gd")
const Impact = preload("res://src/campaign/enemies/kit_bloodnest_impact.gd")
var trail_texture: Texture2D
var wake: KitBloodnestWake
var impact: KitBloodnestImpact
var base_tint: Color=Color.WHITE
var formation: float = 0.0
var last_clock: float = 0.0
var initialized: bool = false

func _ready() -> void:
	set_process(false) # Godot enables inherited _process on first tree entry.

func build(seed_id: int) -> void:
	set_process(false) # The encounter supplies the only, pausable clock.
	var random := RandomNumberGenerator.new()
	random.seed = seed_id * 4513 + 7
	if trail_texture!=null:
		wake=Wake.new()
		wake.filament=trail_texture
		wake.sample_path=current_point
		add_child(wake)
		wake.build()
	impact=Impact.new()
	add_child(impact)
	impact.build(trail_texture,count)
	for i: int in count:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.scale = Vector2.ONE * member_scale * random.randf_range(0.72, 1.08)
		var material_ := ShaderMaterial.new()
		material_.shader = Swim
		material_.set_shader_parameter("phase", random.randf() * TAU)
		sprite.material = material_
		add_child(sprite)
		# Even spacing with small deviations avoids both clumps and a rigid wheel.
		var u: float = float(i) / maxf(1.0,count-1)
		members.append({"node":sprite, "base_scale":sprite.scale.x, "phase":random.randf()*TAU,
			"band":i % 3, "u":u, "path_u":u,
			"opacity":random.randf_range(0.78,1.0)})
	update_at(0.0,"rest",0.0,1.0)

func update_at(clock: float, state: String, timer: float, duration: float) -> void:
	var dt: float = maxf(0.0,clock-last_clock)
	last_clock = clock
	time = clock
	var progress: float = clampf(timer / maxf(duration,0.001),0.0,1.0)
	var target: float = 0.0
	match state:
		"tell": target = smoothstep(0.0,0.85,progress) * 0.82
		"act": target = 1.0
		"recover": target = 1.0-smoothstep(0.0,0.85,progress)
	var blend: float = 1.0-exp(-dt*13.0) if initialized else 1.0
	formation = lerpf(formation,target,blend)
	for index: int in members.size():
		var member: Dictionary=members[index]
		var sprite: Sprite2D = member.node
		var path_u: float = fposmod(float(member.u)+time*0.145,1.0)
		var orbit: Vector2 = current_point(path_u,int(member.band))
		var tangent: Vector2 = current_point(minf(path_u+0.003,1.0),int(member.band))-current_point(maxf(path_u-0.003,0.0),int(member.band))
		var u: float = float(member.u)
		# The front turns first; delayed rear ranks retain an open, flowing outline.
		var gather: float=smoothstep((1.0-u)*0.24,1.0,formation)
		var release: float=smoothstep(0.76,1.0,progress) if state=="act" else 0.0
		var ribbon: Vector2=charge_point(u,int(member.band),release)
		var heading_delta: Vector2=charge_point(minf(u+0.005,1.0),int(member.band),release)-charge_point(maxf(u-0.005,0.0),int(member.band),release)
		var destination: Vector2 = orbit.lerp(ribbon,gather)+impact.offset(index,time)
		var heading: float = lerp_angle(tangent.angle()+PI,heading_delta.angle()+PI,gather)
		heading+=impact.weights[index]*impact.envelope(time)*sin(index*2.4)*0.2
		# Recycle at the transparent inlet only; never draw a teleport across the curl.
		var recycled: bool = path_u<float(member.path_u) and formation<0.1
		sprite.position = destination if recycled else sprite.position.lerp(destination,blend)
		sprite.rotation = lerp_angle(sprite.rotation,heading,blend)
		sprite.flip_h = false # Rotation follows the actual tangent, including both facings.
		sprite.z_index = -1 if int(member.band)==0 else 0
		var edge: float = smoothstep(0.0,0.13,path_u)*(1.0-smoothstep(0.87,1.0,path_u))
		var alpha: float = lerpf(edge,0.5+0.5*u,formation)*float(member.opacity)
		sprite.modulate = Color(1.0,0.92,0.94,alpha*(0.68 if int(member.band)==0 else 1.0))
		sprite.scale=Vector2.ONE*float(member.base_scale)*lerpf(1.0,0.66+0.34*u,formation)
		member.path_u=path_u
		var material_: ShaderMaterial = sprite.material
		material_.set_shader_parameter("clock",time)
		material_.set_shader_parameter("motion_strength",1.0+formation*0.35)
		material_.set_shader_parameter("hit_strength",impact.highlight(index,time))
	impact.update_at(time)
	if is_instance_valid(wake):
		wake.update_at(time,formation,facing,formation if state=="act" else formation*0.35)
		wake.bend_at(impact.origin,impact.direction,impact.envelope(time))
	initialized = true

func receive_hit(source: Vector2) -> void:
	impact.trigger(time,source,members)

func charge_point(u: float, band: int, release: float=0.0) -> Vector2:
	return Vector2((lerpf(-76.0,64.0,u)+(band-1.0)*(1.0-u)*6.0)*facing,
		(8.0+sin(u*PI)*17.0)*(band-1.0)+sin(time*2.6+u*TAU+band)*4.0+sin(u*PI)*release*10.0)

func current_point(u: float, band: int) -> Vector2:
	var point_: Vector2
	if u<0.38:
		var t: float=u/0.38
		var v: float=1.0-t
		point_=Vector2(-154,-17)*v*v*v+Vector2(-82,18)*3.0*v*v*t+Vector2(-91,48)*3.0*v*t*t+Vector2(20,48)*t*t*t
	else:
		var t: float=(u-0.38)/0.62
		var angle: float=PI*0.5-t*TAU*1.13
		var radius: float=lerpf(1.0,0.24,t)
		point_=Vector2(20,0)+Vector2(cos(angle)*83.0,sin(angle)*48.0)*radius
	return point_+Vector2(sin(u*9.0+band)*3.0,(band-1)*8.0)
