class_name CampaignStoryCatalog
extends RefCounted
## 正式地图的阶段表单独绑定空间；正文仍来自已确认白盒，不导入白盒存档。
const PATH: String="res://content/narrative/campaign_story.json"
var chapters: Array[Dictionary]=[]
var stages: Array[Dictionary]=[]
var errors: Array[String]=[]

func load_data(rooms: Array) -> void:
	chapters.clear()
	stages.clear()
	errors.clear()
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary or int(parsed.get("schema_version",0))!=1:
		errors.append("章节表格式无效")
		return
	var room_ids: Array=[]
	for room: Dictionary in rooms: room_ids.append(str(room.id))
	var ids: Dictionary={}
	for source: Dictionary in parsed.get("chapters",[]):
		var chapter: Dictionary=source.duplicate(true)
		chapters.append(chapter)
		for value: Dictionary in chapter.get("stages",[]):
			var stage: Dictionary=value.duplicate(true)
			stage.chapter=int(chapter.id)
			stage.chapter_title=str(chapter.title)
			stage.room_id=str(stage.get("room_id",chapter.room_id))
			if ids.has(str(stage.id)): errors.append("重复阶段: "+str(stage.id))
			ids[str(stage.id)]=true
			if stage.room_id not in room_ids: errors.append("未知正式房间: "+stage.room_id)
			if str(stage.kind) not in ["dialogue","explore","battle","escape","observe","exit"]:
				errors.append("未知阶段类型: "+str(stage.id))
			_validate_point(stage.get("at"),str(stage.id))
			for task: Dictionary in stage.get("tasks",[]): _validate_point(task.get("at"),str(task.id))
			stages.append(stage)
	if chapters.size()!=12: errors.append("正式保底流程必须包含十二章")

func _validate_point(value: Variant, label: String) -> void:
	if not value is Array or value.size()!=2:
		errors.append("缺少房内锚点: "+label)
		return
	for component: Variant in value:
		if not (component is int or component is float) or not is_finite(float(component)):
			errors.append("锚点数值无效: "+label)

func has_stage(id: String) -> bool:
	return stages.any(func(value: Dictionary) -> bool: return str(value.id)==id)
