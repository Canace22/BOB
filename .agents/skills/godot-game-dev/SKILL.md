---
name: godot-game-dev
description: 在BOB的game/正式Godot工程开发、修复与接入，执行资源审计、headless及真实浏览器验收并发布Web版。
---

# BOB Godot正式开发

先读[架构](../../../docs/architecture.md)、[工程规则](../../../game/AGENTS.md)和[进度](../../../game/progress.md)，核对 `project.godot`。当前默认入口是 `content/whalebelly/main.tscn`。完整旧工程、模块化五房、旧资源与专用测试已移到 `codex/archive-legacy-20261103`，按[归档说明](../../../docs/legacy-archive.md)独立检出。

## 开发与资源

- 源码在 `game/src/campaign/`，房间在 `game/content/whalebelly/r1/`，当前环境在 `game/content/whalebelly/environment/`。保持稳定ID、原角色技能、七房内容和V6存档；不以旧静态版本替代已恢复的动态效果。
- 素材先入 `assets/` 并维护台账，再写 `game/art/manifest.json`、运行 `node tools/godot.mjs sync-art`。当前清单不依赖 `legacy/`；正式画面遵循根2D美术规则。
- 已有精灵/图集的整理与压缩用个人 `2d-sprite-animation` Skill的Framecraft流程。可批量调用真实本机接口，原件与实际输出一并存 `.framecraft`，保存后重开。BOB已验证配方见[压缩批次](../../../assets/source/framecraft-runtime/README.md)。
- 手绘素材优先原尺寸保真PNG、阈值0、锐化0；逐张比较尺寸、可见RGBA与Alpha，只清理全透明像素的隐藏RGB。若输出更大，保留原文件并记录实际平台结果。调色板会改变颜色/半透明边缘，不能将它称为无损。
- 不把进入同步清单当作当前在用。归档前从正式入口、七房、现用角色参数场和预览检查引用，保守展开动态加载；使用 `node game/tools/audit_resources.mjs` 和 `runtime-resources.json`。确认旧版专用的资源、消费者、专用测试及同步项一起移出。原画库和未来区域素材不因尚未接入而自动归档。
- 保存完整归档分支并普通推送后，再移出当前分支；只改本批相关文件。已存在的无关修改保留。一次性恢复工具与历史清单不当作当前验收入口。

## 验证

1. 仓库根运行 `node tools/godot.mjs check` 和 `node tools/godot.mjs test`。固定Godot4.7.2，日志中的脚本错误和 `ERROR:` 都算失败；现用测试与旧版已归档测试分别计数。
2. 对图片批次运行 `python assets/source/framecraft-runtime/compress.py --verify`，检查源工程、哈希、像素、Alpha和当前清单来源存在。验证实际导出文件，不只相信界面设置。
3. 当前主线连续路线使用 `tests/whalebelly/campaign_route_test.gd`，仅写QA存档；真实按键Web验证使用 `web_whalebelly.mjs`，不能再用旧模块版的 `web_playthrough.mjs`。
4. `node tools/godot.mjs export-web` 后，运行 `node game/tests/serve_web.mjs` 的独立4187服务；用Node20+和Playwright执行 `node game/tests/web_whalebelly.mjs`。`PLAYWRIGHT_MODULE`指定现有模块，`GAME_URL`指定入口，`TEST_LABEL`隔离证据。
5. 查看 `game/build/qa/` 的实际截图，检查角色接地、素材比例、透明边缘、遮挡、中文和动态效果；技术检查不等于用户美术认可。截图、自动报告和视频只留本地。

## 存档与发布

主线V6在 `user://whalebelly/`。`CampaignSaveBridge`只在目标不存在时复制有效旧档。测试、捕获及隔离试玩不导入真实进度；浏览器使用独立上下文，不刷新用户正在玩的页面。

按根[持续交付流程](../../../AGENTS.md#持续迭代与边做边玩)提交已验证批次，提交不含AI署名。运行 `node tools/deploy-pages.mjs`，普通推送 `gh-pages`，保留在线历史目录。只更新根入口时用 `--entry-only`；`--build-only`产生未提交staging后须先核对，不重置未知修改。

推送后检查部署成功、线上 `godot/build.json` 的源码提交和当前入口，再跑受影响线上按键路线。把源码/发布提交、结果和限制写入 `game/progress.md`；推送成功不能直接当作上线成功。

## 恢复与边界

- 新资源引用要覆盖动态拼接路径；字体必须嵌入并检查中文覆盖。本机正常不证明Web正常。
- `game/build/` 要有 `.gdignore`，导出排除测试/工具/证据；Git忽略不等于Godot不会打包。
- Web模板缺失时安装固定版本的官方单线程模板，不降级引擎。Chromium缺失可用 `CHROME_PATH` 或已安装Chrome，不把工具缺失算玩法失败。
- Pages检出只展开 `/godot/`、根入口和 `.nojekyll`，使用 `blob:none` 保留其余版本的Git树。Git2.32需要先 `sparse-checkout init --no-cone`，再 `set` 路径；不要把 `--no-cone` 传给旧版 `set`。拉取后的合并用 `--no-stat`，避免统计差异时触发无关美术大文件的懒下载。
- 并发Pages发布导致非快进拒绝时，保留本地发布提交，重新fetch远端并正常merge（`--no-stat`），检查 `/godot/` 外与远端一致后普通push；不强推，也不为重试重复导出。真实内容冲突先检查归属，再处理。
- Web大包启动等待只读状态就绪，使用明确超时；不以 `networkidle` 超时判存档损坏。按键后等待状态条件，不做同一帧瞬时判定。
- 场景、参考图与环境动态继续配合[场景环境Skill](../scene-environment-motion/SKILL.md)，本Skill负责正式工程接入、测试和发布。
