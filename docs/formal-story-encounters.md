# 正式章节遭遇的场地与生命周期

`CampaignStoryEncounter`复用统一敌人试验场的完整执行器，面向当前19房的章节保底流程；它不创建新地图、不拥有剧情阶段或存档。主线流程负责进入/退出房间及结果事实。

## 使用边界

- `setup(host)`绑定正式宿主，`spawn(config)`在当前房间生成唯一正在运行的遭遇。config的`room_id`与宿主当前房间不同时拒绝生成；未活动邻房不推进AI。
- `profile`接受EnemyLabCatalog稳定ID或索引；`ending`、`hp`、`height`、`radius`、`speed`、`title`可显式覆盖。正常章节用ChapterCombatPressure维持已确认的进攻压力。
- `at`为角色脚底房内坐标；`arena=[x,y,width,height]`描述真实战区，其底边是默认脚线，可用`floor_y`覆盖。`perches`、`shelter`和`exit_x`同为房内坐标。
- 生成容器直接挂`host.actor_frame`、自身位置为零，与正式玩家局部坐标保持同一原点。不能再把房间origin叠加到enemy.position。
- 预置的0..1280、脚线520仅为原试验场默认单位。`EnemyLabCombatSpace`将其映射到当前场地水平范围；身体、速度、攻击范围不随场地宽度缩放。特殊落点按真实碰撞向下探测，不把回退脚线当作实际可站立面验收。

## 本地与世界坐标

AI换侧/夹取/路线使用共用房内坐标。伤害Rect、遮挡射线和独立弹体使用世界坐标。捕食者俯冲与回挂、鳗潜地锁点/吐卵、执卫水遁/发射朝向、老守护者撑跃/观招射线/复制弹体已分别处理。保留敌人既有动作时钟、伤害、格挡、防反、黄色后囊、复制幻影，不以静态同图代理替代这些能力。

正式玩家与试验场玩家共同继承TideCombatPlayer；防御共同继承TideCombatGuardSkills。敌人和卵/水弹不再要求试验场专用子类。正式主角普攻对旧campaign代理保留原距离规则，对完整章节敌人按共用hurt_rect相交调用_hit；同一击由hit_targets去重，迎击奖励只在原敌人reactions消费，不能再给它注册is_campaign_enemy造成双重消费。

## 结束、身体与跨房

`won()`读取已经结束的结果，`resolved(outcome)`在战斗结束时发出一次。`end_combat(outcome_override)`用于真实撤离等有剧情依据的结果；不能以调用它代替必战验收。

结束时同步取消敌人自动攻击/碰撞/目标组，停用兄弟弹体并退组释放，再冻结容器；不能仅等待queue_free下一帧清理。`clear(true)`保留kill/surrender已结束身体；retreat只做0.45秒、80像素的离场淡出后释放（不称为新增逐帧动作），不会清除同房其他已结束身体，`identity`优先作为身份（回退actor_id/profile.id），`has_body(identity)`只计kill/surrender，帮助叙事演员避免重复出场。跨房、死亡重建与退出必须`clear_room()`或`clear(false)`，清理当前与所有retired身体并恢复玩家碰撞掩码。重访结果由主线保存事实恢复，不由遭遇模块另建存档。

`test_campaign_story_encounter.gd`覆盖非零世界原点下真实正式玩家与全部执行器、普通攻击唯一性及封梁卫真实防御、潜地/卵与水遁空间、战后弹体退组及结束身体归属。专项是接口/物理夹具；不能当作真人通关或地图可达性验收。
