# 美术资源台账

## 2026-11-21 · 全图恢复原画腹腔，局部补尾

[当前全图母版与制作源](source/world-map-tail-v2/README.md)。以须门原画和 A02 的胸腹分层合成，按旧全图的双叶角度补画尾柄和尾鳍。2340 × 724 静态 PNG 原尺寸用于全图和后四区。须门局部页使用原鲸头特写。

## 2026-11-21 · 须门鲸头续画至尾鳍（首稿，已替换）

[整鲸底图与制作源](source/world-map-outpaint/README.md)。用须门七房原画固定鲸头，内置 ImageGen 续绘胸腹、脊柱和双叶尾鳍，再将原画内区等比合回。2172 × 724 母版由 Godot 清单原尺寸同步到 `art/world-map/whale-anatomy-overview.png`，用于全图及后四个区域页。须门页使用原鲸头特写。

## 2026-11-19 · 角色动作与状态乐句

十段本项目原创的短乐句。以轻拨弦、柔和持续音和短立体声回响区分移动、战斗与生命变化。音符、包络、渲染方法见[制作源](source/player-music/render.py)，游戏副本由资源清单同步。

## 2026-11-19 · 鲸腹抒情版配乐

游戏内八首完整 OGG 由资源清单从音频库同步。前两首采用已试听版本，其余按动作和环境配平。原文件保留，播放时间和增益由 Godot 控制。

| 实际使用位置 | 曲目 | 作者与来源 |
| --- | --- | --- |
| 须门探索 | The Lost Town | HitCtrl · [作品与 CC BY 3.0 许可](https://opengameart.org/content/rpg-music-the-lost-town) |
| 营地休息、鲸须记忆袋、安全池 | Journey’s End | Mattias Westlund · Wesnoth |
| 肺心潮庭 | Love Theme | Ryan Reilly · Wesnoth |
| 胃枢 | Into the Shadows | Tyler Johnson · Wesnoth |
| 断脊、未清除的母蟹巢穴 | The Black Temple | HitCtrl · [作品与 CC BY 3.0 许可](https://opengameart.org/content/rpg-exploration-the-black-temple) |
| 耳海与开闸前 | Elvish Theme | Doug Kaufman · Wesnoth |
| 首领正式交锋 | Breaking the Chains，从 1:18 处进入 | Mattias Westlund · Wesnoth |
| 开闸后 | First Light Particles，单次 | Yoiyami · [作品与 CC0 许可](https://opengameart.org/node/182244) |

五首 Wesnoth 原版 OGG 来自 [1.18.5 发布版](https://github.com/wesnoth/wesnoth/tree/1.18.5/data/core/music)。[逐曲作者和 GNU GPL v2 或更高版本声明](https://github.com/wesnoth/wesnoth/blob/1.18.5/copyrights.csv)，[随音频分发的许可证](runtime/godot-support/whalebelly/runtime/audio/score/COPYING.txt)。

## 2026-11-19 · 动作关卡配乐修订

以下三首使用作者发布的原始 Ogg 文件。游戏控制播放音量、循环和切换，设置中的「声音来源」提供曲名、作者和许可。

- 须门探索 · The Deep Below，Technodono。[作品页](https://opengameart.org/content/the-deep-below) · [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- 母蟹巢穴与断脊 · RPG Exploration (The Black Temple)，HitCtrl。[作品页](https://opengameart.org/content/rpg-exploration-the-black-temple) · [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)
- 首领交锋 · Frenzied Swimming，Some Weirdo。[作品页](https://opengameart.org/content/frenzied-swimming) · [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)

## 2026-11-19 · 鲸腹遗城场景配乐

六首完整曲目采用 [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)，运行 Ogg 由美术同步清单复制到游戏。

- 常态探索 · Underwater Theme II，Cleyton Kauffman。[作者发布页](https://opengameart.org/content/underwater-theme-ii)
- 浮游上升 · Exploration Theme，Cleyton Kauffman。[作者发布页](https://opengameart.org/content/exploration-theme)
- 首领交锋 · Epic Boss Battle，Juhani Junkala / SubspaceAudio。[作者发布页](https://opengameart.org/content/boss-battle-music)
- 断脊探索 · Forbidden Space · Loop，SkyleTheFrench。[作者发布页](https://opengameart.org/content/forbidden-space)
- 记忆与歇息 · Iridescent Deep · Alternate Loop，Tsorthan Grove。[作者发布页](https://opengameart.org/content/iridescent-deep)
- 归海开闸 · First Light Particles，Yoiyami。[作者发布页](https://opengameart.org/node/182244)

## 2026-11-18 · 归海释放槽藏珠贝匣

复用已入库的`release-bowl`固定贝壳和`ringed-calcium-pearl`静态珍珠，贝壳位置与比例保持，珍珠等比缩放置于壳内；领取后只隐藏珍珠。没有新增绘图或动作动画，未改已有幼体游动、平台与碰撞。本房重建补登记`r5-tail-window-frame-v3`、`sea-larva-swim-v1`的既有恢复副本尺寸和来源，沿用[恢复台账](source/version101-merge/recovered-runtime.json)，不将恢复文件称作原始母版。实际接入、截图检查与状态验证见[游戏进度](../game/progress.md)；用户整体审美待试玩。

## 2026-11-17 · 血巢战斗动态V6

复用血巢V5玻璃虾／水丝及库内soft-particle／bubble，不新增位图。44群体、局部6只受击、6条水丝、2条短接触弧和8光屑均为程序驱动；原材质来源保持。[实机接入和23项专项](source/bloodnest-combat-v6/README.md)通过，观感待审阅；前轮AI视频继续为参考，未作为MP4贴到游戏画面中。

## 2026-11-16 · 血巢攻击与受击视频参考

两份动作设计／提示词、两段Wan 3.0原视频和无声审阅副本存[本批source](source/bloodnest-combat-video-v1/README.md)。视频属于reference candidate，不加入运行位图JSON清单或Godot manifest。两片10秒720P／30fps、300帧及去音轨保持原视频流已验证；受击片镜头／人物和局部反馈未达设计要求，不能登记为已接入或美术通过。

## 2026-11-16 · 血巢玻璃虾与卷潮V5

新增`bloodnest-glass-shrimp-v5`短圆玻璃虾、`bloodnest-water-filament-v5`水丝，两件内置imagegen透明参考补绘原件，当前仅R2-04使用。源图／SHA／完整提示词与选型见[制作记录](source/bloodnest-animation-v5/README.md)；运行副本最大512，mipmap采样。44个体、同族中心个体、6位图流线及复用微泡／光屑为程序驱动，非逐帧动画，candidate审美状态保留。单测137及实机专项17通过；没有把技术通过登记成用户美术认可。

## 2026-11-16 · 肺心原画背景与独立动态V4

[四件位图／原始输出／完整提示词与SHA](source/r2-reference-motion-v4/README.md)：17／18分别清底重建红褐器官背景，另制细长粉色端足和珍珠菌芽。新背景中无烘焙群体／泡／玩家／地台；旧U形断壁退出R2-03/04可见层。群体、悬膜与菌光为已入库位图程序驱动，原图保留；四件源／库／game字节相同。两房46GPU、来源22与原玩法回归通过，审美仍为候选供用户审阅。

## 2026-11-16 · 原画建筑补全V3

[本批六件新素材、提示词与SHA](source/reference-architecture-v3/README.md)：原画引导补绘红膜／赭褶／骨白洞框、低壳营、横三孔骨壁与尾腱海窗；原尺寸1536×1024 RGBA，不更改原参考图片。两件失败骨框候选留源，无运行节点。六件选用图技术接入十二房通过，保持候选审美状态；36个分层实例不含碰撞，17簇原生菌芽和6处原生悬膜为复用。三槽显示坐标改变、flag含义保持。266GPU与路线通过，整体审美供审阅。

## 2026-11-16 · 后续十二房原画深度与工作位

[本批制作与验收](source/remaining-19-v2/README.md)：复用五张1672×941区域depth取代同源far，新增运行同步，不新生成原画；原中景／前景独立保留。原生bed位图补33处低矮台腹；三簇菌芽／育床骨刻板／红索／空杯壳工作位均来自已有库件。红索与空壳最大边640，五背景副本SHA与原件一致。水色／纯光由程序驱动，居民静态驻留，八帧鸣贝／幼体是前批成果。60来源／物理、168GPU及路线／状态检查通过；整体审美供审阅。

## 2026-11-15 · 动态水光与最后柱块移除

[本批记录](source/xumen-background-current-v1/README.md)：母蟹房补删最后两块，旧柱体位图已无七房引用，原件仅保留来源。复用已有纯光RGBA做低强度背景流动与呼吸，未新生成图像；库／game副本SHA一致。背景技术接入通过，整体审美供审阅。


## 2026-11-15 · 须门深海氛围

[本批记录](source/xumen-deepsea-atmosphere-v1/README.md)：复用已认可的银鳍／青背／微光鱼32相位图集、气泡与软粒子位图。无新增图像资产；七房分层生态、近泡、微粒与共享时钟已接入。5张运行副本SHA与库源相等，原平台和玩法保持；本批整体审美待用户反馈。


## 2026-11-15 · 圈选柱体移除

用户否定上一批柱体造型，五房10处已从场景与碰撞移除；原件保留，不新增美术。红褶tissue-ridge已无当前引用，标记为候选；外伤坡本轮也已删除，骨图目前仅母蟹房使用。[记录](../docs/鲸腹遗城原画集/须门遗港地图布局/柱体移除.md)。


## 2026-11-15 · 柱体重设计

[本批记录](source/xumen-structure-redesign-v1/README.md)：新骨裂壁、断颌低拱、育窝厚红褶已替换七房14处旧装配；软组织横拱仅入库候选。四件原件／库／game副本SHA、尺寸、Alpha及实心core校验通过。旧大帽／尖柱相关家族保留原件并标记换出。三件实际在用与用户审美未签收分开记录，整体造型供审阅。


## 2026-11-15 · 原画样式V2（保留19房规则）

[本批记录](source/xumen-source-style-v2/README.md)：首房原颌骨补底重新入景；育窝／鼻道踏台采用R1红褐组织岸；原参考场景PORTAL复用于门及营地，按可见Alpha和原生门槛配准，邻近时避免重叠营地画面。没有新增位图；素材原件与运行来源字节核对见[art-contract](source/xumen-source-style-v2/art-contract.json)。当前规则与路线保持，整体美术待用户审阅。

## 2026-11-15 · outputs原设定与原画样式校正

按[原设定保留合同](source/xumen-outputs-preservation-v1/source-contract.json)复核须门；复用已有舌台／骨台位图补足24处台体，不新增位图，不更改原画和玩法。原三层继续使用，整体观感待用户审阅。[本批记录](source/xumen-outputs-preservation-v1/README.md)区分文档冲突、实际运行和原生GPU证据。

## 2026-11-15 · 须门遗港原画三层复用

七房恢复既有Far／Middle／Foreground及原鲸须、垂藤根线；首房使用原鲸口环境。未生成新位图，57条逐房现用引用、库源与SHA256见[三层接入合同](source/xumen-original-layers-v1/layer-contract.json)。复杂地形与玩法冻结，GPU分层／遮挡／镜头70项通过；整体美术待用户审阅。[制作与证据](source/xumen-original-layers-v1/README.md)。

## 2026-11-14 · 当前19房内容补齐

[制作与逐房范围](source/completion-19-v1/README.md)：复用原画地标、余索/贝驮、区域闩、三槽标记等；另制作鸣贝开合与幼体尾膜游动两张八帧图集，原件和生成提示保留。接入后续十二房，R1七房保留。状态、水流、交谈与结局生态已经本地实机验证；新图集仍为候选美术，用户审美未签收。动作/路径分别驱动，不将静态驻留说成行走动画。本轮无发布。

## 2026-11-12 · 全鲸地图底图

肺心潮庭、胃肠沉城、鸣肋断脊、耳海归墟四个地图页改用[连续世界原画](source/world-continuity-v1/README.md)的 `01-world.png` 作底图，等比缩到长边1600像素后同步为 `game/art/world-map/whale-anatomy-overview.png`；须门遗港页仍用鲸头特写。没有新绘素材。用户选定该图用于地图，整体审美待看实机后反馈。

## 2026-11-11 · 外伤坡巨鲸尺度

[制作源与接入说明](source/xumen-scale-v1/README.md)：新增一张巨型颌骨口腔远景，首房镜头略拉远，并恢复右侧独立门内景。原道路与角色沿用；透明提取失败稿保留来源但未接入。用户整体审美待反馈。

## 2026-11-11 · 七房门与通道

[制作源与14门分类](source/doorways-v1/README.md)：新增1张透明骨拱通道内景，按各门等比缩放，底部裁片承担角色进入时的前景门槛。Boss 门、未开放门和首关出口分别呈现；没有新增房间。用户整体审美待反馈，实机结果见游戏进度。

## 须门跳跃进阶与低伤害飞怪

最新地图：[七房进阶总览](source/xumen-challenge-v1/review/七房进阶-总览.png)。可切换版在[原画册实景总览](../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html#real-scene)。

[七房新地形与逆流灯鳍](source/xumen-challenge-v1/README.md)：用户授权提高跳跃难度后，另绘7房候选和1敌人设定板，保留旧版、原六边与生态装饰。断台、限高短跳、跳冲和四环释放分阶段递进，拟定8只1HP伤害飞怪、同屏最多2只/攻击1只，Boss房0只。9次实际生成保留一次须筛贯通下路失败；8最终图登记为needs-review/not-integrated。35个总览图像引用、版本开关、原图哈希、18段理想轨迹与窄屏检查通过。仅设计图册，动画、碰撞、AI和实际难度未接入/验证。

## 须门遗港连续空间设计接入（2026-11-04）

以[连续世界原画](../docs/鲸腹遗城原画集/连续世界设计/原画册.html)为依据，新增共用口腔纵深、12处双向连接视觉节点和鲸头地图。实际运行选择11张新增位图；原件、3份OpenRaster与蒙版保留。原房四层、垂须、敌人及地形沿用，来源与边界见[本批说明](source/xumen-continuity-v1/README.md)。仍为七房加载，未实现全局无缝碰撞。

## 2026-11-04 尸蟹七状态动作

新增[尸蟹制作源](source/corpse-crab-actions-v1/README.md)：3张AI姿势表、24个姿势及透明序列，运行使用3张图集和元数据，接入须筛/舌台三个普通敌人。双向七状态GPU复核和12项键盘战斗通过；用户审美认可单独保留候选状态。来源、低扫事件、镜像和限制见[接入记录](../docs/corpse-crab-integration.md)。

## 2026-11-04 新增资源压缩

六房环境及拾潮者动作的111张既有PNG通过Framecraft保真处理，约53.48 → 52.36 MiB，原件和结果保存为两个可重开工程。50张场景的Godot运行编码另用质量0.9轻度有损压缩，Alpha和尺寸不变；角色、特效和偏差较大的平台边缘保持保真。派生副本不新增创作资产ID，原母版、台账原图和制作记录保持有效。来源哈希、工程、导入设置和恢复方法见[本批说明](source/framecraft-runtime/batches/2026-11-04/README.md)。

## R1后续六房环境分件（2026-10-31）

制作与原件/母版入口：[r1-chapter-scenes](source/r1-chapter-scenes/README.md)。逐件ID、来源、层级与方法在`chapter.json`及各房`elements.json`；运行PNG由`game/art/manifest.json`登记同步。当前接入与验收以`game/progress.md`为准，不将已准备的后续房间规格当作完成场景。

## 2026-11-03 当前资源整理

完整旧目录、旧模块和仅供旧预览使用的资源在[归档分支](../docs/legacy-archive.md)。远端资源整理批次运行图片856张，经Framecraft保真压缩约135.26 → 121.07 MiB；9个源工程保留原件、Alpha与坐标。该批次930项同步来源全部位于assets，详见[工作台批次与引用清单](source/framecraft-runtime/README.md)。未接入的可复用原画与未来区域素材继续保留。

下方按日期保留各批次的制作记录；历史接入结论不能代替当前清单。旧资源链接指向归档分支。

## 须门遗港背景音乐（2026-11-12）

[xumen_music.ogg](runtime/godot-support/whalebelly/runtime/audio/xumen_music.ogg) 来自声间音库登记的 `背景音创作 2-背景音.m4a`（曲目 ID `c4a8440f2b1144b881e25bb18db964de`，音库播放副本 SHA-256 `30080f3b9e0626ba0ac72044a2fecfd021cb5e21d2373174760fa718374e1bc6`）。全长约 4 分 29 秒，转为双声道 Ogg Vorbis 时降低 1 dB、首尾分别淡入 0.25 秒与淡出 0.8 秒。由 [运行素材清单](../game/art/manifest.json) 同步，在正式主场景循环播放。

## WhalebellyRuins恢复接入（2026-10-31）

原运行素材逐字节恢复至 `game/art/whalebelly/`，由 `game/art/manifest.json` 登记来源与同步路径。未直接引用的历史原图、母版、旧音效和配置已随 `game/production_sources/whalebelly/source-index.json` 归档；全局编辑源仍保留原位。本轮只恢复与接入，没有重新生成美术；[范围与实机验证](../docs/whalebelly-recovery.md)。

## 拾潮者基础动作首版（2026-10-28）

`tide-picker-locomotion-v01`：[制作源、Blender母版与验收](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/assets/source/tide-picker-locomotion-v01/README.md)，[可播放预览](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/assets/source/tide-picker-locomotion-v01/preview.html)。IDLE / Walk / Run各8帧，透明PNG、图集、统一锚点和Godot评审场景已产出。状态为candidate：腿部交替仍需精修，未替换主关卡。三个动作独立登记到catalog.json，不混入历史静态图集。

登记已有概念资源和新资源批次；制作规划留在设计文档。独立资源的名称、标签、备注与当前验收状态以 [catalog.json](catalog.json) 为准，可通过[管理页面](README.md#查看与管理)维护，不在本页重复登记可变状态。

| 资源 ID | 文件位置 | 用途 / 目标 | 来源与授权 | 状态 |
| --- | --- | --- | --- | --- |
| concept-v1 | [原画集](../docs/鲸腹遗城原画集/README.md)、[提示词](../docs/鲸腹遗城原画集/prompts.md) | 18 张概念图；其中四张被初版引用，见下表 | 仓库已有原画与提示词；授权信息待补 | 设计参考；部分有运行引用 |
| concept-v2 | [图片](../docs/鲸腹遗城原画集/V2/images/)、[清单](../docs/鲸腹遗城原画集/V2/资产清单.json) | 29 张概念图；区域、角色、机关设计 | 仓库已有原画与提示词；授权信息待补 | 设计参考，不能视为已实现内容 |

## V5.2 完整静态资源库

`whalefall-v5-2-complete`：2026-10-27，新增 180 张，连同首批 12 张共 192 张独立静态 PNG；105 个需求家族与 36 房间需求映射记录在[完整清单](source/whalefall-v5-2-complete/coverage.json)。目录和当前状态以 [catalog.json](catalog.json) 为准。

[验收范围与证据](source/whalefall-v5-2-complete/acceptance.md) · [174 件/7 页图集索引](runtime/sprites/whalefall-complete-atlas/index.json) · [静态组合配方](source/whalefall-v5-2-complete/review/components/README.md)。18 张背景保持独立，图集没有动作动画。当前 V2 Canvas 2D 从本批与首批资源选用 41 张原图，生成约 1.85 MiB 的 WebP 运行文件，约 45.37 MiB 的 PNG 原件保持不变；派生文件不重复计入资源数量。来源映射、导出命令和 `runtimeFile` 约定见[资源管理说明](README.md)，运行清单见 [art-manifest.js](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/legacy/web/mvp-v2/art-manifest.js)，工作区、实机与线上状态见 [V2 进度](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/legacy/web/mvp-v2/progress.md)。初版与 Three.js 版本没有新增运行引用。

## R1 悬台支撑补件

`r1-hanging-root`：2026-10-27，内置 imagegen 纯文本补制的透明静态骨纤根簇，作为悬空平台下方装饰；[来源、提示词与像素记录](source/r1-hanging-root/README.md)、[原始 PNG](runtime/sprites/r1-hanging-root/base.png)。这 1 件补件独立于原 192 件完整批次，未加入历史图集；V2 已选择其 WebP，运行选择总数为 42。当前验收与接入状态以 `catalog.json` 为准。

## V5.2 首批静态资源（历史记录）

批次 ID：`whalefall-v5-2-static-01`，2026-10-27 入库。12 项单件 PNG，另含 11 项静态精灵的图集；背景不打入图集。来源为用户指定的 V5.2 简版/详版设计和内置 imagegen 参考重绘，生成资料存于各资源 `source/<ID>/`；共享参考与[验收记录](source/whalefall-v5-2-static-01/acceptance.md)存于批次源目录。

| 稳定 ID | 导出文件 | 用途 |
| --- | --- | --- |
| tide-picker | [PNG](runtime/sprites/tide-picker/idle-right.png) | 拾潮者右向静态站姿 |
| corpse-crab | [PNG](runtime/sprites/corpse-crab/idle.png) | R1 尸蟹静态姿态 |
| fat-sniffer | [PNG](runtime/sprites/fat-sniffer/idle.png) | R3 嗅脂甲静态姿态 |
| membrane-ray | [PNG](runtime/sprites/membrane-ray/idle.png) | R2 膜缘鳐静态姿态 |
| sea-larva | [PNG](runtime/sprites/sea-larva/base.png) | R5 受保护幼体 |
| shell-camp | [PNG](runtime/sprites/shell-camp/base.png) | 亮灯营地，单状态 |
| bone-anchor-ring | [PNG](runtime/sprites/bone-anchor-ring/base.png) | 固定骨质锚环 |
| life-fragment | [PNG](runtime/sprites/life-fragment/base.png) | 三腔生命碎片 |
| empty-shell | [PNG](runtime/sprites/empty-shell/base.png) | 可安置空壳 |
| r1-tongue-ledge | [PNG](runtime/sprites/r1-tongue-ledge/base.png) | R1 独立平台件，非无缝地形集 |
| r1-baleen-curtain | [PNG](runtime/sprites/r1-baleen-curtain/base.png) | R1 上颚装饰垂帘 |
| r1-mouth-depth | [PNG](runtime/sprites/r1-mouth-depth/background.png) | R1 单屏背景 |
| whalefall-static-atlas | [PNG](runtime/sprites/whalefall-static-atlas/atlas.png) / [JSON](runtime/sprites/whalefall-static-atlas/atlas.json) | 128px/U 静态图集，无动作序列 |

目标为 BOB 2D 资源库。以上为首批交付时的范围，当时没有接入游戏；当前运行引用以 `catalog.json` 和 V2 运行清单为准。左右静态、机关状态和独立浮膜等已在完整批次补充，动作动画仍待制作。用户指定用于 BOB，未附独立第三方授权文件；不据此新增对外授权声明。

## 初版现有图片引用

以下文件均位于 `docs/鲸腹遗城原画集/`，加载代码在 `mvp/renderer.js`，后三张另用于 `mvp/game.js` 地图缩略图。当前 Pages 只发布 V2，不再复制初版四张原画。

| 运行 ID | 原文件 | 用途 |
| --- | --- | --- |
| title | [00_鲸落全景.png](../docs/鲸腹遗城原画集/00_鲸落全景.png) | 标题背景 |
| mouth | [01_鲸口门庭.png](../docs/鲸腹遗城原画集/01_鲸口门庭.png) | 鲸口门庭背景、地图 |
| ribs | [08_肋骨穹顶.png](../docs/鲸腹遗城原画集/08_肋骨穹顶.png) | 肋骨穹顶背景、地图 |
| heart | [05_心室潮泵.png](../docs/鲸腹遗城原画集/05_心室潮泵.png) | 心室潮泵背景、地图 |

历史路径检查发现：初版源码请求 `../<图片名>`，但本地文件在原画集目录，当时本地服务没有对应映射。本轮未修改或重新验收初版，不应依赖当前 V2 发布构建补齐其图片。

## 模型、动画与音频

旧Three.js程序几何与声音实现已归档。当前Godot使用位图逐帧角色及原音效，来源由同步清单和当前资源表记录；独立模型/骨骼动画按新需求另行登记。V2历史静态姿态不计作逐帧动作。

## 本轮参考图环境场景

`xumen-reference-environment`：47个运行位图、50个元素/装饰簇/生成器合同；接入唯一Godot工程的独立环境场景。仅参考本轮图；含静态展示角色、轻微垂须/植物、鱼群、气泡、光变及视差。[来源与运行说明](source/xumen-reference-environment/README.md)、[逐元素清单](source/xumen-reference-environment/elements.json)、[验收边界](source/xumen-reference-environment/review/acceptance.md)。没有新增玩法碰撞或控制系统。

## 2026-10-28 独立环境动画

`xumen-motion-elements`：146份位图（含48条鱼的源裁片/12帧图集）、103个场景元素合同、独立动画场景和光效。已替换R1-01共享环境的对应资源。[编辑与验证说明](source/xumen-motion-elements/README.md)、[全元素表](source/xumen-motion-elements/elements.json)、[来源](source/xumen-motion-elements/provenance.json)。以该记录为当前环境动画版本；旧记录保留历史。

### 顶部水面位置修正

当前运行102个元素；新增`WATER-SURFACE.png`（原背景裁切，740×150，场景坐标350,0），位于z=-55。CAUSTIC-01/02退出装配，旧素材保留历史。参见[定向指令](source/xumen-motion-elements/instructions/water-surface-fix.md)。

### Blender垂须帧动画

4组×72张RGBA帧（12FPS/6秒），3组近景乳白垂须与1组远景蓝色垂帘。来源、绘画贴图、可编辑Blender母版、动画帧、运行图集与验证：[资产说明](source/baleen-blender/README.md)。100个运行环境元素，旧六片Shader动件退役，固定根片保留。

### 独立水下柔光与背景接缝修复

BEAM-01/02/03已替换为不含场景纹理的独立柔光贴图和12秒Shader动画；旧多边形裁片退役，被挖背景合回ENV-DEPTH-RESTORED。母版、原件、来源与参数见[水下柔光说明](source/xumen-soft-light/README.md)。

2026-11-18追加复用及返修：`UNDERWATER-SOFT-LIGHT.png`与`fx-particle-soft`用于正式玩家随身光束、补光及68个有界悬浮/柔散射粒子，由`game/src/campaign/player_light.gd`程序驱动（`CPUParticles2D`＋位图明暗Shader）。保留现有源文件/运行副本和等比；光束跟随玩家全局坐标，颗粒在世界空间模拟，光束/颗粒在实体地形后，补光在角色上。不是新增位图或动作素材。实际接入与验收见[流式世界](../docs/streaming-world.md#玩家镜头与随身光2026-11-18当前本地)和[进度](../game/progress.md)。

## 拾潮者视频动作 V02

主关卡Idle现已采用 [提灯守望 V03](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/assets/source/tide-picker-idle-v03/README.md)：70帧/12FPS/6秒透明动画，完整原画承载视频运动，17项Godot实景功能检查通过；用户审美待确认。V02三动作仍保留为独立候选，Walk/Run没有因Idle接入而升级验收状态。

IDLE 88帧、Walk 78帧、Run 48帧；合计214张512×512 RGBA，包含20张光流循环桥接。Run复用历史Wan视频，IDLE含局部呼吸修正。三组均为待精修候选，仅独立Godot评审场景；主关卡未替换。[来源、母版与限制](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/assets/source/tide-picker-locomotion-v02-video/README.md)。

### 左上和右下近景拆分

新增FRONT-TOP-LEFT、FRONT-BOTTOM-RIGHT与有限补绘层；底部FRONT-01补32px余量。10张静态贴图清理对应烘焙前景，三个前景共用-0.14视差；103个活动元素。见[母版与说明](source/xumen-foreground-edges/README.md)。

### 桥下原画轮廓与新增气泡

当前106个环境ID，56个气泡实例；新增三个独立气泡区域，复用绘画气泡素材。ROAD-UNDERSIDE-RESTORED恢复旧道路蒙版遗漏的桥下枝条，FOREGROUND-BACKING-SOFT调整局部补底边缘。共享环境和R1-01同步；见[来源、修复与重建](source/xumen-underbridge-repair/README.md)。

### 当前垂须：Wan2.2视频运动与Krita母版

四组各36帧、12FPS、3秒，合计144张RGBA；采用本地ComfyUI/Wan2.2 TI2V 5B视频的运动场驱动原画，固定根部。Krita四份原生动画母版、原始视频、失败样片、逐帧来源和运行验收见[垂须资产](source/baleen-wan22/README.md)。替换原四个BALEEN图集，总环境ID仍为106，旧Blender源保留。

### 拾潮者 V2.4 Godot 3C/技能试玩

540角色帧与540合成帧、180独立特效帧已接入默认七房主场景及专项Demo；主场景数值和V6存档兼容，移动短击分层；原动作衔接美术保持candidate。[来源与验收](source/tide-picker-v24-godot/README.md)。


## 2026-10-29 拾潮者 Walk V03

[视频走路制作记录](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/assets/source/tide-picker-walk-v03/README.md)：84帧、12FPS、7秒，原视频6.041667秒向上取整；相位匹配稳定段重定时，补回骨叉并清理透明底。接入唯一Godot主关卡移动状态，16项GPU主场景回归通过；源片变形、循环接缝和固定帧率滑步仍在，视觉状态candidate。

## 2026-10-29 拾潮者 Run V03

[最新Run v2视频接入](source/tide-picker-run-v03/README.md)：完整6.041667秒源视频重定时为7秒、84帧、12FPS，256×336透明帧。当前Godot主关卡地面移动默认使用Run，Walk保留为历史资源与独立预览。16项Run与16项保留Walk回归通过；源裁切、持叉漂移、接缝与滑步仍保留，视觉candidate。

## 2026-10-29 拾潮者攻击视频 V01

[三组攻击动作参考](source/tide-picker-attacks-v01/README.md)：踏步横扫、蓄力重劈、腾空下刺，Seedance2.0，分别6.04秒/24FPS。角色来源与完整任务记录保留；抽帧发现道具或头顶裁切、持叉漂移，重劈还有额外白色挥击光痕，保持candidate。视频已交付，未接入游戏攻击逻辑。

## 2026-10-29 须门遗港自然垂须视频

[Chaos / Seedance 2.0 样片](source/baleen-chaos/README.md)：1080P、24FPS、实际5.041667秒；按用户向上取整规则导出72张整场景参考帧及6秒12FPS预览。视频已生成，截图已检查；自然度待用户确认，非透明垂须资产、未验收无缝循环、未接入Godot。

## 2026-10-29 拾潮者战斗视频 V01（部分）

[制作记录](source/tide-combat-videos-v01/README.md)：九段计划已生成4段效果参考，包含标准模型普攻与Mini试片；实际规格、抽帧缺陷、任务及余额变化分别留档，均为candidate。其余5段未提交。

## 2026-10-29 三组海底鱼群 v01

[单鱼、鱼群和循环动画](source/fish-schools-v01/README.md)：银鳍梭鱼28只、青背圆鳍鱼14只、微光鳍鱼20只。内置imagegen透明原画，32相位身体与尾鳍变形烘焙，共96张透明帧和3张图集；16秒队形循环。Godot独立样板通过GPU实渲染、62实例、首尾一致和暂停检查。代理视觉已复核，用户审美未确认；未替换主关卡鱼群。

## 2026-10-29 垂须六关键原画与2D动画 V2

[独立垂须样板](source/baleen-keyart-v2/README.md)：6张512×512透明关键原画，本地ComfyUI/Wan2.2 5B引导视频细化，48张384×384 RGBA、12FPS、4秒。Krita分层原画与动画母版已实际转换，48帧回导逐像素一致。已清理外侧残影，视觉自然度待用户确认；仅一簇样板，未替换主关卡。

## 2026-10-29 垂须末端跟随循环 V3

[循环动画与检查](source/baleen-loop-v3/README.md)：保留V2绘画，制作8个对齐派生关键姿态；本地ComfyUI/Wan2.2 5B低强度细化，周期材质处理后交付48张384×384 RGBA、12FPS、4秒。下段先弯、末端延迟约0.276秒并扩大摆幅。根部像素不变、无边缘裁切，48帧Krita实际回导逐像素一致。现已按用户指令接入主关卡顶部三处，清理静态细丝残留、保留蓝色远柱；23项环境、14项主场景、17项环境回归及14项独立包检查通过。[实机录像与接入](source/baleen-loop-v3/integration/README.md)。


## 2026-10-29 主关卡鱼群替换

三组新鱼群已替换R1-01共享环境中旧48实例，现为28/14/20共62条鱼。主关卡、环境预览和独立样板同步；15项主关卡、17项环境、15项独立包检查通过。当前试玩包已更新。接入说明与证据：`assets/source/fish-schools-v01/integration/`（相对BOB根目录）。

## Godot 正式工程运行副本

`game/art/manifest.json` 是正式工程的同步清单，记录旧 Godot 位图/音频与全局静态库的来源关系；`node tools/godot.mjs sync-art` 生成运行副本。接入结果见 [game/progress.md](../game/progress.md)。复用不计新增创作，静态姿态加程序反馈不计正式动作动画。

中文 UI 使用 [Noto Sans SC](source/noto-sans-sc/README.md) 字体，原文件在 `runtime/fonts/`，SIL OFL 1.1 许可证随运行副本保留。字体属于 UI 依赖，不计入静态精灵数量。

Godot 运行时使用派生的 `runtime/fonts/WhalefallUI.ttf`，由工程文字生成子集并重命名，完整原字体保留；生成方式与哈希见上述字体说明。场景图只调整 Godot 导入压缩，制作源、像素尺寸和场景坐标保持原值，不计新增美术创作。

## 模型、动画与音频

### 16 格跑动方法实验（未接入）

2026-10-28 新增 [拾潮者 16 格直接生成实验](source/tide-picker/run16-trial-v01/README.md)：四版原始图、完整提示词、64 张拆帧 PNG、姿势引导图和同步播放对照。用途是验证「角色图 → 16 格连续姿势 → 拆帧播放」的方法，省略视频生成；仍有循环和姿势缺陷，不计为正式动画，不进入运行素材清单。

旧Three.js程序几何与声音实现已归档。当前Godot使用位图逐帧角色及原音效，来源由同步清单和当前资源表记录；独立模型/骨骼动画按新需求另行登记。V2历史静态姿态不计作逐帧动作。

合并本地六房环境后，运行清单共994项（含64项r1-chapter-scenes），来源均位于assets；本地制作源与环境动态继续保留。

## 2026-11-04 拾潮者36动作接入批次

[制作源、实际来源与复跑](source/tide-picker-action36/README.md)保存36项显式动作映射、视频选段/哈希、定向补片回执、关键姿势表、透明图集和独立弹体/红索来源。[最终接入复核](source/tide-picker-action36/final-review.md)记录全36项两向72项覆盖、最终7项两向14项复验及连续主场景14项操作验收；AI外观复核与用户审美确认分别记录，未虚构用户批准。

48份运行文件经manifest/sync-art进入正式CampaignPlayer，包括44张唯一动画图集（22.095MiB）、3张支持位图及动画元数据。run/parry/wall_jump/heavy/dive为AI补制关键姿势；独立纯地环替代原片脚叉缺口。影冲和深钟显式复用已清理本体。视频抠像、补制、复用三种来源不会混称独立视频生成。

保留源运动模糊、离散姿势和半透明反混的限制；技法、输入和取得条件见[36项操作说明](../docs/action36-controls.md)，逐项来源与状态见[覆盖表](../docs/action36-asset-coverage.md)，实测性能和最终发布状态见[工程进度](../game/progress.md)。验收录像/截图与自动报告仅本地保存，已入库正式美术及可复跑脚本不会随测试清理删除。


## 2026-11-04 正式 UI 系统

[UI V1 图标母版](source/whalefall-ui-v1/README.md)保留十份可编辑 SVG，来源为本项目现有 UI V1 原创设计，通过 manifest 同步至 game/art/ui；叶、回声、壳与装饰线实际使用，其余保留图标不表示共生玩法已完成。字体子集使用明确的 Regular 400 字重，并通过中文字形覆盖检查。常规 UI 使用引擎控件、文字和矢量图形，未替换正式角色/场景素材。数据接口、已实现页面及验收范围见 [UI 系统](../docs/ui-system.md)。

## 2026-11-04 主线母蟹

选择性恢复 `codex/crab-boss-prototype@581397ab` 的 [V3制作源](source/crab-video-v3/README.md)与[V4制作源](source/crab-video-v4/README.md)：主线同步V3待机、下砸、退场，V4走路、横扫、冲撞、抖壳共七张身体图集，以及接触尘与飞壳两张效果位图。导出位于 `assets/runtime/sprites/crab-video-v3/`、`crab-video-v4/`，同步到 `game/art/enemies/`。未新增生成素材，V4的48帧仍为既有重绘关键帧；来源和漂移限制沿用原说明。字体重建加入“弹刀/破防”的实际字形。[主线接入与验收边界](../docs/mother-crab-integration.md)。

## 2026-11-04 须门遗港实际连通 V2

[制作源与边界](source/xumen-connected-v2/README.md)：内置imagegen补画水平通道、上行通道和透明骨质平台三件原画，保存原件、两份OpenRaster、蒙版与锚点。manifest选择6张实际运行位图，旧矩形step仅作失败候选保留。四段主路与两条支路有真实碰撞，七房静态几何同时存在；鱼群/气泡/垂须继承原场景。来源记录、参数、制作阶段与验收见generation.json/production.json及game/progress.md，不把源码图数当作实机已显示数量。

## 须门遗港过渡样式图 V1

[三张原画与来源](source/xumen-transition-style-v1/README.md)用于确定主路斜拱、骨膜渐变与骨壁上行三类过渡。源图/提示词/哈希保存于同目录；[图册](../docs/鲸腹遗城原画集/过渡样式设计/原画册.html)有路线/分层开关。概念资料，不进入运行manifest，不宣称实机接入。

## E01 联合过渡样板

[制作源、母版与复验](source/xumen-e01-seam-v1/README.md)：5份新原件，8张运行位图；独立骨路、斜拱、远景、前景及复用动件。接入与发布状态见game/progress.md。

- [须门后续五边专用过渡](source/xumen-transitions-v2/README.md)：E01样板通过后逐边制作，当前具体状态见production.json；原件、母版、蒙版与运行PNG分开保存。

## 须门遗港统一重制

[连续母版与手绘贴图地形](source/xumen-unified-v1/README.md)：8张原件、OpenRaster全区母版、110张当前运行位图与逐元素表。91网格、100静态/交互物件，鱼80、泡66、垂须13、柔性植物7独立接入；数量类别不混算。新画面候选、运行验证通过，用户审美待反馈；性能限制见验收记录。

## 须门遗港原画精修 V2

[制作源与提示词](source/xumen-keyart-v2/README.md)、[可浏览图册](../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html)：1张鲸头整区剖面＋7张逐房新原画，保留7房6边；补充器官定位、跨屏地标、分层和动态选型。主图均由内置imagegen生成，来源快照、生成编号、哈希与须筛定向修订保留。仅概念候选，用户审美待反馈，未分层导出、未接入或发布游戏。

[六条接续专用原画](source/xumen-seam-keyart-v1/README.md)：后续补绘E01/E02/E03/E04/E33/E35共6张联合过渡，已加到原图册。含两端参考、离开/经过/抵达注记、材质与分层、原26个连接碰撞实例快照。图册共14张概念主图；未替换运行资源。

[旧总布局实景样式](source/xumen-real-scene-v1/README.md)：联合绘制全景遗漏了原房间结构，2026-11-06按用户反馈标为needs-work并撤出主展示。来源与评审记录保留于历史稿，不能代表完整七房或Godot实机。

## 2026-11-06 须门七房原图恢复

[原图保真排布母版与复验](source/xumen-reference-panorama-v2/README.md)：本轮8张附件逐字节保存，实际对应7房及外伤坡备选版；全景直接定位7张原尺寸位图，保留拱路、层台、锚环、双丘下层、蟹场侧台、三沟软床和上层大平台。6段既有接续图独立放置；SVG和assembly.json可编辑。13个总览图元素加载、哈希/尺寸、7房定位与手机浏览验证通过。当前仍有拼景接缝，未登记为无缝画作或引擎资源接入；未新增生成美术。

## 2026-11-06 六处接缝精修

[上下文局部补绘](source/xumen-seam-repaint-v2/README.md)：在上述保真母版基础上，通过内置imagegen制作6张接续位图，实际两端上下文、英文提示词、生成编号和哈希保留。7房核心构图与源图不变，6个新层覆盖接口边缘，分别修正缓坡、骨拱、膜拱、竖向落脚点、远景和前景连续性。19图实际加载、7房与6处连接定位、蒙版、精修前后切换、窄屏及链接验证通过。静态设计图册已更新，用户审美待反馈；未进入运行manifest，不代表Godot接入。

## 须门过渡结构再精修 V3

[4新补绘与2复用收边](source/xumen-transition-polish-v3/README.md)：E01实接骨梁、E02保持开敞、E33/E35补非可玩承重带；E03/E04复用旧画。保留本轮5次调用记录与被拒绝的意外横梁候选，最终4图登记台账。25个实际引用、原图尺寸与哈希、三版本比较、6边定位、随形蒙版及窄屏检查通过。仅静态图册，原房源文件不变，未接入游戏。

## 须筛接续 · 两处生态浅窝

[珊瑚与藤蔓局部补绘](source/xumen-ecology-niches-v1/README.md)：1新原件、2局部蒙版，将E02低位空拱与深壳窝改为封闭浅凹，淡紫/灰黄珊瑚与海生藤蔓附着骨壁，右侧保留少量暖光。非门/营地/交互点；27引用实际加载，像素差异只发生在两处范围内，开关和窄屏通过。原房与高位锚环保持，静态原画未接入游戏。

## E01骨根发光珊瑚

[骨根琥珀灯蕊珊瑚](source/xumen-root-glow-v1/README.md)：用户圈定的低位壳洞改为实心骨根上的发光珊瑚簇，椭圆门框与低位红绳删除；上层圆口、三层平台和角色保留。1新位图、1局部蒙版，静态像素差异仅在指定范围，当前28引用和版本开关通过。无交互功能，未制作引擎发光或接入Godot。

## 2026-11-12 胃枢样板房 · R3 套件首次接入 Godot

V5.2 静态套件中的 11 件经 `game/art/manifest.json` 同步到 `game/art/world-kit/`，由 `node game/tools/build_world_rooms.mjs` 装配进 `game/content/whalebelly/r3/R3-01.tscn`：`r3-water-base`、`r3-gastric-far-layer`、`r3-bank-platform`、`r3-mesentery-fold`、`r3-foreground-fold`、`shell-camp`、`anchor-pull-gate-closed`、`bone-anchor-ring`，以及程序驱动的 `fx-particle-soft`（漂脂）、`fx-particle-drift`（水流线）、`fx-cold-beam`（透光）。场景件按清单 `max` 缩到运行尺寸，背景层保持原尺寸；摆放读取本台账的包围盒、锚点和世界单位，只做等比缩放、镜像和拼接。此前标为未接入的五件改为本地运行已验证；闸只接了关闭态，没有开合动画。红结闩曾接入，地图精简后移除。验收与限制见[工程进度](../game/progress.md)，用户观感待确认。

## 2026-11-12 肺心潮庭三房 · R2 套件接入 Godot

育床、心室观察台、血巢三房由同一生成器装配，接入 `r2-water-base`、`r2-lung-far-layer`、`r2-membrane-platform`、`r2-soft-bed`、`r2-foreground-membrane` 和 `nursery-sac`（育囊，静态，作为授予浮游的交互点），营地、漂脂和透光复用胃枢已接入的位图。`r2-soft-bed` 与 `nursery-sac` 改为本地运行已验证。端足群和血巢潮群的位图尚未接入。

## 2026-11-12 断脊、耳海、归海与程序驱动敌人

由同一生成器接入 R4、R5 头、R5 尾三套场景件，以及 `anchor-pull-gate-open`、`tail-flow-shutter`、`progress-three-slots`、`release-bowl`、`release-sluice-closed`、`release-sluice-open`。敌人与预告按协作规则标为程序驱动：`amphipod-swarm`（端足群流与血巢潮群，后者整体染红）、`resonant-clam`、`spine-resonant-clams`、`ringed-calcium-pearl`、`silent-membrane`，预告使用 `fx-danger-line`、`fx-pearl-rings`、`fx-echo-open-ring`、`fx-silence-ring`。这些都是静态位图加程序运动，不是逐帧动作；`blood-nest-swarm` 与 `blood-nest-core` 未使用。共 24 件由未接入改为本地运行已验证，详见[工程进度](../game/progress.md)。

## 2026-11-15 连续世界连接段 · 既有位图复用

19房流式连接复用已入库的 `r3-bank-platform` 与 `r3-water-base`：平台等比拼接并绑定单向碰撞，水体用单一绘制面等比镜像重复。它们仍为静态位图；运行定位、重复采样及房间边缘透明度为程序驱动，不登记为新绘或逐帧动作。交通椎P1、底床与前景从原位图运行时裁出竖口，保留源纹理、比例和翻转；没有改制作源或导出图。新消费入口、参数与本地验证见[流式世界说明](../docs/streaming-world.md)。

## 2026-11-16 连续世界18边联合补绘

针对流式连接的背景与路径拼接，新增18张同坐标联合补绘、4张竖井去台深景、2张透明承重台根；另复用1张旧E35台件作注册/对照。来源为实际两房渲染参考，经内置ImageGen参考引导重绘；原房核心仍使用原位图，新增均为静态结构，不登记逐帧动作。世界矩形、实际脚线、原件/提示词/哈希、运行导出和AI复核边界见[补绘批次](source/seamless-continuity-v1/README.md)。25张运行位图与注册JSON已进入manifest，用户整体审美待试玩；未发布。

## 2026-11-16 六区世界远景与背景分层返修

新增6张完整2172×724连续远景、14张连接道路RGBA层、12张须门World/Middle的Alpha遮罩；内置ImageGen参考引导新绘/分层，原件、提示词、失败候选与SHA256见[连续背景批次](source/continuous-backdrops-v1/README.md)。运行按世界固定相位和区域锚点采样，背景不再按房间矩形退出；四条竖井沿用独立台根。新图均为静态2D素材，用户整体审美待确认，未发布。

## 2026-11-16 完整世界地形母版与切片

复用已有位图组成完整世界母版，279个组成件、61张1540×1540运行切片（1536网格＋四边2px采样余量）。实体道路不透明淡出，舌台膜保持实时；新增返程承重根与胃枢实体岸台面来自已入库素材，未新生成图片。制作源、清单、脚线校验与限制见[母版批次](source/world-terrain-v1/README.md)。已登记manifest/catalog，用户整体观感待确认，未发布。



## 2026-11-16 世界接缝结构补绘V2

用户拒绝旧总览中的矩形路基/裁切边界后，内置ImageGen重绘22张透明地形：14条水平连接与4条竖井两端。新画接管完整交接形体，再进入世界母版切片，原动态膜保留；原件、提示词、参考与哈希见[本批记录](source/world-seam-repaint-v2/README.md)。最终61区块已同步，AI实机复核与用户认可分别记录，未发布。

## 2026-11-17 Version1.0.1新布局母版

采用主干七房新尺寸与十九房当前地形，重新制作[完整母版V2](source/world-terrain-v2/README.md)及[22处结构重绘V3](source/world-seam-repaint-v3/README.md)。ImageGen静态位图，非动画；保留输入、完整提示词、候选、局部返修与SHA256。母版导出62张1540×1540区块，运行加载保持原世界坐标与动态膜独立责任。旧版母版保留历史，当前加载器消费V2/V3；技术验证与用户美术认可分开，未发布Web。

另恢复27条主干已提交运行PNG的清单源，逐字节复制自 `game/art/`，来源见[恢复记录](source/version101-merge/recovered-runtime.json)；仅恢复运行像素，不宣称原始全分辨率制作源。同步清单现包含这些来源。

2026-11-16白盒格挡复用：`parry-body.png`保持抬叉接触帧；`ground-ring-fx.png`第4帧竖置为前方潮环，标记为程序驱动，成功时调色/放大。无新增制作源或位图；仅白盒接入，来源沿用本批动作集。编排与GPU证据见[白盒动画映射](../game/tests/whitebox_combat/ANIMATION-MAPPING.md)。

2026-11-16白盒命中反馈V1复用：action36的`projectile.png`作为命中粒子Alpha、尸蟹life图集hurt帧作为受击动作，标记为程序驱动（池化Sprite、Shader短闪、辅助显示回弹）；声音沿用whalebelly/runtime/audio的strike、hit/hit_2/hit_3、heavy。没有新增位图或动作源，没有接入正式主线。参数、资源路径与GPU验收见[白盒命中反馈](../game/tests/whitebox_combat/HIT-FEEDBACK.md)。


## 2026-11-18 须筛垂须透明修复

[修复批次](source/r1-02-curtain-cleanup-v1/README.md)保留用户参考、两张旧PNG、两次内置ImageGen输出、完整提示词与来源哈希。新透明须帘补齐根部，静态中景清除同簇深蓝重复像素；两张运行PNG替换原清单来源，旧原件保留。固定端网格微摆标记程序驱动，非新增逐帧动画；14项本地GPU/真实键盘检查通过，用户整体审美待试玩，未发布。


## 2026-11-19 统一敌人试验场代理复用

独立敌人白盒复用既有`runtime/sprites/corpse-crab-actions-v1/attack.png`、`walk.png`、`life.png`，运行引用仍为`game/art/enemies/corpse_crab/`。按角色参数等比缩放、色调区分、实际阶段切帧，并沿用共用命中Shader；这是白盒代理复用，不登记为负壳守卫或栖污大甲的新正式动作。未新增图集或修改manifest，字体按原子集流程增量重建。入口与限制见[试验场说明](../game/content/prototypes/enemy_lab/README.md)。

### 2026-11-19 · 敌人试验场辨识度样板

新增三种独立轮廓与九套四关键帧，见[制作记录](source/enemy-lab-readability-v1/README.md)。图集、区域/pivot元数据及守卫清底失败候选均保留；runtime三图只用于enemy_lab，未获美术认可，不替代主线敌人。格挡特效复用已入库潮环与声音，属程序驱动反馈。

2026-11-19 试验场招式特效复用`tide-picker-action36/{strike1-fx,dash_slash-fx,ground-ring-fx,projectile}.png`与既有strike声音，以固定24槽池和独立调制Shader程序驱动；原位图不变。有效段从接触帧播，不重播空白蓄势，见试验场README。

2026-11-19 试验场低扫弧光、前摇地圈与头顶文字提示已移除；不可挡招式仅由敌人本体Shader冒红光，普通攻击以前摇姿势预警。出招后特效与旧素材保留供其他动作使用，无新位图。

### 2026-11-19 · 膜上捕食者试验场样板

新增独立钩肢/三角体轮廓与挂膜、扑击、掠过、重坠关键姿势，见[制作记录](source/enemy-lab-predator-v1/README.md)。16个姿势非完整流畅动画，状态candidate；挂点与遮蔽顶盖仍是白盒设施。红光/落地冲击为已有程序驱动路径，未改正式环境。

2026-11-19 膜上捕食者新增[乌贼/水母融合概念](source/enemy-lab-predator-squid-jelly-v1/README.md)，三种姿态供外观评审，非动画，未替换运行素材。

2026-11-19 用户确认乌贼/水母融合形象，新增[16姿势运行图集](source/enemy-lab-predator-squid-jelly-v1/README.md)。概念状态accepted，动作图集candidate待实机；旧虫状形象标为needs-work、保留历史。新图集进入独立runtime/game路径，四帧悬挂和三招关键姿势按原战斗阶段播放。

2026-11-19 捕食者收伞/喷水闪避复用已确认图集第13/10姿势及既有粒子，水弹复用`tide-picker-action36/projectile.png`位图、程序驱动定位与消散；无新位图，无红光或地面提示扩展。

## 缠巢鳗头尾动作样板（2026-11-19）

- 制作源：[enemy-lab-eel-v1](source/enemy-lab-eel-v1/README.md)，含原PNG、完整提示及区域/pivot。
- 参考既有blind-eel材质用内置image_gen重绘，1536×1024透明12关键姿势，游动/扑咬/扫尾各4。源/runtime/game原像素同源；固定0.8比例，按腹侧支撑线登记枢轴，未按包围盒逐帧缩放。
- 独立试验场第5敌人使用，不覆盖原鳗或主线资源。candidate待用户实际认可；不声明完整高帧逐帧动画。身体朝向、状态驱动与碰撞由代码承担，非新正式特效。


## 缠巢鳗潜地/布卵补充（2026-11-19）

- [制作源与区域](source/enemy-lab-eel-nest-v2/README.md)：内置image_gen沿初版鳗图集重绘，1536×1024透明16格，12个潜地/出土/鼓喉关键姿势与4个独立卵/土脊道具，完整提示与原图保留。
- 不覆盖初版头尾图。源/runtime/game同RGBA；角色统一0.8比例与接地枢轴；完整/鼓胀卵同像素比例，独立胀裂特效按实际范围显示。土脊路线、卵抛射/胀裂属入库位图“程序驱动”，不登记为新增高帧生物逐帧动画。
- 独立试验场专用，candidate待用户审美与手感认可；未接主线、未制作真正幼体/拖行动作。


## 泵庭执卫长柄动作样板（2026-11-19）

- [来源与区域](source/enemy-lab-warden-v1/README.md)：1536×1024透明16关键姿势，行走/长刺/横柄推位/二刺各4，独立窄直立长杆轮廓。两栖外形为白盒候选，不固定正式族群，candidate待用户实际认可。
- 保存完整prompt、原PNG、主Alpha区域与枢轴，源/runtime/game同RGBA。跨格杆尖约2px，以16个独立主轮廓分配区域，不改原像素、不逐帧拉伸。动作样板不代表完整高帧动画。
- 仅统一敌人试验场使用。安全线/窄道顶板是白盒设施，正式场景与第七章演出未制作。


## 泵庭压力交互样板（2026-11-19）

- [制作源与静动判定](source/enemy-lab-pump-court-v2/README.md)：内置image_gen沿执卫候选制作1536×1024透明16格，8个导压/反抽关键姿势、4个膜泵状态、2个泄压瓣状态与2张水流位图，全部保存原图/完整提示/区域；源/runtime/game同RGBA。
- 膜泵/阀瓣按固定画布状态切换，3个水流精灵与局部Shader为“程序驱动”；硬骨台/顶板仍白盒静态碰撞，未作为正式场景美术。暂停使用显式时钟，不套用TIME让停止画面继续流水。
- candidate待用户实际认可；关键姿势/机关状态不等于完整连续角色动画，正式管路/场景未制作。


## 泵庭执卫自身水术 v3（2026-11-19）

- [制作源](source/enemy-lab-warden-water-v3/README.md)：三连水弹、转柄水龙卷、水遁各4个关键姿势，末行4个独立水术道具。压囊随身，图中无场景膜泵或泄压瓣。
- 初稿半透明白底拒用并保留失败原件，内置image_gen返修后空白Alpha0；最终源/runtime/game同RGBA，完整原提示/透明返修提示与区域保留。角色/水迹为关键姿势样板，水弹/龙卷为位图程序驱动，candidate待试玩。
- 囊体黄亮采用既有像素局部Shader与动作窗口，不新增几何光圈。旧膜泵图仍作为后续关卡交互素材保存，未继续充当Boss技能资产。


- `enemy-lab-beam-guard-v1`：封梁卫宽甲/短柄弧刃候选，1536×1024透明图集、16关键姿势；[制作源与提示](source/enemy-lab-beam-guard-v1/README.md)。runtime与game同SHA，统一等比尺度，跨名义格刀刃用实际区域完整保留。仅独立试验场第7项，非正式高帧动画，待用户形象/手感认可。

封梁卫主动防反增量复用原16关键姿势与既有格挡环/金属音效，PNG及SHA不变；格挡碰撞为程序驱动，未新增或冒充完整逐帧动画，见同批制作说明。


- `enemy-lab-elder-v1`：老守护者高宽骨壳披衣/三叉长柄候选，1254×1254透明24关键姿势，独立试验场第8项；[制作源与两次提示](source/enemy-lab-elder-v1/README.md)。源/runtime/game同SHA，保留实际区域和等比根锚。动作候选、技术接入与正式完整动画/族群定稿分开，待用户形象与手感认可。

老守护者观招复现额外复用现有玩家action36动作/特效与projectile.png，姿势提示/播放为程序驱动，没有新增完整逐帧复制动作或可战斗克隆；同批源PNG不变。

老守护者全战斗复制修订继续复用原24姿势与既有格挡/治疗/探潮/强化射弹位图，不新增或修改PNG；程序驱动行为、完整动画待制和本轮声音未验收边界见试验场README当前修订。

老守护者复制演出已加入完整主角幻影身体动画，复用action36所有对应body帧、源时序/脚底元数据，以Shader淡青显形；原敌人PNG不变，属于已有2D素材程序驱动接入，无新绘守护者动作。

## 2026-11-15 须门遗港地图结构位图

新增 `xumen-layout-bone-wall-v1`、`xumen-layout-thick-platform-v1`、`xumen-layout-low-roof-v1` 三件透明实体结构位图，原件、参考来源、生成意图与实际坐标见[本批记录](source/xumen-layout-integration-v1/README.md)。入库后定向同步九件资源至 `game/art/xumen-layout-v1/`；复用原生中空支架、圆环和记忆位图，盾奖励复用既有碎壳。新增位图按原生方向等比摆放，实机已检查加载、比例、遮挡和碰撞。骨膜的形变标为程序驱动，沿用既有机关逻辑。三件 `integrationStatus=integrated`，审美状态仍为 `candidate`，未声称用户已签收整套美术。

## 2026-11-15 须门遗港恢复outputs原画样式 · 结构资源

按原outputs参考修正两件结构位图，最终选用v4多孔竖壁与厚骨顶；旧深凹顶与中间修正版只留source。最初大叉肩wall额外定向复制为`anatomy-fracture.png`，仅低对比非碰撞背景附着，严禁当实体墙。另复用舌台、承重膜两态、鼻腔横骨、软膜台五件，保留原字节，复制到`assets/runtime/scenes/xumen-original-style-v1/`与`game/art/xumen-original-style-v1/`。八件已登记manifest，未全局sync。完整提示词、edit链、生成ID、上游旧素材提示词和三份副本SHA256见[制作与实心核心记录](source/xumen-original-style-v1/production-assets.json)及[接入说明](source/xumen-original-style-v1/asset-delivery.md)。`candidate`与`not-integrated`表示场景接地/碰撞覆盖和用户美术签收仍由主任务验收，不能按透明总bbox替代连续实心核心。
## 2026-11-19 · 心室观察台生态动态层次概念稿

新增[设计源与说明](source/r2-ecology-layer-design-v1/README.md)，1536×1024设计板以原17_R2-03及当前R2-03全景为参考，展示远景群游、中景群流、两处膜边附着微动及侧缘逸泡。由内置image_gen参考补绘，完整提示词、生成来源和SHA保存在同目录。此为待审阅概念图，非逐像素关卡图、透明素材或已实现动画；未加入运行清单，未改变平台/碰撞/玩法，未获用户美术验收。

## 2026-11-19 · 19房生态动态与设计图 V1

[逐房图集与制作来源](source/ecology-19-v1/README.md)：19张1536×1024设计板（18新生成+心室前稿复用），内置image_gen逐房原画/实机参考，完整提示词与SHA索引同目录。概念图不进入runtime/manifest。实际生态复用已入库habitat-fungus-bed、r2-pearl-stalks-v4、bubble、fx-particle-soft、三种32帧小鱼图集及r2-pelagic-amphipod-v4，标为“位图/逐帧素材＋程序驱动”；不记成全套新生物动作或付费视频生成。

CampaignRoomEcology按19房配方提供固定根菌群、窄域逸泡、微粒、后区开放迁移及育床端足群，保留现有虾群、膜与归海幼体。GPU逐房接入和时钟验证191项通过，人工审美待用户反馈；实例、幅度与源/运行关系见本批README。无新运行贴图，不更改原资产来源或许可。

## 2026-11-19 · 当前场景环境适配生态 V2

新增两件环境专用透明候选：断脊暗红骨孔附生穗、耳海灰白管状骨壁小群落。源图、提示词、尺寸、透明Alpha诊断和运行副本见[source/ecology-19-v2](source/ecology-19-v2/README.md)。实际当前场景均新增 `RoomEcology` 节点；配方按须门、肺心、胃枢、断脊、耳海、归海的材质与安静程度选择生态，不把概念板中的额外生物直接当运行内容。两件新图由内置 image_gen 生成并标为 candidate；接入技术通过，用户审美待签收。
## 2026-11-19 · 须门珊瑚配色与黑门视觉修正

须门 R1-01～R1-07 改用冷色附生群落，去掉暖橙 `habitat-fungus-bed` 在蓝色口腔环境中的突兀感；胃枢暖色菌群保留。R1-04 的 `PORTAL.png` 仅为黑色入口视觉，已从场景引用移除，门逻辑仍由 `CampaignDoorway` 和世界连接负责。运行截图和回归记录在 `game/build/qa/ecology-in-scene-v2/`。
## 2026-11-19 · 19房完整生态组合设计

每房的鱼类/端足、浮游微粒、气泡和附生物组合已按远景、中景、前景登记，见 `assets/source/ecology-19-v2/ecology-design.json`。运行配方支持每房独立的鱼群色调、气泡数量/尺寸/速度、微粒颜色/密度和安静区间；不重复接管R1已有场景鱼群，不改变战斗、通路或碰撞。
## 2026-11-20 · 须门黑门视觉清除

须门七房的 `PORTAL.png` 门体只承担视觉，不再在当前场景中引用或生成；入口逻辑和世界连接保留。R1-01～R1-07 场景的入口高度设为0，避免 `CampaignDoorway` 创建 inset/lip；不删除源素材文件。技术回归与截图见 `game/build/qa/ecology-in-scene-v2/`。

## 2026-11-20 · 老守护者立稳帧修正

[制作源与提取记录](source/enemy-lab-elder-idle-fix-v1/README.md)：内置image_gen删除pose22多画的竖直杆，仅提取独立透明裁片；待机静止和回稳立稳使用新裁片，保留原pivot与比例，其余23帧不变。已登记manifest和JSON台账；单帧修正，不记为新增动画。

## 紧凑动作 HUD V1（2026-11-21）

[制作源与来源链](source/action-hud-v1/README.md)：24枚静态技能/状态图标、12枚连击字形；运行明暗、切页和连击缩放由正式UI状态驱动。运行验收见游戏进度。
