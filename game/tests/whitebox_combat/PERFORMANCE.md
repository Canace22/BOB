# 动画接入后全画面卡顿：取证与修复

2026-11-16，分支 `codex/combat-whitebox-backstep`。用户反馈整幅画面突然停顿，而非只觉得角色帧数低。

## 原因与证据

动画版白盒漏开 `atlas_visual_enabled`，可见角色已用图集，隐藏旧AnimationTree却仍在首次出招同步解码36帧旧身体图及相关特效。固定GPU回放第一帧182.668ms，其中隐藏旧帧加载154.445ms；随后首次位移斩又有90.068ms。该回放隐藏旧帧累计加载240.873ms，发生在主线程，因而整幅画面一起停顿。

另一个来源是新脚底注册：`AtlasTexture.get_image().get_used_rect()`第一次访问某帧时触发GPU像素回读。基线每段回放72–74次，单次可达4.541ms，并且首次图集加载还有10–31ms开销。调试UI关闭后p95仍18.591ms，而同一暖缓存条件关闭脚底回读后p95为17.014ms；UI不是这次主要瓶颈。

修复前日志：`game/build/combat-whitebox-profile-instrumented.log`。结构回归用例先运行得到31通过、1失败，分别捕获图集模式未开、隐藏旧帧重复加载、战斗中实际像素回读12次（`combat-whitebox-perf-regression-before.log`）。

## 修复

- 白盒启用既有图集模式，隐藏AnimationTree保留状态与事件，旧身体帧复用idle引用。
- 本白盒17种常用图集在试玩开始前准备，固定持有帧引用，避免8项LRU在技能切换时淘汰重建；当前样本预热约199ms，移到开始接收操作之前。
- `build_foot_offsets.py`从原PNG离线提取36动作的逐帧脚底，生成 `foot_offsets.json`。运行时只查数值，不再读回GPU像素；动作时长、位移、取消窗口及根锚点规则保持。
- 元数据携带源图SHA256和裁片矩形，测试验证17个常用动作的哈希/布局，避免素材更新后沿用过期脚底。新增两项回归，现33项通过。
- HUD增加实际FPS、壁钟帧耗时与峰值，R重置峰值；Timeline仍读取技能时间，慢动作不会伪装成FPS降低。

## 修复后相同回放

| 样本 | 修复前p95 / 最大帧 | 修复后p95 / 最大帧 |
| --- | --- | --- |
| 首次出招A，240帧 | 19.188 / 182.668ms | 17.048 / 17.962ms |
| 暖缓存重复B，240帧 | 18.963 / 20.101ms | 17.295 / 27.741ms |

修复后所有阶段像素回读0次；首次阶段隐藏旧帧处理0.059ms，视觉更新p95 0.115ms。B轮保留一次27.741ms孤立峰值，该帧动画更新仅0.051ms，没有旧帧加载或回读；未据此归因，也不宣称所有场景/设备稳定60fps。不能只报最好的一轮。

对照JSON保存在 `game/build/qa/whitebox-performance/before.json`、`after.json`，日志 `combat-whitebox-profile-after.log`。所有证据仅本地，不提交大文件。六个GPU动画截图复跑确认显示与接地不变。

## 复跑

```powershell
python game/tests/whitebox_combat/build_foot_offsets.py
node tools/godot.mjs run -- --windowed --resolution 1280x720 res://tests/whitebox_combat/main.tscn -- --profile-whitebox
node tools/godot.mjs run -- --headless --fixed-fps 60 res://tests/whitebox_combat/verify.tscn
```

脚底生成需要Pillow；只读取PNG、输出JSON，不覆盖图集。改动作图或裁片后重建元数据。性能场景会自动结束，四组依次隔离脚底注册/调试UI并重复基线；比较冷加载需新开进程，不能用暖缓存对照掩盖首次出招卡顿。独立GPU回放使用固定操作次序和实际壁钟帧耗时，不把headless测试耗时当渲染性能。

本次不调整技能速度、打击停顿或物理手感来掩盖性能问题。工程check/test仍另跑；已有chapter01缺图不是本轮卡顿结论的依据。

本次完整检查仍2处旧chapter01缺图；完整测试另报UI字体缺字“岸”（字体检查扫描正式src/content，白盒测试目录不在扫描范围）。这批无关源文件/字体不在本次修改范围，独立待处理。专项33项通过不能替代全工程通过。


2026-11-16 命中反馈V1：新增粒子/声音预建池，命中不读GPU。后台不限帧时，按40个渲染帧重置的回放可能尚未进入技能释放，不能作战斗性能证据；使用`--max-fps 60`执行既有profile脚本，确认日志实际HIT。有效hit-feedback-profile-60.log两组默认p95约16.85ms、max约17.16ms，read_calls=0；本机短样本，无PNG录制。具体四组结果与实现边界见[命中反馈说明](HIT-FEEDBACK.md)。
