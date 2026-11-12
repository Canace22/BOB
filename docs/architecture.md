# 鲸落 Godot 架构

正式工程位于 `game/`，固定 Godot 4.7.2、GL Compatibility、Web 单线程。F5 默认进入 `content/whalebelly/main.tscn`，运行 WhalebellyRuins 七房、CampaignPlayer、角色技能和环境动态。旧模块化五房及完整旧目录已移到[归档分支](legacy-archive.md)。

七房默认使用角色跟随镜头，Tab统一切换跟随/全景；原图对照、截图和分层查看保留全景行为。F9为会话临时练习，退出恢复正式进度快照；F10仅在练习中切换基础/升级技能组，不改正式取得条件。

当前正式入口按房间加载，使用[须门遗港场景衔接](../assets/source/xumen-continuity-v1/README.md)的共用远景、连接动件和过门混合。后续[实际连通场景](../assets/source/xumen-connected-v2/README.md)及[统一母版](../assets/source/xumen-unified-v1/README.md)的制作源仍保留在资源库。

## 代码与内容

| 路径（相对 game/） | 职责 |
| --- | --- |
| `src/campaign/main.gd` | 七房切换、机关、敌人/Boss、能力、营地、HUD、V6进度 |
| `src/campaign/tide_player.gd`、`campaign_player.gd` | 完整角色动作与技能、主关卡参数适配、动画事件 |
| `src/campaign/action_visual.gd`、`tide_world_effects.gd` | 正式主角的可变帧图集、实际状态/阶段映射、世界特效与历史残影；物理由角色控制 |
| `src/campaign/tide_action_phases.gd` | 晶长冲蓄力/飞行/退出的呈现阶段，退出尾帧不延长控制锁定 |
| `src/campaign/tide_skill_catalog.gd`、`tide_skill_controller.gd` | 增量技能参数、解锁与时间轴，复用旧角色/房间/进度接口 |
| `src/campaign/campaign_run_visual.gd` | 保留旧跑步适配器供兼容；正式主角只实例化新视觉桥，避免双重显示 |
| `src/campaign/campaign_camera.gd`、`mechanisms.gd` | 镜头（前视、上下探看、下落前置）和机关表现 |
| `src/campaign/campaign_impact.gd` | 命中与受击的全场定格，按物理帧计数并保证恢复时间流速 |
| `src/campaign/campaign_save_bridge.gd` | V6用户目录隔离及有效旧档首次复制 |
| `src/campaign/campaign_world.gd` | 后续区域的房间表、按房间 ID 的门目标、能力与进度标记组合条件、地图分页落位 |
| `content/whalebelly/world/`、`tools/build_world_rooms.mjs` | 套件房配方（单位 U）、跨区链接与生成的运行数据；生成器读取资源台账的包围盒与锚点，输出 `content/whalebelly/<区>/<房间ID>.tscn` |
| `src/world/scenery/kit/` | 套件房的位图层视差、漂移粒子场（漂脂、水流线）和透光明暗 |
| `src/campaign/enemies/kit_encounter.gd`、`kit_swarm_visual.gd` | 程序驱动的敌人与 Boss：群体横穿、鸣贝吐珠、覆膜回声；位图来自台账，行为写在房间配方的 `enemies` 中，伤害、血条、击败存档沿用主线 |
| `src/campaign/campaign_relics.gd` | 按既有奖励ID计算护盾上限，管理本次旅途剩余护盾；主角在偏转/无敌判定后扣盾，超额伤害沿用原受击流程 |
| `src/campaign/boss/` | 母蟹三招、阶段连招、护壳/破防和逐帧显示；通过主线敌人字典及 `R1-04:0` 连接奖励与存档 |
| `src/campaign/enemies/` | 普通尸蟹物理/状态与图集呈现，复用主线伤害和房间生命周期；[接入合同](corpse-crab-integration.md) |
| `src/core/`、`content/data/world_graph.gd` | 保留的兼容状态/存档校验，不再包含旧版关卡场景加载入口 |
| `src/ui/` | 正式标题、HUD、模态页面与设置；注入主线宿主，只读实际状态并请求主线操作。旧 tide_hud 保留给独立角色参数场 |
| `content/whalebelly/r1/` | 七个房间场景、道路碰撞、分层贴图和节点 |
| `content/whalebelly/environment/` | 当前环境场景、各动件脚本/Shader；保留恢复阶段的组织方式 |
| `content/whalebelly/Player.tscn`、`CampaignPlayer.tscn` | 角色动作与主线参数 |
| `art/` | 由清单同步的运行副本，手工修改源文件应在 assets/ |
| `tests/whalebelly/` | 当前角色、战斗、路线、环境及存档专项验证 |

恢复阶段保留原主循环的兼容实现。后续按功能渐进拆分，不用旧模块版替代现有角色、七房或动态效果。运行逻辑使用稳定ID；创作状态和用户美术确认分别记录。

## 资源归属

`game/art/manifest.json` 同步当前资源，所有来源均在 `assets/`；实际数量以资源审计为准。既有856张图片经过[Framecraft保真压缩](../assets/source/framecraft-runtime/README.md)，画布、可见像素和Alpha不变；9个 `.framecraft` 工程保留原件与结果。新36动作制作、源片选段与透明图集见[制作源](../assets/source/tide-picker-action36/README.md)，其候选/验收状态不沿用旧素材结论。文本、遮罩、音频及字体在 `assets/runtime/godot-support/` 等库目录保存。

后续111张图片由Framecraft增量批次保真处理，额外保留两个源工程；50张场景的Godot导入改为质量0.9的轻度有损编码，保持原PNG、像素尺寸、Alpha与坐标。角色和特效仍为保真导入。处理与运行包体分别统计，配置和恢复说明见[本批记录](../assets/source/framecraft-runtime/batches/2026-11-04/README.md)。

动作本体与FX可有独立帧数；世界环读取图层 `frame_count`/`event_frame`，按真实释放或落地启动，不随本体帧索引截断。影潮穿行复用dash本体并施冷青色调，深钟复用dive本体及地面环，保留各自伤害/范围/无敌逻辑；这些不是独立生成的两套美术。逐项来源、复用、参数和待验状态见[36项资产覆盖](action36-asset-coverage.md)，根目录 `build_asset_coverage.py` 可按实际清单及哈希绑定验收记录重建。

`content/whalebelly/runtime-resources.json` 记录当前资源及引用拥有者。`node game/tools/audit_resources.mjs` 从正式入口、当前角色参数场、Run与环境预览检查引用，并展开身体/特效帧、七房、鱼群和音效的动态路径。它采用保守的路径族检查；新增加载方式时同步维护审计规则，再做实机验证。

`recovery-manifest.json` 保留2026-10-31恢复时的1914项历史来源，不再充当当前文件必须全部存在的清单。未使用的旧合成帧、旧动画预览、重复环境与旧模块资源已归档；可复用原画库和未来区域素材仍保留。

## 存档

正式主线使用 `user://whalebelly/artmatch_save.json`（V6）。桌面首次启动仅在目标不存在时复制原 `WhalefallArtmatchV05` 的有效存档，保留原件；已有目标不覆盖。浏览器使用自身站点存储。保留的兼容存档服务有独立的 `user://save.json`，不能混作主线V6进度。

测试只写独立测试档，真实浏览器使用独立上下文。隔离试玩入口为 `tests/whalebelly/manual_play.tscn`。

牵引圆环是基础探索操作；读取旧V6时将`abilities.anchor`归一为true。`collected["R1-07"]`表示记忆袋奖励，领取时解锁浮游、恢复生命与蓄振；旧档已收集该奖励时补齐浮游，不重置检查点或其它能力。地图详情按同一收集ID显示可重读记忆。

UI新版保留V6结构并增加可选`visited`房间ID字典。发现定义为正式进入房间，同时在地图显示其配置的相邻出口；房间预览不登记、练习不保存。旧档至少恢复检查点及明确获得奖励/击败Boss的房间，不猜测其余历史路线。原子写入保留`.bak`，确认新旅途另保留`.before-new`；标题与加载共用V6校验。UI设置独立存于`ui_settings.cfg`，不混入玩法状态；QA使用`ui_qa_settings.cfg`。

## 命令与验证

在仓库根目录运行，需要Node.js 18+、Git LFS和Godot 4.7.2。命令入口依次查找 `GODOT`、`.tools/godot/` 和已配置的本机引擎。

```sh
node tools/godot.mjs sync-art
node tools/godot.mjs check
node tools/godot.mjs test
node tools/godot.mjs run
node tools/godot.mjs export-web
node game/tests/serve_web.mjs
node game/tests/web_whalebelly.mjs
```

`check`加载全部脚本和场景；`test`执行当前单元测试。日志中的脚本错误和 `ERROR:` 都算失败。浏览器验收另需Node.js 20+、Playwright与可用Chrome/Chromium；通过真实键盘验证移动、跳跃、短击、迎珠、暂停、营地和刷新续档。专项连续路线在 `tests/whalebelly/campaign_route_test.gd`；状态接口 `render_game_to_text()` 只读。

## Web发布

`node tools/deploy-pages.mjs` 导出单线程Web版，更新已有 `gh-pages` 的 `/godot/` 和默认根入口，普通推送，保留V2等在线历史目录。需要匹配版本的 `web_nothreads_release.zip` 模板。

Pages检出使用 `blob:none` 和稀疏工作目录，只展开Godot、根入口及 `.nojekyll`；其他页面在Git树中保留。同步合并关闭差异统计，避免旧版Git为输出统计而下载未展开的大型图片。并发发布导致推送非快进时，保留发布提交，获取并合并远端后普通推送，检查Godot范围外与远端一致。

导出后 `tools/prepare-web.mjs` 生成带内容哈希的gzip和 `downloads.json`；`game/web/preload.js` 接管引擎与PCK的下载、浏览器流式解压及独立资源缓存。大包分别拆为64MiB的压缩/原始分片，并检查分片及串接SHA256；缺少解压API的浏览器使用原始分片。导出保留原文件，发布只在完整原始分片覆盖后省略超限单文件。缓存只管理启动资源，不清理存档。导出排除构建证据、测试、工具和制作源；最终线上启动结果另见进度。

中文UI使用[字体子集](../assets/source/noto-sans-sc/README.md)。新增中文后重建并运行字形覆盖测试。发布后核对部署状态、实际 `build.json`、当前入口和线上键盘路线；源码提交、发布提交、测试和限制记录在 [game/progress.md](../game/progress.md)。

## 后续区域与套件房

设计地图为 5 区 36 房（[连续世界设计](鲸腹遗城原画集/连续世界设计/设计说明.md)），实施范围已精简为 19 房。R1 七房仍由 `art/whalebelly/rooms.json` 定义，后续区域追加在其后，序号不变。精简后的 12 个新房间已全部接入，门都是可见骨拱门并按交互键进入。Boss 击败后的授予（`grants`）和归海释放的条件（`reward_requires`）同样写在配方里。房间在运行表中的顺序由配方 `_world.json` 的 `order` 决定，只能在末尾追加，因为检查点按序号保存。指引、房间说明、推荐下一房和奖励授能都写在配方里。

- 门用 `to_id` 指向房间 ID；`requires` 列出能力和进度标记，`locked` 表示要从对侧开启。标记与能力同存于 V6 的 `abilities` 字典。跨区入口写在配方 `_world.json` 的 `links`，不修改 R1 原始数据。
- 新房间先写配方，再运行 `node game/tools/build_world_rooms.mjs` 和 `node tools/godot.mjs sync-art`。生成的场景和 `world/rooms.json` 不手工修改；需要调整时改配方或台账后重新生成。
- 房间名与门提示来自生成数据，字体子集脚本和覆盖测试已包含 `world/rooms.json`。Web 导出的 `include_filter` 已加入该文件。
- 实机路线用 `tests/whalebelly/world_skeleton.gd`，`-- --reload-world` 验证独立进程读档，`-- --views` 只出定点截图。
- 地图每区一页，节点坐标写在配方 `_world.json` 的 `map`，是底图上的比例位置。须门遗港页的底图是鲸头特写，其余各页共用全鲸剖面图，同一房间在这些页上用同一坐标。改坐标后看 `-- --views` 输出的五张地图截图；节点重叠和跨页不一致由 `test_campaign_world.gd` 检查。
