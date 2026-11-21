# 第三章 · 胃室白盒

独立入口 `res://content/prototypes/chapter_three/main.tscn`。第二章完成后在出口按F进入；也可在根目录运行：

```powershell
$env:GODOT='F:/Godot_v4.7.2/Godot_v4.7.2-stable_win64_console.exe'
node tools/godot.mjs run -- res://content/prototypes/chapter_three/main.tscn
```

流程：靠近补巢者交流→槽口F可选查看回水→向右走近大甲自动预警交战栖污大甲→旧瓣F查看→再F主动撬开→回水事故与救援→回左侧捡壳→住巢固定→右侧脂库入口结束。开瓣是独立交互，推进对白/打赢敌人不会代替执行。故事固定发生事故，无伪装成可赢挑战的护巢目标。

WASD移动、空格跳跃，J/I/K/L/Z与Q/E组合沿用第二章。F交互；F/空格/Enter推进对白，Esc跳过对白或暂停。事故演出F可跳过到同一安全终态。R回本章检查点，F6只重开本章；独立存档 `user://chapter-three-whitebox/<工作区摘要>-<后缀>.json`，不读写正式V6或第二章进度。

场地、居民、水路、补巢者、救援都为明确标识的白盒代理，未制作正式胃室美术或新动画。玩家/大甲复用既有动作，老守护者复用既有位图姿势。正式19房主入口未变。完成本章后按F进入第四章，继续至第十二章；见[连续白盒说明](../chapters/README.md)。

设计见[第三章循环](../../../../docs/第三章游戏循环设计.md)，结果见 game/progress.md。单元入口 `tests/test_chapter_three.gd`，原生实际按键 `tests/whalebelly/chapter_three_qa.gd`；截图日志只留 game/build/qa/chapter-three/。
