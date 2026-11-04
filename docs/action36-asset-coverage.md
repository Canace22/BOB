# 拾潮者36项资产与逻辑覆盖

由仓库根目录 `build_asset_coverage.py` 根据实际 `animations.json`、[操作映射](action36-controls.md)、独立 `validation.json`（存在时）和哈希绑定的图集完整性报告生成。重跑：`python build_asset_coverage.py`。本表不会写入验收状态或修改运行清单。

动画清单 SHA-256：`a18bd70cbd33d4b1f13319ba25a618f5c3a207e47e9e9963bb6b8c40dc94243f`。

技术完整性只包含源/图集帧数、字节哈希、透明边界和矩形范围；不代表操控、美术或正式取得流程通过。逻辑回归与GPU外观分别记录，最终日志见 `game/build/qa/action36/tests-final.log`；不能以逻辑测试替代外观结论。逐项实机/美术状态仅采用当前图集哈希匹配且证据完整的 validation 记录；缺失时明确待验，候选不自动升格。

表内FPS是素材名义帧率；运行时走跑由位移驱动，攻击按事件重映射，跳跃/下砸/长冲按物理阶段选择，并不播放整段展示视频。左右使用一套图集的一次 facing 镜像；腰灯/持叉手遵循整体2D镜像规范。

| key / 名称 | 逻辑ID / 现有实现 | 本体来源与当前采用 | 帧数 / FPS | FX分层与来源 | 本批类型 | 技术 / 实机 / 美术 | 验收入口（两向） |
|---|---|---|---|---|---|---|---|
| `idle` 待机 | idle；复用+换图 | 视频提取 [01_idle_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/01_idle_retry.mp4>) | 36 / 12 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 地面静止；基础/状态；循环、脚底；主场景/隔离F9 |
| `walk` 行走 | run + tp_walk；新减速分支 | 视频提取 [02_walk.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/02_walk.mp4>) | 24 / 12 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | Ctrl+左右；基础/移动派生；两向步距；主场景/隔离F9 |
| `run` 跑步 | run；复用+换图 | AI补制精灵表 [run-v3.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/run-v3.png>) | 8 / 12 | 无独立图集FX | 新增AI精灵表替换缺陷视频本体 | 完整性通过 / 证据通过 / 独立审阅通过 | 左右；基础/状态；距离驱动、撞墙停步；主场景/隔离F9 |
| `jump` 跳跃与落地 | jump_land；物理上下行/落地；复用+分阶段显示 | 视频提取 [04_jump_final_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/04_jump_final_retry.mp4>) | 18 / 24 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | K/空格；基础/状态；可变跳高、实际落地；主场景/隔离F9 |
| `double_jump` 空中二段跃 | strike_02；复用+换图 | 视频提取 [05_double_jump_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/05_double_jump_retry.mp4>) | 16 / 24 | 角色局部层 16帧；同源拆分 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 空中再按跳；基础/状态；次数重置、可攻击取消；主场景/隔离F9 |
| `wall_slide` 贴壁缓降 | 空中墙探针+向墙输入；复用+独立显示 | 视频提取 [wall_slide-body.mp4](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/jobs/wall_slide-body.mp4>) | 20 / 12 | 无独立图集FX | 新增AI补制视频并提取本体 | 完整性通过 / 证据通过 / 独立审阅通过 | 贴墙下落；基础/状态；两侧墙方向；主场景/隔离F9 |
| `wall_jump` 蹬壁反跳 | _try_jump墙分支+wall_lock；复用+独立显示 | AI补制精灵表 [wall_jump-v1.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/wall_jump-v1.png>) | 8 / 20 | 无独立图集FX | 新增AI精灵表替换缺陷视频本体 | 完整性通过 / 证据通过 / 独立审阅通过 | 贴墙按跳；基础/状态；背离墙的速度与朝向；主场景/隔离F9 |
| `dash` 贴流冲 | A1_dash；复用+残影 | 视频提取 [08_dash.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/08_dash.mp4>) | 12 / 24 | 无独立图集FX；历史本体快照残影，世界空间 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | L/Shift；冲刺/基础技能；撞墙、冷却、取消；主场景/隔离F9 |
| `float` 浮膜滑翔 | floating；动画代理A2_float；复用+换图 | 视频提取 [09_float_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/09_float_retry.mp4>) | 24 / 12 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 空中按W；浮膜/移动能力；1.5秒额度、落地重置；主场景/隔离F9 |
| `anchor` 红索锚定与脱环 | grapple_target；代理A3_anchor；复用+世界绳 | 视频提取 [anchor-body.mp4](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/jobs/anchor-body.mp4>) | 20 / 24 | 无独立图集FX；tether.png世界位图绳；来源见effects-sources.json | 新增AI补制视频并提取本体 | 完整性通过 / 证据通过 / 独立审阅通过 | G选择前方近环/再次G脱环；锚定/场景移动；挂点、脱环、切房清理；主场景/隔离F9 |
| `strike1` 扣潮·横击 | strike_01；复用+事件防漏 | 视频提取 [11_strike1.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/11_strike1.mp4>) | 12 / 24 | 角色局部层 12帧；同源拆分 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | J/Q；基础/攻击；左右判定、同目标去重；主场景/隔离F9 |
| `strike2` 回拨·斜击 | strike2；代理strike_01；新增 | 视频提取 [12_strike2.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/12_strike2.mp4>) | 8 / 24 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 连续J/Q，间隔≤0.65秒；基础/连招；缓冲、锁向、命中帧；主场景/隔离F9 |
| `upper` 挑潮·上挑 | upper；代理strike_01；新增 | 视频提取 [13_upper_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/13_upper_retry.mp4>) | 12 / 24 | 角色局部层 12帧；同源拆分 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | W/上+J；基础/方向攻击；上方范围；主场景/隔离F9 |
| `pogo` 点潮·下刺反弹 | A3_anchor；复用+换图 | 视频提取 [14_pogo_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/14_pogo_retry.mp4>) | 12 / 24 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 空中S/下+J；基础/方向攻击；命中才反弹、重置冲刺/跳跃；主场景/隔离F9 |
| `orb` 叉鸣弹 | A4_parry；WhalebellyTideOrb；复用+扫掠碰撞 | 视频提取 [15_orb_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/15_orb_retry.mp4>) | 16 / 24 | 无独立图集FX；projectile.png离体弹体；来源见effects-sources.json | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | U；基础/弹体；挂点、墙遮挡、固定方向；主场景/隔离F9 |
| `heavy` 重鸣·涨潮环 | heavy；复用+换图 | AI补制精灵表 [heavy-v1.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/heavy-v1.png>) | 8 / 16 | 世界地面环 8帧，event_frame=4；[ground_ring-v2.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/ground_ring-v2.png>) | 新增AI精灵表替换缺陷视频本体 | 完整性通过 / 证据通过 / 独立审阅通过 | I；基础/范围技能；70像素实际范围、资源；主场景/隔离F9 |
| `dive` 坠潮·沉钟 | dive；代理heavy；新增 | AI补制精灵表 [dive-v1.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/dive-v1.png>) | 8 / 16 | 世界地面环 8帧，event_frame=4；[ground_ring-v2.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/ground_ring-v2.png>) | 新增AI精灵表替换缺陷视频本体 | 完整性通过 / 证据通过 / 独立审阅通过 | 空中S/下+U；舌台/基础潮术；空中准备、真实落地点；主场景/隔离F9 |
| `parry` 迎珠·偏转 | parry；代理A4_parry；新增 | AI补制精灵表 [parry-v1.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/parry-v1.png>) | 6 / 16 | 无独立图集FX；成功时复用projectile.png闪光；窗口开始不播放 | 新增AI精灵表替换缺陷视频本体 | 完整性通过 / 证据通过 / 独立审阅通过 | B；基础/防御；正前方、0.06～0.21秒有效；主场景/隔离F9 |
| `slit` 敛膜潜隙 | A5_slit；复用+换图 | 视频提取 [slit-r2-body.mp4](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/jobs/slit-r2-body.mp4>) | 18 / 24 | 无独立图集FX；历史本体快照残影，世界空间 | 新增AI补制视频并提取本体 | 完整性通过 / 证据通过 / 独立审阅通过 | O；冲刺/移动技能；世界墙仍阻挡；主场景/隔离F9 |
| `heal` 合灯调息 | recover；复用+换图 | 视频提取 [20_heal.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/20_heal.mp4>) | 24 / 24 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 落地且受伤时P；基础/恢复；33魂、完成时回血、打断；主场景/隔离F9 |
| `scan` 照见·骨音探潮 | scan；代理interact；新增 | 视频提取 [21_scan.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/21_scan.mp4>) | 16 / 24 | 世界地面环 16帧；同源拆分 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | T；基础/探索；420像素探查、reveal接口；主场景/隔离F9 |
| `interact` 伸手交互 | interact；复用+换图 | 视频提取 [22_interact.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/22_interact.mp4>) | 13 / 24 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 门/营地/奖励旁E；基础/交互；仅有效目标、延迟安全切房；主场景/隔离F9 |
| `hurt` 受击与踉跄 | hit；复用+清理 | 视频提取 [23_hurt.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/23_hurt.mp4>) | 10 / 24 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 受伤且非无敌；基础/状态；扣血、硬直、打断残留；主场景/隔离F9 |
| `defeat` 力竭归零 | defeat；复用+换图 | 视频提取 [24_defeat.mp4](<G:/鲸落万物生/outputs/拾潮者_空洞骑士参考_全动作展示/24_defeat.mp4>) | 36 / 24 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 生命归零；基础/状态；动画继续、死亡菜单按R返回检查点；主场景/隔离F9 |
| `shadow_dash` 影潮穿行 | shadow_dash；代理A1_dash；新增 | 视频提取 [08_dash.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/08_dash.mp4>)；复用dash本体，冷青色调 | 12 / 24 | 无独立图集FX；历史本体快照残影，世界空间 | 复用修复本体，保留独立升级逻辑 | 完整性通过 / 证据通过 / 独立审阅通过 | 章末后L/Shift；章末/冲刺升级；免敌层、世界墙保留；主场景/隔离F9 |
| `great_slash` 蓄潮·重劈 | great_slash；代理heavy；新增 | 视频提取 [26_great_slash.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/26_great_slash.mp4>) | 16 / 24 | 角色局部层 16帧；同源拆分 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 按住J≥0.55秒松开；冲刺/蓄力派生；蓄力受击取消、单次伤害；主场景/隔离F9 |
| `dash_slash` 奔潮·冲刺劈砍 | dash_slash；代理strike_01；新增 | 视频提取 [27_dash_slash.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/27_dash_slash.mp4>) | 12 / 24 | 角色局部层 12帧；同源拆分 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 冲刺中J；冲刺/移动攻击；方向锁、真实前冲；主场景/隔离F9 |
| `cyclone` 旋潮·回旋斩 | cyclone；代理heavy；新增 | 视频提取 [28_cyclone.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/28_cyclone.mp4>) | 24 / 24 | 角色局部层 24帧；同源拆分 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 按住J≥0.55秒，S+松开；冲刺/蓄力派生；三段各一次、时间跨越；主场景/隔离F9 |
| `crystal_dash` 凝流·蓄力长冲 | crystal_dash；代理A1_dash；新增 | 视频提取 [29_crystal_dash.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/29_crystal_dash.mp4>) | 24 / 24 | 无独立图集FX；历史本体快照残影，世界空间 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 地面按V≥0.6秒松开；冲刺/蓄力移动；移动扫击、撞墙退出、跳取消；主场景/隔离F9 |
| `up_spell` 潮声·上涌 | up_spell；代理heavy；新增 | 视频提取 [30_up_spell_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/30_up_spell_retry.mp4>) | 16 / 24 | 角色局部层 16帧；同源拆分 | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | W/上+U；舌台/方向潮术；上方命中、共享潮术冷却；主场景/隔离F9 |
| `abyss_scream` 深潮·共鸣啸 | abyss_scream；代理heavy；新增 | AI补制精灵表 [abyss_scream-v2.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/abyss_scream-v2.png>) | 20 / 24 | 角色局部层 20帧；[31_abyss_scream_final_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/31_abyss_scream_final_retry.mp4>) | 新增AI精灵表替换缺陷视频本体 | 完整性通过 / 证据通过 / 独立审阅通过 | 章末后W/上+U；章末/上涌升级；三段脉冲、单次扣费；主场景/隔离F9 |
| `shadow_orb` 深鸣·穿潮弹 | shadow_orb；代理A4_parry；新增 | 视频提取 [32_shadow_orb.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/32_shadow_orb.mp4>) | 16 / 24 | 无独立图集FX；shadow_projectile.png离体弹体；来源见effects-sources.json | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 章末后U；章末/弹体升级；穿敌不穿墙、每敌一次；主场景/隔离F9 |
| `dark_dive` 坠潮·深钟 | dark_dive；代理heavy；新增 | AI补制精灵表 [dive-v1.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/dive-v1.png>)；复用dive本体及地面环 | 8 / 16 | 世界地面环 8帧，event_frame=4；[ground_ring-v2.png](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/sprite-sheets/ground_ring-v2.png>) | 复用修复本体，保留独立升级逻辑 | 完整性通过 / 证据通过 / 独立审阅通过 | 章末后空中S/下+U；章末/下砸升级；真实落地、0.28秒落地保护；主场景/隔离F9 |
| `swim` 耐蚀浮游 | TideSkillWater + visual_key=swim；新增组件 | 视频提取 [swim-body.mp4](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/jobs/swim-body.mp4>) | 24 / 12 | 无独立图集FX | 新增AI补制视频并提取本体 | 完整性通过 / 证据通过 / 独立审阅通过 | 进入显式水面Area；章末/被动环境能力；未解锁受酸伤、出水还原；独立最小条件，非正式七房已配置 |
| `tram` 通行凭证·启门 | tram + TideTransitGate；新增组件 | 视频提取 [tram-body.mp4](<G:/鲸落万物生/BOB/assets/source/tide-picker-action36/jobs/tram-body.mp4>) | 16 / 24 | 无独立图集FX | 新增AI补制视频并提取本体 | 完整性通过 / 证据通过 / 独立审阅通过 | 有效门旁E；章末/交互条件；无目标拒绝、回调一次；独立最小条件，非正式七房已配置 |
| `turn` 原地转向 | facing变化短暂显示turn；新增显示 | 视频提取 [36_turn_retry.mp4](<G:/鲸落万物生/outputs/拾潮者_14集参考_左右动作全集/36_turn_retry.mp4>) | 8 / 24 | 无独立图集FX | 复用现有源片并返修抠像/配准 | 完整性通过 / 证据通过 / 独立审阅通过 | 静止时反向；基础/表现；不锁移动、不二次镜像；主场景/隔离F9 |

当前哈希匹配的完整性通过：**36/36**；报告错误 0，警告 0。

验收脚本：`game/tests/whalebelly/action36_coverage.gd` 通过正式主场景共享角色检查两向；记录带 `practice_only_evidence`，包含按键/API和临时条件，不等同于操作系统键盘全流程。正式解锁、可照做路线、取消规则与参数见[操作说明](action36-controls.md)。最终录屏、性能、发布和未完成项以[进度](../game/progress.md)及独立验收记录为准。

FX独立帧数以图层自己的 `frame_count` 为准，世界环从 `event_frame` 开始，生命周期由真实释放/落地事件决定。本批heavy/dive/dark_dive共享独立纯地环，峰值起播并按范围等比缩放；升级深钟复用基础下砸本体，差异为伤害、范围、深青色调和落地保护，未虚构一套新身体动画。
