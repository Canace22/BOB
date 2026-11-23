# 现有地图保底版过场

本版沿用正式19房地图和已确认的85阶段章节次序。`game/content/narrative/campaign_cinematics.json`独立编排14段、46个镜头，不修改正文源白盒或代做任务。`CampaignCinematic`管理暂停与恢复，`CampaignCinematicView`只呈现镜头、已有位图和字幕。

## 已接入

| 触发点 | 演出 |
| --- | --- |
| `loop.arrival` | 第一次交谈前，主角伤后回稳、抬手与补巢者镜头 |
| `ch02_rescue` | 岸边住户、守卫支撑与内侧接应的分镜 |
| `ch03_flood` | 独立F开瓣之后，膜瓣开合、回水、菌床和老守护者压瓣 |
| `ch04_05_tides` / `ch06_04_tides` | 潮位与样片观察的定时镜头，字幕保留原阶段观察结果 |
| `ch08_no_reply` | 封梁卫战后身体、等待回应、守卫与名字壳 |
| `ch09_record_old_loss` / `ch10_whale_memory` / `ch11_listen_pause` | 记录、旧歌与听骨节点的观察镜头；旧歌复用主角交互逐帧动作 |
| `ch12_move_elder_safe` | 台边老守护者、接应与靠稳的镜头衔接，之后仍播放原救援对白 |
| `ch12_shift_narrow_cover` / `ch12_set_old_anchor` | 主角交互动作、守卫顶撑、老守护者稳梁；各任务仍需独立F |
| `ch12_limited_outflow` / `ch12_recovery_life` | 有限排水与恢复期的多角色镜头 |

普通交谈继续使用原头像对白，不为每次F都插过场。已完成阶段的存档不回退重播；过场中退出或读档不提交半段，回到未完成阶段后可重新观看。

## 控制与事实

- 按住Tab暂时停住镜头和字幕，松开继续。F结束当前观看；Esc或鼠标按钮首次确认，第二次Esc/Enter/按钮才跳过。
- 触发F的持有不会立即跳过，因为只接收后续新按下事件。结束后等待所有游戏键松开，避免移动、技能或交互漏到下一段。
- 开场跳过只进入原开场对白；终章救援任务的过场跳过后仍需结束该任务对白。下一项移封护/旧锚必须另按F，不由跳过完成。
- 场景树暂停之外，显式保存ActorFrame、流式管理器/通路和原镜头的process_mode并暂设PAUSABLE。主控的ALWAYS不再使主角重开原身体，演出镜头/逐帧代理由唯一时钟更新。
- 正常结束、取消、读档、换房和退出均经同一清理口恢复原可见性、控制、HUD、相机和暂停状态。演出代理没有碰撞和伤害，不运行技能执行器。

## 素材与动作边界

复用已入库主角`combat-animation-v2/player`及原action36逐帧、守卫/老守护者`combat-animation-v2/enemies`、章节人物位图、`chapter-reference-v1/name-shell.png`、`world-kit/habitat-fungus-bed.png`、`nursery-valve-leaf.png`与`bloodnest-water-filament-v5.png`。没有新增PNG、拉伸背景、几何角色或改动正式碰撞。素材原来源、许可与台账继续使用既有条目。

| 对象 | 判断及呈现 |
| --- | --- |
| 地形、石台、菌床、普通住户/补巢者 | static；镜头切换，不用静图滑动冒充走路/搬运 |
| 主角、守卫、老守护者 | motion；已有逐帧姿势按过场时间取样，不复制其攻击或伤害 |
| 膜瓣 | motion；入库膜片以脚线根部有限转动，只表示开合过渡 |
| 回水、外排、旧歌氛围 | motion；24个有界位图水丝，进出渐隐，统一时钟，不创建水体碰撞 |

本轮是现有素材的场景内演出，不含新绘的抱扶、行走或搬家专用动画，也没有配音。源/运行字体按实际新增文本同步重建。

## 验证入口

`node tools/godot.mjs check` / `node tools/godot.mjs test`为必需检查。`test_campaign_cinematic.gd`覆盖提交一次、确认跳过、松键门、读档取消/可重试、开场对白保留、危险任务不越级、原身体隐藏与窄窗口/Tab阅读。

`game/tests/story/cinematics_qa.gd`为分段起点夹具：从正式场景读取真实角色和身体，自然播放14段并截图；它不等于从头连续通关。可用 `node tools/godot.mjs run -- -s res://tests/story/cinematics_qa.gd -- --id=ch03_flood --stay`预览指定段并留在隔离体验场景，存档是`cinematics-preview.json`，不覆盖正常存档。

`tests/story/flow_qa.gd`保留真实F对白/任务输入并等待过场、排队对白和释放后的恢复；战斗仍为伤害夹具，不能用它证明Boss难度或徒步通关。实际结果及遗留失败记在[工程进度](../game/progress.md)。
