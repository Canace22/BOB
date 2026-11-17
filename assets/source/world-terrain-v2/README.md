# Version1.0.1 连续世界母版 V2

采用主干须门七房新布局及其余十二房最新地形，保留19房玩法、门条件和活动机关。`master.tscn` 为同一世界坐标的完整构图，`composition.json`保存来源和变换，`world-layout.json`保存19房脚线与原点，`connections.json`保存18条通道落脚点。连接像素来自[V3重绘](../world-seam-repaint-v3/README.md)，动态舌膜不进入静态母版。

`overview.png`只用于总览；运行贴图从同一树按1536×1536世界网格切片，四边2px采样余量，实际1540×1540。`registration.json`记录区块世界位置和SHA256。加载器只决定驻留，不在可碰撞地形上做房间透明淡出。旧V1和V2重绘仍可查阅，当前消费者使用本目录与V3。

仓库根依次执行：

```powershell
node tools/godot.mjs sync-art
& $env:GODOT --audio-driver Dummy --path game --fixed-fps 60 -s res://tools/build_terrain_master.gd
python game/tools/verify_terrain_master.py
node tools/godot.mjs sync-art
```

构建结束后按新chunks维护manifest及registration；检查重叠边、全房静态脚线和实际通道落脚点。实时膜仅排除活动膜面，不能排除整间房。新素材导入、PNG同步与读取必须顺序，避免Windows文件锁导致旧资源被误认为新结果。当前验收及限制见 [game/progress.md](../../../game/progress.md)。
