# 敌人动作补查与返修

用户指出并非所有敌人的动作都已处理完整。本轮将“有新图”与“实际连续状态表现完成”分开检查，不以帧数或节点visible代替动态验收。

## 本轮四套64张绘图

| 对象 | 问题 | 修正 |
| --- | --- | --- |
| 膜上捕食者 | 主要攻击已换图，脱身后的return仍回退旧姿势 | 新绘16张伞膜收张、触手随动的回挂游动；给保留原move_key的四个入口登记明确别名 |
| 老守护者 | 独立reground仍播旧回稳，不只发生在撑跃之后 | 新绘16张立杖、换脚、回稳；五个前置招式都可进入，复制active与幻影仍归原实现 |
| 栖污大甲 | 压砸前摇主要是小幅变化，实际尺寸难辨意图 | 重绘16张：前肢与前身明显抬高、压下、回收；替换press的三个原阶段 |
| 负壳守卫 | 顶壳准备与刺针的轮廓过于接近 | 重绘16张：收针、后倾蓄势、壳沿顶出、恢复；替换shell_push的三个原阶段 |

食腐甲、缠巢鳗、泵庭执卫和封梁卫本轮复查实际出招路径，未另称新绘。地下dive/tunnel、水遁wash、复制active/recover保留原专用呈现，不将这些例外悄悄计作新身体动画。素材保留candidate，用户尚未认可。

## 来源与确定性导出

`requests.json`与`readable-requests.json`保存内置image_gen完整提示词和身份参考；原件在上级`masters/`，模型名称未由工具暴露。老守护者首稿相邻角色核心间隔仅4像素，12像素扩边会切入邻格；首稿保存为`elder_reground-spacing-rejected.png`，按`elder-padding-request.json`定向返修。新原件16个完整核心、透明边距及导出源RGBA一致性重新检查；生成返修可能重绘细节，不声称原像素不变。

运行`python assets/source/combat-animation-v2/followup/build.py`复用原连通角色提取与统一根流程，生成4张PNG、`animations-followup.json`及`production.json`。回稳第一张是蹲姿，统一尺度读取最后立稳帧的实体高度，避免把蹲姿放大成站高。所有动作只采用一个固定尺度；没有生成插值或几何替身。

`register.py`先合并normal/special，再按action/state/pulse精确替换followup条目，避免旧数据抢先被sample选中；原件和旧候选保留。新增2段与重绘2段分别计数，不能把旧替换候选也重复算作当前活动帧。共享台账和manifest保留其他工作项内容。

## 验证入口与边界

- `test_enemy_animation_transitions.gd`：通过真实begin_attack和物理推进检查回挂、非撑跃第三招后的回稳、复制保护及两个强化准备图。初版三个用例均失败，修复后扩为四项。
- `enemy_animation_flow_qa.gd`：遍历八类敌人真实状态；明确的出场位置、来源技能、受压刺激和格挡命中夹具不等于自然AI通关。例外专用呈现列入报告，其他无新身体状态计失败。
- `enemy_animation_v2_qa.gd`：手动GPU夹具补上每种捕食者return和每种老守护者reground，不再只抽主要攻击段。它不证明伤害、自然战斗或输入手感。
- 原地回稳按既有逻辑可在首帧立即结束；有实际返程距离才呈现较多帧。不得延长技能/AI时序强制播完整图集。回归使用真实贯刺产生位移，避免原地夹具误判。

完整结果以本轮`game/progress.md`与`game/build/qa/enemy-followup-*`日志为准。当前人工看过深浅底板与原生尺寸板，实际GPU和运行检查继续独立记录；不自动提交、推送或发布。
