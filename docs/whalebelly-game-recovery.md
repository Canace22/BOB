# WhalebellyRuins 完整可玩内容恢复

> 当前归档清单、存档兼容与最终验收补充见[恢复说明](whalebelly-recovery.md)。本页保留恢复阶段记录。

2026-10-31。本次修正此前只接入环境预览的遗漏：原工程的完整可玩入口、角色、战斗和七房内容已迁入 `game/`，并恢复为 F5 默认入口。

## 开发与运行入口

- 唯一项目仍是 `game/project.godot`，默认场景为 `game/content/whalebelly/main.tscn`。
- 原有模块化五房版本保留在 `game/src/main/main.tscn`，可单独运行；没有删除它的代码、场景或存档。
- 独立角色/技能试玩：`game/content/whalebelly/tide_demo.tscn`；原七房角色参数场：`game/content/whalebelly/test/PlayerTest.tscn`。
- 环境展示与各动作预览也迁入 `game/content/whalebelly/`，保持原有场景关系；它们不再是恢复工作的唯一交付。

```sh
node tools/godot.mjs run
node tools/godot.mjs run -- res://content/whalebelly/tide_demo.tscn
node tools/godot.mjs run -- res://src/main/main.tscn
```

## 找回的实际内容

| 内容 | 新位置与状态 |
| --- | --- |
| 原七房、道路碰撞、分层布景、门与支路、营地、敌人和 Boss | `content/whalebelly/r1/`、`art/whalebelly/rooms.json`、`src/campaign/`；恢复原房间组装与参数 |
| CampaignPlayer、V2.4 角色/技能、HUD 与引导 | `content/whalebelly/CampaignPlayer.tscn`、`Player.tscn`、`PlayerUI.tscn`；F5 实际使用 |
| 短击、下劈反弹、二段、墙滑/墙跳、冲刺/潜隙、迎珠、重鸣、调息、魂与死亡重生 | `src/campaign/tide_player.gd` 及 campaign 适配；原完整动作库与事件保留 |
| Run/Walk 图集、上下身动作层、角色颜色修复、技能效果与声音 | `art/whalebelly/`、`src/campaign/campaign_run_visual.gd` 和原 Shader；保留原素材和播放逻辑 |
| 62 条鱼、V3 垂须、气泡、柔光、前景修复、镜头与视差 | 已在恢复的 R1-01 主关卡内使用；不止独立预览 |
| V6 进度、Boss/能力与机关状态、检查点 | `user://whalebelly/`，与模块化版本 `save.json` 隔离 |

路径映射和原文件 SHA256 见 `game/content/whalebelly/recovery-manifest.json`，共记录 1914 个恢复文件。1655 个位图、音频及字体等二进制素材与原件逐字节一致。资源同步清单仍是 `game/art/manifest.json`，文本资源在同步时改写原 `res://` 路径；不把制作源换成视频播放器或静态总图。

`tools/recover-whalebelly.mjs` 是一次性恢复工具，默认拒绝覆盖已恢复模块。后续开发直接修改 `game/`；不要用 `--refresh` 覆盖后续修正。恢复阶段保留经过验证的原实现，暂未为拆小文件重写旧主循环；历史脚本的无类型声明警告仅在恢复模块内兼容，不关闭全项目检查。

## 原有进度保护

首次正常运行时，`CampaignSaveBridge` 只在目标文件不存在时读取原 `WhalefallArtmatchV05` 用户目录，并复制有效 V6 进度及引导状态到新目录。原文件不删除、不覆盖；新工程已有目标进度也不覆盖。QA 和捕获运行不导入真实进度。

测试只写 `artmatch_qa_save.json` 等隔离文件。自动化原生试玩入口是 `tests/whalebelly/manual_play.tscn`，不作为正式入口。

## 操作

A/D 或方向键移动；K/空格跳跃与二段；J/Q 短击，空中 S+J 下劈；L/Shift 冲刺，O 潜隙，U 迎珠，I 重鸣，P 调息，E 交互，H 查看完整引导。原参考层、分层查看及能力练习模式仍保留。

## 本轮验收与边界

- 原工程 3C 46、参数场 11、主接口 58、连续路线 17、独立进程读档 2，共 134 项断言通过。连续路线实际行走/跳跃、战斗击败 Boss、获得冲刺并抵达首关出口；测试没有用传送替代该路线。
- 新工程检查为 0 错误；原有与新增恢复测试共 23 项通过，含七房场景、恢复依赖、默认入口与存档隔离。
- GPU 重跑主接口 58 项通过，已实际查看 R1-01、Boss 房、移动攻击、引导及 16:10 布局截图。该重复运行不另算新增断言。
- 原生桌面窗口截图接口返回超时，发送的键盘操作未观察到游戏响应，不能将其记作真实 OS 输入验收成功。
- 原有素材候选状态、滑步/武器形变与动画接缝限制没有因搬迁而消失；未新增美术生成，也没有宣称商业级动画质量验收。

校验 JSON、截图、日志和视频仅本地保存，不入库；测试源码与简短结论保留。原工程备份、Git 备份分支及冻结历史继续存在。

- 浏览器真实键盘 11 项检查通过：移动、跳跃、短击、迎珠消耗、暂停/恢复、营地保存、刷新读档；错误列表为空。Web 导出成功，但全量启动压缩下载为 301.45 MiB，暂未替换线上稳定版本；需后续资源拆包或按需加载，不能为恢复任务删掉已开发内容。
