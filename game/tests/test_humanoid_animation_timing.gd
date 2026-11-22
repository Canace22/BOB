extends TestSuite
## 画面到位与实际命中时钟对齐；不靠缩短AI有效期制造快速出手。

func test_humanoid_contact_drawing_reaches_real_release_in_shortened_phases() -> void:
	var view:=EnemyLabAnimationOverride.new()
	for item: Array in [["beam_guard","beam_press",0.04,0.22],["beam_guard","beam_riposte",0.04,0.20],["elder_guardian","elder_grip",0.04,0.18],["pump_warden","warden_thrust",0.06,0.16]]:
		var contact: float=float(item[2])
		for duration: float in [float(item[3]),float(item[3])*0.8]:
			var sampled: Dictionary=view.sample(str(item[0]),str(item[1]),"active",1,contact/duration,"clips",duration)
			eq(sampled.clip.frames.find(sampled.frame),2,"contact pose uses real seconds despite pressure speed")
			var previous: Dictionary=view.sample(str(item[0]),str(item[1]),"active",1,(contact-0.001)/duration,"clips",duration)
			eq(previous.clip.frames.find(previous.frame),1,"contact pose never appears before release")

func test_slow_preparation_keeps_loaded_pose_and_guard_still_arrives_quickly() -> void:
	var view:=EnemyLabAnimationOverride.new()
	var first: Dictionary=view.sample("beam_guard","beam_press","tell",1,0.20)
	eq(first.clip.frames.find(first.frame),2,"early weight shift remains readable")
	var loaded: Dictionary=view.sample("beam_guard","beam_press","tell",1,0.90)
	eq(loaded.clip.frames.find(loaded.frame),5,"last preparation is held before release")
	var guard: Dictionary=view.sample("beam_guard","beam_guard","tell",1,0.20)
	check(not guard.clip.has("time_unit") and is_equal_approx(float(guard.clip.frames[1].at),1.0/6.0),"defensive raise is not slowed by attack cadence")

func test_three_water_shots_each_have_a_fast_launch_and_copy_stays_owned() -> void:
	var view:=EnemyLabAnimationOverride.new()
	for index: int in 3:
		var time: float=0.04+float(index)*0.22
		var shot: Dictionary=view.sample("pump_warden","warden_barrage","active",1,time/0.65,"clips",0.65)
		eq(shot.clip.frames.find(shot.frame),index*4+2,"each real shot reaches its launch pose")
	eq(view.sample("elder_guardian","elder_mimic","active",1,0.5),{},"complete player copy remains owned by phantom execution")

func test_vault_ground_attack_does_not_replay_flying_drawings() -> void:
	var view:=EnemyLabAnimationOverride.new()
	var prep: Dictionary=view.sample("elder_guardian","elder_vault","settle",1,0.95)
	var hit: Dictionary=view.sample("elder_guardian","elder_vault","active",1,0.04/0.18,"clips",0.18)
	check(prep.frame.rect!=hit.frame.rect,"ground compression is reserved for real hit")
	var airborne: Dictionary=view.sample("elder_guardian","elder_vault","vault",1,0.0)
	check(hit.frame.rect!=airborne.frame.rect,"ground attack never uses first flying drawing")

func test_real_humanoid_damage_occurs_during_fast_contact_pose() -> void:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	for item: Array in [[6,"beam_press",0.04],[5,"warden_thrust",0.06],[7,"elder_sweep",0.04]]:
		lab.profile_index=int(item[0])
		lab.reset_round()
		await physics_frames(14)
		var enemy: EnemyLabEnemy=lab.enemies[0]
		lab.player.position=enemy.position-Vector2(85,0)
		var damage: Array[Dictionary]=[]
		lab.player.damaged.connect(func() -> void:
			var phase: float=enemy.phase_duration()
			var sample: Dictionary=enemy.visual.animation_override.sample(str(enemy.profile.id),enemy.move_key,enemy.state,enemy.pulse,enemy.timer/phase,"clips",phase)
			damage.append({"time":enemy.timer,"state":enemy.state,"pose":sample.clip.frames.find(sample.frame)}))
		check(enemy.begin_attack(str(item[1])),"real humanoid attack starts")
		var spec: Dictionary=enemy.spec.duplicate(true)
		for frame: int in 150:
			await physics_frames(1)
			if not damage.is_empty(): break
		check(not damage.is_empty(),"real attack damages actual player")
		if not damage.is_empty():
			eq(damage[0].state,"active","damage still uses actual attack stage")
			eq(damage[0].pose,2,"real damage coincides with contact drawing")
			check(float(damage[0].time)>=float(item[2])-0.000001 and float(damage[0].time)<=float(item[2])+1.0/60.0+0.000001,"release time is not sped up")
		eq(enemy.spec,spec,"presentation does not rewrite AI parameters")

func test_actual_vault_landing_keeps_feet_on_floor_without_resizing() -> void:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=7
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	var enemy: EnemyLabElder=lab.enemies[0] as EnemyLabElder
	check(enemy.begin_attack("elder_vault"),"real vault starts")
	var bitmap: Image=load("res://art/combat-animation-v2/enemies/elder_guardian--elder_vault.png").get_image()
	var contacts: Dictionary={}
	var observed: Dictionary={}
	for tick: int in 180:
		await physics_frames(1)
		if enemy.state not in ["settle","active","recover"]: continue
		observed[enemy.state]=true
		var sprite: Sprite2D=enemy.visual
		var region: Rect2i=Rect2i(sprite.region_rect)
		if not contacts.has(region):
			# 此图已逐帧复核：落地阶段最低实体为脚底，不含落地尘土或独立FX。
			var bottom: int=0
			for y: int in range(region.size.y):
				for x: int in range(region.size.x):
					if bitmap.get_pixel(region.position.x+x,region.position.y+y).a>96.0/255.0:
						bottom=y+1
			contacts[region]=bottom
		var foot_y: float=sprite.global_position.y+(float(contacts[region])+sprite.offset.y)*sprite.scale.y
		check(absf(foot_y-EnemyLab.FLOOR)<1.5,"real landing drawing feet stay on actual floor: "+enemy.state)
		check(absf(enemy.position.y-EnemyLab.FLOOR)<1.0,"physics root stays grounded")
	eq(observed.size(),3,"real vault visits settle, active and recover")
