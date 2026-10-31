# WhalebellyRuins 内容恢复

2026-10-31。拉新后的 `game/` 仅迁入独立环境预览，默认玩法仍是简化的模块版，导致原角色动作、技能和七房表现看似消失。原件实际保存在 `legacy/godot/WhalebellyRuins/` 与仓库外备份中。

## 当前入口与恢复范围

**打开 `game/project.godot`，F5 运行。** 默认主场景已改为 `res://content/whalebelly/main.tscn`。操作与目录见 [工程说明](../game/README.md)。后续只开发 `game/`。

| 原内容 | 当前路径 |
| --- | --- |
| 七房主场景、原地形与路线 | `game/content/whalebelly/main.tscn`、`r1/` |
| 拾潮者角色、动作、技能、原5生命参数 | `game/content/whalebelly/CampaignPlayer.tscn`、`game/src/campaign/` |
| 84帧/12FPS跑步、原Walk/Idle及15组动作库 | `game/art/whalebelly/animations/`及运行资源 |
| 三组62条鱼、48帧/12FPS垂须、56个气泡、水面、柔光、前景 | `game/content/whalebelly/environment/`与`game/art/whalebelly/` |
| 原音效变体、HUD、帮助、镜头、机关与V6存档 | `game/src/campaign/` |
| 拉新后的模块版 | 保留 `game/src/main/main.tscn`，未删除 |
| 历史原图、旧母版、配置、文档 | `game/production_sources/whalebelly/`，不导出 |

`game/content/whalebelly/recovery-manifest.json` 记录1914项原运行文件的来源和路径映射；包含30个原运行脚本、109个原场景和8个Shader。所有来源SHA256与原件一致，复制的二进制资源与原件一致；文本只做路径/类名适配及明确的兼容修复。95份附加制作源、工具配置和文档由 `production_sources/whalebelly/source-index.json` 登记。原零字节占位文件单独列明，不冒充功能。

`tools/recover-whalebelly.mjs` 是一次性恢复工具，默认拒绝覆盖；**不要用 `--refresh` 覆盖当前已修复源码**。常规素材同步仍用 `game/art/manifest.json` 和 `sync-art`，JSON/TRES资源路径同步改写。

## 存档保护

- 正式恢复关卡写 `WhalefallGame/whalebelly/artmatch_save.json`，原模块版 `save.json` 保持隔离。
- 桌面首次正式启动仅在目标文件不存在时，从 `WhalefallArtmatchV05` 复制有效V6进度及帮助设置。原件保留，目标已有进度不覆盖；QA和截图模式不导入真实旧档。
- 恢复测试使用独立QA存档；导入测试使用专用fixture目录。Web存档与桌面分开。

## 验收证据

本地证据在 `game/build/qa/whalebelly-recovery/` 及 `game/build/qa/whalebelly/`，截图/录像/运行日志不提交。

- 项目检查0错误，23项工程测试通过；既有模块测试保留，新增依赖、默认入口、存档隔离及旧档拒绝/复制/不覆盖测试。
- 3C专项46项、主关卡58项、输入驱动主路17项、独立进程重载2项通过。主路覆盖前五房、正常战斗Boss、冲刺、咽喉出口；七房加载和支路机制专项不能代替全支路连续通关。
- 实际GPU运行：跑步16项、主场景垂须14项、鱼群15项通过；检查暂停/恢复、12FPS帧序、返房资源、原镜头与控制器。
- 实际Chrome独立上下文真实按键：移动、跳跃、短击、迎珠、暂停/恢复、走回营地、E存档、刷新续档11项通过，无浏览器/引擎错误。不是全七房Web通关。
- 已查看恢复后主场景跑步、开局及环境截图，原角色、道路、鱼群、垂须和HUD实际加载。

## 保留与限制

原快照：仓库外 `G:/鲸落万物生/backups/BOB-before-sync-20261031/local-godot.tar`。原历史分支 `backup/before-godot-sync-20261031`、`backup/before-lfs-publish-20261031` 保留。原全局编辑母版和参考视频仍在 `assets/source/`；本次未重新生成或降质替换美术。

本轮先恢复行为，原主脚本仍超过250行，并保留历史QA入口，尚未彻底模块化。现有模块版的Tab地图规则与原恢复版Tab镜头规则不同，按恢复版H帮助为准。系统原生窗口截图工具超时，原生键盘测试未完成；真实键盘验证使用Chrome导出版本，GPU专项在原生运行。音频资源与触发保留，本轮未重新人工试听。

Web导出成功，但恢复完整素材后包体显著增大，当前PCK约308MB、压缩启动下载约301.39MiB。现有发布脚本不能直接发布这个体积的单文件，暂不替换稳定Pages；需要后续专门做保留动作表现的资源打包/分包与线上回归。**本地恢复完成不代表线上版本已更新。**
