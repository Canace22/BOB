class_name ChapterCharacterActor
extends Sprite2D
## 单个静态演员：只配置位图、落脚锚点和等比尺寸，不拥有任务或动作时钟。
const METRICS: Dictionary={
	"nest_mender":[248,635,630],"fat_store_keeper":[132.5,637,634],
	"ring_keeper":[320,286,283],"lung_keeper":[221.5,636,632],
	"resident_settled":[221.5,635,630],"resident_migrant":[129.5,637,634],
	"resident_carrier":[320,256,253]}

func configure(id: String, height: float) -> void:
	centered=false
	z_as_relative=false
	z_index=3
	if id in ["shell_guard","pump_warden","beam_guard","elder_guardian"]:
		configure_guard(id,height)
		return
	var path: String="res://art/chapter-characters-v1/%s.png" % id
	if not ResourceLoader.exists(path):
		push_error("Chapter NPC bitmap missing: "+path)
		return
	texture=load(path) as Texture2D
	# 来自本批assets.json的alpha32实体锚点；不能按整画布高度让宽壳角色悬空。
	var metrics: Array=METRICS[id]
	offset=-Vector2(float(metrics[0]),float(metrics[1]))
	scale=Vector2.ONE*height/float(metrics[2])

func configure_guard(id: String, height: float) -> void:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://art/enemy-lab-readability-v1/atlas.json"))
	if not parsed is Dictionary or not parsed.has(id):
		push_error("Chapter NPC atlas entry missing: "+id)
		return
	var metadata: Dictionary=parsed[id]
	var cell: Dictionary=metadata.regions[22 if id=="elder_guardian" else 0]
	var raw: Array=cell.rect
	texture=EnemyLabVisual.SHEETS[id]
	region_enabled=true
	region_filter_clip_enabled=true
	region_rect=Rect2(raw[0],raw[1],raw[2],raw[3])
	if id=="elder_guardian":
		texture=EnemyLabVisual.ELDER_IDLE_FIXED
		region_rect.position=Vector2.ZERO
	offset=-Vector2(cell.pivot[0],cell.pivot[1])
	scale=Vector2.ONE*height/float(metadata.reference_height)
