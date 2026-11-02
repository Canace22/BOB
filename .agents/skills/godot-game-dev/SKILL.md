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

- 首屏性能：先用 `game/tests/web_startup.mjs` 记录线上冷/暖启动、Resource Timing 传输字节；HEAD 的未压缩长度不代表浏览器实际下载量。测速时避免其他下载/路线回归争用同一网络。
- 导出后由 `tools/prepare-web.mjs` 生成 gzip 和内容哈希，`game/web/preload.js` 只接管两个启动文件并使用独立资源缓存；原始包保留供无解压 API 的浏览器回退。`STARTUP_FALLBACK=1` / `STARTUP_NO_CACHE=1` 分别验证解压缺失和缓存不可用。
- 新增中文后按[字体制作说明](../../../assets/source/noto-sans-sc/README.md)重建子集并同步；字体覆盖测试必须通过。场景图压缩改 `.import`，不缩图或改裁片坐标；复核游戏实际截图。

- 导出模板缺失：安装对应固定版本的官方 Web 单线程模板，再重新导出；不降级引擎或改成线程版绕过。
- 首次导入依赖缺失：先确认清单源文件和 LFS 实体，再同步；UI Theme 在场景中加载，避免把尚未导入的字体设成项目启动主题。
- 构建目录也会被 Godot 导入：命令入口在 `game/build/` 创建 `.gdignore`，导出预设再次排除 `build/*`；导出清单不能出现验收截图或旧导出资源，Git 忽略规则本身不会阻止打包。
- Playwright 缺 Chromium：使用 `CHROME_PATH` 的现有浏览器或安装匹配浏览器；不要把浏览器无法启动算作玩法失败。
- 按键后立刻读状态会早一帧：等待目标条件，不用瞬时截图/读数判定暂停失败。
- 线上大包首载/刷新可能超过浏览器工具默认 30 秒：等待 `render_game_to_text` 就绪，传入明确的超时选项；不能把 `networkidle` 超时直接判成存档损坏。
- 入口仍靠近返回门：自动路线应先走到奖励范围再按交互，避免把连续 E 当成奖励领取失败。
- 独立战斗原型：`src/prototype/crab_arena.tscn` 在子节点初始化前隔离 GameState，禁止自动保存，退出恢复原运行状态。`PlayerTuning.prototype_controls` 必须显式开启，不改变主线默认手感。原型 Web 用 `?prototype=crab` 或 `/godot-boss/`，以 `tests/web_crab_prototype.mjs` 的独立上下文真实按键验收，低扫需要按住跳跃而非短点 Space。
- 训练场技能通过 `TrainingSkills` 单独接入；生命上限、治疗、护盾与重试一起验证，不能只改 HUD 的血格。远程 `HitData.ranged` 不计近战回能、护盾或破防。临时弹体释放后再发第二次是必要回归：Godot 的类型化 lambda 在接收已释放对象时会先转换失败，检查有效性之前不要把失效对象传进类型参数；测试必须真正等待销毁，不能只调用 `queue_free()` 就声称覆盖。
- 边做边玩采用已验证小批：原型发布用 `node tools/deploy-pages.mjs --prototype`，仅更新 `/godot-boss/`，不替换用户当前主线。核对部署差异、线上 `godot-boss/build.json` 和受影响路线，及时给用户可试玩链接；静态关键姿态与正式动画的限制必须明确记录。
- 测试脚本解析失败：runner 应报告不能实例化的 suite 并退出失败，不能在引擎窗口永久等待；先跑 `check` 再跑 `test`，不要仅看导入进程完成。并行代理写文件可以，Godot import/test/export 由一处串行安排，避免共享导入缓存竞争。
- 玩家序列帧接入：公共画布/pivot、两向独立文件、逐帧时长和步幅以 `assets/runtime/sprites/tide-picker-animation-v2/animations.json` 为准；来源和导出见[制作说明](../../../assets/source/player-animation-v2/README.md)。攻击有效段必须落在帧边界；跑步按实际位移推进，不能只看全局时钟。素材缺项会显式回退旧图，验收须用只读 `player.animation.using_directional` 和实际文件路径确认新素材正在加载。
- 动作专项按键路线：`tests/web_player_animation.mjs` 分完整/基础移动两种范围，保存两向姿势、暂停、撞墙与录屏；有限状态测试不能替代整圈换腿、脚滑和实际画面复核。Mac 引擎默认位置已由命令入口支持，仍严格检查项目固定版本。
- 环境图集复用：保持原单元和固定根点，以 `AmbientAtlas` / `AmbientFishSchool` 及场景导出属性控制播放和摆放；动画继承 World 的暂停/顿帧，不用系统时间绕过暂停。源图、成员相位和固定来源提交记录在 `assets/source/crab-environment-main/`，`tests/web_environment_motion.mjs` 检查实际图集、完整周期及按键暂停；洞顶遮挡与战斗可读性仍要看截图和连续播放。全量 `sync-art` 可能重新编码其他派生 PNG，提交前检查并排除无关差异；恢复 LFS 文件时用正常 checkout/smudge，不能把 `git show` 的指针文本写成 PNG。
