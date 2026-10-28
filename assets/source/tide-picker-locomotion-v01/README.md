# 拾潮者 · 基础动作首版

2026-10-28。用户提供角色参考，确认动作参考作品为《空洞骑士》。本批输出 IDLE、Walk、Run 各 8 张透明帧，共 24 帧。**当前为制作候选，不是最终步态美术验收通过版本。**

## 查看与使用

- 双击 [preview.html](preview.html)：可直接本地播放，支持暂停、逐帧、0.25×慢放、深浅背景和94px显示尺寸；不需要服务端。
- [循环动图](review/loops.webp)、[全部帧](review/contact-sheet.png)、[浅底检查](review/light-contact-sheet.png)。
- [Blender工程](tide-picker-locomotion.blend)：Blender 4.2，选择 IDLE / WALK / RUN 场景，各自 1–8 帧；图片全部内嵌。此工程为 **2D 图卡序列与时序母版**，没有3D网格角色、骨骼绑定或分层绘画笔触。
- [PNG和图集](../../runtime/sprites/tide-picker-locomotion-v01/)及[manifest.json](../../runtime/sprites/tide-picker-locomotion-v01/manifest.json)。
- Godot同一项目内打开 [locomotion_preview.tscn](../../../godot/WhalebellyRuins/scenes/characters/locomotion_preview.tscn)，F6。空格暂停、右键头逐帧、1正常速度、2慢放。主关卡与存档保持原版。

| 动作 | 帧数 | 播放速度 | 循环时长 | 当前观察 |
|---|---:|---:|---:|---|
| IDLE | 8 | 6 FPS | 1.333秒 | 呼吸与手臂/灯具轻动；头部有轻微绘图漂移 |
| Walk | 8 | 10 FPS | 0.800秒 | 接触/经过姿势可辨，前后腿身份在接触帧仍不够稳定 |
| Run | 8 | 14 FPS | 0.571秒 | 更大步幅与离地姿势，腿部交替和支撑时序仍需精修 |

统一 512×512 RGBA，朝右，锚点(256,460)，每帧等倍率1:1保留源像素。目标游戏显示高度约94px，统一显示比例94/365。左向应另绘，不把镜像当成保持左右非对称道具设定的正式版本。

## 来源、工具与重跑

`reference.png` 是用户提供的原图副本。`idle-source.png`、`walk-source.png`、`run-source.png` 是内置 imagegen 首轮生成；`walk-revision.png` 和 `run-revision.png` 是局部步态返修并选作当前候选。完整提示词见 `prompts.json`、`revision-prompts.json`。

第二次行走返修 `walk-rejected-r2.png` 错将大腿延伸到灯具前并增大了体积，**已弃用**，保留原件与 `rejected-prompt.txt` 供追溯。未用其覆盖运行帧。

本机Blender MCP未连通；实际通过Blender 4.2 CLI建立序列场景、内嵌24张贴图、设置正交相机、逐帧可见性和三种速度，并渲染各动作首帧检查。没有调用图生3D或收费外部模型。

```powershell
node assets/source/tide-picker-locomotion-v01/build.cjs
blender --background --factory-startup --python assets/source/tide-picker-locomotion-v01/build_blender.py
node assets/source/tide-picker-locomotion-v01/export_preview.cjs
```

`build.cjs`只做裁格和整数平移。原图实际1774×887，不能假定提示词要求的2048×1024已满足。使用四列两行的显式裁格，按每行共同地面与逐帧手工估计骨盆轴注册；不逐帧按可见包围盒缩放，也不把腾空帧的脚底强行贴地。参数记录在脚本与manifest。

## 验收记录

技术检查为agent执行，用户美术签收尚未发生。

1. **通过**：24张不同PNG，全部512×512，真实alpha，alpha≥32轮廓距画布边缘大于5px；原始/8/32阈值包围盒见[technical.json](review/technical.json)。
2. **通过**：深、浅背景合成检查；没有把查看器显示的透明RGB误判为红边。主体未裁断，球壳、青披风、双叉、红绳和灯具可辨。
3. **通过**：Blender保存含3场景/24内嵌贴图，真实渲染见`review/blender-*-01.png`。
4. **通过**：Godot4.7.2导入及测试，真实加载24帧，播放推进、暂停保持、7→0循环、Walk→Run切换均成功；[测试日志](review/godot-test.log)，[实机截图](../../../godot/WhalebellyRuins/evidence/locomotion-v01/playback-a.png)。
5. **部分通过**：浏览器真实加载播放，暂停/逐帧UI已操作检查；姿态在正常与94px尺寸可读。逐帧检查仍发现左右腿身份、头部与躯干稳定性问题。不能将帧切换通过等同于动态自然或最终艺术质量通过。

未完成：严格的双腿交替、移动中的支撑脚锁定、主关卡碰撞/斜坡/转向/起停验收、左向独立素材。下一步优先拆出大腿/小腿/蹼足并在Blender建立2D关节约束，以固定骨长和遮挡关系制作步态，再补绘关节接缝；不要继续用增加图集张数掩盖同腿重复问题。

## 其他动作与技能合同

参考[《空洞骑士》官网](https://www.hollowknight.com/)及[游戏操作手册](https://cdn.pidgi.net/images/5/51/Manual_EN_-_Hollow_Knight.pdf)的移动、跳跃、攻击、冲刺和聚能分类。以下是**本角色的拟定制作节奏**，不是原作实测帧数，也不是本批已制作的技能。

| 优先级 | 动作 | 建议分段 | 关键要求 |
|---|---|---|---|
| P1 | 跳跃/落地 | 起跳压缩2、蹬地2、上升2、顶点1、下落2、落地3 | 空中段由实际速度选帧；落地事件驱动收势 |
| P1 | 冲刺 | 前倾预备1、伸展2、持续2、回收3 | 披风拖后，水平轮廓清晰；位移由角色控制器负责 |
| P1 | 横击/上击/下击 | 蓄势2、发力1、接触1、随势2、收势2 | U形骨鸣器不变三叉；命中窗口单独配置 |
| P1 | 受击 | 接触1、后仰2、恢复3 | 区别于死亡；不循环播放 |
| P2 | 蓄力共鸣 | 收拢3、蓄能循环4、释放2、恢复3 | 灯与鸣器建立能量关系；特效独立序列 |
| P2 | 下砸/向上共鸣/远程波 | 预备、发射/冲击、停顿、恢复 | 参考原作动作意图，采用鲸落世界的波纹/菌光语言 |
| P2 | 空中二段跃/蹬墙 | 各6–8帧 | 需先对照当前玩法是否启用，避免美术自增能力 |
| P2 | 死亡/恢复 | 失衡、蜷缩、灯暗、静止；恢复另组 | 不把壳体粉碎当作默认死亡方式 |

本批不发布网页游戏、不替换旧角色动画；仅新增资产及同一Godot项目的独立评审场景。
