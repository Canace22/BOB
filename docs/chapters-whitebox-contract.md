# 第4–12章并行白盒合同

用户已授权子Agent并行开发，主Agent统一运行器与接线。范围为连续可玩白盒，不替换正式19房、不补正式美术、不提交推送。创作遵循原稿与已认可的第2–3章：具体处境、人能说出来的话，不能凭鲸歌获取他人认同；不写“得试”式刻意省略。使用 H:/Git/BOB/.agents/skills/humanizer/SKILL.md。

## 文件所有权

内容Agent各自只写 `game/content/prototypes/chapters/chXX.json` 和自己的设计说明，主Agent写 `game/src/prototypes/chapter_run/` 统一运行器、测试、全局README/progress、字体及第3章接线。禁止修改共用战斗、其他Agent文件；不要运行Godot或生成字体，避免并行导入冲突。完成后JSON解析、ID/依赖自查，汇报内容/边界。

## JSON v1（所有章节可直接由运行器消费）

根字段：`id` 整数4..12，`title`，`location`，`summary`，`platforms` [[x,y,w,h],...]，`spawn` [x,y]，`width` 默认3600，`props` [{id,label,rect:[x,y,w,h],color:"6a776f"}]，`stages` 数组，`next` 下章整数或0。只用明确标记的几何代理与已有敌人/角色；地面统一y520为宜，台阶差<=70，平地不能有假空气墙。

每个stage：`id`本章唯一，`kind`，`objective`短句，`checkpoint`[x,y]，`at`[x,y]（阶段目标），`radius`默认140。进入stage不瞬移玩家，checkpoint仅用于R恢复。阶段全部稳定ID顺序保存，终止不能越章。可选 `actor_at` 在战后将已结束角色身体作为位移代理移至当地稳台，不移动玩家，也不冒充新动画。阶段种类：

- `dialogue`：玩家靠近at后主动触发 `lines` [[说话人,正文],...]；Esc跳过仍完成本阶段；不会附带危险操作。
- `explore`：`tasks` 数组，每项 {id,label,at:[x,y],lines:[[说话人,正文]],requires:[本章已完成taskID],grant:[事实ID]}。站目标附近按F完成；`required`:[taskID...] 必须完成的清单，或 `any`:[taskID...] 二选一。依赖只能引用本章已存在任务或之前阶段task/flag，不能造跨章隐形前置。可选观察不能锁敌人。每章至少一个实际位置操作，不能全是站着点对白。
- `battle`：靠近at自动预警0.8秒后开战。`enemy`:{profile:0..7,at:[x,y],lane:[min,max],ending:"kill"/"retreat"/"surrender"}。用现有试验场完整行为，胜后停止敌对，不能仅复制外观。enemy可用hp/height/radius/speed/title覆盖本次实例，不改原Catalog。第5章用profile4缠巢鳗，第8章profile6封梁卫且kill，第12章profile7老守护者surrender。必经战斗不能走到出口跳过。
- `escape`：同battle的enemy，但胜利条件是实际到达 `goal`:[x,y]，不要求击杀/输掉。`min_seconds` 默认0，可用于必须应对一次压迫后再撤。第7章用profile5水系执卫，脱离后立即停战接老守护者喝止。
- `observe`：到at按F开始 `duration`秒（建议3..6），显示 `captions`字符串数组，可F跳过至同一终态；用于潮汐/回声/生活结果代理，不空等真实数个潮汐。结束完成阶段。`grant`数组可记录事实。
- `exit`：到at按F完成章，出现继续下一章提示；下一次F切换下一章。第12章next0显示全线白盒结束，能R回访，不循环敌对。

explore可含可选敌人`enemy`同battle，optional:true；其at是触发位置，player可绕到另一观察点完成any，不要求打赢。阶段离开会安全回收敌人及弹体。

事实仅本章内使用；序章文本可以承接上一章确定发生的事，独立启动采用“从本章开始”的上下文摘要，不能偷偷创建前章真实存档。结局/技法权限不新增随机掉落或刷装。最终Boss必须复用现有完整复制/幻影动作，不回退基础敌人。

每章建议4–7个阶段，完整起承转合与实际空间操作，不用长对白凑时长。可选战斗第4/6章必须有真正可走的不战斗路径；第10/11章不得加必经怪。第9章复用野生敌人并核对成功和失败结果。第8章死亡保留完整战后段，不能发奖励祝贺。所有目标写明去哪里、按什么；实际交互可用target箭头，图中标签清楚。最终玩家验收另记，数据与技术通过不等于故事/美术认可。
