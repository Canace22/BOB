extends Node2D
var bursts: Array=[]
var elapsed:=0.0
var emitted: Dictionary={}

func emit(kind: String,at: Vector2,direction: float=1.0) -> void:
	if bursts.size()>80: bursts.pop_front()
	bursts.append({"kind":kind,"at":at,"dir":direction,"age":0.0,"life":0.65 if kind=="death" else 0.32})
	emitted[kind]=int(emitted.get(kind,0))+1

func _process(delta: float) -> void:
	elapsed+=delta
	for b in bursts:b.age+=delta
	bursts=bursts.filter(func(b):return b.age<b.life)
	queue_redraw()

func _draw() -> void:
	for b in bursts:
		var t=float(b.age)/float(b.life)
		var alpha=1-t
		var pos: Vector2=b.at
		if b.kind in ["hit","death"]:
			var count=16 if b.kind=="death" else 8
			for i in range(count):
				var angle=TAU*i/count
				var offset=Vector2(cos(angle),sin(angle))*(8+t*(75 if b.kind=="death" else 34))
				draw_line(pos+offset,pos+offset*1.22,Color(0.72,0.94,0.85,alpha),2,true)
			draw_arc(pos,10+t*35,0,TAU,32,Color(0.8,0.9,0.65,alpha*0.6),2,true)
		elif b.kind=="dash":
			for i in range(4):
				draw_line(pos-Vector2(b.dir*(25+i*18+t*60),8-i*5),pos-Vector2(b.dir*(5+i*12+t*30),8-i*5),Color(0.4,0.9,0.95,alpha*0.6),3,true)
		elif b.kind in ["jump","land","ripple"]:
			draw_set_transform(pos,0,Vector2(1,0.24))
			draw_arc(Vector2.ZERO,8+t*64,0,TAU,30,Color(0.65,0.87,0.9,alpha*0.5),2,true)
			draw_set_transform(Vector2.ZERO)
		elif b.kind=="heavy":
			var theta=PI if b.dir<0 else 0.0
			draw_arc(pos,60+t*95,theta-0.65,theta+0.65,24,Color(0.55,0.93,1,alpha),6*alpha+1,true)
