# 安全存档落点生成修复

2026-11-15。本专项只改 `game/tools/build_xumen_layout.py` 的checkpoint_lanes生成，并新增 `game/tests/test_xumen_checkpoint_lanes.gd`。没有修改场景、碰撞、recipe、qa_routes或CampaignLayout.restore_point；由主任务统一build。

原先每个宽度≥100的平台直接取 `[x+35,x+w-35]`、y=平台y，忽略角色身体与邻近骨壁、承重膜、错层平台的重叠。现在仍从原区间出发，只减去身体占用障碍的横向范围，保留连续安全段：

- 玩家足点左右18px、身高94px；墙体按现有box内缩12px后的实际核心。
- 其他非one_way平台用已经生成的实际顶面contour与原底深（膜100、普通30）形成多边形，本台排除。只对落点身体的垂直带裁剪，再减去其横向投影；不拿整个图片bbox当碰撞。
- 减区端点增加0.01px防浮点/三位小数序列化后的接触侵入。每段记录surface_id以核对支撑面。

例如初次生成修复时R1-03奖励台右端从1125缩至1103.99，避开身高内的骨壁；下层Surface6左端从835缩至894.01，避开邻接膜/折返台的身体重叠。后续recipe并行调整后以统一build产物为准。

## 实际运行结果

使用Godot4.7.2正式测试runner，只过滤xumen_checkpoint_lanes：

1. **PASS**：每条安全lane整段的身体扫掠矩形，与实际tscn中非one_way CollisionPolygon2D求交面积，无穿墙/穿其他平台。每段仍在原平台安全区间内。
2. **PASS**：旧存档、越界、R1-03奖励台与膜重叠探针经restore_point后落到未占用安全区；不修改room元数据。
3. **最终PASS**：7个默认出生点、12个内部连接到达点经restore_point后均保持精确位置。首轮专项曾发现5处门到达点在原安全lane以外；主任务已修正对应recipe并统一build。R1-04返回R1-03直接改为正确上层的[1490,580]，另外4处对齐同层安全区间。回归测试保留，以防未来改布局时再次出现跨层投影。

已修复的首轮问题：02→01原[1400,790]、03→02原[1400,710]、04→03原[1390,580]、06→02原[295,180]、07→02原[1350,210]均曾在原安全段外。这来自原始安全段边距与门到达点不一致，并非本轮障碍减区导致。最终统一build后再次运行同一正式过滤专项：**3 passed, 0 failed**，实际运行无stderr错误；`git diff --check`通过。本专项未修改生成器以外的生产代码、场景或recipe，五处到达点由主任务调整。

未通过单独`--check-only --script`宣称验证：该调用没有autoload，会在TestSuite依赖的GameState处失败。正确验收是正式`res://tests/run_tests.tscn -- --filter=xumen_checkpoint_lanes`，使用真实autoload与正式场景。该经验仅记本项目执行方式，未改其他Skill。
