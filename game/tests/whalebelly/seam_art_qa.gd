extends SceneTree
## 每条连接的固定镜头检查，只验证视觉注册；自然通行另跑streaming_world_qa。
var host: WhalebellyMain
const OUT := "res://build/qa/seamless-art"
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","seam-art-qa")
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(6)
	var report: Array=[]
	for edge: Dictionary in host.streaming.layout.links:
		if "--first" in OS.get_cmdline_user_args() and not (int(edge.a)==0 and int(edge.b)==1): continue
		host.load_room(int(edge.a))
		host.player.set_physics_process(false)
		host.player.invulnerable=1000
		for i: int in 300:
			if host.streaming.is_ready(int(edge.b)): break
			await tick(1)
		var label: String=str(host.rooms[int(edge.a)].id)+"--"+str(host.rooms[int(edge.b)].id)
		var path: PackedVector2Array=edge.path
		for slot: int in [0,path.size()/2,path.size()-1]:
			host.player.global_position=path[slot]
			host.camera.update_follow(1.0/60.0)
			await tick(6)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT.path_join(label+"-"+str(slot)+".png"))
		# 新布局由整图切片接管，旧逐连接图应停用；报告真实的母版驻留数。
		report.append({"id":label,"legacy_seam_enabled":host.streaming.corridors.seam_art.has_edge(int(edge.a),int(edge.b)),"master_chunks":host.streaming.corridors.world_terrain.resident.size(),"points":path.size()})
		print("SEAM_VIEW ",label)
	var file:=FileAccess.open(OUT.path_join("views.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	await host.graceful_quit()
