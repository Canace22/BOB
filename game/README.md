# 鲸腹遗城 · 当前工程

唯一开发入口是本目录的 `project.godot`，固定 Godot **4.7.2**。打开后按 **F5**，启动已恢复的 WhalebellyRuins 七房主关卡：`content/whalebelly/main.tscn`。

首次出现操作说明时，按 Enter 关闭，再操作角色。A/D 移动，K/空格跳跃，J/Q 短击，L/Shift 冲刺，U 迎珠，I 重鸣，P 调息，O 潜隙，E 交互；W 浮游、G 牵引沿用能力限制。Esc 暂停，H 帮助，M 静音，F5/F6 为游戏窗口内的存档/读档。

## 恢复后的目录

| 路径 | 内容 |
| --- | --- |
| `content/whalebelly/` | 原七房、角色、环境与独立动画场景 |
| `src/campaign/` | 原角色3C、技能、关卡交互、镜头、HUD与音频逻辑 |
| `art/whalebelly/` | 原运行素材，包括逐帧角色、鱼群、垂须、水面与前景 |
| `production_sources/whalebelly/` | 历史原图、母版、制作说明及工具配置；有 `.gdignore`，不打包 |
| `tests/whalebelly/` | 恢复后的旧专项验收；`manual_play.tscn` 用隔离进度试玩 |
| `src/main/main.tscn` | 拉新时的模块版保留入口，供后续整合参考 |

原模块版和原七房共用一个工程，不需要切换另一个 `project.godot`。独立环境是 `content/whalebelly/environment/xumen_reference.tscn`，在编辑器按 F6 预览；F5 始终进入主关卡。

## R1后续六房环境

R1-02至R1-07已接入独立四层与环境动件，主场景运行时直接使用。数字 **2–7** 为已有房间预览；**Tab** 切换已有全景/跟随镜头，**F4** 查看四层，**F2** 对照原图。预览不是能力解锁；正式入口仍按Boss、浮游和锚环限制推进。R1-06/07是后续能力回访房，**F9** 仅开启已有临时练习能力。

原件、SVG选区/根线、OpenRaster母版与方法清单：[制作说明](../assets/source/r1-chapter-scenes/README.md)。本地实机验收页在 `build/qa/r1-chapter-scenes/场景验收与对照.html`，含24FPS环境展示与六房截图；日志/录像只保留本地。当前阶段见 [进度](progress.md)。

## 存档与启动

恢复关卡使用 `user://whalebelly/artmatch_save.json`，模块版仍使用 `user://save.json`。桌面首次正式启动时，只有恢复关卡尚无存档，才从原 `WhalefallArtmatchV05` 目录复制有效V6存档；不覆盖已有新档，不删除原档。浏览器不会读取本机 AppData。

在仓库根目录运行 `node tools/godot.mjs run` 或 `node tools/godot.mjs editor`。若找不到引擎，设置 `GODOT` 环境变量为现有 Godot 4.7.2 console 可执行文件。校验入口为 `node tools/godot.mjs check` 和 `node tools/godot.mjs test`。

来源清单、恢复范围和验收限制见 [恢复说明](../docs/whalebelly-recovery.md)。后续只在 `game/` 继续开发，`legacy/` 保持只读。
