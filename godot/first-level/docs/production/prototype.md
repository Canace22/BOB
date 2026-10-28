# P03原型复验通过
实际Godot4.7.2运行五房，InputMap输入驱动由起点走跳至Boss、击败180耐受Boss、E授A1、三段空中冲刺、尾端交互结关。未在首通测试中传送、开无敌、增伤、跳过Boss或直接写能力。
原始prototype.json记录每次输入/伤害/换房/授能。故障夹具combat.json测试同帧重复伤害保护、无伤坠落与营地重生。旧viewport.png被美术接入后截图覆盖，摘要检查已将本阶段正确标为stale，未伪造旧图。
独立Computer Use窗口捕获两次超时；采用Godot实际viewport截图作为视觉证据，未使用假截图。
返修：测试驾驶器避开跨沟锁敌；Boss上层平台设置单向以免玩家头顶横梁阻断跳跃。上层平台仍有顶面碰撞，不删除挑战。
当前复验使用 evidence/fixed-run/prototype.json、combat.json、view-42.png、playthrough.mp4。实机图已包含新原画；角色/镜头/菜单/保存修复的源码冻结在 evidence/fixed-source.zip。正常完整通关与边界夹具分开；结果见 evidence/fixed-run/review.md。
