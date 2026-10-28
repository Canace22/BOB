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
