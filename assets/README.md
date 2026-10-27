# 美术资源管理

这里是 BOB 美术资源的统一入口。新增模型、贴图、动画和音频放在本目录，已有概念原画保留在[原画集](../docs/鲸腹遗城原画集/README.md)，通过[资源台账](catalog.md)统一查找用途与接入状态。

制作前先对照[美术风格规范](art-style.md)，确认基准图、角色特征和画面层次。

## 文件放哪里

| 目录 | 内容 |
| --- | --- |
| `source/<资源ID>/` | Blender、绘画工程等可编辑源文件，制作提示词、来源与授权说明 |
| `runtime/models/<资源ID>/` | 游戏用模型及配套动画，优先自包含 GLB；实际格式须匹配加载器 |
| `runtime/textures/<资源ID>/` | 模型外置贴图、材质纹理 |
| `runtime/sprites/<资源ID>/` | 背景、角色序列帧、UI 图片等 2D 导出资源 |
| `runtime/audio/<资源ID>/` | 游戏使用的音效、音乐与语音 |
| `../docs/鲸腹遗城原画集/` | 已有概念原画、原画册与设计资料，保持原有相对引用 |

V5.2 静态素材库现有 **192 张独立 PNG**：25 张角色/生物、51 张道具、46 张场景件、18 张独立背景层、32 张界面组件、20 张特效纹理。原 12 张保留，本次增加 180 张。按照 105 个需求家族核对，并附 36 房间需求映射；这是素材覆盖，不等于 36 个可玩房间已完成。

上述历史批次之外，另补绘1张正式2D悬根 [r1-hanging-root](source/r1-hanging-root/README.md)，当前台账共193项。新素材用内置 imagegen 生成透明 PNG，原件保留，运行等比 WebP；制作规范统一见根 [AGENTS.md](../AGENTS.md#正式美术必须使用2d素材)。

图像检查通过后整理入库；用户美术确认、动作动画、各版游戏接入分别验收。源图和提示词在 `source/`，游戏导出在 `runtime/sprites/`。

当前 Canvas 2D [V2](../mvp-v2/README.md)按来源选用 42 张静态原图，运行时使用缩放后的 WebP；清单在 [art-manifest.js](../mvp-v2/art-manifest.js)，绘制适配在 [runtime-art.js](../mvp-v2/runtime-art.js) 与 [campaign-renderer.js](../mvp-v2/campaign-renderer.js)。原 33 项用于旧四区，新增 8 项包含负壳蟹、授予点两态、生命碎片、空壳与三件须门器官地形，服务新的五房主线。来源区域 R1 / R3 / R2 / R4 在旧四区分别对应鲸口 / 胃库 / 肺缘 / 肋骨，新主线使用真实 R1 房间 ID；其他区域按批次接入。初版 `mvp/` 与 `mvp-nightmare/` 未接入本批素材。工作区改动、实机验收与实际线上版本分别记录在 [V2 进度](../mvp-v2/progress.md)。

V2 运行导出由 [export-runtime-art.py](../mvp-v2/tools/export-runtime-art.py)生成，需要 Python、支持 WebP 的 Pillow 和 Node.js，在仓库根目录运行 `python mvp-v2/tools/export-runtime-art.py`。42 张共享图由约 46.32 MiB 的 PNG 缩为约 1.87 MiB 的 WebP，放在 `runtime/sprites/whalefall-v2-optimized/`；封面和旧外观回退另有派生导出，不计入这组体积。原图与台账 `file` 保持不变，台账接入记录的 `runtimeFile` 指向游戏导出。清单记录原路径、原尺寸、导出倍率，并将 bbox / pivot 换算到导出像素；不是新增 42 项创作资源。

当前工作区的鲸口、胃库、肺缘采用 [levels.js](../mvp-v2/levels.js) 中共享地形顶线，碰撞、缓存绘制和工作台多边形读取同一组点；肋骨保留现有悬空平台与设施路线。素材的起伏需与真实地形一致，不能仅改变背景或贴图来表示坡道。具体分工见 [场景制作说明](../mvp-v2/SCENE_PIPELINE.md)。

## 查看与管理

在仓库根目录运行，无需安装依赖：

```sh
npm --prefix assets/manager start
```

打开 [本机管理页](http://127.0.0.1:4176/) 。可搜索名称、ID、标签，按类别、区域和状态筛选，切换透明底色、放大查看、下载原图/图集、查看来源、提示词与可编辑 SVG。完整需求页另外显示尚缺项、状态组合、六区域及机关/生态拼装预览。修改名称、标签、备注、验收状态后点击保存，会写入 [catalog.json](catalog.json)，刷新与重启后保留。归档只改变台账状态，不删除图片；在“归档”筛选中可以恢复。

该页面服务于本机的美术整理工作。端口被占用时可用 `PORT=4177 npm --prefix assets/manager start`。不要通过游戏的静态服务器直接打开它：页面保存需要管理服务的 API。

新独立资源以 `catalog.json` 为可编辑台账；[catalog.md](catalog.md)保留概念原画与批次索引，不重复维护页面中可变的状态。页面中的“静态验收通过”只表示图像、尺度与确定性合成检查通过，不代表已接入游戏或用户已经确认美术。

## 精灵与图集

单张透明 PNG 就是一个静态精灵。图集将多个精灵装入一张纹理，配合矩形坐标读取；只有按某个动作制作的连续帧才构成动画。

完整导出为 [7 页静态图集包](runtime/sprites/whalefall-complete-atlas/whalefall-complete-atlas.zip)与[索引 JSON](runtime/sprites/whalefall-complete-atlas/index.json)：174 件精灵按角色、道具、场景、界面、特效分组，18 张背景单独保存。每页不超过 4096×4096，间隔 4px、边缘外扩 2px，`animations` 为空。

世界精灵按 128px/U 等比缩放，裁出可见区域并保留原始 pivot/sourceRect；UI 保留整张原生画布和九宫格参数。同体状态共用比例与根位置。L0 水体和 L1 器官层按完整画布放置、独立视差；不可裁掉透明区域后重新拉伸。逐件 PNG 原样保留，图集只作为派生导出。

复跑需要 Python 与 Pillow；这些是离线制作工具，管理页本身没有外部运行依赖：

```sh
python3 assets/source/whalefall-v5-2-complete/tools/pack-atlases.py
python3 assets/source/whalefall-v5-2-complete/tools/verify-atlases.py
```

[首批单页图集](runtime/sprites/whalefall-static-atlas/atlas.json)保留为历史交付，只包含当时的 11 件精灵。页面修改台账不会自动重新导出图集；包内是导出时的快照。当前页面可管理标签、备注和验收状态，不上传或替换原图。

机关的旋转轴、门闩正反侧、奖励拾取前后与六处生态状态见[组合配方与复跑入口](source/whalefall-v5-2-complete/review/components/README.md)。部分形状依据文字规则适配，具体说明保留在各文件来源记录里。

## 新资源入库

1. 使用稳定的英文小写 ID，例如 `tide-picker`；同一资源的源文件与导出文件使用相同 ID，避免只用“最终版”等名称。
2. 保留可编辑源文件，导出到对应 runtime 目录；GLTF 等多文件资源保留相对结构。只在确有多个保留版本时加 `v001` 等版本目录。
3. 在 [catalog.json](catalog.json)补充路径、来源与使用授权、目标版本、用途、状态，在[批次索引](catalog.md)登记新批次。模型另在源文件目录记录单位、朝向、原点及动画名称。
4. 接入时按[美术接入 Skill](../.agents/skills/bob-art-integration/SKILL.md)更新加载代码、本地服务和发布复制规则，验证后再将状态改为“已接入”。

**放进目录不等于游戏已经能加载。** V2 开发服务器映射 `/assets/runtime/sprites/`；稳定快照与 Pages 构建只复制 `art-manifest.js` 选中的 WebP 运行文件，并保留相对目录。新增运行资源应同时更新导出、清单、绘制适配和台账，验证实际请求与 `/BOB/` 前缀；制作源、管理页及未选中的资源不会随游戏发布。当前 Pages 只发布 V2，初版与 Three.js 版本保留源码。

管理服务验证：`npm --prefix assets/manager run check` 和 `npm --prefix assets/manager test`。本轮入库与图集证据见[完整静态验收记录](source/whalefall-v5-2-complete/acceptance.md)，页面与保存验证见[管理页进度](manager/progress.md)。验收接触表、本地预览图和被拒中间稿不进入 Git；拼装预览仍随 `review/region-assembly/` 与 `review/components/` 保存。
