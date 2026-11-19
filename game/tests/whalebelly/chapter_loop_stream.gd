class_name ChapterLoopRoomStream
extends CampaignRoomStream
## 已确认循环样板的独立场地；正式19房继续使用默认流式世界与新地形。
func _ready() -> void:
	enabled=false
	layout={"origins":{0:Vector2.ZERO,1:Vector2.ZERO},"rooms":host.rooms,"links":[]}
func explicit_scene(index: int) -> PackedScene:
	return preload("res://tests/fixtures/chapter_loop/R1-01.tscn") if index==0 else preload("res://tests/fixtures/chapter_loop/R1-02.tscn")
func neighbors(_index: int) -> Array[int]:
	return []
