# 美术资源管理

这里保存BOB的原画、制作源、运行导出和资源台账。当前游戏从 `game/art/manifest.json` 同步需要的文件；素材库还保留可复用原画与未来区域素材，入库不代表已接入游戏。

制作前阅读[美术风格规范](art-style.md)，查找[原画集](../docs/鲸腹遗城原画集/README.md)和[资源台账](catalog.md)。正式画面使用入库的2D位图；分层、鱼群、垂须、气泡等制作方法见[场景与环境动态](../docs/scene-and-environment-production.md)。

## 查看与管理

直接打开[线上美术资源预览](https://canace22.github.io/BOB/art/)，可搜索、筛选、放大和下载素材，查看完整需求与拼装预览。线上为只读快照；更新命令为 `node tools/deploy-art-pages.mjs`，详见[预览与发布说明](manager/README.md)。

仓库根目录运行 `npm --prefix assets/manager start`，打开[本机管理页](http://127.0.0.1:4176/)。可搜索、筛选、查看原图及来源，修改名称、标签、备注和验收状态；点击保存写入 [catalog.json](catalog.json)，刷新或重启后保留。归档按钮仅改变台账状态，不删除图片。

管理页需要自己的服务API，不能用游戏静态服务器代替。端口被占用时，在PowerShell设置 `$env:PORT=4177` 再启动服务。页面的静态图像检查、用户美术确认和游戏接入分别记录。

## 文件放哪里

| 目录 | 内容 |
| --- | --- |
| `source/<资源ID>/` | 可编辑母版、提示词、来源与授权说明 |
| `runtime/sprites/` | 背景、角色、动画、UI与正式PNG/JSON图集 |
| `runtime/godot-support/` | 当前工程需要的遮罩、文本资源、音频等迁出旧工程的依赖 |
| `runtime/fonts/` | 字体、授权与运行子集 |
| `runtime/audio/`、`runtime/models/`、`runtime/textures/` | 按对应格式保存的音频、模型及贴图 |
| `../docs/鲸腹遗城原画集/` | 既有概念原画与设计资料，保持原位 |

正式素材、母版与管理页选用预览入库；构建ZIP、临时报告、验收截图和录像只留本地。详见[资源存储](../docs/resource-storage.md)。

## 当前游戏的图片处理

此前967张同步图片已分批用Framecraft保真PNG处理，原件与结果保存在11个可重开的 `.framecraft` 工程。新增111张的保真PNG约53.48 → 52.36 MiB；50张场景另用Godot质量0.9的轻度有损导入。正式发布排除旧动作和独立预览专用资源，保留新母蟹及主角修复后启动下载约57.58 MiB，具体见[包体说明](../docs/web-package.md)。图片尺寸、Alpha与动画数据保留，后续动作修复和母蟹分别按其制作记录管理，不能套用旧批次的全量像素结论。来源哈希与复核命令见[压缩批次](source/framecraft-runtime/README.md)。

```sh
python assets/source/framecraft-runtime/compress.py --verify
python assets/source/framecraft-runtime/compress.py --verify --batch 2026-11-04
node game/tools/audit_resources.mjs
node tools/godot.mjs sync-art
```

压缩验证需要Pillow和NumPy，可使用现有Framecraft的Python环境。素材同步只从 `assets/` 读取，不需要恢复旧工程。动态加载路径、当前同步文件及其拥有者见 `game/content/whalebelly/runtime-resources.json`，实际引用以审计结果为准。

完整 `legacy/`、旧模块版、四批旧角色动画和旧版专用运行副本已移到[归档分支](../docs/legacy-archive.md)。台账中的V2接入记录保留历史分支标记；这些记录不代表当前Godot的加载关系。当前资源与尚未接入的创作素材按用途分别判断，不能仅因未被主场景引用就删除母版或未来区域素材。

## 精灵与图集

单张PNG可以是静态精灵；图集将多个精灵装入一张纹理，配合rect与pivot读取。只有连续变化的姿势与正确时序才构成动作动画。

既有V5.2完整静态图集为7页PNG/JSON，174件精灵分组、18张背景独立保存；`animations`为空。[图集索引](runtime/sprites/whalefall-complete-atlas/index.json)与逐件原图继续保留。世界精灵按128px/U，保留sourceRect/pivot；UI保留原画布与九宫格，背景不裁掉留白后拉伸。

需要重新打包时，使用带Pillow的Python在仓库根目录运行：

```sh
python assets/source/whalefall-v5-2-complete/tools/pack-atlases.py
python assets/source/whalefall-v5-2-complete/tools/verify-atlases.py
```

更改台账不会自动更新图集；ZIP按需本地生成，不进入Git。静态库的[覆盖与验收](source/whalefall-v5-2-complete/acceptance.md)是对应批次记录，不等于整个关卡已经实现。

## 新资源入库与接入

1. 使用稳定英文ID，保存原件、可编辑源和来源授权，导出到对应runtime目录。
2. 更新 `catalog.json` 与 [catalog.md](catalog.md) 的批次入口；候选、用户认可和接入状态分开记录。
3. 按当前Godot开发Skill更新同步清单，运行 `sync-art`。新增动态加载路径同时维护资源审计。
4. 检查实际资源加载、比例、遮挡、碰撞/可达性、动作与存档，再标记已接入并按项目流程提交发布。

管理页改动运行 `npm --prefix assets/manager run check` 和 `npm --prefix assets/manager test`。游戏接入执行Godot检查、当前测试及真实按键验收，结果见 [game/progress.md](../game/progress.md)。
