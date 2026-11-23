extends TestSuite
## 在真实主线后跳路径验证越界回收；坐标夹具仅用于确定性模拟越过地图底界。

func world() -> WhalebellyMain:
	var host: WhalebellyMain=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true
	host.integration_external_test=true
	add(host)
	await physics_frames(35)
	return host

func test_backstep_void_returns_once_and_clears_retreat() -> void:
	var host := await world()
	var p: WhalebellyCampaignPlayer=host.player
	var safe: Vector2=p.last_safe
	var actor: int=p.get_instance_id()
	check(p.try_backstep(),"real grounded backstep starts")
	p.invulnerable=10.0
	p.position=Vector2(200,p.world_bounds.end.y+150)
	await physics_frames(3)
	eq(host.health,4,"backstep void costs one life despite invulnerability")
	check(p.position.distance_to(safe)<8,"returns to last supported ledge")
	check(not p.retreating,"recovery ends exclusive backstep motion")
	eq(p.get_instance_id(),actor,"fall preserves actor and chapter state")
	await physics_frames(60)
	check(host.health==4 and p.is_on_floor(),"recovered actor stays supported without repeat damage")

func test_backstep_in_valid_air_still_moves_without_false_void() -> void:
	var host := await world()
	var p: WhalebellyCampaignPlayer=host.player
	check(p.try_backstep(),"backstep starts on real floor")
	p.position.y-=150
	var start: Vector2=p.position
	await physics_frames(3)
	check(p.retreating and p.position.x<start.x,"valid airborne backstep retains motion")
	eq(host.health,5,"normal airborne retreat does not incur terrain damage")
