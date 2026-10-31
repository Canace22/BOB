# Godot 本地与远端工程合并

2026-10-31：将本地 `5097908` 与远端 `46994bd` 的独有提交合并，正式工程统一使用 `game/project.godot`。本地原路径 `godot/WhalebellyRuins` 已退役，不再作为开发入口。

## 保留与迁入

- 以远端的模块、五房玩法、存档隔离、Web 加载优化和命令入口为准。
- 本地统一工程的已提交源码、素材和制作历史保存在 `legacy/godot/WhalebellyRuins/`，由 `.gdignore` 隔离。截图、日志和制作运行态不重新入库；完整快照与原工作目录另保存在仓库外 `backups/BOB-before-sync-20261031/`。
- 本地新增的全局素材、原画/动画母版、视频参考、台账和制作说明保留在 `assets/` 与 `docs/`。未提交的场景制作 Skill 更新也已保留。
- 环境场景迁入 `game/src/world/scenery/local_environment/`，含三组共 62 条鱼、V3 垂须、气泡、柔性植物、水面与柔光。移除旧场景根脚本中的验收分支和旧控制器依赖，使用共享时钟；默认隐藏参考角色。
- `game/art/manifest.json` 记录所有运行位图和鱼群编排数据的来源，`sync-art` 可重建。动态选择的三种 Shader 已显式迁入。

## 打开与预览

打开 `game/project.godot`，F5 运行正式游戏。

在编辑器打开 `game/content/environment/local_environment_preview.tscn` 后按 F6，可观看本地新增环境。命令行可运行：

```sh
node tools/godot.mjs run -- res://content/environment/local_environment_preview.tscn
```

此次保留远端正式关卡的碰撞和玩法布局。新环境作为独立可运行场景迁入，没有将其不同的道路轮廓直接替换正式 R1-01 的布景与碰撞；其展示角色仍是参考剪影，不是正式玩家控制器。

## 本轮验证

- Godot 4.7.2：`node tools/godot.mjs sync-art` 成功；`check` 为 0 错误。
- `node tools/godot.mjs test`：19 项通过，0 项失败。新增测试核对 3 组/62 条鱼、运动与暂停、参考角色显隐、无玩法碰撞及存档路径不变；原有玩法/存档测试一并通过。
- 录制并查看新路径的环境实机画面，鱼群、垂须、道路、角色剪影、前景与柔光加载正常，运行日志无脚本或资源错误。证据在本地 `game/build/qa/migrated-environment/`，不提交。
- 未在本轮重新执行整条浏览器按键通关，也未发布 Pages；线上继续使用远端已发布版本。录制只验证短时画面，不替代长时性能验收或用户审美确认。

原始提交由备份分支 `backup/before-godot-sync-20261031` 保留；未提交文件另有外部备份及命名 stash。迁移过程不改写已有提交历史。
