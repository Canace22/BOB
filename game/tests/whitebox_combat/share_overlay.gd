class_name CombatWhiteboxShareOverlay
extends Control
## 录制专用排版：中文标题与简化时间轴；不写入角色或技能状态。

var arena: Node2D
var headline: String = ""
var hint: String = ""
var counter: String = ""
var font: SystemFont

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC"])

func _process(_dt: float) -> void:
	queue_redraw()

func text_at(at: Vector2,value: String,pixels: int,color: Color=Color.WHITE) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func _draw() -> void:
	if arena == null or font == null: return
	draw_rect(Rect2(0,0,1280,114),Color(0.035,0.05,0.08,0.95))
	text_at(Vector2(40,48),headline,32)
	text_at(Vector2(40,88),hint,22,Color("85d7e5"))
	text_at(Vector2(1030,45),counter,21,Color("b0bac9"))
	draw_rect(Rect2(0,606,1280,114),Color(0.035,0.05,0.08,0.95))
	var live: Dictionary = CombatWhiteboxTimelineData.sample(arena.player,arena.enemy)
	var current: Dictionary = live if bool(live.active) else arena.timeline.last_action
	if current.is_empty(): current = live
	var phase: String = str({"STARTUP":"前摇","ATTACK":"攻击段","RECOVERY":"后摇","GUARD":"格挡窗口","DASH":"冲刺","IDLE":"待机","UNTIL LANDING":"后跳"}.get(current.phase,current.phase))
	text_at(Vector2(40,642),"%s  ·  %.2f / %.2f 秒" % [phase,float(current.elapsed),float(current.duration)],21)
	text_at(Vector2(760,642),"连击 %d   ·   敌人生命 %d" % [arena.player.skill_controller.combo_hits,arena.enemy.health],21)
	var total: float = float(current.duration)
	var width: float = 1200.0
	draw_rect(Rect2(40,660,width,16),Color("293445"))
	if total > 0.0:
		var split: float = clampf(float(current.release)/total,0.0,1.0)
		var recovery: float = clampf(float(current.recovery)/total,split,1.0)
		draw_rect(Rect2(40,660,width*split,16),Color("eac571"))
		draw_rect(Rect2(40+width*split,660,width*(recovery-split),16),Color("ff6d82"))
		draw_rect(Rect2(40+width*recovery,660,width*(1.0-recovery),16),Color("8ed8a0"))
		for hit: Variant in current.hits:
			var x: float = 40+width*clampf(float(hit)/total,0.0,1.0)
			draw_line(Vector2(x,657),Vector2(x,680),Color("ff6d82"),3.0)
		var cursor: float = 40+width*float(current.progress)
		draw_line(Vector2(cursor,655),Vector2(cursor,681),Color.WHITE,3.0)
	text_at(Vector2(40,705),"鲸落万物生 · 战斗白盒实录 · 当前技能仍为调试版本",16,Color("a5aebd"))
