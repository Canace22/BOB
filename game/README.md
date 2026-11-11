# 鲸腹遗城 · 当前工程

2026-11-04：须门遗港七房已接入连续空间设计的共用口腔远景、六条连接双向动件与短淡黑过门；C地图以鲸头原画定位主路和上层支路。原道路与玩法保留，仍按房间加载。来源、母版、验收及后续边界见[制作说明](../assets/source/xumen-continuity-v1/README.md)。

用Godot 4.7.2打开 `project.godot`，按F5进入正式标题界面，选择新旅途或继续已有存档。入口仍为 `content/whalebelly/main.tscn`，实际运行WhalebellyRuins七房主关卡。

`A/D`移动，`Ctrl+方向`行走，`K/空格`跳跃，`J/Q`攻击，`L/Shift`冲刺，`U`叉鸣弹/潮术，`B`偏转，`I`重鸣，`P`调息，`O`潜隙，`T`探潮，`V`蓄力长冲，`E`交互，`W`浮游，`G`牵引，`Esc`暂停，`H`帮助，`M`静音。方向+攻击/潮术及长按派生见[36项动作、操作与参数](../docs/action36-controls.md)。能力遵循正式解锁，F9临时练习、F10在练习中切换基础/升级组。

本批动作资产正在接入和返修。代码可达、资源导入与外观验收分别记录；当前完成情况与录屏以[进度](progress.md)最新记录为准，不能把36项候选图集等同于全部验收完成。

默认七房为跟随镜头，Tab切换跟随/全景；原图、截图和分层查看仍用既有全景行为。F9退出练习时恢复进入前的正式能力/进度快照，F10只切换会话内技能组。逐项资产及当前验收状态见[36项覆盖表](../docs/action36-asset-coverage.md)。

R1-04已接入之前训练场的母蟹：低扫可跳、下砸可退或用`I`反制、冲撞结束后反击。击败后照常获得冲刺；已通关旧档保留结果。操作、素材来源与验证入口见[主线母蟹](../docs/mother-crab-integration.md)。

须筛1只、舌台2只普通尸蟹已接入七状态逐帧动画：观察举钳后跳过低扫，收招时用`J/Q`反击。普通击杀不会发放Boss能力，切房重进会复活。制作源、参数及实际键盘验收见[尸蟹接入](../docs/corpse-crab-integration.md)。

屏幕下方的一行方向提示会随进度更新；地图区分主线与可选支路，并标出下一步。记忆袋拿到浮游后从左门返回须筛，从高台左缘落回下层，再沿下层向右进入舌台。喷气孔上层是可选补给支路，远侧区域未开放，探索后需要原路返回。

`C`打开区域地图，`Esc`暂停，`H`查看操作说明。菜单支持鼠标、Tab焦点和Enter确认；关闭菜单时需先松开仍按住的游戏键，防止攻击/跳跃误触。`E`在营地恢复生命、记录检查点并打开营地页；共生模块当前尚无玩法实现，两槽明确未开放。死亡动画结束后显示黑底重试界面。Boss 未击败时按`R`、`Enter`或点击“重新挑战”回到本房入口，恢复角色和 Boss 状态；也可点击“返回检查点”。普通死亡仍返回检查点，已取得能力与收集保留。普通过门以约0.53秒淡黑切换；返回检查点以约0.8秒淡黑重生（不含场景加载耗时）。黑屏覆盖HUD，期间锁定操作，结束恢复；不增加过场文字。数值辅助、对比、减少镜头动态、主音量和静音设置会保存。UI接口、规则差异与验证见[UI系统](../docs/ui-system.md)。

在仓库根目录运行：

```sh
node tools/godot.mjs run
node tools/godot.mjs editor
node tools/godot.mjs check
node tools/godot.mjs test
```

找不到引擎时，将 `GODOT` 设置为现有Godot 4.7.2 console可执行文件。运行素材由 `art/manifest.json` 从 `assets/` 同步，不依赖旧工程目录。图片来源、工作台工程与压缩方式见 [Framecraft批次](../assets/source/framecraft-runtime/README.md)。

当前[在线试玩](https://canace22.github.io/BOB/godot/)的启动下载约112.30 MiB，首次进入需要等待。场景压缩设置与原件恢复方式见[资源说明](../assets/source/framecraft-runtime/batches/2026-11-04/README.md)。

## R1后续六房环境

R1-02至R1-07已接入独立四层与环境动件，主场景运行时直接使用。数字 **2–7** 为已有房间预览；**Tab** 切换全景/跟随镜头，**F4** 查看四层，**F2** 对照原图。预览不是能力解锁；须筛右侧三枚圆环现可用 **G** 逐环牵引，到环后停挂等待；到最后一环后用 **空格 + D** 跃上平台，进入鲸须记忆袋。深处按 **E** 拾取奖励，解锁 **W 浮游** 并恢复生命和蓄振；记忆短文可在 **C 地图** 中重读。沿原路返回上层，从平台左缘落回主路即可；喷气孔上层仍需浮游，守关者仍控制冲刺。**F9** 只临时开放当前会话的练习能力。

原件、SVG选区/根线、OpenRaster母版与方法清单：[制作说明](../assets/source/r1-chapter-scenes/README.md)。本地实机验收页在 `build/qa/r1-chapter-scenes/场景验收与对照.html`，含24FPS环境展示与六房截图；日志/录像只保留本地。当前阶段见 [进度](progress.md)。

## 存档与启动

主线代码在 `src/campaign/`，房间在 `content/whalebelly/r1/`，环境在 `content/whalebelly/environment/`。角色技能参数场 `content/whalebelly/test/PlayerTest.tscn`、Run预览与当前环境预览继续保留。旧模块版、旧动画、完整 `legacy/` 与历史制作源见[归档说明](../docs/legacy-archive.md)。

主线存档为 `user://whalebelly/artmatch_save.json`。桌面仅在目标尚无存档时复制旧目录的有效V6进度，不覆盖新档或删除原件；浏览器不会读取本机AppData。隔离试玩使用 `node tools/godot.mjs run -- res://tests/whalebelly/manual_play.tscn`。

起始房骨路已按可见路面校正碰撞，修复坡顶和下坡时脚踩进路面的现象。已有存档可继续使用，载入时会落到修正后的地面。

Web验证先运行 `node tools/godot.mjs export-web`，再在独立终端运行 `node game/tests/serve_web.mjs`，使用 `node game/tests/web_whalebelly.mjs` 真实按键验收。可用 `GAME_URL` 指定线上入口、`TEST_LABEL` 区分证据。测试创建独立浏览器上下文；报告、截图和录像只留本地。

模块边界、发布和资源审计见[架构](../docs/architecture.md)，本轮执行结果见[进度](progress.md)。

资源维护：本体和世界FX分别保存帧数，释放/落地从FX自己的 `event_frame` 启动。影潮穿行复用dash本体加冷青色调；深钟复用dive本体和环，升级差异保留在技能逻辑中。资源审计运行 `node game/tools/audit_resources.mjs`；覆盖表用仓库根目录 `python build_asset_coverage.py` 更新，不因此自动认可候选美术。

## 门与通道

外伤坡右侧通道走到可见门前会显示 E 进入，也可继续向右直接穿过；画面中的骨拱门靠近后按 E 进入，提示会跟随改键设置。进入时短暂迈步、淡黑，再从相邻房间对应入口落地。返回门需要先离开门口再进入，避免反复切房。能力不足、Boss 尚存活和远侧闩分别提示条件；首关出口确认后保留原房间，不加载尚未制作的章节。营地与洞门距离很近时，门前进入、稍退回房内歇息。逐门设计、素材与验收入口见[门与通道](../assets/source/doorways-v1/README.md)。
