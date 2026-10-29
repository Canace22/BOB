# 鲸腹遗城 · Whalebelly Ruins

唯一开发入口：[project.godot](../godot/WhalebellyRuins/project.godot)。固定引擎 **Godot 4.7.2.stable.official.ed1daf0bf**，Windows / Compatibility。

用该引擎导入工程，按 F5 运行 `scenes/main.tscn`。房间为 `scenes/r1/R1-01.tscn` 至 `R1-07.tscn`，逻辑在 `scripts/`，关卡数据在 `assets/rooms.json`。目录重命名不改变 `res://` 内部路径。

## 合并规则

- 以 `first-level-artmatch` 最新七房运行代码、角色、场景、素材和测试为准，合入原 `first-level` 的独有资源。
- 同路径冲突取最新 artmatch 版本；first-level 的冲突原件、旧脚本/测试/制作记录保存在 `production-history/pre-unification/first-level/`，由 `.gdignore` 隔离。
- `first-level-v02-graybox` 已移出开发目录并停用，不再保留第三个开发入口。
- 合并前的三个工程已做 ZIP 备份，排除可再生 `.godot` 缓存；已核验文件数、CRC及复制后SHA256。具体备份路径、冲突列表、逐文件来源见 [合并清单](godot-consolidation.json)。备份位于仓库外的 `../backups/`，不会被识别为第二个开发工程。
- 现有 artmatch 存档目录 `WhalefallArtmatchV05` 保留。旧 first-level 的用户存档不删除、不自动转换；两者运行数据格式不同。

永久删除操作被工具自动审批以“blocked by policy”拦截，未返回更具体原因。因此三个旧目录可恢复地移到 `G:/鲸落万物生/backups/godot-retired-20261028/`，其 `project.godot` 改名为 `project.godot.archived`。它们不是活跃工程；开发区仅保留 WhalebellyRuins。

## 后续开发

所有代码、场景与资产修改进入这一工程；使用 Git 历史管理版本，不再复制出 `first-level-vXX`。

`work/r1_v05_capture.py`、`r1_v05_package.py`、`r1_v05_delivery.py`、`r1_v05_finalize.py`、`refine_audio_v05.py` 已指向统一工程。历史初始化/整版重建脚本移到 `work/archive/godot-pre-unification/`，不再作为生产入口。

`outputs/` 和 `builds/` 仍在 BOB 上一级。当前交付册的项目链接已更新。网页原型目录沿用各自说明，本次未合并或发布 Web 版本。

本次验证与未完成事项见 [工程进度](../godot/WhalebellyRuins/progress.md)。历史验收日志保留原始路径与日期，不冒充迁移后的新验证。

## 本轮参考图 · 环境展示场景

在同一工程打开 `scenes/environment/xumen_reference.tscn`，**F6**运行。也可执行工程根目录 `preview-reference-environment.ps1`（可加`-Pan`）。这是仅环境和静态展示角色的1280×720场景，不接入七房关卡控制器；F5入口保持原游戏。[素材、母版、范围和限制](../assets/source/xumen-reference-environment/README.md)。

## R1-01新环境已接入主地图

F5主入口的R1-01现在实例化参考图环境，角色由既有控制器接管，路面碰撞/门/旧档坐标已绑定。独立环境F6仍可用。当前便携包位于 `G:/鲸落万物生/builds/WhalebellyRuins/`；[接入与验收说明](../assets/source/xumen-reference-environment/integration/README.md)。

## 主场景编辑器同步

`scenes/main.tscn`显式实例化R1-01，打开即可看到地图，并共享`xumen_reference.tscn`的源图像与布局。[同步说明与验收](../assets/source/xumen-reference-environment/integration/README.md#主场景编辑器同步)。

## 2026-10-28 环境动态更新

新纯环境预览：`scenes/environment/motion_preview.tscn`（F6，C视差、空格暂停）；分组预览：`element_gallery.tscn`。R1-01主关卡已共享新分件，默认平滑跟随既有角色，Tab切回全景。[母版、参数、来源、运行证据](../assets/source/xumen-motion-elements/README.md)。旧`preview-reference-environment.ps1`继续可用，推荐新预览入口。

### 垂须动画母版

R1-01和环境预览共用4组Blender烘焙帧动画，12FPS、6秒循环。可编辑母版及定向重建说明见[垂须资产](../assets/source/baleen-blender/README.md)。仍使用唯一工程及既有PreviewEnvironment.cmd，无新玩法。

### 2026-10-29 桥下轮廓与气泡

共享环境恢复原图桥下被裁短的枝条，并新增左侧岩缝、桥下、右侧三处循环气泡。独立包已同步；可在主地图或环境F6查看。[修改、原件及验收](../assets/source/xumen-underbridge-repair/README.md)。

### 当前垂须动画

顶部左、中、右三组已切换为V3末端跟随循环，每组48帧、12FPS、4秒，共享一张图集并错开相位；旧静态细丝已从洞顶/根部层清理。远处资源实际含蓝色岩柱，保留原36帧动画。R1-01、环境预览和现有便携包同步。[当前实机录像、布局和验收](../assets/source/baleen-loop-v3/integration/README.md)。旧[Wan运动派生资产](../assets/source/baleen-wan22/README.md)、Blender与Krita源文件保留。

## V2.4角色主场景接入

F5默认七房已使用CampaignPlayer及PlayerUI；原场景/房间数据保留，V6存档不迁移。独立PlayerTest先验收再接入，数值以原工程为准。操作、数值来源、测试及美术边界见[角色系统说明](../godot/WhalebellyRuins/docs/tide-3c.md)。

### 海底鱼群美术样板

打开 `scenes/environment/fish_school_gallery.tscn` 按F6：3种单鱼拼成28/14/20只三组，独立身体与尾鳍摆动，16秒循环。空格暂停，R重置，1/2/3切换可见组。源、图集、可复用元素及验收见[鱼群母版](../assets/source/fish-schools-v01/README.md)。主关卡入口保持原配置。


## 2026-10-29 主关卡鱼群替换

三组新鱼群已替换R1-01共享环境中旧48实例，现为28/14/20共62条鱼。主关卡、环境预览和独立样板同步；15项主关卡、17项环境、15项独立包检查通过。当前试玩包已更新。接入说明与证据：`assets/source/fish-schools-v01/integration/`（相对BOB根目录）。
