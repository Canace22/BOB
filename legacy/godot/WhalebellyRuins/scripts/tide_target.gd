extends Node2D
@export var max_health: int = 100
@export var hostile: bool = false
var health: int = 100
var flash: float = 0
var reset_left: float = 0
var player: TidePlayer
var label: Label
func _ready() -> void:
	add_to_group("tide_targets")
	health=max_health
	var sprite:=Sprite2D.new()
	sprite.texture=load("res://assets/runtime/crab.png")
	var bounds:=sprite.texture.get_image().get_used_rect()
	sprite.centered=false
	sprite.offset=Vector2(-bounds.get_center().x,-bounds.end.y)
	sprite.scale=Vector2.ONE*48/maxf(bounds.size.y,1)
	add_child(sprite)
	label=Label.new()
	label.position=Vector2(-65,-90)
	label.size=Vector2(130,30)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",13)
	add_child(label)
func hurt_rect() -> Rect2:
	return Rect2(global_position+Vector2(-18,-45),Vector2(36,45)) if health>0 else Rect2()
func take_hit(amount:int) -> void:
	if health<=0:return
	health=maxi(0,health-amount)
	flash=.12
	if health<=0: reset_left=3
func _physics_process(dt:float) -> void:
	flash=maxf(0,flash-dt)
	modulate=Color(1,.55,.35) if flash>0 else Color.WHITE
	label.text=("接触伤害" if hostile else "练习靶")+" %d/%d"%[health,max_health]
	if health<=0:
		reset_left-=dt
		if reset_left<=0:health=max_health
	elif hostile and is_instance_valid(player) and hurt_rect().intersects(Rect2(player.global_position+Vector2(-12,-32),Vector2(24,32))):
		player.take_damage(player.contact_damage,global_position)
