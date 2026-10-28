# 鲸腹遗城 · Whalebelly Ruins

唯一开发工程。Godot 4.7.2，入口 `project.godot`，F5运行。

运行、合并规则与开发约定：[统一工程说明](../../docs/godot-project.md)。当前成果及未完成项：[progress.md](progress.md)。

原artmatch七房与最新音效已合并；旧代码仅在production-history中作为资料，不再创建版本分支工程。用户存档目录保持WhalefallArtmatchV05。

操作：A/D移动，空格跳跃，Q攻击，Boss后Shift冲刺，E交互；F5存档、F6重载。F9为回访能力临时练习。

主角站立已接入6秒「提灯守望」Idle（70帧、12FPS、透明图集）。独立观察打开 `scenes/characters/idle_preview.tscn` 后F6：空格暂停、右箭头逐帧、A/D转向、1/2正常或慢放。[制作来源与验收](../../assets/source/tide-picker-idle-v03/README.md)。

## 角色3C与技能试玩（2026-10-29）

双击 `试玩角色与技能.cmd`；或打开 `scenes/tide_demo.tscn` 按 F6。A/D移动、K跳跃、J短击、L冲刺、U迎珠、I重鸣、P调息、O潜隙、E交互、R重生、H帮助。原 F5 七房入口保持不变。[完整操作、参数、资源与限制](docs/tide-3c.md)。
