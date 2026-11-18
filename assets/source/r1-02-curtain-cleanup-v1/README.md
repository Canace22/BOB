# 须筛垂须透明修复 V1

用户圈出须筛右上圆环路线旁的垂须，指出背景未处理好。正式入口的逐层GPU截图确认：`Middle/OriginalChamber`仍有深蓝静态须帘，`Middle/Fringe0`只抽取浅色尖端；叠加后出现深蓝残块、断丝和过亮下缘。

本批只修正这一簇的分层和色调。远水背景、墙体、平台、圆环、碰撞、技能和存档结构沿用现有工程。

## 输入与制作源

- `reference-gameplay.png`：本次用户提供的实机参考，含红框。
- `Middle-original.png`、`curtain-original.png`：改动前清单实际同步的两张PNG副本，保留历史源。
- `curtain-candidate-01.png`：第一次内置ImageGen结果。试接入后发现右侧根部不完整，未选用。
- `curtain-generated.png`：第二次内置ImageGen修复结果；明确要求全部细丝延伸到顶部附着线，保留斜向下缘、透明间隙和手绘材质。
- `provenance.json`：实际提示词、来源关系、原件与运行导出的SHA256。
- [Godot原生导出脚本](../../../game/tools/export_curtain_cleanup.gd)：统一缩放新PNG、保留原814×399画布；按旧附着线清除静态重复像素。旧版原件不覆盖，无全屏颜色键。

运行导出在`assets/runtime/sprites/r1-02-curtain-cleanup-v1/`。`game/art/manifest.json`仍绑定原有两个目标路径，只将来源切到本批；所以当前房间和保留的Chapter环境预览共用修复。旧Framecraft批次和旧`r1-chapter-scenes/runtime-index.json`继续记录历史产物，不代表本次输出的哈希。

## 静动所有权与接入

| 元素 | 判断和理由 | 当前处理 |
| --- | --- | --- |
| 须帘完整细丝 | motion；根部附着、自由端随水流 | 一张透明位图，复用现有固定端网格微摆；标记程序驱动，非逐帧动画 |
| 静态中景中的同簇须帘 | inspect后确认为重复副本 | 仅清除对应像素；附着线上方的顶壁与其它侧壁保持原像素 |
| 远水、骨岸、圆环 | static或既有交互；不属于本次缺陷 | 不增加素材或新运动 |

运行PNG按相同比例缩到767×375，再放回814×399透明画布的(12,4)，无非等比拉伸。保留原`Fringe0`位置、比例、摆幅2.5、周期9秒及根线；中景调制为(0.68,0.82,0.84,0.65)，使亮端融入远水。Chapter预览使用相同素材与调制，其原有周期10秒不变。

静态清理使用PNG像素坐标x=548…1379及原附着曲线以下、源场景y≤428的范围；原图有16px留边。导出后检查范围外RGBA逐像素相同，避免同时删去骨岸或墙体。

## 复跑和证据

在仓库根目录运行匹配版本的Godot控制台程序：

```text
Godot --headless --path game --script res://tools/export_curtain_cleanup.gd
node tools/godot.mjs sync-art
Godot --path game --resolution 1280x720 --max-fps 60 --fixed-fps 60 --script res://tests/whalebelly/curtain_cleanup_qa.gd
node tools/godot.mjs check
node tools/godot.mjs test
```

导出脚本不修改场景；重新生成场景时仍须保留上文的中景调制。原生专项仅写独立`curtain-cleanup` QA档，从须筛右侧岸台起点夹具运行真实D、空格和Esc，不声称从开局通关。

本轮专项14项通过：实际资源与透明留边、静态重复清理、上部细丝和间隙、GPU固定根部与9秒循环、键盘移动/跳跃/落稳、暂停恢复、存档字节不变。静态清理174150个可见像素，范围外0像素变化。观察四个相位和前后实机截图，未执行多轮连续主观动画审查或性能基准。

对比导出源时须读PNG原字节，导入器可能改写Alpha零处隐藏RGB；GPU循环测试须隔离须帘，整屏中的ALWAYS角色和UI仍可能变化，不能把它们当作须帘接缝。专项报告、截图和日志仅本地`game/build/qa/curtain-cleanup/`、`curtain-native.log`；完整工程检查结论见[工程进度](../../../game/progress.md)。

已完成本地资源接入和AI画面复核；用户整体审美仍待试玩。此次没有新增缺图回退，实际同步/加载两张PNG正常；没有验证缺图故障、Web导出或线上结果。当前运行窗口需重新运行才读取新贴图；未提交或发布。
