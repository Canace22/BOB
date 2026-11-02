# BOB · 鲸腹遗城 / 鲸落万物生

以「鲸落」为题材的 2D 战斗 + 收集探索游戏（类空洞骑士），使用 Godot 4.7.2 开发。

| 入口 | 说明 |
| --- | --- |
| [默认在线试玩](https://canace22.github.io/BOB/) | 自动跳转到当前 Godot 正式版 |
| [Godot 版在线试玩](https://canace22.github.io/BOB/godot/) | 正式工程 `game/` 的 Web 导出 |
| [V2 原画版在线试玩](https://canace22.github.io/BOB/mvp-v2/) | 冻结的 Canvas 2D 原型，保留可玩 |

## 目录

```
BOB/
├── game/        # 唯一开发目录：Godot 正式工程（代码、房间场景、运行素材、测试）
├── assets/      # 全局素材库、制作源与资源台账
├── docs/        # 架构说明、世界观与原画设计
├── tools/       # godot.mjs 命令入口、Pages 发布脚本
├── legacy/      # 冻结只读：旧 Godot 工程、Web 原型、旧制作脚本
├── .agents/     # 项目 Skill
└── AGENTS.md    # 协作规则（AI 与人共用）
```

架构、模块与约定见 [docs/architecture.md](docs/architecture.md)。旧版本说明见 [legacy/README.md](legacy/README.md)。

当前设计取舍见[游戏方向](docs/游戏方向.md)：持叉主角的战斗与收集探索、共鸣开路、鱼群指挥及生态图鉴；其中规划内容不代表已实现。

## 当前内容

Godot 正式工程已迁移五房主路：外伤坡 → 须筛 → 舌台 → 负壳蟹 → 流膜育窝。包含短击连段、重鸣、调息、Boss、交互领取贴流冲、三段跨沟、营地与版本化存档、地图和暂停。舌台可收集碎片并打开持久壳闩短桥。

七个 R1 房间均保留独立场景；R1-06 / R1-07 的浮升、挂环门仍锁定，相关能力和后续区域不属于本批可玩内容。主线线上版本仍沿用旧玩家素材，本批新动作先在下方独立训练场验收与发布。实测范围、发布提交和限制见 [game/progress.md](game/progress.md)。

## 母蟹 Boss 独立原型

分支 `codex/crab-boss-prototype`。独立试玩入口为 [母蟹训练场](https://canace22.github.io/BOB/godot-boss/)，上线状态以 [进度记录](game/progress.md) 为准；默认主线入口不随原型发布更新。

**J 近战**。第一击打中后再按 J，可以在有效段结束时接回挑；轻击打中后按 K，可提前接重击。挥空会走完收招。母蟹出招时有护壳，近战敲壳不攒盾。对同一记单招连敲两次，它会追加一次低扫，长按空格可以跳过。

**K 反击**。躲开整套攻击，它打空收钳时会露出软处。如果打中了你或护盾，收招时它仍然护壳。看到母蟹准备下砸，有退路就后撤；已经贴近、手里有 2 蓄振时，也可以在钳子举高发亮时按 K。重击赶在落钳前打中，会打断这套动作，留出 1.6 秒反击时间。

**U 远程**。轻点快射，长按约半秒，看到叉前的共鸣环亮起或听到提示音再松手，打出更快、更重的一发。蓄力时可以移动和跳跃，收钳后射击能打出全额伤害。

开场 6 格生命、一层护盾。打中露出的身体可重新攒盾，**F** 花 2 蓄振治疗。Enter 开始或重试，Esc 暂停；准备与结果界面可开启 Shift 冲刺对照。训练场进度与主线存档隔离。

Boss 在 65% / 35% 血量转入二、三阶段：单招逐步变为二连扫、扫接砸、冲撞接扫和砸接二扫。二阶段第一次主动拉开到冲撞距离、身后还有退路时，母蟹会冲撞接一次低扫。先退开壳身，再看钳子起跳。每段都有提示，低扫长按跳跃，下砸和冲撞提前后退；躲过整套连招后可以上前反击。具体数值与边界见[战斗方案](docs/鲸腹遗城原画集/母蟹Boss战原型.md)，线上版本见进度。

玩家两段轻击分别下扫、回挑，命中时才溅出碎屑。母蟹低扫、下砸和冲撞各有贴地特效，下一招前摇开始时清除上一招的尘雾。二、三阶段短暂显示鼓励语与共鸣提示；胜利时，生物光在拾潮者身边升起，按 Enter 可立即再战。见[特效制作说明](assets/source/combo-vfx-v1/README.md)。

训练场上沿有三簇随水流摆动的垂须，后方有三种鱼群缓慢游过；环境动画随 Esc 暂停。素材来自 main 已有图集，摆放与限制见[环境接入说明](assets/source/crab-environment-main/README.md)。

训练场现接入视频参考的骨壳洞窟、七组补绘动作、独立落地尘雾和抖壳碎片；蓄力、命中、收招与伤害窗口同步，战斗中自动收起设置按钮。远程与护盾复用已入库的共振环、回声圈位图，出手复用玩家轻击，Boss 组合复用现有动作。素材仍有动作间体积/视角变化，尚未达到原视频的一致性。来源、映射与限制见[制作记录](assets/source/crab-video-v3/README.md)。

V4 将横扫、冲撞、走路和抖壳统一为待机的侧向镜头，补绘 48 帧；走路随实际位移推进，停住不空踏。来源、打包和剩余漂移见 [V4 记录](assets/source/crab-video-v4/README.md)。

待机闪烁修复：玩家出生/重试的保护状态不再触发受击闪烁；准备与结果界面保持正常透明度。母蟹待机采用稳定的第 0 帧站姿，原待机重绘序列因壳纹和钳角跳变停用；这是静态待机，移动、出招和退场继续播放各自动作。

拾潮者 V2 使用独立左右位图动作：待机、跑步、上升/下降/落地、两段普攻、重击、受击、冲刺与调息。统一脚底根，跑步跟随实际位移；站定落地缓冲后回待机，移动落地接跑步。地面出招站稳，收招允许移动；武器和腰灯不随朝向交换挂点。画面仍是有限关键姿势的逐帧动画，连续性与用户试玩反馈分别记录在[制作说明](assets/source/player-animation-v2/README.md)和进度中。

训练场使用精灵台压缩后的玩家贴图，原尺寸制作帧保存在素材库。首次下载量与实测启动时间见[进度记录](game/progress.md)。

本地直接运行 `node tools/godot.mjs run -- res://src/prototype/crab_arena.tscn`；Web 开发预览使用 `/BOB/godot/?prototype=crab`，可用 `PORT=4188` 启动独立服务。真实按键回归脚本为 `node game/tests/web_crab_prototype.mjs`（支持 `PLAYWRIGHT_MODULE`、`GAME_URL`、`TEST_LABEL`）。

玩家动作专项复核运行 `node game/tests/web_player_animation.mjs`，默认验证两向完整动作并保存录像；`ANIMATION_SUITE=locomotion` 只跑移动和跳落。该脚本使用独立浏览器上下文，不修改玩家主线存档。

待机与受击反馈用 `node game/tests/web_idle_feedback.mjs`，默认访问独立 4190 预览；支持 `GAME_URL` 指向线上，持续采样左右待机透明度、暂停、真实伤害、死亡和重试，保存报告与录像。

发布原型用 `node tools/deploy-pages.mjs --prototype`，只更新 `gh-pages` 的 `/godot-boss/`，不替换 `/godot/`、根入口或 V2。原型启动下载使用独立缓存 `bob-boss-downloads-v1`，不清理主线缓存。

## 快速开始

需要 Node.js 18+、Godot 4.7.2 和 Git LFS。macOS 默认识别 `/Applications/Godot.app`，其他位置可用 `GODOT` 指定。

```sh
git lfs install && git lfs pull
export GODOT=/path/to/Godot_v4.7.2-stable_win64_console.exe   # 或放到 .tools/godot/

node tools/godot.mjs run      # 运行游戏
node tools/godot.mjs editor   # 打开编辑器
node tools/godot.mjs check    # 导入资源并检查全部脚本和场景
node tools/godot.mjs test     # headless 自动测试
```

测试只写独立测试文件。桌面画面检查可运行 `node tools/godot.mjs run -- res://tests/manual_preview.tscn`，不会改写真实存档。新工程不读取旧 Godot / V2 存档；Web 版自动保存到当前浏览器站点存储。

Web 验收需要 Node.js 20+、Playwright 与可用 Chrome/Chromium：

```sh
node tools/godot.mjs export-web
node game/tests/serve_web.mjs       # 独立终端保持运行，端口 4187
node game/tests/web_playthrough.mjs # 另一终端执行，五房真实按键路线
```

`PLAYWRIGHT_MODULE` 可指定现有模块路径，`CHROME_PATH` 可指定浏览器。线上复核设置 `GAME_URL=https://canace22.github.io/BOB/godot/`。测试自动创建独立浏览器上下文，报告和截图在 `game/build/qa/`（不提交）。

## 操作（桌面键盘）

`A / D` 移动，`Space` 跳跃，`Q` 或 `J` 短击（后半段再按接第二击），`R` 或 `K` 重鸣（消耗 2 蓄振），`F` 原地调息（消耗 2 蓄振恢复 1 生命），`Shift` 或 `L` 贴流冲（击败负壳蟹后获得），`E` 或 `↑` 交互，`Tab` 或 `M` 地图，`Esc` 暂停。

## 发布

```sh
node tools/deploy-pages.mjs
```

导出 Web 版，合并进 `gh-pages` 分支的 `/godot/` 目录并正常推送，同时将根入口跳转到 `godot/`，保留 `mvp-v2/` 等历史版本目录。只修正默认入口时使用 `node tools/deploy-pages.mjs --entry-only`，不重新导出或替换游戏包。流程见 [AGENTS.md 的持续迭代规则](AGENTS.md#持续迭代与边做边玩)。

导出需要安装 Godot 4.7.2 官方模板中的 `web_nothreads_release.zip`。发布脚本在 `.pages-dist-godot/` 保留独立的 Pages 检出；`godot/build.json` 记录源码版本，推送后还需核实 Pages 部署和线上路线。

Web 导出后自动生成压缩下载文件与加载说明，浏览器缓存按内容哈希区分版本；支持的浏览器会复用已下载引擎和资源包。加载页会显示实际压缩下载量与启动阶段。原始文件保留，供缺少解压 API 的浏览器使用。首屏测速运行 `node game/tests/web_startup.mjs`，环境变量与上面的浏览器验收一致。

中文 UI 使用[字体子集](assets/source/noto-sans-sc/README.md)。新增中文后重建字体并运行素材同步；完整原字体保留在素材库，验收测试会检查缺字。

## 美术资源

正式画面只用入库的 2D 位图素材，规则见 [AGENTS.md](AGENTS.md#正式美术必须使用2d素材)。素材管理：[全局风格规范](assets/art-style.md) · [目录约定](assets/README.md) · [资源台账](assets/catalog.md)。管理页面：`npm --prefix assets/manager start`，打开 http://127.0.0.1:4176/ 。

大型素材使用 Git LFS。编辑器缓存、验收截图、第三方工具和日志不入库，见[迁移与提交范围](docs/workspace-migration.md)。
