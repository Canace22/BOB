class_name CampaignStoryView
extends Node2D
## 章节演员与当地交互标记；沿用位图与真实脚线，不生成玩法地形。
var story: CampaignStory
var actors: Array[ChapterCharacterActor]=[]
var marker_layer: Node2D
var label_font: Font=preload("res://art/fonts/WhalefallUI.ttf")
const MARKER: Texture2D=preload("res://art/action-hud-v1/objective.png")

func clear() -> void:
	for actor: ChapterCharacterActor in actors:
		if is_instance_valid(actor): actor.queue_free()
	actors.clear()
	if is_instance_valid(marker_layer): marker_layer.queue_free()
	marker_layer=null

func rebuild() -> void:
	clear()
	if not story.running() or not is_instance_valid(story.host.actor_frame): return
	var host: WhalebellyMain=story.host
	var stage: Dictionary=story.stage()
	if stage.is_empty() and not story.catalog.stages.is_empty(): stage=story.catalog.stages.back()
	if not story.current_room() and (not story.stage().is_empty() or str(stage.room_id)!=str(host.room.id)): return
	for spec: Dictionary in stage.get("actors",[]):
		if str(spec.get("room_id",host.room.id))!=str(host.room.id): continue
		var identity: String=str(spec.id)
		if story.encounter.has_body(identity):
			var body: EnemyLabEnemy=story.encounter.body_for(identity)
			# 明确救援完成后才切到安全工作位；死亡身体保持实际倒下的位置。
			if is_instance_valid(body) and body.outcome=="surrender" and (identity!="elder_guardian" or story.facts.get("ch12_move_elder_safe",false)):
				body.position=host.point(spec.at)
			continue
		if is_instance_valid(story.encounter.enemy) and str(story.encounter.enemy.profile.id)==identity: continue
		if identity=="beam_guard" and bool(story.facts.get("ch08_beam_guard_dead",false)): continue
		var actor:=ChapterCharacterActor.new()
		actor.configure(identity,float(spec.get("height",100)))
		actor.set_meta("story_identity",identity)
		actor.z_index=host.player.z_index
		actor.position=host.point(spec.at)
		host.actor_frame.add_child(actor)
		actors.append(actor)
	if story.stage().is_empty(): return
	marker_layer=Node2D.new()
	marker_layer.name="StoryInteractionMarkers"
	marker_layer.z_index=host.player.z_index+2
	host.actor_frame.add_child(marker_layer)
	var targets: Array[Dictionary]=[]
	if str(story.stage().kind)=="explore": targets=story.active_tasks()
	elif str(story.stage().kind) in ["observe","exit","dialogue"]: targets.append(story.stage())
	for target: Dictionary in targets:
		if str(target.get("room_id",story.stage().room_id))!=str(host.room.id): continue
		var marker:=Sprite2D.new()
		marker.texture=MARKER
		marker.scale=Vector2.ONE*25.0/maxf(MARKER.get_width(),MARKER.get_height())
		marker.position=host.point(target.at)-Vector2(0,110)
		marker_layer.add_child(marker)
		var label:=Label.new()
		label.text=str(target.get("label","交谈" if story.stage().kind=="dialogue" else "F 查看"))
		label.add_theme_font_override("font",label_font)
		label.add_theme_font_size_override("font_size",15)
		label.add_theme_color_override("font_color",Color("ffe0a3"))
		label.add_theme_color_override("font_outline_color",Color("15202b"))
		label.add_theme_constant_override("outline_size",4)
		label.position=host.point(target.at)+Vector2(-110,-149)
		label.size=Vector2(220,24)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		marker_layer.add_child(label)

func _exit_tree() -> void:
	clear()
