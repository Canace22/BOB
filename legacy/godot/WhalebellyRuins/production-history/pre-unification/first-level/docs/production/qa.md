# 综合验收记录
审查者：agent。技术/运行已执行；玩家主观手感和音色审美尚无人类签收。

- 固定环境：Windows，Godot4.7.2.stable.official.ed1daf0bf，OpenGL3.3 Compatibility，1280×720；i5-14600K/RTX5060。
- 主线：evidence/fixed-run/playthrough.mp4 为实际渲染录制，五房完整通关；prototype.json 记录Input驱动事件。
- 故障恢复与持久状态：combat.json、integration-v1.json、persistence.json。真实正常玩家档未被测试覆盖。
- 视觉：检查原始角色透明图、引擎最终尺寸和实际录像抽帧。角色与地形分层；攻击前摇/命中闪色/跳跃跨扫、半血二扫与冲刺可辨。动作采用有限关键姿势，不能当作最终动画质量。
- 音频：11种原创程序合成WAV，动作事件调用真实AudioStreamPlayer；实际录像音轨已解码，77.97秒，峰值0.1933FS，非零样本1063567，削波0。详见 audio.md、evidence/fixed-run/audio-check.json。模型音频输入不受支持，主观试听为not_run；没有用数值冒充“听起来好”。
- 性能：evidence/integration-run/performance.json 为非MovieWriter实际窗口渲染4309帧，p50 16.67ms、p95 16.85ms，37帧超过33ms，最大146.70ms；包含截图读回与换房长帧。MovieWriter固定帧率不能用于性能结论。独立包另有 standalone-run 性能结果。
- 已修复：营地截获左门、暂停组合状态错乱、无效保存编号、地形带入邻图残片、右入口错误、冲刺动作互斥、奖励支台缺失。
- 保留历史：原灰盒试错1–5日志、被发现过期的截图说明、集成失败的原始JSON。没有修改失败证据。
- 最终独立包：standalone-run/prototype.json通过，零死亡77.88秒（自动驱动）；4304帧，p50/p95均16.67ms，最大143.35ms，37帧超过33.3ms。截图读回/换房的长帧仍保留，不以均值隐藏。standalone-run/engine.log无错误与退出泄漏告警。
- 音频事件窗口复核：93个跳跃/攻击/命中/冲刺事件全部在-0.08至+0.35秒窗口中有非静音输出；这是混音时序证据，不能分离重叠音色或代替主观试听。

