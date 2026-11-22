# 主角连续帧与共用起手呈现 V2

## 本批交付

通过内置 `image_gen` 从同一拾潮者身份母版生成十二套独立动作，共184张唯一帧。首批为回拨 `strike2` 16帧、深啸 `abyss_scream` 16帧、交互 `interact` 16帧、格挡 `parry` 8帧（进入2帧、持盾小循环4帧、退出2帧）。补齐八个核心族 `strike1`、`upper`、`heavy`、`orb`、`up_spell`、`great_slash`、`cyclone`、`dive` 各16帧。它们是重新绘制的时间序列，没有用缩放、重复、插值或淡入淡出制造额外动作帧。`dark_dive` 明确复用新dive本体，不另计新绘帧。

状态为 **candidate**：本轮已检查原图、灰底透明合成、逐帧唯一性、画布边距与固定尺度；尚未获得用户美术认可。当前会话的浏览器预览访问被 `GetCursorPos` 拒绝访问（`0x80070005`），可见和隐藏入口均失败，所以不声称实际看过动画播放或Godot实机。预览已保留，主Agent负责统一引擎、GPU播放与路线验收。

| 动作 | 新帧数 | 本体阶段 | 真实技能边界 |
| --- | --- | --- | --- |
| 回拨 | 16 | 准备0–6，切入/回收7–15 | 读取既有strike2或wb_backcut实际release；后跳回拨30ms不加长 |
| 深啸 | 16 | 蓄气/抬手0–6，释放/回收7–15 | 释放0.16秒、3次伤害脉冲均未改 |
| 交互 | 16 | 完整0–15 | 真实交互发生时刻未动；解开视觉被结束事件截断的问题 |
| 格挡 | 8 | 进入0–1，持盾2–5循环，退出6–7 | 按各实际控制器的release/parry_end；正式主线/enemy_lab20ms保持，旧whitebox兼容控制器原值不动 |

新本体保留旧动作的独立FX与socket元数据。深啸本体16帧、旧FX20槽分别读取，不能共用同一个整数帧索引。

新增八个核心族都有六张真实准备绘图0–5，出手6–9、回收10–15；非坠潮动作播放释放后的完整6–15段。准备段不画攻击挥弧或落地冲击，独立FX仍受真实release约束。实际能看到多少准备帧仍取决于既有窗口与物理采样，例如100ms普通横击可容纳约6次60Hz采样，上挑60ms只约3–4次；本批不以宣称“六帧准备”暗示加长了技能判定窗口。

重劈与旋斩的长蓄力使用本批准备绘图2–5循环，不回放已释放的挥击。坠潮单独配置：0–5空中起手、6–9空中下坠循环、真实落地后才播放10–15落地回收；落地时间与追加0.24秒由原控制器所有。新图中腾空起手/下坠没有地面冲击画面。

## 可追溯产物与重建

- `requests.json`、`requests-core8.json`：两批精确请求与身份参考路径，使用内置工具，无外部收费API；第二批按两图并发生成，未遇429。
- `repairs-core8.json`：上挑半透明白底、重击第三手、旋斩回收双叉的三次定向修复请求与保留的失败原件；每个缺陷只重试一次，未把失败版本接入。
- `<action>/original.png`：内置工具输出原件，未覆写母版。
- `<action>/frame-00.png` 等：统一256×256画布的184张裁片。
- `<action>/review-gray.jpg`：原件正常alpha合成，避免把alpha=0下的隐藏彩色RGB误诊为溢色。
- `<action>/preview.gif`：每帧85ms的慢放素材预览，不等同于真实技能时序；[preview.html](preview.html) 同时显示放大与接近94px角色高度的预览。
- `extraction.json`：原件SHA256、实际输出尺寸、显式裁切矩形、每行地面锚点、每动作唯一尺度、每帧平移/pivot/边距与像素SHA256。
- `build_player.py`：确定性裁片、打包及重复/边距检查；运行 `python assets/source/combat-animation-v2/player/build_player.py` 可重建。

运行导出在 `assets/runtime/sprites/combat-animation-v2/player/`，由主Agent加入 `game/art/manifest.json` 并执行标准同步。运行时只读 `res://art/combat-animation-v2/player/`，不从source目录加载。

生成器实际输出不是请求中的标准尺寸：三套16帧分别为1246×1262、1247×1261、1261×1247，8帧为1774×887。按实际尺寸计算等分网格，而非假设1024或1536。每动作只用一个尺度；第二、三、四行的地面偏移作为显式行配准记录，不对每帧可见框单独拉伸或归一身高。原画动作自身的蹲伏、伸手、摆袍与重心变化保留。

第二批同样记录实际尺寸。上挑/上涌的举叉或举手越过了名义等分行界，潮弹最大伸叉越过名义列界；完整原件没有裁缺这些肢体。`build_player.py` 的显式 `CUTS` 在透明gutter中选裁界，并仍以原网格root配准，避免截叉、混入邻帧尖端或因裁框变宽移动角色。坠潮落地10–15按明确的着地脚点配准，空中阶段保持原动作起伏；不是用每帧最高/最低alpha来拉伸或归一身高。所有裁界、脚点、平移与原件hash保存在 `extraction.json`。

## 共用读取器与程序驱动FX

`TideVisualPhaseMap` 读取 `phase-profiles.json`。普通横击、上挑、重击、回拨、重劈、奔劈、旋斩、上涌、潮弹、下刺分别设置准备与释放后帧段；包含攻击挥弧的源帧不再提前放进准备段。重劈/旋斩长蓄力使用已检查的准备姿态小循环，格挡使用本批新绘的2–5循环。长冲没有新绘，完整保留原 `TideActionPhases` 契约：准备0–13、满蓄保持13、飞行14–22、退出23，不另加准备或飞行循环。所有新循环只由呈现时钟推进，hitstop时停住，不写状态时间。

`TideStartupEffects` 在共用战斗视觉器中建立固定7粒子池，覆盖29个独立动作ID（审计表31项含三段drive的重复ID）。轻招用武器聚光、重招用压缩水丝、咒术用凝聚光点、移动用已开始后的短尾迹，治疗/交互用弱聚光。贴图复用已经入库的 `tide-picker-action36/projectile.png`，登记为 **程序驱动特效**，不算新绘本体帧。特效读取实际release及多段脉冲、蓄力输入层已经选择的状态，不提前猜测60ms组合输入；受击、死亡、禁用控制、自然结束和取消后回收，不发伤害、不建碰撞、不改位移。

普通近战按本轮主Agent确认的默认样板从50ms调整到100ms，仅修改 `CampaignPlayer.tscn`、`campaign_profile.gd`、`tests/whitebox_combat/player.gd` 三处 `melee_startup`。默认动作总时长0.35秒不变。输入60ms容差/200ms预输入、格挡、dash、后跳、后跳回拨、技能catalog与wb技能release/伤害/冷却均未改；泛用旧 `TidePlayer` 的marker回退仍保留。

## 验证边界

已执行：确定性重建4套56帧、唯一性和alpha边距检查、正常灰底合成检查、源脚本语法检查、定向文本diff空白检查。原件与裁片静态检查没有明显第三手、武器交换或裁边；这不能替代动态连续性或用户美术审阅。

后续已扩展为12套184帧并重新执行像素唯一性、alpha边距和所有phase索引范围检查，见 `verification-core12.json`。已看 [review-core12.png](review-core12.png) 的统一尺度准备/释放/回收复合图，并对upper/up_spell/orb保留逐帧灰底检查图；三次生成缺陷修复后保留候选，动态与场景验收仍归主Agent。首批 `verification.json` 仅是当时56帧的阶段快照，不代表当前最终总数。

已添加、待主Agent统一执行的 `game/tests/test_player_animation_v2.gd` 覆盖：

1、横击及其它挥弧/施放帧不能出现在真实release之前。

2、16帧新深啸本体和20槽旧FX独立，交互能到最后一帧。

3、持盾四帧循环只改变画面，不推进或改写防御时钟。

4、所有catalog与共用技法有起手FX家族，多段脉冲有各自聚拢阶段。

5、主线/profile/白盒/UI的100ms近战前摇一致，真实首伤不早于100ms，保留后摇防御取消与前摇后跳取消且无幽灵伤害。

6、新增八个核心族各16帧、各6张真实准备绘图；坠潮空中永不选落地回收，真实落地后才能进入10–15，呈现不写落地时钟。

## 老守护者幻影消费缝与原生GPU展示

幻影原来已经从主角 `action_visual.load_clip` 与同一合并manifest取得新texture；缺口是它继续自行按旧fraction选本体、按新本体帧数索引旧FX，并用旧足底数据覆盖新pivot。现将 `TideVisualPhaseMap.index_from_context` 作为共用只读解析口：主角 `body_index` 保持原接口，幻影只向同一resolver传自身复制时钟、release与落地上下文。仅 `authored_pivot` 新本体走此入口并跳过旧foot覆盖，旧非override片段仍保持原映射、选帧和FX规则。`elder_mimic.gd` 与 `elder_repertoire.gd` 的执行、观招、脉冲、伤害和位移未改。

新增 `game/tests/test_elder_player_animation_v2.gd` 通过实际执行普攻/上挑/重击、真实释放后的观招和真正复制伤害，检查幻影的新atlas、准备帧段、原release边界及schedule不变；重复呈现采样不推进敌人执行时间或玩家呈现时间。该回归由主Agent统一运行，本子任务未执行引擎。

原生GPU素材展示入口：

```text
node tools/godot.mjs run -- --script res://tests/player_animation_v2_qa.gd -- --fps=60
```

这是明确标注的 **MANUAL ANIMATION FIXTURE / BODY ONLY**。它读取实际运行metadata，复用 `TideActionVisual.make_frames` 与同一phase resolver，直接摆放图集；不创建输入、碰撞、技能或复制执行器。默认拒绝headless运行。1280×720画面同时显示旧action36/新runtime、左右朝向、双倍尺寸及94px角色高度，粉色十字表示根点。

输出到 `game/build/qa/player-animation-v2/`：十二动作及两个长蓄力序列的逐帧PNG、统一 `frames.json`。该JSON记录相对时间、供GIF使用的 `display_ms`、实际GPU抓取耗时 `wall_capture_ms`、准备/释放/回收/长蓄/空中/落地阶段、旧新帧索引、runtime texture路径、应用pivot/offset及双向alpha边界镜像误差。额外在真实release与手动落地边界精确采样，防止低采样率跳过边界。展示时序中parry与dive的阶段是显式手动夹具，不构成真实按键或物理落地证明；实战仍需对应回归及本地输入路线。

## 首轮完整回归后的修正

原始 `game/build/qa/animation-v2-tests.log` 保留未改，结果为471通过、8个测试方法失败，另有一次测试侧越界；修正分类与原始日志hash记录在 `regression-repairs.json`。其中长冲错误来自对未新绘动作添加了准备循环，现已撤回并在共用resolver直接保留原phase分数；新本体足底路径生产代码已正确跳过旧表，越界实际在测试直接用新索引13读取旧12槽脚底数组，未误改正确的生产分支。

测试已区分新片段的authored pivot/自身PNG byte hash/完整rect与旧片段的原脚底表hash/rect，旧脚底表没有伪造或重写。新增回归会让真实角色跑到超过旧12槽的晚帧，核对生产 `apply_layer` 保留新pivot。近战手感测试按实际start/hit_resolved的物理tick与状态时间约束100ms首伤，跳跃紧接真实命中；白盒防御取消等待首次真实后摇窗口并计入原hitstop，不用旧固定12帧。

已读取主Agent产出的native `frames.json`，首轮14个手工素材展示case、0失败；这份手工layout没有走真实角色旧脚底补偿，不能作为生产足底无错或真实输入通过的证据。主Agent后续串行完整回归报告为479通过、1失败，0 SCRIPT ERROR/ERROR，本批主角/幻影修复全部通过；剩余唯一R1-02上游碰撞断言不在本子任务修改范围。主角14case最终GPU重跑仍由主Agent记录结果。

仍待实际验收：check/test结果、94px真实角色比例、两侧朝向、场景遮挡与足底、四套动作连续播放/收口、持盾循环接缝、长蓄力、hitstop、取消/受击/死亡回收、真实键盘路线。没有将静态检查、离线模型或源图数量写成这些项目通过。

未修改Skill：本批使用现有sprite-animation规定的固定尺度、显式行配准、身份锁定与技术/实机分栏流程；新增具体参数与失败证据集中记录于本目录，避免把未经引擎验证的参数提升为通用配方。
