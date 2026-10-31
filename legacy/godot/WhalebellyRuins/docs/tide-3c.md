# 拾潮者 · 角色与技能试玩

默认 `scenes/main.tscn` 已接入V2.4逐帧角色、3C、技能和HUD。在唯一Godot 4.7.2工程按F5运行即可；独立回归场景为 `scenes/test/PlayerTest.tscn`，打开后F6。`tide_demo.tscn` 和 **试玩角色与技能.cmd** 保留为旧大尺度试验场。主场景使用原七房参数，不能把旧试验场的180速度、100血套进主关卡。

## 操作

|操作|键位|
|---|---|
|移动|A/D、左右方向键|
|跳跃、二段跳、蹬墙跳|K，兼容空格；轻按短跳，按住高跳|
|短击|J，兼容Q；移动中可以攻击|
|下劈反弹|空中按住S再按J|
|贴流冲、潜隙|L（兼容Shift）、O|
|迎珠弹道、重鸣范围攻击|U、I|
|调息|P；地面引导1.5秒，受击中断，不返魂|
|交互|靠近潮灯按E|
|死亡重生、重看引导|R、H|

主关卡W浮游、G锚环牵引（原J与短击冲突，因此迁至G）；两者保留原能力解锁/F9练习规则。S+K/空格可在压沉的舌膜上下潜。右侧第三个练习靶会造成接触伤害，其余为伤害测试靶，击破3秒后恢复。左右色块明确为测试墙，不代表正式环境美术。

## 资源与动画

- 输入：`G:/鲸落万物生/outputs/拾潮者_V2.4_透明边缘去紫/`，实际文件夹为英文稳定ID。自动映射15组中文显示名。
- 读取HTML、配套JSON及此前生产脚本确认规则。HTML本身没有逐帧战斗标签；新增的命中/释放标签是本次游戏设计，不能当作原图事实。
- 去紫已在V2.4完成。原规则为Alpha边界3px、Alpha<240、R-G>8且B-G>8、R/B平衡系数0.65，替换5px内非紫色高覆盖像素的RGB。此次不重复执行去色，不修改Alpha或用色阶阈值硬切轮廓。
- 原生产归一化锚点 `(320,440)` 加显示偏移 `(x-220,80-y)`，故每帧源锚点为 `(round(x+100), round(520-y))`。整数平移和统一裁剪后画布 **711×489**，锚点 **(305,413)**；旧试验场统一缩放 **0.22**；主关卡按原角色轮廓高度80–110px（默认94）求一次等比缩放，每帧共用，不按每帧外接框放大缩小。空中姿势原先按髋部代理点制作，此处只移除展示轨迹，不把空中脚底强拉到同一水平线。
- `assets/animations/player/<id>/` 保留540张最终帧；`body/<id>/` 独立角色540帧；`effects/<id>/` 为五项技能180帧效果。潜隙紫膜原图属于环境，未绑成跟随角色移动的墙。
- Nearest、关闭Mipmap、透明边界颜色扩展开启；试玩视口开启2D像素对齐。原PNG的RGBA经统一裁剪后与源像素完全相同，未改体型。
- `full_library.tres`：每项完整36帧、12fps、3秒。待机/跑步/浮膜循环。
- `game_library.tres`：实际控制使用短片段，避免3秒普攻。普攻第3个游戏帧命中，重鸣第4帧释放；动画marker由控制器读取，不另设不同命中时刻。详见 `combat_events.json` 的源帧映射。
- 跑步运行循环取连续源帧06–29，去掉起步和制动；速度按 `run_cycle_distance` 驱动，不改变原片段存储的12fps。
- AnimationTree负责视觉状态与转换，角色与技能效果分层，物理移动独立于攻击播放。移动短击使用独立 `layers/run_legs` 腿部帧轨道和上身攻击轨道，通过Shader软遮罩组合；原PNG不变形。这是2D位图分层，不是骨骼动画，也没有补绘缺失姿势。

## 规则和可调参数

主关卡选择 `CampaignPlayer.tscn` 根节点调整实际参数，主场景根节点提供相机前偏移/震动/冲刺缩放；参数保存在场景中，不在_ready强制覆盖。以下数值为旧试验场，主关卡数值见下一节。选择 `Player.tscn` 根节点：Movement、Skills、Combat、Presentation 参数均可在Inspector调整；场景根节点提供镜头跟随、前偏移、震动、缩放和范围设置。镜头默认从本场景碰撞边界推导范围。

- 移动180，地面加速2200、摩擦1600；空中控制70%；重力1200、下落系数1.35；输入缓存0.15秒、土狼0.1秒、最高点停留0.08秒。
- 长/短跳的480/320按**目标高度px**解释，起跳速度按 `sqrt(2*g*h)` 计算。二段350按**速度px/s**解释，蹬墙/下劈反弹300/280按**高度px**解释。它们不是相同物理量。
- 贴流冲700/0.2秒/CD0.6秒，潜隙900/0.3秒/CD2秒，冲刺全段无敌；落地重置贴流冲CD。
- 血100、魂99。短击10伤害回11魂；受击15伤害并扣33魂。迎珠/重鸣/调息各33魂，分别20伤害/15伤害/恢复90血。伤害、半径、时长、CD均已导出。
- 受击0.2秒硬直、0.5秒无敌；命中冻结角色3个60Hz物理帧并震屏。技能命中事件一次释放，攻击窗口内同一目标只结算一次。
- 普攻12fps下第3帧约0.167秒生效；0.1秒恢复后半段允许跳跃/冲刺取消。这是遵循本次指定帧规则的实现，**不是《空洞骑士》官方参数或逐帧手感复刻**。
- 引导独立存储于 `user://tide_3c_guide.cfg`；不改原七房进度。按H随时重看。测试使用独立引导配置。

## 验证与已知边界

自动测试覆盖资源、移动、长短跳、二段限制、缓存、土狼、墙滑蹬墙、冲刺距离/无敌/CD、普攻/下劈、弹道/AOE、魂耗、调息中断、伤害、死亡重生、UI信号、真实键位映射和引导保存。结果见 `evidence/tide-3c/tests.json`，资源像素检查见 `assets.json`。真实GPU渲染截图覆盖待机、跑步、跳跃、短击、重鸣与16:9/16:10引导。

本轮运行异常修复与测试通过不能替代人工手感验收。V2.3/V2.4源素材已有跳切、个别武器形变和锚索接头问题，未通过导入脚本重绘；下劈当前复用原锚定姿势，不是新绘制的下劈动画。跑步速度同步不等于所有原始脚姿已无滑步。角色资产仍保留候选状态，未宣布达到商业级动画验收。

主场景迁移、七房逐房检查和连续主线回归见下节。原房间资源、地形碰撞、原怪物画面、机关脚本及V6存档结构保持；新角色替代运行时旧控制器，旧控制器源码留存。

## 维护

1. `tools/player_import.py`：原画裁剪、根位移去除、源哈希与映射。输入已是V2.4，不重复去紫。
2. 固定引擎 `--headless --editor --import`，等待导入完成。
3. `--headless --script res://tools/build_player.gd`：生成AnimationPlayer、事件marker及Player场景。
4. `--headless --script res://tests/tide_3c_test.gd --fixed-fps 60`：逻辑回归；`--script res://tests/tide_visual.gd --fixed-fps 60`：GPU截图。

依据Godot官方[AnimationTree说明](https://docs.godotengine.org/en/stable/classes/class_animationtree.html)，激活Tree后由Tree控制播放，AnimationPlayer维护片段；避免两者同时调用play争夺轨道。


## 主场景接入与数值来源（2026-10-29）

入口仍为 `scenes/main.tscn`，实例化 `scenes/CampaignPlayer.tscn`（继承Player）；UI为 `scenes/PlayerUI.tscn`。`scripts/campaign_player.gd` 适配旧交互/伤害/能力/重生；敌人代理只增加无形碰撞和伤害接口，不更换旧敌人AI及画面。唯一现有Camera2D挂 `campaign_camera.gd`，保留原房间跟随/全图模式及边界。主场景没有增加第二个相机。

|参数|主场景值|依据|
|---|---|---|
|移动/加速/摩擦|265 / 1800 / 1800|原player.gd|
|重力/终端下落|1050 / 850|原player.gd|
|一段起跳/长跳目标高|570px/s / 154.71px|原起跳速度换算；独立实测约159.5px|
|缓存/土狼|0.12s / 0.12s|原player.gd|
|贴流冲|800px/s，0.2s，CD0.7s|原player.gd|
|生命/敌伤/短击/普通敌血/Boss血|5 / 1 / 1 / 3 / 10|原main.gd|
|普通/Boss近战距离|125 / 180px|原main.gd，不缩成无法命中的Demo距离|
|胶囊/地面吸附/坡度|28×65px / 24px / 55°|原player.gd|
|受击无敌/硬直/击退|1.2s / 0.25s / 160|原player.gd|
|二段上冲/短跳比例|399px/s / 65%|新增默认设计值，可在Inspector调整|
|下落系数/空控/顶点停留|1.35 / 70% / 0.08s|新增默认设计值，可在Inspector调整|
|潜隙/迎珠/重鸣半径|1040px/s / 583px/s / 70px|新增默认设计值，按主工程尺度推导，可在Inspector调整|
|魂/消耗/普攻回魂/伤害扣魂|99 / 33 / 11 / 33|新增默认设计值，可在Inspector调整|
|弹道/范围伤害/调息恢复|2 / 2 / 5|新增默认设计值，对齐5点血量级，可在Inspector调整|
|镜头跟随率/前偏移/震屏|6（原值）/120px /6px|后两项为新增默认设计值，可在主场景Inspector调整|
|主角/地形/新增怪物代理层|2 / 1 / 4|前两层原有；普通移动mask5，冲刺mask1穿怪但不穿墙|

主关卡没有TileMap；复用原多边形地形，不发明Tile单位。UI沿用主题默认字体、18px边距和17px文字；状态条CanvasLayer100。魂和CD为会话状态，不扩充V6永久存档字段。死亡动画完成调用旧检查点重生；R保留手动返回。

通道进入48px横向、125px纵向窗口后自动切换，先离开160px范围再重新允许进入，防止出生立即传回；换房后0.1秒隔离上一房残留输入。与存档点重叠的返回门保留A/D+E，避免自动传送抢占休息。E仍可拾取、存档及主动过门。能力门和Boss封锁仍由原逻辑判断；未制作的后续章节不伪装成已实现地图。

F5/F6是游戏内保存/读取；编辑器F5才是启动。F9临时开启练习能力，原规则禁止将练习能力写入正式存档。Tab镜头、F2原图、F3碰撞、F4分层、1–7房间预览及Esc暂停仍保留。H帮助期间停止玩家输入和敌人伤害推进。

### 验收证据与复跑

扫描记录在 `.production/tide-main-integration/`：`inventory.json`、`baseline.json`、`protected_hashes.json`。逐帧源RGBA未变，本轮重新比对1260张运行PNG（540最终帧、540角色层、180效果层）的RGBA与源裁剪，全部一致，见 `assets-current.json`。134项功能断言通过：核心46、原工程配置11、七房/技能接口58、连续主线17、独立进程读档2。123个受保护文件哈希未变。

使用固定引擎，依次运行（各进程结束再运行下一项，QA共享同一测试存档）：

```powershell
Godot --headless --audio-driver Dummy --path . --script tests/tide_3c_test.gd --fixed-fps 60
Godot --headless --audio-driver Dummy --path . --script tests/campaign_profile_test.gd --fixed-fps 60
Godot --headless --audio-driver Dummy --path . --script tests/campaign_main_test.gd --fixed-fps 60
Godot --headless --audio-driver Dummy --path . --script tests/campaign_route_test.gd -- --reload-fixture
Godot --headless --audio-driver Dummy --path . --script tests/campaign_route_test.gd --fixed-fps 60
```

去掉headless运行 `campaign_main_test.gd` 会保存真实GPU截图，覆盖16:9、16:10、移动攻击分层、Boss房及引导。逻辑结果为 `core-tests.json`、`independent-tests.json`、`main-tests.json`、`reload-tests.json`、`route-tests.json`，不将单个函数断言等同于全地图实战。

测试环境WASAPI输出设备初始化失败，最终自动回归显式使用Dummy音频驱动；声音资源和事件保留，未声称通过扬声器听感验收。GPU证据来自实际Godot视口，键位测试使用引擎物理输入事件；未声称完成原生窗口长时间人工试玩。源动画跳切/武器漂移仍保持candidate，需另做动画美术精修；技术接入通过不代表与《空洞骑士》手感逐帧完全一致。

`tools/build_campaign_player.gd` 仅在重建基准场景时运行，会重设该生成场景参数；日常调参直接编辑CampaignPlayer，不要无故重跑生成器。

### 角色色彩修正

已修复共用角色Shader的重复乘色/重复Alpha问题，恢复源图的灰青披风、暖灯和轮廓过渡。仅修改渲染计算，不改PNG或动画。实机前后对照见[颜色对照](../.production/character-color/对照.html)，专项复跑 `tests/character_color_test.gd`（需要真实渲染，不用headless）。
