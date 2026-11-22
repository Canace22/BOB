# 主角动作审计与呈现补齐范围

审计基线：`e8053a8b`。下方是实施前的静态审计与方案快照，逐动作像素结果、逐技能播放采样和基线源码位置见 [player-audit.json](player-audit.json)。索引均从 0 开始。后续已制作十二套184帧候选、接入分段读取与共用起手FX，并按本轮样板范围将主线/参数场/白盒普通近战调到100ms；当前实施与验收边界以 [player/README.md](player/README.md) 为准。Godot由主Agent统一执行。

## 已有素材与真实播放

读取正式 `game/art/tide-picker-action36/animations.json` 的36动作，直接解码 RGBA8 PNG，按每帧矩形提取像素计算 SHA256；同时将全透明像素的隐藏 RGB 清零后重新计数。像素不同不等于姿态连贯，计数不代替身份、握叉手、灯、红绳及足底的视觉检查。

| 动作 | 本体槽位 / 唯一可见像素帧 | 证据与缺口 |
| --- | --- | --- |
| `abyss_scream` | 20 / 7 | 有重复本体；已看原图，抬手姿态多次保持。优先补连续蓄气、抬手、啸出与回收。 |
| `interact` | 13 / 7 | 有重复本体；同时存在结束事件映射截断，不能只补图。 |
| `parry` | 6 / 6 | 真实起手20ms，随后接触帧保持；按住可以一直保持。 |
| `strike2` | 8 / 8 | 已看原图，准备后直接跳高举姿态；像素虽唯一，缺少连续回拨挥弧。 |
| `dash` / `shadow_dash` | 各12 / 12 | 两动作复用同一个本体PNG，影潮不是独立新绘。 |
| `dive` / `dark_dive` | 各8 / 8 | 两动作复用同一个本体PNG；落地前保持索引3。 |
| 其余28动作 | 槽位数等于唯一像素帧数 | 不能因此宣称全部动作连续、全部帧已播放或实机通过。 |

FX里的透明槽是有意停顿，不能当成待补绘缺图：`strike1`、`upper` 各12槽含7个透明槽，只有5张非空FX；`double_jump` 16槽含12个透明槽，只有4张非空FX。详细透明索引记录在JSON。部分本体本身已有发光挥弧，不能只根据独立FX层判断起手是否已经出现攻击光弧。

## 调用路径与保持原因

主线由 `game/src/campaign/campaign_player.gd:3` 继承共用角色，`game/src/combat/combat_player.gd:26` 创建视觉器，`game/src/combat/combat_player.gd:225` 返回 `TideCombatVisual`；选择片段在 `game/src/combat/combat_visual.gd:85`，基础逐帧选取在 `game/src/campaign/action_visual.gd:84`。试验场经 `game/src/prototypes/enemy_lab/player.gd:2` → `game/tests/whitebox_combat/player.gd:2`，其 `game/tests/whitebox_combat/player.gd:59` 返回兼容视觉器，最终仍继承共用实现（`game/tests/whitebox_combat/action_visual.gd:2`）。

1、短窗口：普通近战前摇50ms（`game/content/whalebelly/CampaignPlayer.tscn:47`），格挡20ms（`game/src/combat/combat_guard_skills.gd:24`），后跳回拨30ms（`game/src/combat/combat_skills.gd:11`）。60Hz下只有约1–3个采样机会，增加PNG不会自动增加可见准备帧。尚未修改这些窗口。

2、事件映射：基础播放按真实release对齐原画event_phase（`game/src/campaign/action_visual.gd:150`）。普通近战在50ms内的离线采样为 `strike1:[0,1,3]`，跳过抬叉帧2，提前出现带挥弧的帧3；`upper` 只有 `[0,1]`；`strike2` 和后跳回拨均只显示前摇帧0。

3、保持阶段：格挡在接触帧2保持（`game/src/combat/combat_visual.gd:101`），持续按键把战斗时间停在0.48秒（`game/src/combat/combat_guard_skills.gd:38`）；坠潮在落地前保持索引3，落地后0.24秒播4–7（`game/src/campaign/action_visual.gd:118`）；长冲分为蓄力0–13、飞行14–22、结束23（`game/src/campaign/tide_action_phases.gd:17`）；重劈/旋斩长按预览会停在固定前段帧（`game/src/campaign/tide_skill_input.gd:50`）。这些是需要分段配置和自身动作循环的地方。

4、交互截断：交互的视觉trigger被设为状态结束（`game/src/campaign/action_visual.gd:146`），同时原画event_phase是6/13，因此结束前只播放0–5，不会自然走完后续本体帧。应先将“交互发生时刻”与“呈现整段进度”区分；实际互动行为不移动。

5、复用拼接：`wb_drive` 使用三种现有片段，`wb_charge` 拼接dash+upper，`wb_flurry`复用五段普通斩击（`game/src/combat/combat_visual.gd:90`、`:91`、`:92`）。这些不等于新增独立连续招式。后跳复用jump，残影只是触发前姿态的世界复制（`game/src/combat/combat_player.gd:109`、`game/src/combat/afterimage.gd:18`）。

## 不改变战斗参数的呈现方案

建议先增加只读、显式分段配置：`prepare_frames`、`release_frames`、`recover_frames`、可选`hold_loop`，事件边界仍读取实际控制器release；显示帧不反向驱动命中、位移或输入。首轮建议如下，未实施：

| 家族 | 准备 / 释放后 / 回收映射 | 新绘与注意事项 |
| --- | --- | --- |
| 普通横击 `strike1` | `[0,1,2]` / `[3,4,5,6,7]` / `[8,9,10,11]` | 已看源图，帧3才出现挥弧；50ms最多3个准备姿态。若改变前摇须另获明确授权。 |
| 上挑 `upper`、`wb_rise` | `[0,1]` / `[2,3,4,5,6,7,8,9,10]` / `[11]` | 现有前2帧姿势接近；重映射可保释放边界，但要更明显的蓄势仍须新绘。 |
| 重击 `heavy` | `[0,1,2,3]` / `[4,5]` / `[6,7]` | 已有8独立姿态，先修分段；保持0.25秒释放。 |
| 回拨 `strike2`、`wb_backcut` | 原图仅`[0]`可做准备 / 后续1–7 | 优先新绘连续回拨序列；不把高举命中帧塞入前摇来凑数量。 |
| 格挡 `parry` | `[0,1]` / 接触`[2]` / `[3,4,5]` | 保持20ms；需要持盾自身微动时新绘小循环，不往返播放收叉姿态。 |
| 重劈/奔劈/旋斩 | 按真实release分准备与释放，独立配置满蓄力循环 | 当前已有独立帧，先检查源帧语义；不能任意将攻击弧帧移到蓄力阶段。 |
| 咒术上涌/深啸 | 按0.16秒release分段 | 上涌16唯一先复用；深啸20槽7唯一优先新绘连续序列。3次伤害脉冲保持。 |
| 潮弹/深鸣 | 保持原release，准备与发射后分别配置 | 本体已有16唯一；投射物发射口保持既有配置，不从FX或新图反推判定。 |
| 坠潮/深钟 | 起手 / 空中保持循环 / 落地后4–7 | 起手和空中自身动作可补图；落地环仍归land事件，不能提前播放落地冲击。 |
| 长冲 | 蓄力0–13 / 飞行14–22 / 结束23 | 保留段边界；长时间满蓄力及飞行需要真正连贯小循环，不能用缩放冒充。 |
| 六种共用技法 | 各段按原命中时刻编排 | `wb_charge`、`wb_drive`、`wb_flurry`若需要完整独立动作，应分招新绘；不能以拼接现有片段宣称完成。 |
| 交互 | 完整呈现0–12，交互触发仍在原时刻 | 原图7唯一，先修结束映射再评估是否全部替换；不改变互动生效时间。 |

FX接入缺口：主线在 `game/src/campaign/campaign_player.gd:49` 安装 `TideWorldEffects`，但 `game/src/campaign/tide_world_effects.gd:95` 没有通用start处理；heavy释放、scan释放和dive落地从事件帧起播，旧FX前半段不构成通用起手特效。试验场没有安装该世界层，仅使用共用本体FX、格挡环及后跳残影。新增起手FX应放共用呈现层，使用已入库位图并跟随命中停顿、取消、受击/死亡和退出统一回收，不改变攻击所有权。

接入边界：`world_socket` 会读取逐帧socket（`game/src/campaign/action_visual.gd:233`），当前只有anchor的tether使用逐帧socket；本批不重映射anchor。投射物创建在 `game/src/campaign/tide_skill_hits.gd:20`，区域伤害在同文件`:6`，显示配置不能替换这些真实攻击路径。

## 本轮验证与后续验收

- 已执行：36动作的body/fx逐区域像素哈希与透明帧计数；manifest槽位读取。
- 已执行：31个技能/分段按源码公式进行60Hz离线采样；包含t=0、排除duration末端，不包含取消、hitstop或物理/渲染相位差。JSON记录的最长保持是同索引保持，不等同于重复像素的最长保持。
- 已执行：查看身份母版及parry、strike2、strike1、upper、heavy、abyss_scream、interact原图，核对前摇姿态语义；没有将其余动作标为视觉通过。
- 待执行：收到具体新绘范围后使用内置image_gen制作时间连续序列，检查身份、持叉手、灯、红绳、足底、画布和透明边距；不调用外部收费API。
- 待执行：呈现接入后由主Agent统一运行Godot check/test，并实按短前摇、蓄力保持、打断与死亡、后跳回拨、空中落地五类路线；当前离线审计不构成实机或美术认可。

本批未修改Skill：已经沿用现有素材与Godot Skill，尚未形成新的成功制作配方，不沉淀未经实机验证的参数。
