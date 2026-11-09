extends SceneTree
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func capture(view: SubViewport) -> Image:
 await process_frame;await process_frame;RenderingServer.force_draw()
 return view.get_texture().get_image()
func difference(a: Image,b: Image,rect: Rect2i) -> int:
 var count: int=0
 for y: int in range(rect.position.y,rect.end.y):
  for x: int in range(rect.position.x,rect.end.x):
   var ca: Color=a.get_pixel(x,y);var cb: Color=b.get_pixel(x,y)
   if absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b)+absf(ca.a-cb.a)>.025:count+=1
 return count
func check(id: String,passed: bool,detail: Variant) -> void:
 checks.append({"id":id,"pass":passed,"detail":detail});print(id," ",passed," ",detail)
func run() -> void:
 var view:=SubViewport.new();view.size=Vector2i(512,512);view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var flex:=ChapterPinnedBitmap.new();flex.texture=load("res://art/xumen-unified/kelp.png");flex.pin_bottom=true;flex.amplitude=12;flex.period=11;view.add_child(flex)
 flex.update_at(0);var a: Image=await capture(view);a.save_png("res://build/qa/xumen-unified/kelp-0.png")
 flex.update_at(4);var b: Image=await capture(view);b.save_png("res://build/qa/xumen-unified/kelp-4.png")
 var h: int=flex.texture.get_height();var w: int=flex.texture.get_width()
 check("rendered_bottom_roots_fixed",difference(a,b,Rect2i(0,h-18,w,18))==0, difference(a,b,Rect2i(0,h-18,w,18)))
 check("rendered_leaf_tips_bend",difference(a,b,Rect2i(0,0,w,int(h*.7)))>50,difference(a,b,Rect2i(0,0,w,int(h*.7))))
 flex.update_at(11);var c: Image=await capture(view)
 check("rendered_kelp_loop",difference(a,c,Rect2i(0,0,512,512))<5,difference(a,c,Rect2i(0,0,512,512)))
 flex.hide()
 var far:=Sprite2D.new();far.texture=load("res://art/xumen-unified/Far-0-0.png");far.centered=false;view.add_child(far)
 var m:=ShaderMaterial.new();m.shader=load("res://src/campaign/connected/unified_water.gdshader");far.material=m
 m.set_shader_parameter("clock",0);a=await capture(view)
 m.set_shader_parameter("clock",4);b=await capture(view)
 check("rendered_background_light_changes",difference(a,b,Rect2i(0,0,512,512))>100,difference(a,b,Rect2i(0,0,512,512)))
 # Adjacent half-open cutouts share world phase; compare rendered rebase.
 m.set_shader_parameter("clock",2);a=await capture(view)
 far.position=Vector2(-100,0);m.set_shader_parameter("chapter_origin",Vector2(100,0));view.canvas_transform=Transform2D(0,Vector2(100,0));b=await capture(view)
 check("light_phase_preserved_on_rebase",difference(a,b,Rect2i(0,0,512,512))<5,difference(a,b,Rect2i(0,0,512,512)))
 var failed: int=checks.filter(func(i: Dictionary)->bool:return not i.pass).size()
 FileAccess.open("res://build/qa/xumen-unified/bitmap-render.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "))
 quit(1 if failed else 0)
