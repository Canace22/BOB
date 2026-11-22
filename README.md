# BOB · 鲸腹遗城 / 鲸落万物生

以「鲸落」为题材的 2D 战斗 + 收集探索游戏（类空洞骑士），使用 Godot 4.7.2 开发。

打开[在线试玩](https://canace22.github.io/BOB/godot/)即可进入须门遗港。当前正式版按房间加载，保留七房、过门衔接和 C 键鲸头地图。版本与验收见[工程进度](game/progress.md)。

在[原画集](docs/鲸腹遗城原画集/README.md)可以查看七房进阶总览、场景设计和后续制作素材。

## 在线页面

### 游戏与美术

| 入口 | 说明 |
| --- | --- |
| [世界观数据库](https://canace22.github.io/BOB/lore/) | 开发用设定卡片、全文搜索、腔室示意地图与章节路线，追溯原稿 |
| [默认在线试玩](https://canace22.github.io/BOB/) | 自动跳转到当前 Godot 正式版 |
| [Godot 版在线试玩](https://canace22.github.io/BOB/godot/) | 正式工程 `game/` 的 Web 导出 |
| [Godot 章节原型](https://canace22.github.io/BOB/godot-chapters/) | 独立发布的章节原型，入口为 `chapters-v1` |
| [Godot Boss 原型](https://canace22.github.io/BOB/godot-boss/) | 独立发布的母蟹 Boss 原型，入口为 `crab-prototype` |
| [美术资源在线预览](https://canace22.github.io/BOB/art/) | 搜索、筛选、放大与下载素材，查看需求及拼装预览 |
| [完整美术需求与缺项](https://canace22.github.io/BOB/art/requirements.html) | 查看资源家族、缺项、状态组合及房间需求映射 |

### 历史试玩与工具

| 入口 | 说明 |
| --- | --- |
| [V2 原画版在线试玩](https://canace22.github.io/BOB/mvp-v2/) | 冻结的 Canvas 2D 须门遗港原型 |
| [V2 旧四区试玩](https://canace22.github.io/BOB/mvp-v2/legacy.html) | 保留鲸口、胃库、肺缘与肋骨的旧四区玩法 |
| [地图与场景工作台](https://canace22.github.io/BOB/mvp-v2/scene-lab.html) | 查看旧四区的地图实体、场景分层和制作来源 |
| [历史 MVP 原型](https://canace22.github.io/BOB/mvp/) | 保留的早期试玩入口 |
| [历史梦魇原型](https://canace22.github.io/BOB/nightmare/) | 保留的 Nightmare 试玩入口 |

游戏与美术入口于 2026-11-03 核对过线上访问。世界观数据库单独发布；各入口的最新发布与验收以对应进度记录为准。

世界观页面从两份新稿生成，保留初稿与提案状态。本地运行 `node game/pages/lore/serve.mjs`，打开 http://127.0.0.1:4191/BOB/lore/ 。修改原稿后重新构建或重启服务即可同步；[使用与维护说明](docs/world-archive.md)。

## 目录

```
BOB/
├── game/        # 唯一开发目录：Godot 正式工程（代码、房间场景、运行素材、测试）
├── assets/      # 全局素材库、制作源与资源台账
├── docs/        # 架构说明、世界观与原画设计
├── tools/       # godot.mjs 命令入口、Pages 发布脚本
├── .agents/     # 项目 Skill
└── AGENTS.md    # 协作规则（AI 与人共用）
```

架构、模块与约定见 [docs/architecture.md](docs/architecture.md)。旧版本说明见 [legacy/README.md](https://github.com/Canace22/BOB/blob/codex/archive-legacy-20261103/legacy/README.md)。

2026-10-31 已完整恢复原 WhalebellyRuins 可玩内容。打开 `game/project.godot` 按 F5，默认运行原七房、CampaignPlayer、完整 3C/技能、Run 动画、HUD 及主地图环境动态；不再仅有独立环境预览。[恢复范围、操作与验收](docs/whalebelly-game-recovery.md)。旧模块化五房、旧动画预览与完整 `legacy/` 已移到[归档分支](docs/legacy-archive.md)。

## 当前内容

本地游戏启动进入首页，选择“开始旅程”或“继续旅途”；游戏中按 `Esc` 可直接“重新开始”或“返回首页”。重开需确认并备份旧档，操作和当前验证见[主工程说明](game/README.md)。

本地19房使用统一世界远景与完整地形母版切片；22处接缝已重绘岸线、路基和骨根，保留动态机关。对应[结构补绘与验收](assets/source/world-seam-repaint-v2/README.md)；线上仍以发布记录为准。

默认入口已恢复原 WhalebellyRuins：七房地形、道路与支路、逐帧拾潮者、短击/下劈/迎珠/重鸣/调息、能力门、Boss、营地、V6存档和镜头。R1-01 使用分层环境、62条鱼、垂须、气泡、水面与前景；15组动作库及84帧跑步保留；当前使用540张身体帧、180张独立特效帧，旧合成帧已归档。

R1-04使用之前训练场的母蟹Boss，现有地形和主角技能保持原样；击败后照常获得冲刺并打开出口。[操作与接入范围](docs/mother-crab-integration.md)。

R1-02至R1-07已继续接入独立四层环境与动件，保留原房间、碰撞和能力门。[六房制作源与方法](assets/source/r1-chapter-scenes/README.md) · [主工程操作](game/README.md)。本地实机验收页与录像在 `game/build/qa/r1-chapter-scenes/`；线上仍保留原稳定版。


2026-11-12 起，流膜育窝右侧出口通往胃肠沉城的胃枢（样板房，本地）。地图已精简为 19 房并全部接通：肺心、断脊、耳海三场 Boss 分别给出潮压、骨音、静默，三样齐备后在归海释放槽完成结局（本地，未发布）。范围见[精简实施范围](docs/鲸腹遗城原画集/连续世界设计/设计说明.md#2026-11-12-精简实施范围)。

主线已验证前五房至首关出口；支路机制专项通过不代表七房全部连续路线已验证。恢复细节与制作源清单见[恢复说明](docs/whalebelly-recovery.md)，实际测试与限制见 [game/progress.md](game/progress.md)。线上版本与本地验证状态以进度中的最新发布记录为准。

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

`PLAYWRIGHT_MODULE` 可指定现有模块路径，`GAME_URL` 指定验收服务地址。旧模块版及其专用测试已归档；当前按键验收使用 `web_whalebelly.mjs`。测试自动创建独立浏览器上下文，报告和截图在 `game/build/qa/`（不提交）。

## 操作（桌面键盘）

本地版已将 19 房接成连续地图：沿连接平台或竖井行走、跳跃即可跨房，普通跨房不按 E、不淡黑，主角和技能状态保持；相机严格居中、固定缩放。Boss 与能力门仍需满足条件，F 用于营地、奖励和结局交互。实现与验收见 [流式世界说明](docs/streaming-world.md)。本批未发布。

本地版右上角已加入房间小地图：当前房间亮金色，已探索与未探索房间区分显示，并标记营地、Boss 和受限通路；换房自动更新，`C` 打开完整地图。2026-11-18修复边缘镜头停滞：持续居中跟随玩家，新增随身柔光束，小地图靠近角色时淡出避让。显示规则见 [工程说明](game/README.md)。本批未发布。

启动先进入标题界面；有有效存档才可继续，新旅途覆盖前会确认并保留备份。`C`区域地图，`Esc`暂停与设置，`E`营地歇息；死亡动画后`R`返回检查点。UI使用真实5点生命/99点蓄振，常用技能消耗33点。共生配置系统尚未实现，营地两槽明确未开放。[正式UI说明与验收](docs/ui-system.md)。

`A/D` 移动，`空格` 跳跃 / 二段跳，`J` 站定普攻，`K` 三段斩（每段用 A/D 换向），`I` 格挡，`L/Shift` 冲刺，`A/D+L` 撞击挑空，`S+L` 后跳打断并留下当前姿势白影，后跳中 `J` 回斩；`W+J` 上挑，地面 `S+J` 横扫，空中 `S+J` 下刺。点按 `Q/E` 预选技能页，下方原有技能栏替换为四列显示 `+ J/K/I/L` 的技能与可用状态，预选保留 0.8 秒；`Q+E` 辅助页。`F` 营地 / 奖励 / 门交互，`W` 浮游，`G` 牵引，`C` 地图，`Esc` 暂停，`M` 静音，`H` 帮助。基础剑技开局可用，五段连斩与回旋沿用冲刺奖励，上涌 / 下潜沿用舌台奖励；存档取得条件不变。右侧显示实际命中的 Combo 数及续连倒计时，1 秒无命中归零。完整操作见游戏内帮助。

开场引导已接入首房：安全落地后自动对话；F / 空格 / Enter 继续，Esc 跳过并保留目标。营灯旁 F 查看刻痕，沿骨路前进触发行进字幕。隔离试玩入口和触发配置见[对话系统](docs/dialogue-system.md)。这是现有场景的引导样板，完整第一章叙事尚未接入。

## 发布

日常开发默认本地运行和验收，使用 `node tools/godot.mjs run` 即可试玩。完成任务不自动更新线上；以下发布流程仅在用户明确要求时执行。

```sh
node tools/deploy-pages.mjs
```

只更新世界观数据库时运行 `node tools/deploy-pages.mjs --lore-only`，仅发布 `/lore/`，保留所有游戏和美术入口。

导出 Web 版，合并进 `gh-pages` 分支的 `/godot/` 目录并正常推送，同时将根入口跳转到 `godot/`，保留 `mvp-v2/` 等历史版本目录。只修正默认入口时使用 `node tools/deploy-pages.mjs --entry-only`，不重新导出或替换游戏包。流程见 [AGENTS.md 的验证与交付规则](AGENTS.md#验证与交付)。

导出需要安装 Godot 4.7.2 官方模板中的 `web_nothreads_release.zip`。发布脚本在 `.pages-dist-godot/` 保留独立的 Pages 检出；`godot/build.json` 记录源码版本，推送后还需核实 Pages 部署和线上路线。

Web 导出后自动生成压缩下载文件与加载说明，浏览器缓存按内容哈希区分版本；支持的浏览器会复用已下载引擎和资源包。加载页会显示实际压缩下载量与启动阶段。原始文件保留，供缺少解压 API 的浏览器使用。首屏测速运行 `node game/tests/web_startup.mjs`，环境变量与上面的浏览器验收一致。

中文 UI 使用[字体子集](assets/source/noto-sans-sc/README.md)。新增中文后重建字体并运行素材同步；完整原字体保留在素材库，验收测试会检查缺字。

## 美术资源

正式画面只用入库的 2D 位图素材，规则见 [AGENTS.md](AGENTS.md#正式美术必须使用2d素材)。素材管理：[全局风格规范](assets/art-style.md) · [目录约定](assets/README.md) · [资源台账](assets/catalog.md)。管理页面：`npm --prefix assets/manager start`，打开 http://127.0.0.1:4176/ 。

运行图片经过[Framecraft 保真处理](assets/source/framecraft-runtime/README.md)，场景运行纹理另作轻度有损压缩，保留原件、尺寸和透明度。当前 Web 启动下载约 114.99 MiB。

大型素材使用 Git LFS。编辑器缓存、验收截图、第三方工具和日志不入库，见[迁移与提交范围](docs/workspace-migration.md)。

第一章的压缩循环样板入口为 `game/tests/whalebelly/chapter_loop_play.tscn`，可体验地面压退或上路观察突破，再衔接战后对话与下一目标。使用独立存档，完整章节和正式人物素材尚未交付；启动、占位和玩家验证问题见[第一章循环试玩](docs/第一章循环试玩.md)。

当前循环样板新增低扫、冲撞、二连钳读招；共用主线/白盒输入支持60ms组合容错和200ms下一招预输入，细节见[试玩说明](docs/第一章循环试玩.md)。

第一章样板的聚食怪现支持格挡破绽、首次反击加压和头顶阶段/压退进度；操作与验证边界继续见[循环试玩说明](docs/第一章循环试玩.md)。

统一敌人试验场入口：`res://content/prototypes/enemy_lab/main.tscn`。首批食腐甲、栖污大甲、负壳守卫可切换单怪/混编，支持实际窗口、判定与逐帧调试；启动、操作及代理边界见[试验场说明](game/content/prototypes/enemy_lab/README.md)。

敌人试验场已提供有限架势的按住I格挡、完美格挡反击及三套独立动作样板，操作与验收边界见[试验场说明](game/content/prototypes/enemy_lab/README.md)。

统一敌人试验场新增膜上捕食者：F1切至第4项，可体验扑击落地反击、回挂及左侧遮蔽脱战，详见[操作说明](game/content/prototypes/enemy_lab/README.md)。

捕食者新增受压后收伞喷水脱身，水弹可格挡或跳开；落地短连招仍有效，详见[试验场说明](game/content/prototypes/enemy_lab/README.md)。

统一敌人试验场新增第5项缠巢鳗：潜地换位突击、三卵布巢接扑咬，保留头咬与低扫，操作和当前验证边界见[试验场说明](game/content/prototypes/enemy_lab/README.md)。

统一敌人试验场第6项为泵庭执卫：架开长柄并向右通过窄道安全线即可停战，普通/完美格挡对跟进二刺作用不同。操作与验证边界见[试验场说明](game/content/prototypes/enemy_lab/README.md)。

膜泵场景互动保留为手选关卡样板：观察泵送节拍、靠近按F泄压。Boss自身能力以随身压囊水术为准。

泵庭执卫默认改为自身水术Boss验证：三连水弹、追击水龙卷、水遁回刺，黄亮压囊可从背侧打断。默认无泄压瓣；膜泵互动与撤离窄道从场地菜单另选。


敌人试验场第7项已加入封梁卫反追击样板：退步回刃、主动格挡/防御回刃、真实受击架叉反推、绕背拆架；操作与验证边界见[试验场说明](game/content/prototypes/enemy_lab/README.md)。仅本地独立验证，主线尚未接入。


敌人试验场第8项加入老守护者：撑柄贯刺、两段换握、真实撑跃换侧、可压制的回稳与观招复制玩家技能，固定非致死解除武装；[操作和当前实现边界](game/content/prototypes/enemy_lab/README.md#第8项老守护者撑柄控距与换握)。仅独立本地验证，主闸关卡/演出尚未接入。

老守护者最终Boss样板已提高追击与连招频率，观招库覆盖全部战斗/辅助技能及强化变体；试验场F7显式全技能练习，R清敌人招式记忆，详情见试验场README当前修订。

老守护者复制技能现由完整主角幻影播放对应动作，身体、特效与实际攻击时序同步；试验场第8项可体验。

战斗动作V2已接入共用玩家呈现、八类章节敌人与第一章食腐甲：新增准备/出手/收招帧及只读起手FX，普攻前摇100ms、总时长保持，防御撤招与60ms组合容错/200ms预输入保持。十二章补入七种静态人物形象；素材数量、来源、试玩入口和技术/审美边界见[动作批次](assets/source/combat-animation-v2/README.md)。统一敌人试验场仍使用上方同一入口，未发布Web版。

敌人动作[补查修订](assets/source/combat-animation-v2/followup/README.md)补上捕食者回挂与老守护者回稳，重绘大甲压砸与负壳顶壳的准备动作。试验场入口和按键保持，逐阶段覆盖检查与真实出招检查分别记录。

敌人不同技能的[显示比例](assets/source/combat-animation-v2/scale-registration.md)以各自待机的固定身体单位校准，整套动作保持同一比例；没有按出招包围盒逐帧放大缩小，碰撞和技能时序保持。

三类人形敌人的[动作节奏](assets/source/combat-animation-v2/humanoid-timing.md)采用慢蓄势、短暂停顿、快速到位和惯性收招；画面按真实命中/发射点取帧，保持原攻击频率和格挡反击窗口。

现有正式19房现已接入[十二章保底主线](docs/现有地图章节保底接入.md)：Boss、NPC、任务与结局按章节推进，F交互与自动对白共用既有对话框，并加入角色头像。新地图继续独立开发；本版复用现有地形和流式通路。历史存档保留原物品/能力/位置，尚未体验的新故事从第一章开始补接；建议用“重新开始”体验完整次序。验证范围和已知主干问题见`game/progress.md`，当前未发布Web版。
