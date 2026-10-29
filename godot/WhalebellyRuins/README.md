# 鲸腹遗城 · Whalebelly Ruins

唯一开发工程。Godot 4.7.2，入口 `project.godot`，F5运行；也可双击 **启动主关卡.cmd**。

运行、合并规则与开发约定：[统一工程说明](../../docs/godot-project.md)。当前成果及未完成项：[progress.md](progress.md)。

原artmatch七房与最新音效已合并；旧代码仅在production-history中作为资料，不再创建版本分支工程。用户存档目录保持WhalefallArtmatchV05。

操作：A/D移动，K/空格跳跃、二段/蹬墙；J/Q短击，S+J下劈；L/Shift冲刺，U迎珠、I重鸣、P调息、O潜隙、E交互、W浮游、G锚环、H帮助。沿用原能力解锁，F9临时练习；游戏内F5存档、F6读取。

历史独立预览保留6秒「提灯守望」Idle（70帧、12FPS、透明图集）。独立观察打开 `scenes/characters/idle_preview.tscn` 后F6：空格暂停、右箭头逐帧、A/D转向、1/2正常或慢放。[制作来源与验收](../../assets/source/tide-picker-idle-v03/README.md)。

主关卡地面移动已接入视频Walk：**84帧、12FPS、7秒**；停止回到当前Idle。`scenes/characters/walk_preview.tscn`可独立F6预览，操作同上。[Walk来源、重定时与限制](../../assets/source/tide-picker-walk-v03/README.md)。源视频稳定段重定时以闭合循环，固定帧率下仍有滑步，属于已接入的视觉评审稿。

## 角色3C与技能试玩（2026-10-29）

双击 `试玩角色与技能.cmd`；或打开 `scenes/tide_demo.tscn` 按 F6。A/D移动、K跳跃、J短击、L冲刺、U迎珠、I重鸣、P调息、O潜隙、E交互、R重生、H帮助。F5默认七房入口已接入新角色和HUD，复用原265速度/5血量；独立主工程尺度测试打开 `scenes/test/PlayerTest.tscn`。[完整操作、参数、资源与限制](docs/tide-3c.md)。
