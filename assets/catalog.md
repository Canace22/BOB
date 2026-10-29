# 美术资源台账

## 拾潮者基础动作首版（2026-10-28）

`tide-picker-locomotion-v01`：[制作源、Blender母版与验收](source/tide-picker-locomotion-v01/README.md)，[可播放预览](source/tide-picker-locomotion-v01/preview.html)。IDLE / Walk / Run各8帧，透明PNG、图集、统一锚点和Godot评审场景已产出。状态为candidate：腿部交替仍需精修，未替换主关卡。三个动作独立登记到catalog.json，不混入历史静态图集。

登记已有概念资源和新资源批次；制作规划留在设计文档。独立资源的名称、标签、备注与当前验收状态以 [catalog.json](catalog.json) 为准，可通过[管理页面](README.md#查看与管理)维护，不在本页重复登记可变状态。

| 资源 ID | 文件位置 | 用途 / 目标 | 来源与授权 | 状态 |
| --- | --- | --- | --- | --- |
| concept-v1 | [原画集](../docs/鲸腹遗城原画集/README.md)、[提示词](../docs/鲸腹遗城原画集/prompts.md) | 18 张概念图；其中四张被初版引用，见下表 | 仓库已有原画与提示词；授权信息待补 | 设计参考；部分有运行引用 |
| concept-v2 | [图片](../docs/鲸腹遗城原画集/V2/images/)、[清单](../docs/鲸腹遗城原画集/V2/资产清单.json) | 29 张概念图；区域、角色、机关设计 | 仓库已有原画与提示词；授权信息待补 | 设计参考，不能视为已实现内容 |

## V5.2 完整静态资源库

`whalefall-v5-2-complete`：2026-10-27，新增 180 张，连同首批 12 张共 192 张独立静态 PNG；105 个需求家族与 36 房间需求映射记录在[完整清单](source/whalefall-v5-2-complete/coverage.json)。目录和当前状态以 [catalog.json](catalog.json) 为准。

[验收范围与证据](source/whalefall-v5-2-complete/acceptance.md) · [174 件/7 页图集索引](runtime/sprites/whalefall-complete-atlas/index.json) · [静态组合配方](source/whalefall-v5-2-complete/review/components/README.md)。18 张背景保持独立，图集没有动作动画。当前 V2 Canvas 2D 从本批与首批资源选用 41 张原图，生成约 1.85 MiB 的 WebP 运行文件，约 45.37 MiB 的 PNG 原件保持不变；派生文件不重复计入资源数量。来源映射、导出命令和 `runtimeFile` 约定见[资源管理说明](README.md)，运行清单见 [art-manifest.js](../mvp-v2/art-manifest.js)，工作区、实机与线上状态见 [V2 进度](../mvp-v2/progress.md)。初版与 Three.js 版本没有新增运行引用。

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

当前没有独立的模型、骨骼动画或音频文件登记。Three.js 版本几何体及基础动画由 `mvp-nightmare/renderer.js` 生成，各版声音由各自 `audio.js` 合成。V2 新增素材为静态姿态和状态图，不能当作逐帧动画。正式资源交付后逐项登记源文件、导出文件和接入证据。

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

主关卡Idle现已采用 [提灯守望 V03](source/tide-picker-idle-v03/README.md)：70帧/12FPS/6秒透明动画，完整原画承载视频运动，17项Godot实景功能检查通过；用户审美待确认。V02三动作仍保留为独立候选，Walk/Run没有因Idle接入而升级验收状态。

IDLE 88帧、Walk 78帧、Run 48帧；合计214张512×512 RGBA，包含20张光流循环桥接。Run复用历史Wan视频，IDLE含局部呼吸修正。三组均为待精修候选，仅独立Godot评审场景；主关卡未替换。[来源、母版与限制](source/tide-picker-locomotion-v02-video/README.md)。

### 左上和右下近景拆分

新增FRONT-TOP-LEFT、FRONT-BOTTOM-RIGHT与有限补绘层；底部FRONT-01补32px余量。10张静态贴图清理对应烘焙前景，三个前景共用-0.14视差；103个活动元素。见[母版与说明](source/xumen-foreground-edges/README.md)。

### 桥下原画轮廓与新增气泡

当前106个环境ID，56个气泡实例；新增三个独立气泡区域，复用绘画气泡素材。ROAD-UNDERSIDE-RESTORED恢复旧道路蒙版遗漏的桥下枝条，FOREGROUND-BACKING-SOFT调整局部补底边缘。共享环境和R1-01同步；见[来源、修复与重建](source/xumen-underbridge-repair/README.md)。

### 当前垂须：Wan2.2视频运动与Krita母版

四组各36帧、12FPS、3秒，合计144张RGBA；采用本地ComfyUI/Wan2.2 TI2V 5B视频的运动场驱动原画，固定根部。Krita四份原生动画母版、原始视频、失败样片、逐帧来源和运行验收见[垂须资产](source/baleen-wan22/README.md)。替换原四个BALEEN图集，总环境ID仍为106，旧Blender源保留。

### 拾潮者 V2.4 Godot 3C/技能试玩

540角色帧与540合成帧、180独立特效帧已接入默认七房主场景及专项Demo；主场景数值和V6存档兼容，移动短击分层；原动作衔接美术保持candidate。[来源与验收](source/tide-picker-v24-godot/README.md)。


## 2026-10-29 拾潮者 Walk V03

[视频走路制作记录](source/tide-picker-walk-v03/README.md)：84帧、12FPS、7秒，原视频6.041667秒向上取整；相位匹配稳定段重定时，补回骨叉并清理透明底。接入唯一Godot主关卡移动状态，16项GPU主场景回归通过；源片变形、循环接缝和固定帧率滑步仍在，视觉状态candidate。

## 2026-10-29 拾潮者 Run V03

[最新Run v2视频接入](source/tide-picker-run-v03/README.md)：完整6.041667秒源视频重定时为7秒、84帧、12FPS，256×336透明帧。当前Godot主关卡地面移动默认使用Run，Walk保留为历史资源与独立预览。16项Run与16项保留Walk回归通过；源裁切、持叉漂移、接缝与滑步仍保留，视觉candidate。

## 2026-10-29 拾潮者攻击视频 V01

[三组攻击动作参考](source/tide-picker-attacks-v01/README.md)：踏步横扫、蓄力重劈、腾空下刺，Seedance2.0，分别6.04秒/24FPS。角色来源与完整任务记录保留；抽帧发现道具或头顶裁切、持叉漂移，重劈还有额外白色挥击光痕，保持candidate。视频已交付，未接入游戏攻击逻辑。

## 2026-10-29 须门遗港自然垂须视频

[Chaos / Seedance 2.0 样片](source/baleen-chaos/README.md)：1080P、24FPS、实际5.041667秒；按用户向上取整规则导出72张整场景参考帧及6秒12FPS预览。视频已生成，截图已检查；自然度待用户确认，非透明垂须资产、未验收无缝循环、未接入Godot。

## 2026-10-29 拾潮者战斗视频 V01（部分）

[制作记录](source/tide-combat-videos-v01/README.md)：九段计划已生成1段普攻效果参考，16:9/720P/6.04秒/24FPS；宽构图改善人物边缘，但回拨与短压波仍偏离设计，candidate。首段完成后余额317点，不足同规格600点；其余8段提示词已准备，未提交，等待额度或用户调整。
