class_name WhaleCampaignRouteHUD
extends Control
## 所有当前房间出口同时显示；稳定目标ID决定内容，真实门点决定方向。
var controller: WhaleCampaignUI
var routes: Array[Dictionary] = []
var markers: Array[Dictionary] = []
var refresh_left: float = 0.0
var source_id: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

static func destinations(host: Node2D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	var next: String = CampaignGuidance.next_room(host)
	for door: Dictionary in host.room.get("doors",[]):
		var target: int = int(door.get("to",-2))
		if target<0 or target>=host.rooms.size() or seen.has(target): continue
		seen[target] = true
		var room: Dictionary = host.rooms[target]
		var missing: PackedStringArray = []
		for need: String in CampaignWorld.requirements(door):
			var satisfied: bool = bool(host.defeated.get(str(host.room.id)+":0",false)) if need=="boss" else host.has_ability(need)
			if not satisfied: missing.append(str(CampaignWorld.NAMES.get(need,need)))
		if door.has("locked") and not host.has_ability(str(door.locked)): missing.append("另一侧开启")
		var main: bool = str(room.id)==next
		var visited: bool = bool(host.visited.get(str(room.id),false))
		result.append({"target":target,"id":str(room.id),"name":str(room.name),"point":host.point(door.pos),"main":main,"blocked":not missing.is_empty(),"detail":"需"+" / ".join(missing) if not missing.is_empty() else "","kind":"前往" if main else ("返回" if visited else "可前往")})
	return result

static func route_world_point(host: Node2D, route: Dictionary) -> Vector2:
	var stream := host.streaming as CampaignRoomStream
	if is_instance_valid(stream) and stream.enabled:
		for link: Dictionary in stream.layout.get("links",[]):
			# 无缝交界先切换房间归属，旧房内门点可能还在主角前方。
			# 指向目的房一侧的真实连接端，避免返回左房的箭头在入房前段反指右边。
			if int(link.a)==host.room_index and int(link.b)==int(route.target): return Vector2(link.to)
			if int(link.b)==host.room_index and int(link.a)==int(route.target): return Vector2(link.from)
	return host.scenery.to_global(Vector2(route.point))

func _process(dt: float) -> void:
	var host: Node2D = controller.host
	visible = controller.page_id.is_empty() and is_instance_valid(controller.player) and controller.player.health>0 and controller.player.controls_enabled and not host.continuity.travelling
	if not visible: return
	refresh_left -= dt
	if refresh_left<=0 or source_id!=str(host.room.id):
		refresh_left = 0.2
		source_id = str(host.room.id)
		routes = destinations(host)
	markers.clear()
	var viewport: Vector2 = get_viewport_rect().size
	# 下缘留出技能/小地图，上缘留出任务/Boss；只在边缘显示，不在主角前方重复。
	var bottom: float = viewport.y-204
	var prompt: WhaleInteractionPrompt = controller.hud.interaction_prompt
	if prompt.visible and prompt.card_rect.size.y>0: bottom = minf(bottom,prompt.card_rect.position.y-50)
	var boundary := Rect2(Vector2(24,108),Vector2(viewport.x-48,maxf(100,bottom-108)))
	# 门点和主角先统一到HUD坐标，避免相机跟随缓动或窗口缩放改变相对方向。
	var canvas_to_hud: Transform2D = get_global_transform_with_canvas().affine_inverse()
	var player_point: Vector2 = canvas_to_hud*controller.player.get_global_transform_with_canvas().origin
	for route: Dictionary in routes:
		var world_point: Vector2 = route_world_point(host,route)
		var screen_point: Vector2 = canvas_to_hud*host.get_canvas_transform()*world_point
		var ray: Vector2 = screen_point-player_point
		if ray.length_squared()<1: continue
		var marker: Dictionary = route.duplicate()
		marker.world_point = world_point
		marker.direction = ray.normalized()
		marker.at = edge_point(player_point,ray,boundary)
		marker.side = "left" if is_equal_approx(marker.at.x,boundary.position.x) else ("right" if is_equal_approx(marker.at.x,boundary.end.x) else ("top" if is_equal_approx(marker.at.y,boundary.position.y) else "bottom"))
		markers.append(marker)
	_separate(boundary)
	queue_redraw()

static func edge_point(center: Vector2, ray: Vector2, boundary: Rect2) -> Vector2:
	# 提示避让后主角可能位于安全区外；只移动方向显示起点，保留出口相对主角的方向。
	# 起点在矩形外会得到负交距，使左门反投到右侧；不能直接取原来的最小交距。
	var origin: Vector2 = center if boundary.has_point(center) else boundary.get_center()
	if ray.length_squared()<0.0001: return origin
	var tx: float = INF if is_zero_approx(ray.x) else ((boundary.end.x if ray.x>0 else boundary.position.x)-origin.x)/ray.x
	var ty: float = INF if is_zero_approx(ray.y) else ((boundary.end.y if ray.y>0 else boundary.position.y)-origin.y)/ray.y
	return origin+ray*minf(tx,ty)

func _separate(boundary: Rect2) -> void:
	# 同边多个出口沿边排列，保留全部目的地；不把重叠标签叠成一团。
	for side: String in ["left","right","top","bottom"]:
		var group: Array[Dictionary] = markers.filter(func(item: Dictionary) -> bool: return item.side==side)
		var vertical: bool = side in ["left","right"]
		group.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.at.y<b.at.y if vertical else a.at.x<b.at.x)
		var start: float = maxf(174,boundary.position.y) if vertical else boundary.position.x+330
		var finish: float = boundary.end.y if vertical else boundary.end.x-330
		var spacing: float = minf(64 if vertical else 185,(finish-start)/maxi(1,group.size()-1))
		var previous: float = start-spacing
		for i: int in group.size():
			var marker: Dictionary = group[i]
			var at: Vector2 = marker.at
			var value: float = clampf(at.y if vertical else at.x,previous+spacing,finish-spacing*(group.size()-1-i))
			if vertical: at.y = value
			else: at.x = value
			marker.at = at
			previous = value

func _draw() -> void:
	for marker: Dictionary in markers:
		var at: Vector2 = marker.at
		var direction: Vector2 = {"left":Vector2.LEFT,"right":Vector2.RIGHT,"top":Vector2.UP,"bottom":Vector2.DOWN}[marker.side]
		var color := Color("ffd886") if not marker.blocked else Color("e6b083")
		var text_width: float = maxf(WhaleUIStyle.FONT.get_string_size(marker.name,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x,WhaleUIStyle.FONT.get_string_size(marker.detail,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)
		var x: float = at.x+20 if marker.side=="left" else at.x-20-text_width
		if marker.side in ["top","bottom"]: x = at.x-text_width*0.5
		var y: float = at.y-10 if marker.side in ["left","right"] else at.y+(30 if marker.side=="top" else -44)
		WhaleActionHUDStyle.panel(self,Rect2(x-5,y-17,text_width+10,64 if marker.blocked else 44),0.22)
		var normal := Vector2(-direction.y,direction.x)
		var triangle := PackedVector2Array([at+direction*10,at-direction*7+normal*9,at-direction*7-normal*9])
		draw_colored_polygon(triangle,color)
		WhaleActionHUDStyle.text(self,Vector2(x,y),"受阻" if marker.blocked else marker.kind,14,WhaleUIStyle.BONE)
		WhaleActionHUDStyle.text(self,Vector2(x,y+24),marker.name,18,color)
		if marker.blocked: WhaleActionHUDStyle.text(self,Vector2(x,y+43),marker.detail,12,WhaleUIStyle.BONE)
