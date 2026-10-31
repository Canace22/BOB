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

2026-10-31 本地新增素材与环境动态已合并到此结构；正式入口为 `game/project.godot`。鱼群、垂须和分层环境可打开 `game/content/environment/local_environment_preview.tscn` 按 F6 预览。[合并范围与验收](docs/godot-local-integration.md)。

## 当前内容

Godot 正式工程已迁移五房主路：外伤坡 → 须筛 → 舌台 → 负壳蟹 → 流膜育窝。包含短击连段、重鸣、调息、Boss、交互领取贴流冲、三段跨沟、营地与版本化存档、地图和暂停。舌台可收集碎片并打开持久壳闩短桥。

七个 R1 房间均保留独立场景；R1-06 / R1-07 的浮升、挂环门仍锁定，相关能力和后续区域不属于本批可玩内容。角色沿用旧版静态姿态加程序反馈；复用素材接入不代表制作了新的逐帧动画。实测范围、发布提交和限制见 [game/progress.md](game/progress.md)。

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
