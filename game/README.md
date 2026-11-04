# 鲸腹遗城 · 当前工程

用Godot 4.7.2打开 `project.godot`，按F5进入正式标题界面，选择新旅途或继续已有存档。入口仍为 `content/whalebelly/main.tscn`，实际运行WhalebellyRuins七房主关卡。

`A/D`移动，`Ctrl+方向`行走，`K/空格`跳跃，`J/Q`攻击，`L/Shift`冲刺，`U`叉鸣弹/潮术，`B`偏转，`I`重鸣，`P`调息，`O`潜隙，`T`探潮，`V`蓄力长冲，`E`交互，`W`浮游，`G`牵引，`Esc`暂停，`H`帮助，`M`静音。方向+攻击/潮术及长按派生见[36项动作、操作与参数](../docs/action36-controls.md)。能力遵循正式解锁，F9临时练习、F10在练习中切换基础/升级组。

本批动作资产正在接入和返修。代码可达、资源导入与外观验收分别记录；当前完成情况与录屏以[进度](progress.md)最新记录为准，不能把36项候选图集等同于全部验收完成。

默认七房为跟随镜头，Tab切换跟随/全景；原图、截图和分层查看仍用既有全景行为。F9退出练习时恢复进入前的正式能力/进度快照，F10只切换会话内技能组。逐项资产及当前验收状态见[36项覆盖表](../docs/action36-asset-coverage.md)。

R1-04已接入之前训练场的母蟹：低扫可跳、下砸可退或用`I`反制、冲撞结束后反击。击败后照常获得冲刺；已通关旧档保留结果。操作、素材来源与验证入口见[主线母蟹](../docs/mother-crab-integration.md)。

`C`打开区域地图，`Esc`暂停，`H`查看操作说明。菜单支持鼠标、Tab焦点和Enter确认；关闭菜单时需先松开仍按住的游戏键，防止攻击/跳跃误触。`E`在营地恢复生命、记录检查点并打开营地页；共生模块当前尚无玩法实现，两槽明确未开放。死亡动画结束后按`R`或点击返回检查点。数值辅助、对比、减少镜头动态、主音量和静音设置会保存。UI接口、规则差异与验证见[UI系统](../docs/ui-system.md)。

在仓库根目录运行：

```sh
node tools/godot.mjs run
node tools/godot.mjs editor
node tools/godot.mjs check
node tools/godot.mjs test
```

找不到引擎时，将 `GODOT` 设置为现有Godot 4.7.2 console可执行文件。运行素材由 `art/manifest.json` 从 `assets/` 同步，不依赖旧工程目录。图片来源、工作台工程与压缩方式见 [Framecraft批次](../assets/source/framecraft-runtime/README.md)。

默认七房Web的既有批次启动文件约103.15 MiB，较该批压缩前减少约30%。50张场景使用原尺寸的轻度有损导入；原件、Alpha及动画数据保留，角色和特效仍为保真编码，具体设置与恢复方式见[本批说明](../assets/source/framecraft-runtime/batches/2026-11-04/README.md)。独立第一章数据另见下文。

## 新主线第一章须庭

独立入口为 `content/story/main.tscn`，房间稳定ID为 `story-c01-xuting`；默认 F5 仍进入七房。须庭包含补巢者共鸣、两侧食腐甲非致死退却、内侧指路及出口完成。第二章折井尚未开放，完成界面可返回标题或留在本章探索；具体本轮验证与发布结果见[进度](progress.md)。

在仓库根目录执行：

```sh
node tools/godot.mjs run -- res://content/story/main.tscn
node tools/godot.mjs run -- res://content/story/main.tscn -- --story-qa
node tools/godot.mjs export-story-web
node game/tests/serve_web.mjs --story
node tools/deploy-pages.mjs --story-only --build-only
node tools/deploy-pages.mjs --story-only
```

Web 本地地址 http://127.0.0.1:4193/BOB/godot-story/ ，对应[章节 Pages 入口](https://canace22.github.io/BOB/godot-story/)。`--build-only` 只构建，不推送或修改 Pages 检出；正式章节发布只替换 `/godot-story/`，保留默认根入口与历史版本。发布源码、`story-c01` 入口及启动场景写入 `build.json`。构建脚本在 `build/story-export-project/` 创建隔离工程副本并复制导入缓存，仅修改副本 `run/main_scene` 后导出到 `build/story-web/`，不临时更改正式 `project.godot`。官方Web发布模板禁用命令行场景路径覆盖，因此HTML不传场景参数；章节主场景直接写入导出包。

操作：`A/D` 移动、`Space/K` 跳跃、`J/Q` 短击，靠近补巢者按 `E` 共鸣，靠近安全台按 `E` 恢复。对话 `E/Enter` 翻页，`Esc` 中断不完成事件；菜单支持鼠标、Tab焦点和Enter。`Esc` 暂停/恢复，`M` 静音，游戏中 `Tab` 切换跟随/全景，死亡后 `R` 重试。菜单关闭后需松开游戏按键再恢复控制。

食腐甲收紧壳足后沿预警方向扑击，普通短击不会打断已经开始的预警。左侧一扑、右侧二连扑，每次都有独立预兆，最后一扑结束后留出反击时间。可跳过、后撤或登上两侧高台观察，再选择落点出手；击退后它们仍存活并返回聚食处。这一轮是战斗节奏样板，尚未扩展第二章。

章节导出副本采用明确资源列表，从入口、autoload、脚本引用及已登记动态加载目录递归选择130项资源；遇到未知动态加载写法直接报错。排除无关旧房和已由动作图集替代的独立帧库，保留运行中的36项动作图集、环境动态和原尺寸图片，不减帧。选择报告在 `build/story-export-resources.json`；[架构说明](../docs/architecture.md#web发布)记录维护规则。

2026-11-04最终发布导出：压缩引擎10,153,810字节、压缩PCK 41,653,851字节，共49.41 MiB，优化前115.51 MiB；原始PCK为42,114,936字节。10张PNG实际经[Framecraft增量处理](../assets/source/framecraft-runtime/batches/story-c01-2026-11-04/README.md)，12.94→11.77 MiB（−9.02%）；Web总量还受导出资源范围和Godot纹理编码影响，不将两种收益混算。线上源码为 `006f5170`；实机路线复验和发布证据见[进度](progress.md)。已有通关存档可在标题选择“开始新旅途”体验战斗迭代。

本章存档 `user://story-c01/progress.json`、测试档 `user://story-c01-qa/progress.json` 与旧 V6 隔离。四个事件按 `met_mender → foragers_retreated → route_known → completed` 顺序保存：首次交流完整结束、两侧敌人实际退回聚食处并停止敌对、内侧指路完整结束、玩家到达出口。跳过战斗、逃出探测范围或中断对话不能推进。死亡重置未完成遭遇，已保存的事件保持；重入按持久阶段恢复世界，不恢复攻击时钟。存档写入成功后才更新内存，失败提示可重试；损坏主档尝试 `.bak`，新旅途先保留 `.before-new`。

素材来源：[环境](../assets/source/story-c01/environment/README.md)、[角色图集](../assets/source/story-c01/characters/README.md)、[原创合成低鸣与共鸣](../assets/source/story-c01/audio/README.md)。图集是有限帧样板，退却包含姿态重组；低鸣不是鲸类真实录音。技术通过、场景实机结果与用户审美认可分开记录，不以素材入库宣称整体美术已获认可。

## R1后续六房环境

R1-02至R1-07已接入独立四层与环境动件，主场景运行时直接使用。数字 **2–7** 为已有房间预览；**Tab** 切换全景/跟随镜头，**F4** 查看四层，**F2** 对照原图。预览不是能力解锁；正式入口仍按Boss、浮游和锚环限制推进。R1-06/07是后续能力回访房，**F9** 只临时开放当前会话的练习能力。

原件、SVG选区/根线、OpenRaster母版与方法清单：[制作说明](../assets/source/r1-chapter-scenes/README.md)。本地实机验收页在 `build/qa/r1-chapter-scenes/场景验收与对照.html`，含24FPS环境展示与六房截图；日志/录像只保留本地。当前阶段见 [进度](progress.md)。

## 存档与启动

主线代码在 `src/campaign/`，房间在 `content/whalebelly/r1/`，环境在 `content/whalebelly/environment/`。角色技能参数场 `content/whalebelly/test/PlayerTest.tscn`、Run预览与当前环境预览继续保留。旧模块版、旧动画、完整 `legacy/` 与历史制作源见[归档说明](../docs/legacy-archive.md)。

主线存档为 `user://whalebelly/artmatch_save.json`。桌面仅在目标尚无存档时复制旧目录的有效V6进度，不覆盖新档或删除原件；浏览器不会读取本机AppData。隔离试玩使用 `node tools/godot.mjs run -- res://tests/whalebelly/manual_play.tscn`。

Web验证先运行 `node tools/godot.mjs export-web`，再在独立终端运行 `node game/tests/serve_web.mjs`，使用 `node game/tests/web_whalebelly.mjs` 真实按键验收。可用 `GAME_URL` 指定线上入口、`TEST_LABEL` 区分证据。测试创建独立浏览器上下文；报告、截图和录像只留本地。

模块边界、发布和资源审计见[架构](../docs/architecture.md)，本轮执行结果见[进度](progress.md)。

资源维护：本体和世界FX分别保存帧数，释放/落地从FX自己的 `event_frame` 启动。影潮穿行复用dash本体加冷青色调；深钟复用dive本体和环，升级差异保留在技能逻辑中。资源审计运行 `node game/tools/audit_resources.mjs`；覆盖表用仓库根目录 `python build_asset_coverage.py` 更新，不因此自动认可候选美术。
