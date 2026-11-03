# 鲸落 Godot 架构

正式工程位于 `game/`，固定 Godot 4.7.2、GL Compatibility、Web 单线程。F5 默认进入 `content/whalebelly/main.tscn`，运行 WhalebellyRuins 七房、CampaignPlayer、角色技能和环境动态。旧模块化五房及完整旧目录已移到[归档分支](legacy-archive.md)。

## 代码与内容

| 路径（相对 game/） | 职责 |
| --- | --- |
| `src/campaign/main.gd` | 七房切换、机关、敌人/Boss、能力、营地、HUD、V6进度 |
| `src/campaign/tide_player.gd`、`campaign_player.gd` | 完整角色动作与技能、主关卡参数适配、动画事件 |
| `src/campaign/campaign_run_visual.gd` | 当前84帧/12FPS跑步；物理由角色控制 |
| `src/campaign/campaign_camera.gd`、`mechanisms.gd` | 镜头和机关表现 |
| `src/campaign/campaign_save_bridge.gd` | V6用户目录隔离及有效旧档首次复制 |
| `src/core/`、`content/data/world_graph.gd` | 保留的兼容状态/存档校验，不再包含旧版关卡场景加载入口 |
| `content/whalebelly/r1/` | 七个房间场景、道路碰撞、分层贴图和节点 |
| `content/whalebelly/environment/` | 当前环境场景、各动件脚本/Shader；保留恢复阶段的组织方式 |
| `content/whalebelly/Player.tscn`、`CampaignPlayer.tscn` | 角色动作与主线参数 |
| `art/` | 由清单同步的运行副本，手工修改源文件应在 assets/ |
| `tests/whalebelly/` | 当前角色、战斗、路线、环境及存档专项验证 |

恢复阶段保留原主循环的兼容实现。后续按功能渐进拆分，不用旧模块版替代现有角色、七房或动态效果。运行逻辑使用稳定ID；创作状态和用户美术确认分别记录。

## 资源归属

`game/art/manifest.json` 仅同步当前引用的930个文件，所有来源均在 `assets/`。其中856张图片经过[Framecraft保真压缩](../assets/source/framecraft-runtime/README.md)，画布、可见像素和Alpha不变；9个 `.framecraft` 工程保留原件与结果。文本、遮罩、音频及字体在 `assets/runtime/godot-support/` 等库目录保存。

`content/whalebelly/runtime-resources.json` 记录当前资源及引用拥有者。`node game/tools/audit_resources.mjs` 从正式入口、当前角色参数场、Run与环境预览检查引用，并展开身体/特效帧、七房、鱼群和音效的动态路径。它采用保守的路径族检查；新增加载方式时同步维护审计规则，再做实机验证。

`recovery-manifest.json` 保留2026-10-31恢复时的1914项历史来源，不再充当当前文件必须全部存在的清单。未使用的旧合成帧、旧动画预览、重复环境与旧模块资源已归档；可复用原画库和未来区域素材仍保留。

## 存档

正式主线使用 `user://whalebelly/artmatch_save.json`（V6）。桌面首次启动仅在目标不存在时复制原 `WhalefallArtmatchV05` 的有效存档，保留原件；已有目标不覆盖。浏览器使用自身站点存储。保留的兼容存档服务有独立的 `user://save.json`，不能混作主线V6进度。

测试只写独立测试档，真实浏览器使用独立上下文。隔离试玩入口为 `tests/whalebelly/manual_play.tscn`。

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

导出后 `tools/prepare-web.mjs` 生成带内容哈希的gzip和 `downloads.json`；`game/web/preload.js` 接管引擎与PCK的下载、浏览器流式解压及独立资源缓存。保留原始包用于缺少解压API的浏览器。缓存只管理启动资源，不清理存档。导出排除构建证据、测试、工具和制作源。

中文UI使用[字体子集](../assets/source/noto-sans-sc/README.md)。新增中文后重建并运行字形覆盖测试。发布后核对部署状态、实际 `build.json`、当前入口和线上键盘路线；源码提交、发布提交、测试和限制记录在 [game/progress.md](../game/progress.md)。
