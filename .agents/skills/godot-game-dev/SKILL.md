---
name: godot-game-dev
description: 在 BOB 的 game/ Godot 正式工程中开发、迁移或修复玩法与房间，执行 headless 和真实浏览器键盘路线验收，并发布 Godot Web 版本；旧原型只作参考。
---

# BOB Godot 开发

先读[架构](../../../docs/architecture.md)、[工程规则](../../../game/AGENTS.md)和[当前进度](../../../game/progress.md)。正式源码与场景只在 `game/`；从 `legacy/` 定向查数值或素材，不能在那里开发。

## 改动与产物

- 根据稳定 ID 找到 `game/content/rooms/R1/<ID>.tscn`，门的去向/入口/条件、拾取物、营地和敌人直接配置在场景。布景在 `scenery/`；碰撞只随 World 运动，不能挂在视差层下面。
- 玩家动作在 `src/player/states/`，战斗判定共用 `Hitbox/Hurtbox/Health`。每次挥击对同一 Hurtbox 只结算一次；Boss 胜利和玩家交互领取冲刺是两个独立进度。
- 素材先入 `assets/`、登记来源和台账，再改 `game/art/manifest.json` 并运行 `node tools/godot.mjs sync-art`。旧位图可以复用，程序线条/色块、拉长横图不能补缺。UI 中文字体和 OFL 许可也随清单同步。
- 场景是维护入口。`game/tools/import_rooms.mjs` 仅用于一次性迁移，拒绝覆盖已有场景；不要靠重新生成覆盖手工修正。
- 修改存档格式时同步校验、迁移与测试。独立目录 `WhalefallGame`；测试只写 `test-save.json`，不改用户 `save.json`。

## 验证

在仓库根运行 `node tools/godot.mjs check` 与 `node tools/godot.mjs test`。工具校验 `.godot-version`；不能只看 Godot 退出码，输出中的 `ERROR:` 和脚本错误也算失败。测试使用固定步长加速，驱动只在 `tests/`。

玩法/发布改动再执行：

1. `node tools/godot.mjs export-web`，需要匹配版本的 `web_nothreads_release.zip` 导出模板。只用 Web 单线程，Pages 没有隔离响应头。
2. `node game/tests/serve_web.mjs` 启独立 4187 服务，带 `/BOB/godot/` 前缀。不要刷新用户当前试玩页。
3. 用 Node 20+ 执行 `node game/tests/web_playthrough.mjs`。`PLAYWRIGHT_MODULE` 可指定已安装 Playwright，`CHROME_PATH` 指定浏览器；默认找 Playwright Chromium，再用本机 Chrome。`GAME_URL` 可指线上入口，`TEST_LABEL` 隔离证据目录。
4. 脚本创建独立浏览器上下文，以真实键盘通过五房、Boss、交互领取、三段冲刺沟；测试地图暂停与刷新续档。读取 `render_game_to_text()` 只观察状态，不改状态或用传送代替路线。
5. 查看 `game/build/qa/<label>/` 的截图与报告，检查角色接地、素材比例、遮挡、中文提示及界面。截图不自动代表用户认可美术；音效事件无错误也不等于试听通过。

桌面窗口复核可运行 `node tools/godot.mjs run -- res://tests/manual_preview.tscn`，这会开启隔离进度、不写实际存档。截图证据与工具链只保留本地。纯文档改动检查链接和 `git diff --check` 即可。

## 提交与发布

按根[持续交付流程](../../../AGENTS.md#持续迭代与边做边玩)提交已验证批次。运行 `node tools/deploy-pages.mjs`，合并 `/godot/` 并从 `game/pages/index.html` 更新根入口，默认跳转 Godot；保留 `mvp-v2/` 等历史目录和 `gh-pages` 历史，普通推送。仅修复默认入口时使用 `--entry-only`，不导出或替换已上线游戏包；验证根地址实际跳转、禁用 JavaScript 时的跳转、历史入口和游戏启动，游戏无变化时无需重复整条战斗路线。`--build-only` 只准备产物，不提交推送；准备后再次运行会拒绝未提交的 staging，先检查后显式处理，不要重置未知修改。

检查部署状态与线上 `godot/build.json` 的源码提交，再对线上入口运行同一浏览器路线。把源码提交、发布提交、结果和限制记入 `game/progress.md`。发布失败保留稳定远端，不把本地成功记成已上线。

## 已验证的恢复方式

- 导出模板缺失：安装对应固定版本的官方 Web 单线程模板，再重新导出；不降级引擎或改成线程版绕过。
- 首次导入依赖缺失：先确认清单源文件和 LFS 实体，再同步；UI Theme 在场景中加载，避免把尚未导入的字体设成项目启动主题。
- 构建目录也会被 Godot 导入：命令入口在 `game/build/` 创建 `.gdignore`，导出预设再次排除 `build/*`；导出清单不能出现验收截图或旧导出资源，Git 忽略规则本身不会阻止打包。
- Playwright 缺 Chromium：使用 `CHROME_PATH` 的现有浏览器或安装匹配浏览器；不要把浏览器无法启动算作玩法失败。
- 按键后立刻读状态会早一帧：等待目标条件，不用瞬时截图/读数判定暂停失败。
- 线上大包首载/刷新可能超过浏览器工具默认 30 秒：等待 `render_game_to_text` 就绪，传入明确的超时选项；不能把 `networkidle` 超时直接判成存档损坏。
- 入口仍靠近返回门：自动路线应先走到奖励范围再按交互，避免把连续 E 当成奖励领取失败。
