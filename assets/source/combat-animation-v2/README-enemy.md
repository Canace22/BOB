# 敌人动作与前摇审计

本轮先审计当前八种敌人，按稳定招式ID、实际播放入口和连段pulse记录。详表 [enemy-audit.json](enemy-audit.json) 保留制作前基线；后续实际生产更新见下节。源图生产、程序验证、实机接入与用户认可分别记录。

## 普通敌人制作更新

后续本批已实际制作八套16帧身体序列（食腐甲rush/double、栖污大甲ambush/press/flip、负壳守卫poke/shell_push/realign），共128张不同绘制帧，另有独立六帧前摇尘屑水痕。食腐甲sweep由主任务另行制作，未计入此数。原图在 `masters/`，逐招精确提示在 `requests/`；选版、哈希、真实格边、平移注册和已知限制见 [normal-production.json](normal-production.json)。原始审计JSON保留制作前基线。

`python assets/source/combat-animation-v2/pack_normal.py` 只做等像素打包，输出 `assets/runtime/sprites/combat-animation-v2/enemies/animations-normal.json` 供主任务合并；不写总配置、manifest或catalog。源图实为1254×1254，四格边界用round划分，不能整除313后丢掉两列像素。身体统一400像素格扩边，不单格等高、不拉伸、不生成插值；每行共同脚底注册保留真实姿态差异。已检查源格Alpha>8轮廓均未触四边，静态身份/完整剪影已检查，GIF编码在 `game/build/qa/combat-animation-v2/normal/`；尚未实际观看循环、双向实机或用户认可。

double-v1把两击画在一段active中，不符合原pulse驱动，已保留而未选用；double-v2改为一个钳击单元供原两段pulse各采样一次。FX-v1雾光过大，FX-v2返修后透明像素由1065184增加至1333958，保留真实笔触与半透明边缘，不用程序抹除遮罩。首章以旧attack0可见高199×0.82=163.18、脚底偏移32×0.82=26.24配准，当前配置仍待实际地形验证。

## 特殊长兵器源图更新

封梁卫五招与老守护者五招已分别生成16帧源图，命名 `masters/<profile>--<action>.png`；精确原提示词、实际补充提示、身份参考与生成路径保存在 `requests/<profile>--<action>.json`。逐格来源、哈希、Alpha与裁边量测见 [special-review-10.json](special-review-10.json)。这十套源图的特殊状态打包由统一任务负责，本脚本不写特殊分片或总配置。

beam_return首版Alpha最小值140、beam_brace首版只有10个全透明像素，elder_vault首版没有全透明像素且有格线：这是深色合成确认的真实残底，不是工具预览的透明RGB噪声。三套都经内置image_gen定向修复，旧版保留为 `-v1.png`，新选版在canonical路径。十套新选版均已查看深色合成、单根兵器与两手握持，Alpha>32主体轮廓未触格边；每套16个不同可见RGBA裁片，像素不同仍不能替代自然动作播放验收。深色总览在 `game/build/qa/combat-animation-v2/special/`。

## 当前证据与补绘顺序

普通敌人优先：食腐甲、泥背伏壳、封壳卫、膜猎手的每招前摇通常只有2张姿态。首章食腐甲另走 `WhaleForagerVisual`，冲撞前摇 `[0,0,1]` 只有2张不同姿态，低扫3张，二连 `[2,2,2]` 只有1张；冲撞active复用8张行走帧，不能登记为新增冲撞动作。

特殊Boss随后：巢鳗钻地前摇1张、蓄巢2张；泵庭水遁前摇1张、二连每段1张；封梁反推前摇1张；老守护者抓取每段1张、撑跃前摇1张。老守护者复制本体与主角动作幻影由专用呈现拥有，幻影已有主角连续帧，不能以普通Boss关键姿态覆盖。

建议逐招补8张连续前摇、6张出手、4张收招，依据动作结构调整，保持原总时长。每格必须有可读的身体、关节或武器运动，不把淡入、形变、平移或重复静图算新增绘制帧。审计同时列源姿态数与tight-alpha规范化RGBA哈希数；像素不同仍不能证明动作连贯。程序粒子和单图水弹、龙卷、格挡环分别登记，当前通用攻击FX在active发出，尚无独立tell绘制序列。

## 可选运行数据合同

资源由统一清单同步至 `res://art/combat-animation-v2/enemies/animations.json`。根为 `{"enemies":{"稳定profileID":{"clips":[],"windups":[]}}}`。条目示意如下，仅说明格式，不是已生产素材：

```json
{
  "action": "sweep",
  "state": "tell",
  "pulse": 1,
  "texture": "res://art/combat-animation-v2/enemies/forager.png",
  "reference_height": 128,
  "chapter_height": 112,
  "frames": [
    {"at": 0, "rect": [0, 0, 256, 256], "pivot": [144, 224]},
    {"at": 0.125, "rect": [256, 0, 256, 256], "pivot": [144, 224]}
  ]
}
```

- 默认`at`是状态进度，首帧0、后续严格递增至不大于1。人形快速释放显式使用`time_unit=seconds`和`reference_duration`，sample接收当前真实phase_duration还原秒数；不另建时钟。带pulse条目优先，详见[人形节奏](humanoid-timing.md)。
- `reference_height` 是整个动作共用的作者标尺，不能逐格按可见高度拉伸。每格rect与pivot独立，pivot、弱点锚点均相对裁片左上角。
- 首章食腐甲的旧4×2整格与实验场裁片入口不同。`chapter_height` 必须经实机配准显式填写，示例112只是格式数值，未经配准不能当正式比例；未填写则首章保留原身体图。它不是碰撞高度。
- 可选 `chapter_ground_offset` 为相对actor脚底的世界像素偏移；旧入口的26.24不能通过移动碰撞体补偿。
- `pump_warden` 身体片段的每格额外要求 `weak_center:[x,y]`、`weak_radius:[rx,ry]`，保留黄色背部弱点；原窗口、红色不可格挡预警与琥珀续招提示仍由原逻辑与材质拥有。
- `windups` 沿用帧结构，附 `anchor:[x,y]` 与正数 `scale`；anchor在素材面向左的本地坐标内，按原朝向镜像。按明确配置的state显示，可为tell、coil、emerge、reform、escape_tell等现有准备态分别登记；不配置active/recover就不会回退显示准备FX。独立世界变换避免继承身体缩放；不造成伤害、不改位移、不自动触发声音，红色不可格挡提示仍由原tell规则拥有。
- 缺配置保留原图；缺贴图、越界裁片、错误进度或泵庭缺弱点锚点时整clip拒绝，原因写入 `diagnostics` 并只在加载时warning，不逐帧刷屏。旧Sprite入口每次先恢复frame/region/offset合同，避免覆盖结束后污染原动画。
- 配置解析不解码全敌人位图。`warmup(id)` 在对应视觉节点_ready只加载该profile所属图，sample重复读取缓存；避免第一次出招同步解码所有Boss图集。
- `elder_mimic` 的施法仅覆盖tell；复制active/recover与幻影继续走原专用实现，之后的独立reground读取[返修回稳](followup/README.md)。封梁防反、压力AI、tell/active/recover时长、伤害、位移、判定均未调整。

## 验证边界

已执行：现有图集元数据与实际RGBA裁片统计、接入文件差异检查。专项测试在 `game/tests/test_enemy_animation_override.gd`，覆盖阶段边界、pulse优先、坏尾帧整段回退、泵庭锚点与复制保护、pivot和等比缩放、仅当前profile预热、coil准备FX与active无回退七项。

原生GPU手动摆姿势夹具：`game/tests/enemy_animation_v2_qa.gd`，由Godot4.7.2原生窗口运行，禁止headless声称截图通过。脚本入口参数为 `--script res://tests/enemy_animation_v2_qa.gd`；用户参数 `-- --profile=pump_warden --action=warden_waterstep --all-frames` 可缩小复查范围；不传筛选则覆盖八种profile、Catalog动作以及beam_riposte/hunter_escape，双向采样。默认前摇0/0.5/0.95、释放和收招，并包括鳗潜地/蓄巢、水遁、封梁格挡和撑跃等特殊状态。`--all-frames` 增加身体和前摇FX所有at边界。输出目录可由 `ENEMY_ANIMATION_QA_OUT` 隔离，默认 `game/build/qa/enemy-animation-v2/`。

夹具在真实场地实例化对应子类后关闭战斗树处理，直接指定当前阶段进度，不执行出招事件、伤害、移动和投射物。截图带玩家原生尺寸对照、来源/动作/阶段标签；`coverage.json` 记录实际贴图、rect/pivot/scale、前摇FX、弱点UV与世界位置、复制幻影，`slow-playlists.json` 提供0.5倍速截图顺序和时长。mimic使用明确标注的普攻参考快照，不声称从真实输入观招。截图保存错误、资源诊断及已配置FX却不可见都会计入失败。脚本写入不等于已运行，手动视觉夹具不替代自然战斗、时序或用户审美验收。

待父任务执行：Godot check/test和真实输入；待新素材完成后逐招复核原时序、连续动作、比例与接地、黄色弱点及不可格挡红预警、首章原图回退、封梁防反与老守护者复制。测试使用原有位图裁片，仅证明适配器合同，不能算补绘交付。

复用经验：同一profile可能有多个呈现入口，必须分别审计实际播放列表；新动作覆盖需要独立记录源图标尺与旧入口可见尺寸，不能用碰撞身高替代。此说明为本批主要配方，未另建重复Skill。
