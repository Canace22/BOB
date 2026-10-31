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

2026-10-31 已完整恢复原 WhalebellyRuins 可玩内容。打开 `game/project.godot` 按 F5，默认运行原七房、CampaignPlayer、完整 3C/技能、Run 动画、HUD 及主地图环境动态；不再仅有独立环境预览。[恢复范围、操作与验收](docs/whalebelly-game-recovery.md)。原模块化五房场景仍保留在 `game/src/main/main.tscn`。

## 当前内容

默认入口已恢复原 WhalebellyRuins：七房地形、道路与支路、逐帧拾潮者、短击/下劈/迎珠/重鸣/调息、能力门、Boss、营地、V6存档和镜头。R1-01 使用分层环境、62条鱼、垂须、气泡、水面与前景；15组动作库及84帧跑步保留。

主线已验证前五房至首关出口；支路机制专项通过不代表七房全部连续路线已验证。恢复细节与制作源清单见[恢复说明](docs/whalebelly-recovery.md)，实际测试与限制见 [game/progress.md](game/progress.md)。线上目前仍是恢复前的稳定模块版。

## 快速开始

需要 Node.js 18+、Godot 4.7.2 和 Git LFS。

```sh
git lfs install && git lfs pull
export GODOT=/path/to/Godot_v4.7.2-stable_win64_console.exe   # 或放到 .tools/godot/

node tools/godot.mjs run      # 运行游戏
node tools/godot.mjs editor   # 打开编辑器
node tools/godot.mjs check    # 导入资源并检查全部脚本和场景
node tools/godot.mjs test     # headless 自动测试
```

测试只写独立测试文件。恢复版隔离试玩可运行 `node tools/godot.mjs run -- res://tests/whalebelly/manual_play.tscn`。桌面正式运行仅在目标无档时复制原Godot有效V6存档，保留原件；不读取V2存档。Web版保存到当前浏览器站点存储。

Web 验收需要 Node.js 20+、Playwright 与可用 Chrome/Chromium：

```sh
node tools/godot.mjs export-web
node game/tests/serve_web.mjs       # 独立终端保持运行，端口 4187
node game/tests/web_whalebelly.mjs # 恢复版真实按键/营地/刷新冒烟验收
```

`PLAYWRIGHT_MODULE` 可指定现有模块路径，`GAME_URL` 指定验收服务地址。恢复版测试与原模块版 `web_playthrough.mjs` 不同，不能混用。测试自动创建独立浏览器上下文，报告和截图在 `game/build/qa/`（不提交）。

## 操作（桌面键盘）

`A/D` 移动，`K/空格` 跳跃，`J/Q` 短击，空中 `S+J` 下劈，`L/Shift` 冲刺，`U` 迎珠，`I` 重鸣，`P` 调息，`O` 潜隙，`E` 交互，`W` 浮游，`G` 牵引，`Esc` 暂停，`M` 静音，`H` 帮助。冲刺/浮游/牵引沿用能力解锁；首次操作说明按任意键关闭。

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
