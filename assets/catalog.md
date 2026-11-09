# 美术资源台账

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
