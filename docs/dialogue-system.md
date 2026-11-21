# 主线对话与位置引导

2026-11-17。当前实现为轻量对话能力和现有首房的开场样板，服务于[第一章循环验证](第一章游戏循环设计.md)。完整补巢者剧情、角色立绘、分支选择与十二章内容尚未接入。

## 操作与样板

正常主线新旅程进入首房后，在安全落地处自动播放开场。对话显示说话者与逐字文本，按 F 或空格先显示整句，再按进入下一句；鼠标可点“继续”，Tab可选择按钮，Enter执行当前选项（默认“继续”）。Esc或点击“跳过本段”先显示确认，再按Esc／Enter或点击确认才结束整段，仍获得原目标提示。按F／空格继续或切换句子会取消待确认跳过。恢复操作前等待游戏按键全部松开，避免确认键变成跳跃、攻击或技能页。

HUD在入房时短暂显示路线，随时可按C查看当前目标。开场结束后，目标提示前往左侧菌灯。营灯旁按 F 查看刻痕，首次读完或跳过后，目标更新为沿右侧骨路前进，F 恢复原营地歇息功能。沿右侧骨路走入下一范围会出现行进字幕，玩家仍可移动，目标更新为前往须筛。刻痕是复用现有场景的交互样板，不冒充补巢者角色已经制作。

隔离试玩入口：`game/tests/whalebelly/dialogue_play.tscn`。

```powershell
$env:GODOT='F:/Godot_v4.7.2/Godot_v4.7.2-stable_win64_console.exe'
node tools/godot.mjs run -- --windowed --resolution 1280x720 --max-fps 60 res://tests/whalebelly/dialogue_play.tscn
```

该入口每次重新演示开场，只写独立QA存档，不读取或覆盖真实主线进度。正常主线使用原V6存档，在完成或跳过后保存叙事记录；继续游戏、检查点重试不重复已完成开场，新旅程会清空。

两类阅读框共用紧凑宽度、配色、字号和高对比样式；短句收紧高度，长文在上限内展开并滚动，逐字播放期间尺寸保持稳定，具体见[UI系统](ui-system.md)。普通居民读文可按F／空格／Enter／Esc返回；逐句剧情的Esc采用上述确认，防止误跳。

## 配置触发节点

房间内放置使用 `src/narrative/dialogue_trigger.gd` 的Node2D。现有样例在 `content/whalebelly/narrative/opening.tscn`，由首房实例化。

| 字段 | 含义 |
| --- | --- |
| dialogue_id | 稳定且唯一的内容ID，保存和条件以此判断，勿用显示名替代 |
| room_id | 生效房间ID，同时验证节点属于活动房，预加载邻房不会提前播放 |
| area | 节点局部坐标中的矩形，随房间世界偏移自动转换 |
| activation | 自动对话、按键交流或行进字幕 |
| once | 默认为true；完成后不再触发。明确配置false才允许重复交流 |
| priority | 同时满足条件时的优先级，数值大者先检查 |
| required_seen / blocked_seen | 必须完成 / 必须尚未完成的叙事ID |
| required_collected / required_abilities | 沿用主线收集与能力ID的前置条件 |
| speakers / lines | 按行对应的说话者与文本；说话者不足时沿用最后一个。单行建议不超过两至三行屏幕文本 |
| prompt | F交流时的提示文字 |
| objective_id / objective_text | 本段首次完成或跳过后设置的目标；不填则保留已有目标，重读不会回退目标 |
| subtitle_seconds | 行进字幕显示秒数 |

自动对话需安全落地；受击、技能动作、附近敌人或敌方弹体存在时延后。进入范围会记录一个待播请求，危险消失后可在同房安全处播放；切换活动房或条件失效则丢弃。手动交流同样检查安全条件。

战斗中的触发延后不等于新的敌我仇恨系统：当前保守检查目标320px内和敌方弹体420px内；更复杂遭遇需要结合真实攻击覆盖调整。行进字幕也先避开危险起播，已起播后保留控制；死亡、角色重建或离开该房会清除字幕。菜单打开时隐藏字幕并暂停其时间。

## 状态与模块责任

- `WhaleDialogueTrigger`只描述范围、条件和文本，不能自行发奖励、暂停或改档。
- `WhaleCampaignDialogue`由主线宿主持有，负责判定、待播请求、行游标、完成记录与目标；以signals通知呈现层。
- `WhaleDialoguePanel`负责文本、打字速度及继续/跳过意图。它复用既有 `WhaleCampaignUI` 的暂停、输入清理和恢复流程，不另改 `Engine.time_scale`。
- V6增加可选 `narrative` 字段，内含 `seen` 和 `objective`。旧档缺此字段时按空记录加载，不重置能力、护盾或检查点；目标只在所属房间显示，其它房间仍使用现有路线提示。
- 只在结束或跳过时标为完成，半段退出不写完成。角色重建会取消未完成对话并收回控制；下次满足触发条件仍可重播。
- 样板不修改已有房间通行、Boss胜利或奖励条件。QA路线默认关闭自动叙事，专项与隔离试玩显式开启，避免旧自动路线被对话暂停。

## 回归入口

根目录先执行 `node tools/godot.mjs check`、`node tools/godot.mjs test`；新增 `tests/test_dialogue_state.gd` 检查条件组合、可重读配置及旧V6/异常叙事字段。

`tests/whalebelly/dialogue_qa.gd`在真实主场景用键盘事件检查自动开场、逐句/跳过、控制冻结、目标、F与营地优先级、字幕、受击延后和角色重建。桌面模式在 `build/qa/dialogue/`保存截图。随后顺序加 `-- --reload`独立进程验证完成记录、目标与新旅程重置，不与第一进程同时写同一QA档。

```powershell
& $env:GODOT --path game --fixed-fps 60 --windowed --resolution 1280x720 --script res://tests/whalebelly/dialogue_qa.gd
& $env:GODOT --headless --path game --fixed-fps 60 --script res://tests/whalebelly/dialogue_qa.gd -- --reload
```

单句能显示不代表引导成立；首次玩家是否理解方向、动机和背景，仍按第一章设计稿的试玩标准验收。异常日志、资源残留与全局旧原型缺图须单列，不以断言通过掩盖。
