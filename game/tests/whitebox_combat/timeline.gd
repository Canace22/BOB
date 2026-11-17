class_name CombatWhiteboxTimeline
extends Control
## 调试覆盖层：行为保持由角色决定，时间轴只观察，结束/取消后留存最后一招。

var player: CombatWhiteboxPlayer
var enemy: CombatWhiteboxEnemy
var live: Dictionary = {}
var last_action: Dictionary = {}
var last_reason: String = ""
var ended: bool = false
var font: Font
const GRAY := Color("506073")
const YELLOW := Color("eac571")
const RED := Color("ff6d82")
const GREEN := Color("8ed8a0")
const BLUE := Color("75c9f2")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	player.animation_tag.connect(_on_tag)
	player.skill_effect.connect(_on_effect)

func _process(_dt: float) -> void:
	live = CombatWhiteboxTimelineData.sample(player,enemy)
	queue_redraw()

func reset_history() -> void:
	last_action.clear()
	last_reason = ""
	ended = false

func _capture(reason: String) -> void:
	var value: Dictionary = CombatWhiteboxTimelineData.sample(player,enemy)
	if not bool(value.active): return
	last_action = value.duplicate(true)
	last_reason = reason
	ended = true

func _on_tag(tag: String) -> void:
	if tag.ends_with(":end"): _capture("END")
	elif tag.ends_with(":start"): ended = false

func _on_effect(_key: String,event: String,_origin: Vector2,_direction: float) -> void:
	# 自然结束也会经过cancel清理，不把END误显示为中断。
	if event == "cancel" and not ended: _capture("CANCEL")

func _text(at: Vector2, value: String, color: Color=Color.WHITE, pixels: int=14) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func _bar(y: float, total: float, elapsed: float, ranges: Array, markers: Array=[]) -> void:
	var x: float = 210.0
	var width: float = size.x-x-12.0
	draw_rect(Rect2(x,y,width,13.0),Color("26303d"))
	if total <= 0.0: return
	for item: Array in ranges:
		var start: float = clampf(float(item[0])/total,0.0,1.0)
		var finish: float = clampf(float(item[1])/total,start,1.0)
		draw_rect(Rect2(x+width*start,y,width*(finish-start),13.0),item[2])
	for marker: Variant in markers:
		var point: float = x+width*clampf(float(marker)/total,0.0,1.0)
		draw_line(Vector2(point,y-2.0),Vector2(point,y+15.0),RED,3.0)
	var cursor: float = x+width*clampf(elapsed/total,0.0,1.0)
	draw_line(Vector2(cursor,y-4.0),Vector2(cursor,y+17.0),Color.WHITE,2.0)

func _draw() -> void:
	if live.is_empty() or font == null: return
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.055,0.075,0.11,0.95))
	var action: Dictionary = live if bool(live.active) else last_action
	if action.is_empty(): action = live
	var total: float = float(action.duration)
	var elapsed: float = float(action.elapsed)
	var suffix: String = "  LAST "+last_reason if not bool(live.active) and not last_action.is_empty() else ""
	_text(Vector2(8,17),"TIMELINE  %s  %s%s" % [action.key,action.phase,suffix],BLUE)
	_text(Vector2(700,17),"%.3f / %.3fs  %3.0f%%  tick %d  hitstop %.3fs" % [elapsed,total,float(action.progress)*100.0,int(elapsed*Engine.physics_ticks_per_second),float(live.hitstop)])
	_text(Vector2(8,42),"Action: yellow / red / green")
	var start: float = float(action.release)
	var recovery: float = float(action.recovery)
	_bar(29,total,elapsed,[[0.0,start,YELLOW],[start,recovery,RED],[recovery,total,GREEN]],action.hits)
	_text(Vector2(8,65),"Dash / guard cancel",GREEN if bool(live.recovery_open) else GRAY)
	_bar(52,total,elapsed,[[recovery,total,GREEN]] if bool(action.offense) else [])
	_text(Vector2(215,86),"DASH %s CD %.2f  |  GUARD %s CD %.2f  |  BACKSTEP %s%s" % ["READY" if live.dash_ready else "LOCKED",float(live.dash_cd),"READY" if live.guard_ready else "LOCKED",float(live.guard_cd),"READY" if live.backstep_ready else ("MOVING" if live.retreating else "LOCKED")," %.3fs / until landing" % float(live.retreat_elapsed) if live.retreating else ""])
	_text(Vector2(8,108),"Guard / immunity",YELLOW if live.guard_open else GRAY)
	if bool(action.guard_track):
		_bar(95,total,elapsed,[[float(action.guard_start),float(action.guard_end),YELLOW]])
	else: _bar(95,0.0,0.0,[])
	_text(Vector2(215,128),"GUARD %s (front only)  |  INVUL %.3fs remaining" % ["OPEN" if live.guard_open else ("USED" if live.guard_used else "CLOSED"),float(live.invulnerable)],YELLOW if live.guard_open else BLUE)
	_text(Vector2(8,151),"K chain %d/3 %.2fs left" % [int(live.chain_step),float(live.chain_left)],GREEN if live.chain_open else GRAY)
	_bar(138,float(live.chain_max),float(live.chain_max)-float(live.chain_left),[[0.0,float(live.chain_max),GREEN]] if live.chain_open else [])
	_text(Vector2(8,179),"Enemy: %s %.2fs" % [live.enemy_state,float(live.enemy_elapsed)],RED if live.enemy_hit else BLUE)
	var enemy_total: float = float(live.enemy_duration)
	_bar(166,enemy_total,float(live.enemy_elapsed),[[0.0,enemy_total,RED if live.enemy_state == "active" else (YELLOW if live.enemy_state == "tell" else GREEN)]])
