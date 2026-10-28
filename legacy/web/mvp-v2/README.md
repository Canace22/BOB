# 鲸落万物生 · V2

当前主线采用 V5.2 的房间与能力设计，原生 Canvas 2D / WebAudio。公开试玩：[GitHub Pages](https://canace22.github.io/BOB/mvp-v2/)。按主线顺序逐区上线；当前批次为 **须门遗港五间主线房**。全设计的 36 房尚未全部实现。

## 本批玩法

外伤坡的走跳与营地 → 须筛的尸蟹与危险通道 → 舌台双蟹与生命碎片 → 负壳蟹门庭战斗 → 战后交互取得贴流冲 A1 → 流膜育窝三段冲刺沟。育窝终点提示下一批胃枢；A2 / A3 高层支路保留门槛，当前不可进入。H1 清流窝为可选回访互动。

坡面、平台、上下层和沟口均参与碰撞；地图 M 显示当前房间实际地形与位置。首领横扫与壳砸有不同的预告范围，半血后的第二次横扫另有预告。静止碰触身体不掉血。营地按 E 登记并恢复；死亡返回登记营地，能力、奖励、首领胜利保留。敌人战斗状态在重试及离开后重置。

| 默认按键 | 动作 |
| --- | --- |
| A / D、← / → | 移动 |
| 空格 | 跳跃 |
| Q | 短击，命中补充蓄振 |
| R | 重鸣，消耗 2 蓄振 |
| E | 营地、奖励、能力与通路交互 |
| Shift | 取得 A1 后贴流冲 2.6U；落稳刷新 |
| H | 调息恢复 1 生命，消耗 2 蓄振，受伤打断 |
| L | 提灯 |
| M / Esc | 地图 / 暂停 |

HUD「按键」可重绑定并自动保存。初始生命 4、蓄振上限 4；四片生命碎片增加一格生命（本批主线一片）。攻击范围、生命等来源与临时调试值见 [CAMPAIGN.md](CAMPAIGN.md)。静态角色素材配程序动作反馈，尚非正式动作动画。

右侧「任务追踪」常驻显示当前主线、目标勾选与计数，以及已解锁的可选任务。本章共6项主线：踏入须门、穿过须筛、前往蟹门、击败负壳蟹、承接贴流冲、穿越流膜育窝；完成后自动接续下一项。生命碎片和清流窝为可选任务，不阻挡主线。点击追踪栏标题或右下「任务」暂停打开任务面板，可查看目标地点、完成方法和已完成记录；「操作帮助」查看按键说明。进度由实际到访、首领胜利、能力及收集状态计算，继续旧档和死亡回营后保留，重新开始会重置。靠近营地、奖励或出口会显示交互按键；改键后操作说明同步更新。

新主线使用 `whalefall-v52-save`。旧四区试玩保留在 [legacy.html](legacy.html)，沿用 `whalefall-v2-2d-save`，原玩法和回访路线见 [旧四区说明](LEGACY.md)。地图工作台 `scene-lab.html` 仍描述旧四区；新主线地图在游戏内 M 打开。不同站点/浏览器存档互不迁移。

## 边做边玩与开发

用户试玩以 GitHub Pages 为准。每批本地验证后发布，已打开的游戏可继续游玩，发布完成后刷新进入新版。本地快照为开发工具，不能替代公网交付。

```sh
# 仓库根目录，Node.js 18+
npm --prefix mvp-v2 run dev
# 默认4176；与美术管理服务冲突时用PORT选择空闲端口
npm --prefix mvp-v2 run publish:preview
npm --prefix mvp-v2 start
# 稳定快照默认4175
npm --prefix mvp run build:pages
# 用户要求发布时执行
npm --prefix mvp run deploy
```

本地快照将整个页面固定在版本 URL；新主线通过重新打开快照首页进入更新。旧四区另保留游戏内「新版就绪」提示。发布包含两套 V2 入口和选用的 42 张 WebP，不打包全量原始素材。导出约 1.87 MiB，封面与回退图另约 436 KiB。资源制作源、来源关系与导出约定见 [资源管理说明](../assets/README.md)。

## 验证

```powershell
$env:GAME_URL='http://127.0.0.1:4177/' # 设为实际开发服务
npm --prefix mvp-v2 run check
npm --prefix mvp-v2 test # 旧四区回归，自动跳转legacy.html
npm --prefix mvp-v2 run test:campaign # 新主线逻辑、UI和真实按键全路线
node mvp-v2/tests/art-integration.mjs # 旧四区全部清单图加载和缺图回退
```

浏览器测试需 Node.js 20+ 与 Playwright/Chromium；脚本支持已有浏览器/桌面内置依赖，独立浏览器上下文不会读取日常浏览器存档。新主线测试暴露 `render_campaign_to_text()` 只读状态和 `advanceTime(ms)` 确定推进；路线验证通过真实键盘，未改写角色或战斗状态。旧四区使用 `render_game_to_text()`。

当前源码职责：`campaign-levels.js` 数据和世界连接、`campaign-engine.js` 移动/战斗/存档、`campaign-renderer.js` 画面、`campaign-game.js` 输入/UI、`campaign-quests.js` 任务定义与状态投影；旧四区仍使用原来的 `levels.js / engine.js / renderer.js / game.js`。资源清单、导出和 Canvas 基础绘制复用。来源适配边界见 [CAMPAIGN.md](CAMPAIGN.md)，本轮实测证据和局限见 [progress.md](progress.md)。
