# 鲸落 Godot 架构

当前19房场景均自带`RoomEcology`节点及导出`room_id`，单独加载房间即可解析现有房间数据和`content/whalebelly/environment/ecology-19.json`，构造可暂停时钟与有界生态池。主控support仅为旧测试夹具补缺，不重复创建。生态贴图按口腔/肺心/胃枢/断脊/颅腔/尾槽的实际材质选择，根部按曲面插值配准，`colony`可指定贴图可见宽度、根点和幅度；不接管战斗或原有归海幼体。非资源JSON在导出include_filter中；当前接入与实机证据见[生态V2](../assets/source/ecology-19-v2/README.md)，[V1设计图](../assets/source/ecology-19-v1/README.md)保留为概念参考。

正式工程位于 `game/`，固定 Godot 4.7.2、GL Compatibility、Web 单线程。F5 默认进入 `content/whalebelly/main.tscn`，运行 WhalebellyRuins 五区19房、CampaignPlayer、角色技能和环境动态。旧模块化五房及完整旧目录已移到[归档分支](legacy-archive.md)。

R2-03/04以配方`reference_background`选择单房清底图、`background_schools`配置无伤害生态池，`framing.motion`选择固定根膜片或RGB菌光。KitDepthMotion的`unified_ambient`默认关闭，仅这两房登记新动件和原气泡／微粒，关闭子件自播；KitAmphipodSchool可只读flag淡出，不能发伤害／奖励。其它十房204项兼容检查通过。[原画背景与动态V4](../assets/source/r2-reference-motion-v4/README.md)。

原画建筑V3新增`build_world_framing.mjs`，生成配方`framing`中的独立RGBA分件：catalog pivot／axis等比配准，按每项Z／opacity／可选parallax绘制，无物理节点。三槽的位置与图标尺寸是视觉数据，三个flag含义和门条件独立保持。完整洞框需覆盖全景实际长宽比造成的房外视域；[当前来源与验证](../assets/source/reference-architecture-v3/README.md)。

后续十二房以`content/whalebelly/world/recipes/`及`tools/build_world_rooms.mjs`生成。原画depth在Far替换同源透明层，中景地标／生态、World台面／台腹／居民、Foreground分别绘制；台腹辅助生成器`build_world_bodies.mjs`只产美术节点，不改碰撞。`KitDepthMotion`负责新水光／柔光的房间内可暂停时钟，原`KitDriftField`仍负责潮压缓流。来源及本轮168项GPU／67项后区Input验收见[十二房原画接入](../assets/source/remaining-19-v2/README.md)。

正常游玩相机持续居中主角全局坐标，包括世界外缘和支路上端；缩放固定 1.0，不使用前视、探看、下落偏移或震屏。2026-11-18按用户反馈取消外缘软限位，避免角色走到角落HUD下面。随身光束与补光复用入库位图；小地图接近角色轮廓时淡出。Tab不改变正常跟随，原图对照、截图和分层查看保留全景行为并隐藏随身光。当前本地版为19房连续世界，邻房提前准备并可见，普通跨房不淡黑、不重建主角；运行约定与证据统一见[流式世界](streaming-world.md)。F9为会话临时练习，退出恢复正式进度快照；F10仅在练习中切换基础/升级技能组，不改正式取得条件。

当前正式入口按邻房驻留窗口流式准备场景，普通跨界保留同一主角，使用[须门遗港场景衔接](../assets/source/xumen-continuity-v1/README.md)的共用远景与连接动件，以及新增的位图连接平台。后续[实际连通场景](../assets/source/xumen-connected-v2/README.md)及[统一母版](../assets/source/xumen-unified-v1/README.md)的制作源仍保留在资源库。

七房早期素材来源采用[原画保留版](../assets/source/xumen-original-style-v1/implementation.md)，依据outputs的器官、材质和笔触复用/补绘位图。用户明确保持19房获取链；`layout/physics-v1.json`固定已验证地面和安全落点，生成器验证配方几何签名后才换图，不因新贴图重采高。`tests/fixtures/xumen-*.json`保留精简独立玩法快照，测试不依赖外部制作目录。

## 代码与内容

| 路径（相对 game/） | 职责 |
| --- | --- |
| `src/campaign/main.gd` | 活动房间上下文、机关、敌人/Boss、能力、营地、HUD、V6进度；显式重生/读档重建场景 |
| `src/campaign/tide_player.gd`、`campaign_player.gd` | 完整角色动作与技能、主关卡参数适配、动画事件；主线继承共用战斗角色 |
| `src/combat/` | 主线和白盒共用的手柄式键盘输入、剑技、后跳取消、逐帧呈现与局部命中反馈；保留既有 wb_* 稳定技能ID |
| `src/ui/combat_combo_hud.gd`、`src/combat/combat_hints.gd` | 右下图标技能页与方向派生提示，直接读取输入页表、方向派生、升级与实际可用性；右侧Combo由正式命中事件累计；敌人使用主角的可玩层，营房中景不会遮挡敌人 |
| `src/campaign/action_visual.gd`、`tide_world_effects.gd` | 正式主角的可变帧图集、实际状态/阶段映射、世界特效与历史残影；物理由角色控制 |
| `src/campaign/tide_action_phases.gd` | 晶长冲蓄力/飞行/退出的呈现阶段，退出尾帧不延长控制锁定 |
| `src/campaign/tide_skill_catalog.gd`、`tide_skill_controller.gd` | 增量技能参数、解锁与时间轴，复用旧角色/房间/进度接口 |
| `src/campaign/campaign_run_visual.gd` | 保留旧跑步适配器供兼容；正式主角只实例化新视觉桥，避免双重显示 |
| `src/campaign/campaign_camera.gd`、`player_light.gd`、`mechanisms.gd` | 持续居中跟随、位图随身光与68个世界空间悬浮/散射粒子、显式调试全景和机关表现；`camera_world_bounds.gd`保留旧限位算法供历史回归，不参与正常跟随 |
| `src/campaign/campaign_impact.gd` | 保留玩家受伤的全场定格；普通命中改由共用战斗反馈局部冻结双方，不改变镜头 |
| `src/campaign/campaign_save_bridge.gd` | V6用户目录隔离及有效旧档首次复制 |
| `src/campaign/campaign_world.gd` | 后续区域的房间表、按房间 ID 的门目标、能力与进度标记组合条件、地图分页落位 |
| `src/campaign/room_stream.gd` | 邻房后台资源请求、准备与冻结、活动房别名、常驻ActorFrame、跨界状态变换、远房卸载及退出清理；无显示后端按帧串行准备 |
| `src/campaign/streaming_layout.gd`、`streaming_corridors.gd`、`streaming_gates.gd` | 19房世界原点、18条连接、位图平台/水体、尾槽真实竖口与条件实体门；原房配方不改，流式差异是运行时覆盖 |
| `src/campaign/world_terrain.gd`、`tools/build_terrain_master.gd` | 完整世界静态地形母版、1536网格切片与提前驻留；动态舌台膜独立实时，不烘焙 |
| `src/campaign/stream_presentation.gd`、`stream_room_edges.gdshader` | 隐藏由母版接管的静态地形；其它层保留Shader、树结构和Z，实时承重膜禁用接缝淡出 |
| `src/campaign/seam_art.gd`、`seam_art.gdshader` | 按实际世界矩形接入18边联合补绘，接管边界重叠区并保护其它房间核心；原层按相同所有权退出，避免双重轮廓 |

| `content/whalebelly/layout/`、`tools/build_xumen_layout.py` | 须门遗港实际坐标配方、七房生成场景与运行表；按稳定 ID 覆盖原表，不移动旧存档房间索引 |
| `src/campaign/campaign_layout.gd`、`src/world/scenery/layout/` | 新布局的安全落点投影、膜区域与固定端碰撞形变，以及位图裁边、膜网格和共享环境时钟 |
| `content/whalebelly/world/`、`tools/build_world_rooms.mjs` | 套件房配方（单位 U）、跨区链接与生成的运行数据；生成器读取资源台账的包围盒与锚点，输出 `content/whalebelly/<区>/<房间ID>.tscn` |
| `src/world/scenery/kit/` | 套件房的位图层视差、漂移粒子场（漂脂、水流线）和透光明暗 |
| `src/campaign/enemies/kit_encounter.gd`、`kit_swarm_visual.gd` | 程序驱动的敌人与 Boss：群体横穿、鸣贝吐珠、覆膜回声；位图来自台账，行为写在房间配方的 `enemies` 中，伤害、血条、击败存档沿用主线 |
| `src/campaign/campaign_relics.gd` | 按既有奖励ID计算护盾上限，管理本次旅途剩余护盾；主角在偏转/无敌判定后扣盾，超额伤害沿用原受击流程 |
| `src/campaign/boss/` | 母蟹三招、阶段连招、护壳/破防和逐帧显示；通过主线敌人字典及 `R1-04:0` 连接奖励与存档 |
| `src/campaign/enemies/` | 普通尸蟹物理/状态与图集呈现，复用主线伤害和房间生命周期；[接入合同](corpse-crab-integration.md) |
| `src/core/`、`content/data/world_graph.gd` | 保留的兼容状态/存档校验，不再包含旧版关卡场景加载入口 |
| `src/narrative/`、`src/ui/dialogue_panel.gd` | 位置/按键/行进字幕触发、条件、完成记录和目标；对话复用UI暂停与输入恢复，V6追加可选narrative，见[对话系统](dialogue-system.md) |
| `src/ui/` | 正式标题、HUD、模态页面与设置；注入主线宿主，只读实际状态并请求主线操作。旧 tide_hud 保留给独立角色参数场 |
| `src/ui/campaign_route_hud.gd`、`action_hud_style.gd` | 当前房间多出口的只读边缘投影与避让、共用位图图集及紧凑排版；不持有任务或输入状态 |
| `src/ui/campaign_minimap.gd` | HUD 左下角紧凑房间拓扑图，复用 `WhaleUICampaignData.map_rooms()` 的发现规则；按稳定房间 ID 固定布局，读取门条件、所属房间 Boss 击败状态和营地，不写进度 |
| `content/whalebelly/r1/` | 七个房间场景、道路碰撞、分层贴图和节点 |
| `content/whalebelly/environment/` | 当前环境场景、各动件脚本/Shader；保留恢复阶段的组织方式 |
| `content/whalebelly/Player.tscn`、`CampaignPlayer.tscn` | 角色动作与主线参数 |
| `art/` | 由清单同步的运行副本，手工修改源文件应在 assets/ |
| `tests/whalebelly/` | 当前角色、战斗、路线、环境及存档专项验证 |

恢复阶段保留原主循环的兼容实现。后续按功能渐进拆分，不用旧模块版替代现有角色、七房或动态效果。运行逻辑使用稳定ID；创作状态和用户美术确认分别记录。

## 资源归属

`game/art/manifest.json` 同步当前资源，所有来源均在 `assets/`；实际数量以资源审计为准。既有856张图片经过[Framecraft保真压缩](../assets/source/framecraft-runtime/README.md)，画布、可见像素和Alpha不变；9个 `.framecraft` 工程保留原件与结果。新36动作制作、源片选段与透明图集见[制作源](../assets/source/tide-picker-action36/README.md)，其候选/验收状态不沿用旧素材结论。文本、遮罩、音频及字体在 `assets/runtime/godot-support/` 等库目录保存。

后续111张图片由Framecraft增量批次保真处理，额外保留两个源工程；50张场景的Godot导入改为质量0.9的轻度有损编码，保持原PNG、像素尺寸、Alpha与坐标。角色和特效仍为保真导入。处理与运行包体分别统计，配置和恢复说明见[本批记录](../assets/source/framecraft-runtime/batches/2026-11-04/README.md)。

动作本体与FX可有独立帧数；世界环读取图层 `frame_count`/`event_frame`，按真实释放或落地启动，不随本体帧索引截断。影潮穿行复用dash本体并施冷青色调，深钟复用dive本体及地面环，保留各自伤害/范围/无敌逻辑；这些不是独立生成的两套美术。逐项来源、复用、参数和待验状态见[36项资产覆盖](action36-asset-coverage.md)，根目录 `build_asset_coverage.py` 可按实际清单及哈希绑定验收记录重建。

`content/whalebelly/runtime-resources.json` 记录当前资源及引用拥有者。`node game/tools/audit_resources.mjs` 从正式入口、当前角色参数场、Run与环境预览检查引用，并展开身体/特效帧、七房、鱼群和音效的动态路径。它采用保守的路径族检查；新增加载方式时同步维护审计规则，再做实机验证。

`recovery-manifest.json` 保留2026-10-31恢复时的1914项历史来源，不再充当当前文件必须全部存在的清单。未使用的旧合成帧、旧动画预览、重复环境与旧模块资源已归档；可复用原画库和未来区域素材仍保留。

## 存档

独立探索奖励使用`collected["房间ID:物品ID"]`，与本房的主奖励分开。例如`R5-08:tidal-pearl`只记录归潮珠，`R5-08`继续表示导流闸奖励；旧V6无需迁移或补发，回访可领取。`KitTreasure`复用`KitInteractable`的当前房范围和F交互优先级，只隐藏`Loot`子节点。遗物容量由`CampaignRelics`统一计算，地图、H手记、营地与解锁条读同一ID；奖励事件的`id`可区分同房多件，缺少时兼容原`room`字段。读档时收集ID按冒号前缀恢复房间发现，避免将物品ID当作地图房间。

正式主线使用 `user://whalebelly/artmatch_save.json`（V6）。桌面首次启动仅在目标不存在时复制原 `WhalefallArtmatchV05` 的有效存档，保留原件；已有目标不覆盖。浏览器使用自身站点存储。保留的兼容存档服务有独立的 `user://save.json`，不能混作主线V6进度。

测试只写独立测试档，真实浏览器使用独立上下文。隔离试玩入口为 `tests/whalebelly/manual_play.tscn`。

牵引圆环是基础探索操作；读取旧V6时将`abilities.anchor`归一为true。`collected["R1-07"]`表示记忆袋奖励，领取时解锁浮游、恢复生命与蓄振；旧档已收集该奖励时补齐浮游，不重置检查点或其它能力。地图详情按同一收集ID显示可重读记忆。

UI新版保留V6结构并增加可选`visited`房间ID字典。发现定义为正式进入房间，同时在地图显示其配置的相邻出口；房间预览不登记、练习不保存。旧档至少恢复检查点及明确获得奖励/击败Boss的房间，不猜测其余历史路线。原子写入保留`.bak`，确认新旅途另保留`.before-new`；标题与加载共用V6校验。UI设置独立存于`ui_settings.cfg`，不混入玩法状态；QA使用`ui_qa_settings.cfg`。

## 命令与验证

在仓库根目录运行，需要Node.js 18+、Git LFS和Godot 4.7.2。命令入口依次查找 `GODOT`、`.tools/godot/` 和已配置的本机引擎。

```sh
node tools/godot.mjs sync-art
node tools/godot.mjs check
node tools/godot.mjs test
node tools/godot.mjs run
node tools/godot.mjs export-web
node game/tests/serve_web.mjs
node game/tests/web_whalebelly.mjs
```

`check`加载全部脚本和场景；`test`执行当前单元测试。日志中的脚本错误和 `ERROR:` 都算失败。浏览器验收另需Node.js 20+、Playwright与可用Chrome/Chromium；通过真实键盘验证移动、跳跃、短击、迎珠、暂停、营地和刷新续档。专项连续路线在 `tests/whalebelly/campaign_route_test.gd`；状态接口 `render_game_to_text()` 只读。

## Web发布

`node tools/deploy-pages.mjs` 导出单线程Web版，更新已有 `gh-pages` 的 `/godot/` 和默认根入口，普通推送，保留V2等在线历史目录。需要匹配版本的 `web_nothreads_release.zip` 模板。

Pages检出使用 `blob:none` 和稀疏工作目录，只展开Godot、根入口及 `.nojekyll`；其他页面在Git树中保留。同步合并关闭差异统计，避免旧版Git为输出统计而下载未展开的大型图片。并发发布导致推送非快进时，保留发布提交，获取并合并远端后普通推送，检查Godot范围外与远端一致。

导出后 `tools/prepare-web.mjs` 生成带内容哈希的gzip和 `downloads.json`；`game/web/preload.js` 接管引擎与PCK的下载、浏览器流式解压及独立资源缓存。大包分别拆为64MiB的压缩/原始分片，并检查分片及串接SHA256；缺少解压API的浏览器使用原始分片。导出保留原文件，发布只在完整原始分片覆盖后省略超限单文件。缓存只管理启动资源，不清理存档。导出排除构建证据、测试、工具和制作源；最终线上启动结果另见进度。

中文UI使用[字体子集](../assets/source/noto-sans-sc/README.md)。新增中文后重建并运行字形覆盖测试。发布后核对部署状态、实际 `build.json`、当前入口和线上键盘路线；源码提交、发布提交、测试和限制记录在 [game/progress.md](../game/progress.md)。

## 后续区域与套件房

设计地图为 5 区 36 房（[连续世界设计](鲸腹遗城原画集/连续世界设计/设计说明.md)），实施范围已精简为 19 房。R1 七房仍由 `art/whalebelly/rooms.json` 定义，后续区域追加在其后，序号不变。精简后的 12 个新房间已全部接入，门都是可见骨拱门并按交互键进入。Boss 击败后的授予（`grants`）和归海释放的条件（`reward_requires`）同样写在配方里。房间在运行表中的顺序由配方 `_world.json` 的 `order` 决定，只能在末尾追加，因为检查点按序号保存。指引、房间说明、推荐下一房和奖励授能都写在配方里。

- 门用 `to_id` 指向房间 ID；`requires` 列出能力和进度标记，`locked` 表示要从对侧开启。标记与能力同存于 V6 的 `abilities` 字典。跨区入口写在配方 `_world.json` 的 `links`，不修改 R1 原始数据。
- 新房间先写配方，再运行 `node game/tools/build_world_rooms.mjs` 和 `node tools/godot.mjs sync-art`。生成的场景和 `world/rooms.json` 不手工修改；需要调整时改配方或台账后重新生成。
- 房间名与门提示来自生成数据，字体子集脚本和覆盖测试已包含 `world/rooms.json`。Web 导出的 `include_filter` 已加入该文件。
- 实机路线用 `tests/whalebelly/world_skeleton.gd`，`-- --reload-world` 验证独立进程读档，`-- --views` 只出定点截图。
- 地图每区一页，节点坐标写在配方 `_world.json` 的 `map`，是底图上的比例位置。须门遗港页的底图是鲸头特写，其余各页共用全鲸剖面图，同一房间在这些页上用同一坐标。改坐标后看 `-- --views` 输出的五张地图截图；节点重叠和跨页不一致由 `test_campaign_world.gd` 检查。

## 统一敌人试验场

独立入口`game/content/prototypes/enemy_lab/main.tscn`，实现位于`game/src/prototypes/enemy_lab/`。`EnemyLab`拥有配置与整轮重建，`EnemyLabEnemy`拥有试验AI/碰撞/攻击阶段，`EnemyLabReactions`拥有敌人侧结算与控制，`EnemyLabDebug`只读适配实际窗口，`EnemyLabHUD`只发调试请求；玩家继承既有`CombatWhiteboxPlayer`，没有第二份技能/输入执行器。该实现只用于参数验证，不替换主线敌人，也不改主线奖励或存档。资源与实际操作见[试验场说明](../game/content/prototypes/enemy_lab/README.md)。

主线与敌人试验场统一使用`TideCombatGuardSkills`管理持盾、迎击奖励、架势恢复与破防；`EnemyLabSkills`仅保留兼容类型。`TideCombatGuardFeedback`由共用角色创建一次，订阅格挡成功与破防事件驱动已有位图/声音。三套新图集区域与pivot在`art/enemy-lab-readability-v1/atlas.json`，仅由试验场视觉器消费。

试验场`EnemyLabAttackEffects`归单敌所有，监听阶段事件并复用已入库位图固定池；自身不执行伤害。`TideCombatGuardSkills`统一持有架势/恢复/破防，`update_combo`在非技能状态也推进恢复；试验场攻击的压力/不可挡属性只在一次伤害分派期间注入并随即清理；主线现有攻击沿用默认压力。主线近战在共用角色命中入口消费一次反击奖励，试验场仍在护壳结算中消费；两条路径互斥。主线HUD从同一控制器读取架势、破防和反击倒计时。

试验场不可格挡前摇红光由EnemyLabVisual更新独立enemy_warning材质的danger参数，EnemyLabEnemy状态切换时即时清理，避免受击停顿导致残留。材质同时保留共用flash参数，普通攻击不启用danger；不绘地面或文字预警。

`EnemyLabPredator`继承共用敌人命中/格挡/结算协议，独立拥有挂膜、锁定目标、物理飞行、落地后计时、受控后重建与回挂路线。主敌工厂按稳定ID对应的配置选择执行器；HUD与F1使用目录实际数量，不扩第二套玩家控制器。新场地的顶盖是实际碰撞，遮蔽状态限该场地，普通平地不提供隐藏避战区。

捕食者的受压预算与逃离阶段由EnemyLabPredator独占，EnemyLabReactions通过control_window_open虚入口询问控制窗口，避免通用结算硬编码敌种。EnemyLabWaterOrb仅用于本次敌方水弹，复用玩家take_damage/格挡协议，以固定速度及连续线段碰撞推进；弱引用施放者，归整轮world销毁，不复制玩家弹体技能执行器。

试验场`EnemyLabEel`独占长体头尾位置、端点选招与固定反击预算，继承原伤害/格挡/结束协议。整条身体只有一个`tide_targets`节点和一份生命，沿用玩家hit_targets实例去重；不生成多个会重复扣血的身体代理。头尾攻击矩形分别从稳定朝向派生，切换招式不瞬间镜像身体；起手覆盖通用面向玩家的朝向修改。收招预算跨hurt递减，control_window_open只在剩余预算内开放；不使用捕食者飞行/回挂流程。HUD敌人和招式菜单从目录派生，兼容两招与三招敌人。独立图集与统一缩放保留在enemy-lab-eel-v1，头抬高时同步扩大受击区域，普通前摇仍不用红光。


缠巢扩招由`EnemyLabEelNestCycle`持有潜地路线、锁定落点、吐卵/两次扑咬衔接及专属时间轴，Eel继续唯一持有伤害/受控预算。潜行是根位置连续推进，土脊来自专用位图；朝向只在地下切换，出土前给完整露头准备。`EnemyLabNestEgg`是整轮world的独立可击碎目标，弱引用施放者，一枚一个目标ID，沿用玩家真实命中/反馈/格挡协议；投射阶段负责布巢，不隐含触碰伤害。一次胀裂先退目标/威胁组，再显示短暂碎膜，不能同一帧多次结算。NestCycle记录有界活卵计数并清理死亡/重置，旧卵不能漂进新一轮。HUD读取实际阶段与分段pulse，连咬被挡后从时间轴移除取消部分，不复制玩家控制器或主线剧情系统。


Eel的中段连续命中反制归其take_hit入口，先执行原伤害/死亡结算，再在自动交战、中心80px内累计两次实际命中时取消旧动作并启动潜地准备。新动作清旧控制预算但不清伤害、不刷新后续受击的准备时钟；已有卵囊仍按原寿命处理。多端长体的验证必须覆盖身体中段原地真实J连打，不能只测两端单招；证据入口enemy_lab_eel_center_qa.gd。


`EnemyLabWarden`持有执卫三招/二刺衔接、有限收招预算与出口检测；EnemyLabEnemy保留唯一伤害/架势结算，guard_reaction虚入口决定成功格挡后的阶段。默认实现保持原敌人立即收招，执卫首刺普通格挡只短停、保留后段，完美格挡才取消，不回滚伪造的收招状态。位图/时间轴读取实际pulse。执卫越过安全线时先自行非致死收束，再发reached_exit，由EnemyLab统一结束本轮其余敌人；route_passed在整轮重建处唯一重置。安全线结束优先于局部冻结与后段释放，不写主线进度或剧情。


关卡压力样板由`EnemyLabPumpCourt`持有蓄压/泵送/泄压、反抽与F交互，仅terrain4显式创建。场景在角色前发布pump_drift，角色既有move_and_slide执行并归还基础速度；EnemyLabPumpVisual只读状态。该设施不驱动默认Boss技能，旧导压角色动作仅作历史制作资料保留。暂停/结束/R仍统一管理危险水路生命周期。

按用户明确的模块边界，`EnemyLabWardenWater`是Boss自身能力所有者，持有三连射/龙卷/水遁、准备弱点和水体WeakRef；`EnemyLabWardenShot`负责有限寿命与贴地惯性追击，伤害/格挡仍走玩家共用入口。`weak_window`同时驱动黄色囊体Shader和背侧失压判定，Warden唯一hurt_rect在窗口中覆盖实际压囊，避免高亮部件不可打或多部件重复计伤。原捕食者水弹与新水体的线段检测集中在EnemyLabWaterTrace，伤害规则各自保留。

默认选执卫进入平地，court为空、exit_enabled为false；手选窄道/膜泵样板才启退出线，terrain4才创建EnemyLabPumpCourt。关卡压力从自己的请求/交互推进，不再作为Boss水术释放器。Boss水术不读F，也不查询固定进水口/场景压力。先前场景交互接口仅在显式关卡样板中使用。


`EnemyLabBeamGuard`独占封梁卫后撤、真实受击架叉/反推与有限破绽。`EnemyLabEnemy.armor_active`提供状态防护查询，`EnemyLabReactions`继续唯一持有半伤小数、伤害及死亡结算；旧甲/壳规则保持原值。封梁take_hit先调用共用结算，再检查真实received增量和存活，决定前侧启动新tell或背侧拆架，不读输入、不另建伤害控制器。HUD/Debug只读其pose/segments/snapshot；守势与反推前摇分开，已取消的反推从时间轴移除。整轮world持有生命周期，死亡与R清除旧队列，无出口胜利特判。

封梁卫交战时，唯一玩家实例的world_collision_mask在原值上加入敌人层，阻挡正常步行穿胸；原phase_collision_mask不改，基础冲刺仍可穿过，跳跃可越背。只在创建封梁卫的独立整轮中启用，换敌/R销毁玩家后恢复原配置。追击漏洞取证必须记录实际根位置与碰撞mask，不用扩大背后伤害框代替方向判断。


封梁卫主动格挡由`EnemyLabBeamDefense`持有短时防守、实际挡中确认、破防条件、单次回刃与独立金属碰撞反馈。BeamGuard的take_hit先请求此拦截器：成功格挡只登记真实接触/零伤害，不进入HP结算；非防守、重击、绕背、连续破防或已获反击奖励统一回到原Reactions伤害入口。破防先取消防御，再由原入口扣血/消费奖励/判断死亡，避免复制第二份HP与小数结算。防反只由实际命中触发，不读玩家输入；guard_contact保留一次计时，结束后进入独立0.55s tell，回斩为可格挡普通攻击。金属环归同一敌人节点所有，破防/死亡立即隐藏，R统一销毁。Debug与HUD只读实际阶段和计数，不用逻辑上的active阶段冒充防御持续时间。


`EnemyLabElder`持有老守护者站稳/不稳护甲、四招选取、两次换握、有限收招预算与固定非致死结局。`EnemyLabElderCycle`只持有撑跃物理速度、实际落地后的新前摇、收柄回稳路线和回稳受压记录，不结算生命或复制玩家输入。护甲查询复用armor_active，半伤小数/奖励/死亡仍唯一由EnemyLabReactions处理；Elder.finish暂时屏蔽调试击杀选项，使解除武装仍存活。撑跃沿原move_and_slide推进，不改全局物理、不隐藏目标、不在空中无敌，也不在落地时补无前摇伤害。回稳受压只在实际received增加后处理，不能用J按键猜测。站位支撑来自自身长柄和回稳动作，固定柱/主闸机关保留给后续关卡接入。HUD/Debug只读cycle和实际pulse，不另外推进阶段。


老守护者`EnemyLabElderMimic`是敌方能力适配器：订阅真实玩家skill_effect的release/land，以及旧orb/heavy的已确认animation_tag release；读取当前已执行技能数据快照，普通J和非攻击事件不学习。pending memory与当前copied数据分开，每次复制消费一份记录，后续释放不能改写正在施法的快照。复用玩家技能表的范围/脉冲/位移和已加载图集，敌方范围伤害唯一走EnemyLabEnemy.strike；没有第二份玩家输入/技能控制器，也不生成可战斗的克隆角色。EnemyLabElderEchoView只负责既有位图姿势提示和特效，不判定命中；MimicOrb以施法者WeakRef和连续WaterTrace检测执行有限射弹，复制者拥有有界弱引用列表，取消/格挡/结束/R统一清理。浮空只在共用strike确认实际伤害后应用，不穿过格挡和无敌。多段时间轴仍按真实active时钟推进，HUD读取源释放点画标记，不自己计时或发技能。


当前最终Boss增量：EnemyLabElderRepertoire负责28个战斗/辅助执行入口的适配和本轮持久招式库，观测仍从实际执行事件进入，旧辅助动作分别依据即时位移start、后跳事件、治疗完成end；不将未释放的攻击start当作学习。选招按距离、上次复制与生命/治疗额度过滤，普通J不覆盖待复现特殊技；ElderMimic继续持有不可变当前复制快照和统一区域伤害。防御、移动免疫、有限治疗和探潮追赶增益由敌方适配器实现，既有Reactions唯一结算非格挡伤害。复制格挡只拦截轻击并记录接触，重/背击先取消防守再回原全额结算；免疫移动仅改本敌碰撞层，分离后恢复，不改玩家全局掩码。每三招一次有限回稳、最多两招的短收招衔接与0.16s待机归Elder，所有玩家已认可输入保持原值。

EnemyLabPlayer新增all_skill_practice默认false的只限练习权限开关，由EnemyLab拥有并通过F7显式切换/跨R保留；默认super.skill_unlocked与主线存档保持原规则，不为Boss复制验证暗中解锁。全技能矩阵实际执行28个入口，不以枚举数量/数据构造冒充实测；对比频率的静止无敌夹具与可受伤自然交战必须分开报告。


ElderEchoView补充action_echo实际身体层，原memory_pose只作蓄势提示。body_key/body_frame按复制源定义与技能分段计算，复用TideActionVisual.align_event和玩家离线foot_metadata，地面脚底与原角色一致，不新增GPU采样。动作/FX/伤害共用敌人根变换，EchoView不拥有物理/伤害；视觉上淡显施法者、前置显示青色主角幻影，结束clear统一隐藏各层并恢复caster Alpha。身体播放在无FX的技能也独立生效，不因frames.fx为空而跳过动作。完整动作资源原位复用，无第二玩家/目标或重复命中。

### 19房内容补齐（2026-11-14）

制作源和逐房范围见[completion-19-v1](../assets/source/completion-19-v1/README.md)。保留既有19房图、碰撞和奖励，只扩展配方描述及其生成器：`landmarks`是有锚点的视差位图；`state_props`是同锚点的前后态；`progress_slots`复用前后态；`interactables`生成驻留居民或刻痕；`ecology`生成有界幼体群。生成文件不手改。

- `KitStateArt`只读宿主永久`abilities`，驱动前后态渐变；可扫描的声壁暂时揭示4秒，不发放标记。状态画片默认位于平台后方，不能盖住可行走顶面。
- `KitInteractable`只管理范围、文字和只读分支。`CampaignPlayer.interaction_nearby()`、主线`interact()`及UI提示共同支持新对象；优先级为既有专用机关、奖励、居民/刻痕、门、营地。交谈复用`WhaleCampaignUI`模态暂停与松键恢复，不增加任务/奖励存档。
- `KitDriftField`对随永久潮压变化的速度做连续积分，固定实例数量；F9临时练习不改变环境进度。
- `KitEncounterVisual`按既有AI计时选择`KitClamVisual`图集帧，独立显示血巢核心，不驱动伤害或Boss授能。图集和静态故障回退各自保存缩放参数；图集不缩小，旧回退保持原尺寸配置。
- `KitLarvaSchool`以六个实例分别运行身体八帧与路径。永久`ending`使现有个体平滑向外海移动、边缘淡出循环；它是环境生态，没有战斗、碰撞或新增奖励。

单元测试覆盖水流、敌人帧、生态池、交互范围；`completion_19.gd`验证真实场景的状态、资源和帧，`kit_conversation_qa.gd`用物理E/Esc/Enter检查交谈及恢复，`world_skeleton.gd -- --endgame`沿原输入验证后段流程。场景/进度夹具与自然路线分开记录，不把图集技术通过当作用户审美签收。
