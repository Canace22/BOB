class_name ChapterRunView
extends Node2D
## 仅白盒空间和状态代理；所有正式角色与敌人仍来自现有位图。
var host: ChapterRun
var characters: ChapterCharacterPresentation
func _ready() -> void:
	z_index=-2
	characters=ChapterCharacterPresentation.new()
	characters.install(host.chapter_id)
	add_child(characters)
func _process(_dt: float) -> void:
	z_index=20 if host.using_reference() else -2
	characters.update_run(host)
func text(at: Vector2,value: String,font_size: int=17,color: Color=WhaleUIStyle.BONE) -> void:
	WhaleActionHUDStyle.text(self,at,value,font_size,color)
func _draw() -> void:
	var width: float=float(host.data.get("width",3600))
	if not host.using_reference():
		draw_rect(Rect2(-600,-500,width+1200,2000),Color("173239"))
		for i: int in int(width/230)+1: draw_line(Vector2(i*230,-80),Vector2(i*230-100,850),Color("203e43"),40,true)
		for rect: Array in host.data.platforms:
			var box:=Rect2(rect[0],rect[1],rect[2],rect[3])
			draw_rect(box,Color("56635e"))
			draw_line(box.position,Vector2(box.end.x,box.position.y),Color("b9bea5"),4,true)
		for prop: Dictionary in host.data.get("props",[]):
			var rect: Array=prop.rect
			var box:=Rect2(rect[0],rect[1],rect[2],rect[3])
			draw_rect(box,Color(str(prop.get("color","6a776f"))),false,3)
			text(box.position+Vector2(0,-10),str(prop.label)+"（代理）",16)
	if not is_instance_valid(host.flow) or host.flow.finished: return
	var s: Dictionary=host.flow.stage()
	if s.kind=="explore":
		for task: Dictionary in s.get("tasks",[]):
			var p: Vector2=ChapterRunCatalog.point(task.at)
			var done: bool=bool(host.flags.get(str(task.id),false))
			var active: bool=host.flow.unlocked(task)
			draw_circle(p+Vector2(0,-30),8,WhaleUIStyle.MUTED if done or not active else WhaleUIStyle.AMBER)
			text(p+Vector2(-50,-60),str(task.label)+( " · 已完成" if done else (" · F" if active else " · 稍后")),16,WhaleUIStyle.MUTED if done else WhaleUIStyle.AMBER)
	else:
		var value: Array=s.get("goal",s.get("at",host.data.spawn)) if s.kind=="escape" and host.encounter.started else s.get("at",host.data.spawn)
		var p: Vector2=ChapterRunCatalog.point(value)
		var labels: Dictionary={"dialogue":"靠近交谈","battle":"交锋位置","escape":"撤离到窄道","observe":"F观察","exit":"F离开本章"}
		text(p+Vector2(-50,-90),str(labels.get(str(s.kind),"目标位置")),17,WhaleUIStyle.AMBER)
	if not host.using_reference() and is_instance_valid(host.encounter.container):
		for gate: StaticBody2D in host.encounter.gates:
			if is_instance_valid(gate):
				var p: Vector2=gate.position+host.offset
				draw_rect(Rect2(p-Vector2(10,220),Vector2(20,440)),Color("8b806b"))
