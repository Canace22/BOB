import json
from pathlib import Path
p=Path('G:/鲸落万物生/BOB/godot/first-level')
r=p/'evidence/v02/release2-run'
run=json.loads((r/'prototype.json').read_text('utf8'))
reload=json.loads((r/'persistence.json').read_text('utf8'))
perf=json.loads((r/'performance.json').read_text('utf8'))
assert run['passed'] and reload['passed']
for path in ['sample-final/sample.json','branch-final/branch.json','branch-final/latch-reload.json','regression/integration-v1.json','regression/combat.json','fall-final/fall.json','water-v2/water.json']:
    assert json.loads((p/'evidence/v02'/path).read_text('utf-8-sig'))['passed'],path
report=f'''# v0.2 五房实机验收

2026-10-27，审查者agent。固定 Godot4.7.2，GL Compatibility，Windows，1280×720；i5-14600K / NVIDIA RTX5060（真实设备见release2-run.log）。不是低配机器认证，也不是人工审美签收。

## 已实现并运行验证

| 项目 | 实际结果 | 证据（相对工程） |
|---|---|---|
| 独立五房通关 | {run['seconds']:.1f}秒、玩家死亡{run['deaths']}次，走跳/战斗/Boss/冲刺/育窝/终点通过 | evidence/v02/release2-run/prototype.json、complete.png、release2-run.log |
| 独立重载 | 退出进程后再启动，Boss/能力/育窝/结关保持 | evidence/v02/release2-run/persistence.json、release2-load.log |
| 须筛样板 | 10项，素材/连续动态/暂停/灯罩/通行/攻击与恢复 | evidence/v02/sample-final/sample.json；sample-v2.mp4为实际Godot录像 |
| 舌台支路 | 8项，跳上U0、碎片后再E开闩、桥展开、双向往返、死后/换房保存 | evidence/v02/branch-final/branch.json、branch-open.png |
| 机关重载 | 另进程读到latch，恢复桥碰撞 | evidence/v02/branch-final/latch-reload.json |
| 状态边界 | 21项暂停/地图/动作互斥/反向门/奖励唯一/损坏档回退 | evidence/v02/regression/integration-v1.json |
| 受击与复活 | 无敌窗口/跌落恢复/死亡回营地 | evidence/v02/regression/combat.json |
| 致死坠落修复 | 7项，事件一次、特效、0.30秒后复活、玩家档不变 | evidence/v02/fall-final/fall.json、fall-death.png |
| 落地水纹修复 | 7项，实际跳落触发、空中/干区无触发、位置正确、玩家档不变 | evidence/v02/water-v2/water.json、landing-ripple.png |

完整通关为输入驱动自动测试：无房间传送和Boss胜利作弊，但驱动器选择动作与角色朝向，不能替代真人难度测试。专项测试明确使用HP/位置/存档夹具；它们只验证对应分支。主线通关未拾取可选支路物，支路由独立测试覆盖。正常save-v1.json从未作为QA目标。

## 动态与资产覆盖

| 需求 | 实现位置 | 验证与范围 |
|---|---|---|
| 视差 | scripts/backdrop.gd、atmosphere.gd | 实际Camera2D位置驱动；五房连续截图可看镜头/背景分离 |
| 漂移雾 | atmosphere.gd middle层 | 样板前后状态变化及暂停冻结 |
| 浮动生物 | atmosphere.gd | 有限9个生物，无无限实例化；样板状态与运行截图 |
| 尘埃 | atmosphere.gd foreground层 | 36个固定点更新；录像/源码观察，未单设粒子数量断言 |
| 须帘摆动 | atmosphere.gd | 边缘摆动，终房无鲸须；样板状态/终房截图 |
| 灯光变化 | atmosphere.gd、player.gd | PointLight2D，L开关及呼吸亮度已测 |
| 水波纹 | atmosphere.gd、level.gd、event_fx.gd | 环境循环加落地震动；实际水带位置发ripple，非游泳/流体系统 |
| 攻击弧 | player.gd、event_fx.gd | 攻击有效阶段驱动，弧线后段为残影/重鸣余波，不是额外伤害 |
| 命中反馈 | enemy.gd、player.gd、level.gd、event_fx.gd | 真实命中闪色、短震、迸发；样板计数及Boss实机 |
| 死亡效果 | enemy.gd、player.gd、event_fx.gd | 敌/玩家受击死亡和致死坠落；一次事件与恢复已测 |
| 机关动画 | level.gd、atmosphere.gd | 配重落下/桥0.5秒展开后碰撞，重载直接恢复，不重复奖励 |

新植物/灯/门框/水带/鲸须/配重是独立透明资源；地形和角色复用已记录资产。源图、母版、运行版分开。具体尺度、透明边缘与锚点在asset-delivery.json。画面实际检查见sample-review.md；Boss与终房新版截图保持可读平台边缘和人体定位，不在咽后重复上颚鲸须。

水纹规格实施说明：原合同提出水接触；现有首关是实体平台走跳，本轮实现落地震动带动平台下方水带，未增加涉水区域。专项截图为展示低处水纹临时向下取景，非默认镜头处处可见的证明；默认P0水带靠近HUD属于打磨项。

## 性能与限制

最终包真实渲染采样{perf['samples']}帧（剔除前120帧）：P50 {perf['p50_ms']:.2f}ms，P95 {perf['p95_ms']:.2f}ms，最大 {perf['max_ms']:.2f}ms，>33.3ms {perf['frames_over_33ms']}帧。含每2秒PNG截图开销，不能据此宣称零卡顿；MovieWriter定帧录像不用于性能结论。完整原始指标保留在release2-run/performance.json。

仍待完善：角色完整跑动及左右侧连续原画；地形模块重复；Boss关键姿势动画；完整独立门扇（当前门框+触发）；低配测试及真人试玩；主观音效试听not_run。玩家攻击仍为现有距离/高度判定，敌人攻击改为与可视提示共用矩形；未宣称全面像素级判定。水带非游泳；后续器官区域未开发。

本轮无第三方付费生成；内置图像生成一张透明部件图，源/提示已保存，服务实际计费未知，不声称免费。审查是AI技术与视觉审查，非用户人工签收。
'''
(p/'docs/v02/qa.md').write_text(report,encoding='utf8')
print('QA report written from passed final evidence')

