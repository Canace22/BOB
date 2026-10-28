# 集成夹具执行说明

状态：已编写，尚未运行；不能凭本文件宣称验收通过。

`scripts/integration_checks.gd` 是独立 Node 测试夹具，`await run(main)` 返回 `{passed, checks, notes}`。主程序在 `--qa-integration` 分支实例化它、`add_child()`，随后在延迟调用的方法中 await；结果写入 `res://evidence/integration-v1.json`，按 passed 决定退出码。

所需主程序接口：`set_overlay("")` 关闭所有覆盖页，`overlay` 统一状态并维护 `paused/map_open` 镜像；`finish()` 打开完成页；现有 `change_room()`、game、level、menu、rooms 保留。主程序加载器需拒绝非 0/3 的 checkpoint、拒绝错误字段类型并尝试 `.bak`。奖励台恢复 R1-03 原 U0（x23–26，y11.3U），碎片位于 x24.5U；营地与左门的 E 范围分离。

覆盖：

- 真实 Input 触发 Esc 暂停，核对场景时间与玩家位置冻结。
- Esc → Tab → Tab 后菜单、SceneTree.paused、镜像状态一致。
- 完成页 Esc 回到探索。
- 真实地面冲刺中 R/F 被拒绝且不耗能；空中冷却结束后仍拒绝第二次冲刺。
- 五房右侧出生均落在最右主平台；营地恢复、Boss 房左门回返不冲突；战斗期间无法在营地恢复。
- 碎片、A1、H1 唯一领取（碎片和 H1 包含离房重访）。
- 截断 JSON、非法 checkpoint、错误布尔类型的主档均从有效备份恢复。

夹具会明确设置位置、HP、关卡与测试存档。它验证异常和组合状态，不替代正常 Input 驱动五房首通。仅允许 `game.qa=true`，使用隔离的 `save-qa.json`，开始保存其主档/.bak/.tmp 原字节，正常完成时全部恢复；不会主动选择正常玩家存档。如果进程异常终止，应由主代理检查 QA 档状态后再运行持久化测试。

测试时长约 10 秒。`create_timer(..., true)` 保证暂停时测试仍前进。无硬编码胜利、传送通关或无敌结果混入端到端验收。任何失败保留明细，先分析实际业务缺陷与夹具假设，再修复复跑。
