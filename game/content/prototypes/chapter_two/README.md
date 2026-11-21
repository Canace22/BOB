# 第二章 · 折井白盒

独立可玩入口：`res://content/prototypes/chapter_two/main.tscn`。从仓库根启动：

```powershell
$env:GODOT='F:/Godot_v4.7.2/Godot_v4.7.2-stable_win64_console.exe'
node tools/godot.mjs run -- res://content/prototypes/chapter_two/main.tscn
```

若本机暂时无有效音频设备，可追加 `--audio-driver Dummy`；此方式无声，不作为听感验收。

## 本轮体验

沿折井下降，靠近守卫主动交流；越过警戒线先有重壳警告，随后交战。利用既有格挡、后跳和基础连招解除封锁，守卫存活。走出战场触发老守护者撑梁救援，住户安全后交流。守卫不认可强闯，老守护者不凭鲸歌判断故障；住户撤完后通路重开，跟随居民去胃室入口收束。

WASD移动，空格跳跃，J普攻、I格挡、K三段斩、L冲刺、Z后跳；W+J上挑、S+J横扫、A/D+L撞击，Q/E沿用选招。当前只开放基础技法，不发主线技能奖励。F/空格/Enter推进对白，Esc跳过当前对白；救援中F可跳过到居民已安全的状态。平时Esc暂停。

- `R` 回本白盒最近检查点：拒绝交流后直接在战前安全台重试，战胜后不重复打Boss。
- `F6` 清空本白盒进度重新开始。
- 重开与读档仅使用 `user://chapter-two-whitebox/<工作区摘要>-play.json`，不导入或修改正式V6存档。自动测试使用独立后缀。
- 日志与截图只留 `game/build/qa/chapter-two/`，`latest-play.json`记录本轮事件和有效时长，未上传。

## 制作与验收边界

场地、支架、住巢和居民均为有标识的几何白盒代理。玩家和负壳守卫复用已入库动作；救援复用老守护者既有姿势加位置/关键帧演示，不是新绘完整救援动画。没有制作正式折井美术，也没有把19房正式地图改名替代第二章。

本样板不自动修改第一章终点，不把正式主线默认入口切到这里。原有第一章与正式19房都保留；本轮先单独验证第二章链路。第二章在胃室入口收束；完成对白后按F继续第三章独立白盒，保留两章各自存档。

对白按 humanizer 重编，集中在 `src/prototypes/chapter_two/dialogue.gd`；战后先有守卫提醒，居民撤离后才重开通路。剧情是[第二章循环设计](../../../../docs/第二章游戏循环设计.md)的试玩用对白提案，不覆盖叙事原稿。没有随机装备、新增技能奖励或救援倒计时；守卫招式与架势规则复用试验场，不改共用输入容错。

专项入口：`tests/whalebelly/chapter_two_qa.gd`走实际下降与自然战斗通关，`chapter_two_recovery_qa.gd`检查真实敌伤死亡、R重试、撤退、存档夹具恢复及跳过；`tests/test_chapter_two.gd`验证隔离存档与安全落点。验收记录统一见 `game/progress.md`，脚本通过不代表人类难度和章节节奏已认可。
