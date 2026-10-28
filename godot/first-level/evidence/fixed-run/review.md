# 首关修复复验
审查者 agent，2026-10-27。固定引擎 Godot 4.7.2 / OpenGL Compatibility。
prototype.json 和 movie.log：从R1-01起，真实 InputMap 动作，途经五房，击败180HP负壳蟹，E承接A1，三次空中冲刺过沟，E完成；没有传送、无敌或伤害作弊。夹具与此分开。77.97秒是自动驱动时间，不是对真人时长的承诺。
combat.json：受击无敌不连扣，坠落返回稳定台，归零回营地。
integration-v1.json：21项独立夹具通过。包含暂停冻结/地图组合/完成页退出、冲刺中重鸣调息互斥、每次离地限一次冲刺、所有右入口、营地与左门分离、战中不回血、碎片/A1/H1唯一领取和三种坏档恢复。夹具位置/生命/存档设置只用于边界验证。
persistence.json：另起进程，读到 checkpoint3、boss=true、dash=true、habitat=true、complete=true。
历史失败 evidence/integration-run/persistence.json 和 integration-v1.json 保留：数字浮点类型使Array包含校验失败、菜单Input轮询错相。现已改显式数字校验和物理帧UI轮询。
动态依据是真实MovieWriter录像和45–47秒6fps抽帧，而非原画拼动画。音轨实际非零且无削波；主观试听工具不支持音频输入，因此未声称听感验收。

