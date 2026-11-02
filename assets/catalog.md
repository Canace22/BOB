# 美术资源台账

登记已有概念资源和新资源批次；制作规划留在设计文档。独立资源的名称、标签、备注与当前验收状态以 [catalog.json](catalog.json) 为准，可通过[管理页面](README.md#查看与管理)维护，不在本页重复登记可变状态。

| 资源 ID | 文件位置 | 用途 / 目标 | 来源与授权 | 状态 |
| --- | --- | --- | --- | --- |
| concept-v1 | [原画集](../docs/鲸腹遗城原画集/README.md)、[提示词](../docs/鲸腹遗城原画集/prompts.md) | 18 张概念图；其中四张被初版引用，见下表 | 仓库已有原画与提示词；授权信息待补 | 设计参考；部分有运行引用 |
| concept-v2 | [图片](../docs/鲸腹遗城原画集/V2/images/)、[清单](../docs/鲸腹遗城原画集/V2/资产清单.json) | 29 张概念图；区域、角色、机关设计 | 仓库已有原画与提示词；授权信息待补 | 设计参考，不能视为已实现内容 |

## V5.2 完整静态资源库

`whalefall-v5-2-complete`：2026-10-27，新增 180 张，连同首批 12 张共 192 张独立静态 PNG；105 个需求家族与 36 房间需求映射记录在[完整清单](source/whalefall-v5-2-complete/coverage.json)。目录和当前状态以 [catalog.json](catalog.json) 为准。

[验收范围与证据](source/whalefall-v5-2-complete/acceptance.md) · [174 件/7 页图集索引](runtime/sprites/whalefall-complete-atlas/index.json) · [静态组合配方](source/whalefall-v5-2-complete/review/components/README.md)。18 张背景保持独立，图集没有动作动画。当前 V2 Canvas 2D 从本批与首批资源选用 41 张原图，生成约 1.85 MiB 的 WebP 运行文件，约 45.37 MiB 的 PNG 原件保持不变；派生文件不重复计入资源数量。来源映射、导出命令和 `runtimeFile` 约定见[资源管理说明](README.md)，运行清单见 [art-manifest.js](../legacy/web/mvp-v2/art-manifest.js)，工作区、实机与线上状态见 [V2 进度](../legacy/web/mvp-v2/progress.md)。初版与 Three.js 版本没有新增运行引用。

## 搬壳母蟹 Boss 原型姿态

`crab-video-v4`：[同视角补绘与位移步态](source/crab-video-v4/README.md)，四组/48 帧，替换 V3 的横扫、抬身冲撞、后退复用踏步、正面抖壳。单一待机主参考、壳体锚点测量、提示词及可复跑导出已保留；实机与发布验收见进度。

当前训练场改用 `crab-video-v3`：[视频补绘制作与实装](source/crab-video-v3/README.md)，七组动作/84 播放单元、两组独立特效和一张环境板。底图、实际提示词、原帧映射和可重跑导出已保存；旧静态姿态保留归档。实际验收见 [game/progress.md](../game/progress.md)。

`crab-boss-prototype`：2026-10-28，按用户指定 `shell-mother-crab` 的多层巨贝壳身份补制5张关键静态姿态（低扫蓄力/挥出、抬钳/下砸、收钳横冲）；待机复用不计新创作。公共画布1024×768、脚底根 `(400,704)`、运行等比0.6，母蟹常态约452×294世界像素。[制作源与复跑](source/crab-boss-prototype/README.md)、[静态检查与限制](source/crab-boss-prototype/acceptance.md)，实际运行/发布验收见 [game/progress.md](../game/progress.md)。5件为关键姿态，不是正式逐帧动画；原先旧负壳蟹的试稿归档到本批 `superseded/`，没有接入。台账状态以 `catalog.json` 为准。

## 训练场环境动画

[main 环境素材接入](source/crab-environment-main/README.md)：原样复用三种鱼群图集和 V3 垂须图集；训练场放置22条鱼和3簇垂须，暂停与顿帧跟随世界。来源提交、哈希和适用边界见批次说明，实机与发布证据见 [游戏进度](../game/progress.md)。

## 动画候选与平台处理

续修批次 `player-animation-v2` 见[左右动作制作与接入](source/player-animation-v2/README.md)：独立朝向、公共脚底根、交替支撑腿和落地缓冲，新增两条动画台账。实际可用动作、实机检查与发布状态以 `catalog.json` 和 [游戏进度](../game/progress.md) 为准；下列 V1 试验继续保留。

2026-11-02 的 [批次说明](source/animation-platform-20261102.md)记录螃蟹优化与玩家左右动作的当前范围。以下只登记制作候选入口，不计入完整静态库数量，也未写入游戏运行清单；具体缺陷与验收证据见各批次说明。

| 批次 ID | 制作产物 | 来源 | 当前状态 |
| --- | --- | --- | --- |
| crab-video-platform-v1 | [9 组原视频动作](source/crab-video-platform-v1/README.md)，360 帧、12 FPS、672×384；独立 Framecraft 工程和 PNG 序列 | 用户之前提供的视频拆帧，按原时间线做平台压缩与透明边缘整理；来源路径、时间与哈希随批次保留 | 保留原视角及转向；缺钳、遮挡等问题未重绘，独立对向未补，未接入 |
| crab-animation-platform-v1 | [双钳重砸尺度版](source/crab-animation-platform-v1/README.md)，39 个播放帧、13 张不同图像、24 FPS、384×384；PNG/图集和 Framecraft 工程 | 既有尺度修正候选的派生压缩版；保留生成来源与原文件 | 原视角单次动作候选；平台播放控制与导出已检查，连续动作美术验收、对向和游戏接入未完成 |
| player-animation-platform-v1 | [左右动作候选](source/player-animation-platform-v1/README.md)：左向短跳6姿势、面右空中段11帧及独立平台工程 | 左向按角色主参考和原片姿势补绘；右向来自同一原片的原生裁片/平台抠图 | 左向根部/落地待修，右向缺起跳与落地；左右跑动未通过，未接入 |

上述 V1 候选不能视为完整左右动作，也不加入 `catalog.json` 的单件静态记录。V2 按独立动画资源登记，保留当前接入与美术复核状态。

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

## Godot 正式工程运行副本

`game/art/manifest.json` 是正式工程的同步清单，记录旧 Godot 位图/音频与全局静态库的来源关系；`node tools/godot.mjs sync-art` 生成运行副本。接入结果见 [game/progress.md](../game/progress.md)。复用不计新增创作，静态姿态加程序反馈不计正式动作动画。

母蟹训练场远程共鸣弹复用 `fx-heavy-ring`，近战护盾复用 `fx-echo-open-ring`，保持透明位图等比显示；出手复用玩家已有左右轻击。来源 SVG/PNG 保留原位，运行映射见上述清单。这次新增的是弹体、护盾与阶段组合的运行规则，没有新增美术动作。

中文 UI 使用 [Noto Sans SC](source/noto-sans-sc/README.md) 字体，原文件在 `runtime/fonts/`，SIL OFL 1.1 许可证随运行副本保留。字体属于 UI 依赖，不计入静态精灵数量。

Godot 运行时使用派生的 `runtime/fonts/WhalefallUI.ttf`，由工程文字生成子集并重命名，完整原字体保留；生成方式与哈希见上述字体说明。场景图只调整 Godot 导入压缩，制作源、像素尺寸和场景坐标保持原值，不计新增美术创作。

## 模型、动画与音频

当前没有独立的模型、骨骼动画或音频文件登记。Three.js 版本几何体及基础动画由 `mvp-nightmare/renderer.js` 生成，各版声音由各自 `audio.js` 合成。V2 新增素材为静态姿态和状态图，不能当作逐帧动画。正式资源交付后逐项登记源文件、导出文件和接入证据。
