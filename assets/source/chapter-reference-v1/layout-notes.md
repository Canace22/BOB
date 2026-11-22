# 连续章节白盒空间参照V1

本批只接独立白盒入口第2–12章，不重构或生成正式19房。正式地图重构是另一项任务。本文件交接可走空间、锚点和碰撞边界；位图状态选择不是新人物动作或完整开闸动画。

## 所有权与开关

- 独立配置：`game/content/prototypes/chapter_reference/layouts.json`；资源及原图锚点换算：同目录`resources.json`。
- 脚本：`game/src/prototypes/chapter_reference/`。安装缝只在chapter_two/main、chapter_three/main、chapter_run/main和各自view；没有改剧情flow、HUD、Boss AI或chXX.json。
- 默认启用；命令行用户参数`--no-reference`显式回到原几何调试场景，同时不创建新增侧台碰撞。
- 原view在参考模式不画背景色板、平台色块、物件框。保留交互目标与文字；标签全局z20，老守护者Sprite维持原全局z3。参考位图、原角色、UI各有独立层级。
- `host.point`式坐标转换只做一次：参考根节点position=-origin，内部布局仍用章节原坐标。第5/7/8/12章的特殊敌人试验场范围保持原来物理与脚线；参考层只显示原遭遇已有栏杆，不另造栏杆碰撞。

## 静动选择

| 元素 | 选择 | 原因与执行边界 |
| --- | --- | --- |
| 器官、骨台、承重架、膜面、住巢与记录台 | static | 不让死鲸器官本体运动；不以横向平台拉长成柱。台面以同尺度模块拼接，支架用独立库位图。 |
| 旧瓣、主闸、薄壳归属、巢基高低状态 | 状态代理 | 只读已有任务/阶段事实，选显隐或静态位置，不完成任务、不授能、不写存档，不登记为新动作动画。 |
| 局部水丝/污絮 | 既有KitDriftField | 只用入库fx-particle-drift，按既有进度改变局部流向；数量有界，外部host.elapsed时钟。 |
| 气泡 | 既有EnvironmentBubbleEmitter | 外部时钟、有限实例；近景特别行为不启用。 |
| 水光/灯 | 既有WhalebellySoftUnderwaterLight | 复用透明光体，低强度；不叠加整器官形变。 |

通用个人scene-environment-motion主源本机用户目录未找到；本批已读项目入口及保留的执行合同/配方，不宣称加载了通用主源最新版。

## 资产与锚点

记录台与刻名薄壳来源及精确锚点由本批`assets.json`提供。记录台foot=[0.498074,0.844059]、interaction=[0.5,0.33]；刻名薄壳foot=[0.500781,0.793394]、interaction=[0.5,0.58]。听骨复用world-kit/bone-sound-node。人物与敌人仍用既有完整角色，不新增身份。

旧库bbox/pivot以原图归一化后按实际运行PNG尺寸换算，避免把原图像素锚点直接套到缩图。平台surface使用既有套件的bbox顶部加source surface偏移；foot和surface不同，不能把平台底部pivot当落脚面。footprint按可见alpha8 bbox估算，不包含低Alpha柔光；实际脚底像素仍以GPU与物理落地检查为准。

本配置总计26个新增单向薄台和110个独立静态/状态物件。底路没有新增实心挡块，薄台厚18px，可从下方穿上、走出边缘落回底路；本角色没有S+空格向下穿台动作，本批不新增输入机制。

## 逐章空间与新增侧台

### 第2章

背景：r4-vertebrae-depth；平台：r4-bone-platform；章宽2850。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| upper_watch | 折井上沿／观察与下降 | [50,180,420,120] |
| descent | 旧路逐级下降 | [470,310,480,210] |
| guard_lane | 守卫封路／交锋净空 | [1000,410,820,110] |
| rescue | 下层住巢／断架与救援 | [2040,390,600,260] |
| safe_bank | 居民安全侧台／下方通路保留 | [2420,500,310,150] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch02_upper_branch | [60,240,220,18] | 上沿可站观察支台 |
| ch02_safe_branch | [2400,590,340,18] | 救援区旁可站安全台，底路仍连通 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| entry_arch / arch | foot / [230,335] / 330 | [65,171.4,330,163.6] | 静态 |
| upper_camp / r3-shell-nest-before | foot / [300,300] / 220 | [190,201.9,220,98.1] | 静态 |
| blockade / anchor-pull-gate-closed | foot / [1830,520] / 250 | [1705,114.1,250,405.9] | hide_if=guard_defeated |
| fallen_shell / nursery-shell-support | foot / [1900,650] / 210 | [1795,566.6,210,83.4] | show_if=guard_defeated |
| nest_before / r3-shell-nest-before | foot / [2220,500] / 230 | [2105,397.5,230,102.5] | hide_if=rescue_done |
| nest_saved / r3-shell-nest-before | foot / [2510,590] / 240 | [2390,483,240,107] | show_if=rescue_done |
| rescue_support / support | foot / [2230,690] / 250 | [2105,440.5,250,249.5] | 静态 |
| safe_support / support | foot / [2560,810] / 220 | [2450,590.4,220,219.6] | 静态 |
| tether_left / red-tether-segment | foot / [2180,416] / 220 | [2070,406.3,220,19.3] | 静态 |
| tether_right / red-tether-segment | foot / [2310,416] / 220 | [2200,406.3,220,19.3] | 静态 |

### 第3章

背景：r3-gastric-depth；平台：r3-bank-platform；章宽3550。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| residence | 居住高岸／菌床与巢底 | [480,360,600,160] |
| combat | 废弃低坑／交锋净空 | [1150,570,1100,80] |
| outlet | 旧瓣／下游排水口 | [2010,420,240,230] |
| exit | 修复后通往脂库 | [3090,390,400,130] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| 无 | — | 沿用原高低路线，未新增物理面 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| camp / r3-low-shell-camp-v3 | foot / [760,520] / 340 | [590,377.3,340,142.8] | 静态 |
| bed_base / nursery-shell-support | foot / [730,520] / 290 | [585,404.8,290,115.2] | 静态 |
| bed_alive / habitat-fungus-bed | foot / [730,510] / 270 | [595,409.9,270,100.1] | hide_if=valve_opened |
| valve / nursery-valve-leaf | foot / [2130,660] / 75 | [2101.5,463,75,204.1] | 静态 |
| channel / r5-tail-channel | foot / [1730,780] / 1050 | [1205,618.2,1050,161.8] | 静态 |
| right_pier / support | foot / [2410,660] / 190 | [2315,470.4,190,189.6] | 静态 |
| safe_shell / nursery-shell-support | foot / [900,520] / 190 | [805,444.5,190,75.5] | show_if=valve_opened |
| recovered_shell / nursery-shell-support | foot / [480,520] / 75 | [442.5,490.2,75,29.8] | hide_if=salvage |
| settlement_exit_barrier / anchor-pull-gate-closed | foot / [3268,520] / 220 | [3158,162.8,220,357.2] | hide_if=repaired |

### 第4章

背景：r3-gastric-depth；平台：r3-bank-platform；章宽3800。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| gathering | 采集沟／旧组织与菌膜 | [410,420,320,100] |
| low_observation | 底层旁通／安全观察路 | [650,390,170,130] |
| upper_wild | 上层废采沟／可选遭遇 | [1180,180,350,130] |
| refuge | 水线住巢／可达避流架 | [1690,340,350,180] |
| sluice | 窄口压壳／上下游水路 | [2110,360,240,160] |
| sampling | 试流水位／壳样记录 | [2580,360,500,160] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch04_refuge_ledge | [1740,450,250,18] | 抬巢后的避流架；底层仍可穿行 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| record / record-stand | foot / [540,520] / 210 | [435.1,381.5,210,138.7] | 静态 |
| empty_growth / r3-liver-edge | foot / [640,560] / 340 | [470,460.2,340,99.8] | 静态 |
| upper_support / support | foot / [1320,570] / 260 | [1190,310.5,260,259.5] | 静态 |
| refuge_support / support | foot / [1850,670] / 260 | [1720,410.5,260,259.5] | 静态 |
| nest / r3-shell-nest-before | foot / [1840,520] / 230 | [1725,417.5,230,102.5] | raise_if=ch04_homes_above_water; raised_at=[1840,450] |
| limiter / nursery-shell-support | foot / [2200,520] / 150 | [2125,460.4,150,59.6] | 静态 |
| water_channel / r5-tail-channel | foot / [2420,640] / 650 | [2095,539.9,650,100.1] | 静态 |
| sample_table / record-stand | foot / [2700,520] / 210 | [2595.1,381.5,210,138.7] | 静态 |
| record_out / record-stand | foot / [3290,520] / 180 | [3200.1,401.3,180,118.9] | 静态 |

### 第5章

背景：r3-gastric-depth；平台：r3-bank-platform；章宽4000。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| attached_base | 幼体附着巢基／居民区 | [650,360,380,160] |
| covered_refuge | 厚壳遮护侧台／居民退后 | [1040,350,260,170] |
| eel_lane | 空置窄槽／鳗战区保持平整 | [1410,400,1110,120] |
| carry_route | 可走搬巢支路／下方留居通路 | [2650,340,940,180] |
| stay | 留下者缓流住巢／保留系绳 | [3020,345,210,175] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch05_refuge | [1040,460,240,18] | 厚壳后的可达避险侧台 |
| ch05_carry_a | [2660,460,300,18] | 战后搬运路起点 |
| ch05_stay_branch | [3000,460,210,18] | 留居住巢侧台；不拆底路 |
| ch05_carry_b | [3310,460,290,18] | 轻巢接力台 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| base / nursery-shell-support | foot / [850,520] / 260 | [720,416.7,260,103.3] | 静态 |
| refuge_shell / r3-shell-nest-before | foot / [1160,460] / 240 | [1040,353,240,107] | 静态 |
| refuge_pier / support | foot / [1160,700] / 240 | [1040,460.5,240,239.5] | 静态 |
| inner_arch / arch | foot / [1950,650] / 820 | [1540,243.6,820,406.4] | 静态 |
| carry_base / nursery-shell-support | foot / [2780,460] / 250 | [2655,360.7,250,99.3] | 静态 |
| carry_pier / support | foot / [2790,700] / 240 | [2670,460.5,240,239.5] | 静态 |
| stay_nest / r3-shell-nest-before | foot / [3110,460] / 190 | [3015,375.3,190,84.7] | 静态 |
| stay_tether / red-tether-segment | foot / [3150,430] / 160 | [3070,423,160,14.1] | 静态 |
| handover / nursery-shell-support | foot / [3460,460] / 230 | [3345,368.6,230,91.4] | 静态 |
| carry_tether / red-tether-segment | foot / [2920,420] / 300 | [2770,406.8,300,26.4] | 静态 |
| carry_tether_b / red-tether-segment | foot / [3320,420] / 300 | [3170,406.8,300,26.4] | 静态 |

### 第6章

背景：r2-lung-depth；平台：r2-membrane-platform；章宽4200。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| sheltered | 下方残壁窗／安全观察路 | [640,350,215,170] |
| exposed | 上层暴露台／可选捕食者 | [1180,170,380,140] |
| samples | 强流口／避流口／内水对照槽 | [2060,360,480,160] |
| protected_membranes | 两片脆膜／保留封片 | [2950,320,430,200] |
| candidate_inlet | 完整支撑避流台／候选引水位 | [3410,340,250,180] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch06_inlet_branch | [3410,460,260,18] | 可以站稳查看完整支撑的避流侧台 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| sheltered_roof / arch | foot / [744,430] / 240 | [624,311,240,119] | 静态 |
| upper_pier / support | foot / [1360,570] / 260 | [1230,310.5,260,259.5] | 静态 |
| old_marks / record-stand | foot / [1780,520] / 200 | [1680.1,388.1,200,132.1] | 静态 |
| fast_sample / nursery-shell-support | foot / [2130,520] / 110 | [2075,476.3,110,43.7] | 静态 |
| shelter_sample / nursery-shell-support | foot / [2300,520] / 110 | [2245,476.3,110,43.7] | 静态 |
| inner_sample / nursery-shell-support | foot / [2470,520] / 110 | [2415,476.3,110,43.7] | 静态 |
| sample_table / record-stand | foot / [2740,520] / 240 | [2620.1,361.7,240,158.5] | 静态 |
| weak_membrane_a / r2-membrane-patch | foot / [3050,510] / 190 | [2955,432.5,190,77.5] | 静态 |
| weak_membrane_b / r2-membrane-patch | foot / [3260,510] / 190 | [3165,432.5,190,77.5] | 静态 |
| red_mark_a / red-tether-segment | foot / [3050,440] / 100 | [3000,435.6,100,8.8] | show_if=ch06_protect_membrane_a |
| red_mark_b / red-tether-segment | foot / [3260,440] / 100 | [3210,435.6,100,8.8] | show_if=ch06_protect_membrane_b |
| inlet_support / support | foot / [3530,700] / 240 | [3410,460.5,240,239.5] | 静态 |
| inlet_map / record-stand | foot / [3530,460] / 200 | [3430.1,328.1,200,132.1] | 静态 |

### 第7章

背景：r2-lung-depth；平台：r4-bone-platform；章宽3600。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| evidence_forecourt | 供养记录前庭／可站副台 | [750,340,660,180] |
| narrow_exit | 向左撤离窄道／不改原战场 | [1480,380,320,140] |
| pump_lane | 泵庭交锋区／平整退路 | [1525,400,1140,120] |
| maintenance | 维护裂隙／返回出口 | [80,370,400,150] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch07_evidence_branch | [790,460,260,18] | 记录前庭的可站工作副台；远离水系执卫战区 |
| ch07_record_branch | [1120,460,250,18] | 供养记录支台；底层留退路 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| samples / record-stand | foot / [970,460] / 220 | [860.1,314.9,220,145.3] | 静态 |
| records / record-stand | foot / [1270,460] / 220 | [1160.1,314.9,220,145.3] | 静态 |
| record_support / support | foot / [1100,700] / 240 | [980,460.5,240,239.5] | 静态 |
| copy_stand / record-stand | foot / [1810,520] / 200 | [1710.1,388.1,200,132.1] | 静态 |
| narrow_frame / arch | foot / [1660,560] / 260 | [1530,431.1,260,128.9] | 静态 |
| pump_membrane / r2-membrane-patch | foot / [2500,520] / 300 | [2350,397.6,300,122.4] | 静态 |
| exit_arch / arch | foot / [220,540] / 320 | [60,381.4,320,158.6] | 静态 |

### 第8章

背景：r4-vertebrae-depth；平台：r4-bone-platform；章宽3600。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| waiting | 滞留住巢／内侧缓流 | [360,340,650,180] |
| beam_lane | 中央承重骨梁／交锋净空 | [1380,350,1110,170] |
| rope_anchor | 战后通行索桩／可走支台 | [2730,340,340,180] |
| settle | 内侧安置骨台／继续搬巢 | [3140,340,380,180] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch08_waiting_branch | [660,460,300,18] | 住巢检查侧台；不在骨卫战区 |
| ch08_rope_branch | [2740,460,340,18] | 通行索桩工作台 |
| ch08_safe_branch | [3160,460,340,18] | 安置住巢的内侧稳台 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| waiting_nest / r3-shell-nest-before | foot / [500,520] / 240 | [380,413,240,107] | 静态 |
| attached_nest / nursery-shell-support | foot / [900,460] / 220 | [790,372.6,220,87.4] | 静态 |
| water_marks / record-stand | foot / [1240,520] / 190 | [1145.1,394.7,190,125.5] | 静态 |
| beam_arch / arch | foot / [1940,680] / 1040 | [1420,164.5,1040,515.5] | 静态 |
| rope_mount / bone-anchor-ring | foot / [2820,460] / 80 | [2775.2,424.7,80,104.8] | 静态 |
| rope_pier / support | foot / [2900,700] / 240 | [2780,460.5,240,239.5] | 静态 |
| rope_span / red-tether-segment | foot / [3050,425] / 360 | [2870,409.2,360,31.6] | show_if=ch08_restore_rope |
| inside_pier / support | foot / [3310,700] / 240 | [3190,460.5,240,239.5] | 静态 |
| inside_nest / r3-shell-nest-before | foot / [3290,460] / 240 | [3170,353,240,107] | 静态 |
| name_record / record-stand | foot / [2970,520] / 170 | [2885.1,407.9,170,112.3] | 静态 |
| name_shell / name-shell | foot / [2960,416] / 42 | [2939,361.1,42,54.3] | show_if=ch08_shell_held_by_guard |

### 第9章

背景：r4-vertebrae-depth；平台：r4-bone-platform；章宽3600。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| route_map | 骨壁道路／搬运前庭 | [400,330,600,190] |
| wild_lane | 外侧骨台／野生遭遇净空 | [1020,390,900,130] |
| success | 稳定菌床／内水侧台 | [2010,340,370,180] |
| failure | 失败新巢／待封外水口 | [2480,360,400,160] |
| inner_safe | 内侧临时安置／回流核对 | [2890,335,540,185] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch09_growth_branch | [2010,460,340,18] | 稳定菌床观察支台 |
| ch09_inner_branch | [2900,460,430,18] | 失败住巢移入后的内侧稳台 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| road_record / record-stand | foot / [550,520] / 220 | [440.1,374.9,220,145.3] | 静态 |
| waiting_nest / r3-shell-nest-before | foot / [900,520] / 200 | [800,430.8,200,89.2] | 静态 |
| carry_rope / red-tether-segment | foot / [1580,480] / 330 | [1415,465.5,330,29] | 静态 |
| success_bed / habitat-fungus-bed | foot / [2140,460] / 260 | [2010,363.6,260,96.4] | 静态 |
| old_camp / r3-shell-nest-before | foot / [2340,520] / 200 | [2240,430.8,200,89.2] | 静态 |
| failed_base / nursery-shell-support | foot / [2570,520] / 230 | [2455,428.6,230,91.4] | 静态 |
| failed_inlet / tail-flow-shutter | foot / [2800,520] / 150 | [2797.3,476.3,150,85.8] | 静态 |
| inside_nest / r3-shell-nest-before | foot / [3060,460] / 250 | [2935,348.5,250,111.5] | 静态 |
| inner_pier / support | foot / [3100,700] / 240 | [2980,460.5,240,239.5] | 静态 |
| comparison / record-stand | foot / [3320,520] / 190 | [3225.1,394.7,190,125.5] | 静态 |
| name_shell / name-shell | foot / [3310,404] / 42 | [3289,349.1,42,54.3] | hide_completed=ch09_receive_name_shell |
| carried_name_shell / name-shell | foot / [0,0] / 42 | [-21,-54.9,42,54.3] | show_completed=ch09_receive_name_shell; follow_player=true |

### 第10章

背景：r5-cranial-depth；平台：r5-cranial-platform；章宽3600。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| archive | 旧歌腔档案／低骨台支路 | [570,310,360,210] |
| shell_slot | 刻名薄壳槽／保留返回路线 | [1180,320,330,200] |
| memory | 无刻写骨面／回声净空 | [1810,160,660,360] |
| copy_names | 名录拓印台／返回取壳 | [2680,320,400,200] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch10_archive_branch | [590,460,300,18] | 可站阅档低台 |
| ch10_shell_branch | [1200,460,290,18] | 放回并取走薄壳的可达侧台 |
| ch10_names_branch | [2690,460,340,18] | 拓印记录与补录姓名的工作支台 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| archive / record-stand | foot / [720,460] / 250 | [595.1,295.1,250,165.1] | 静态 |
| shell_slot / nursery-shell-support | foot / [1340,460] / 160 | [1260,396.4,160,63.6] | 静态 |
| name_shell / name-shell | foot / [1340,440] / 42 | [1319,385.1,42,54.3] | show_if=ch10_set_shell; hide_if=ch10_take_shell |
| echo_bone / bone-wall | foot / [2150,520] / 500 | [1900,-230,500,750] | 静态 |
| copy_table / record-stand | foot / [2850,460] / 240 | [2730.1,301.7,240,158.5] | 静态 |
| archive_pier / support | foot / [735,700] / 240 | [615,460.5,240,239.5] | 静态 |
| names_pier / support | foot / [2860,700] / 240 | [2740,460.5,240,239.5] | 静态 |

### 第11章

背景：r5-cranial-depth；平台：r5-cranial-platform；章宽4000。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| lung_contact | 肺缘方向／可站触点 | [490,310,280,210] |
| pump_contact | 泵庭方向／可站触点 | [1040,310,280,210] |
| tail_contact | 尾根方向／可站触点 | [1590,310,280,210] |
| evidence | 回水与供养记录台 | [2100,335,420,185] |
| plan | 分流图工作面／住巢保护 | [2670,300,480,220] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch11_lung_branch | [490,460,260,18] | 肺缘触点支台 |
| ch11_pump_branch | [1040,460,260,18] | 泵庭触点支台 |
| ch11_tail_branch | [1590,460,280,18] | 尾根触点支台 |
| ch11_evidence_branch | [2110,460,350,18] | 双记录比对工作台 |
| ch11_map_branch | [2700,460,430,18] | 分流图宽工作台 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| lung_node / bone-sound-node | foot / [620,460] / 85 | [577.5,323.1,85,136.9] | 静态 |
| pump_node / bone-sound-node | foot / [1170,460] / 85 | [1127.5,323.1,85,136.9] | 静态 |
| tail_node / bone-sound-node | foot / [1730,460] / 85 | [1687.5,323.1,85,136.9] | 静态 |
| lung_bearing / support | foot / [620,700] / 240 | [500,460.5,240,239.5] | 静态 |
| pump_bearing / support | foot / [1170,700] / 240 | [1050,460.5,240,239.5] | 静态 |
| tail_bearing / support | foot / [1730,700] / 240 | [1610,460.5,240,239.5] | 静态 |
| evidence / record-stand | foot / [2270,460] / 250 | [2145.1,295.1,250,165.1] | 静态 |
| map_table / record-stand | foot / [2880,460] / 290 | [2735.1,268.7,290,191.5] | 静态 |
| map_bearing / support | foot / [2890,720] / 260 | [2760,460.5,260,259.5] | 静态 |

### 第12章

背景：r5-tail-depth；平台：r4-bone-platform；章宽4700。

| zone | 职责 | 章节坐标footprint [x,y,w,h] |
| --- | --- | --- |
| return_shell | 交还刻名薄壳／记录台 | [450,330,330,190] |
| inner_residents | 内侧住巢侧台／避开决斗 | [870,320,350,200] |
| duel | 主闸前对抗区／保留原平整站位 | [1330,350,1120,170] |
| safe_brace | 伤者稳台／旧撑与锚 | [2650,330,550,190] |
| tail_channel | 行走面下方退流槽／有限外排 | [2850,565,870,180] |
| recovery | 闸后通路／恢复期消息 | [3770,330,800,190] |

| 新增碰撞面 | [x,y,w,h] | 用途 |
| --- | --- | --- |
| ch12_resident_branch | [870,460,330,18] | 决斗区之前的内侧住巢台 |
| ch12_safe_branch | [2670,460,460,18] | 战后伤者与稳闸作业支台 |
| ch12_recovery_branch | [3760,460,400,18] | 闸后恢复段稳台 |

| 对象 / 资产 | anchor / chapter at / 可见宽 | alpha8估算footprint [x,y,w,h] | 状态边界 |
| --- | --- | --- | --- |
| return_table / record-stand | foot / [600,520] / 250 | [475.1,355.1,250,165.1] | 静态 |
| returned_shell / name-shell | foot / [600,390] / 42 | [579,335.1,42,54.3] | hide_completed=ch12_return_name |
| resident_nest / r3-shell-nest-before | foot / [1030,460] / 250 | [905,348.5,250,111.5] | 静态 |
| resident_bearing / support | foot / [1030,700] / 240 | [910,460.5,240,239.5] | 静态 |
| gate_closed / release-sluice-closed | foot / [2880,535] / 480 | [2640,357.6,480,177.4] | hide_if=ch12_shift_narrow_cover |
| gate_open / release-sluice-open | foot / [2880,535] / 480 | [2640,356.9,480,178.1] | show_if=ch12_shift_narrow_cover |
| old_brace / support | foot / [2910,720] / 260 | [2780,460.5,260,259.5] | 静态 |
| old_anchor / bone-anchor-ring | foot / [3020,460] / 80 | [2975.2,424.7,80,104.8] | 静态 |
| retreat_channel / r5-tail-channel | foot / [3340,760] / 850 | [2915,629,850,131] | 静态 |
| safe_shell / nursery-shell-support | foot / [2755,460] / 210 | [2650,376.6,210,83.4] | 静态 |
| life_camp / r3-shell-nest-before | foot / [3920,460] / 270 | [3785,339.6,270,120.4] | 静态 |
| life_growth / habitat-fungus-bed | foot / [4130,520] / 230 | [4015,434.7,230,85.3] | 静态 |

## 验证与交接

- 已执行静态检查：11章配置可解析；资源注册齐全、所有路径真实PNG；新增台面宽≥180、厚18；第5/7/8/12新增侧台均避开敌人固定试验场范围；定向diff空白检查通过。静态检查不代替可见性与通关。
- 主Agent已报告：Godot check零错误；第3/4章GPU截图中骨架承重、低坑、旧瓣与住巢可见且missing=[]。证据：`game/build/qa/chapter-reference/ch3-view1.png`、`ch4-view1.png`。
- 主Agent已报告：第2章15项、第3章16项及第4–12章真实键盘87项通过；第4新台从(1640,520)按D+空格跳到(1853.76,449.995)。这些证据不代替后来新增薄壳归属显隐与每个物件的逐态截图。
- 新增`game/tests/test_chapter_reference.gd`，待主Agent串行执行：真实Texture解码；实际物理射线验证offset应用一次；状态切换不写flags/completed且不累积抬巢位移；实际探针从台下穿上并落稳；薄壳交接/置槽/取回显示状态。测试不是正式动画或审美验收。
- 待主Agent补：从第4侧台走出边缘落回底路；其余新增支台自然跳跃与往返；2–12逐章局部/全景截图的层级、目标道具比例、台面接地；主闸开闭图与刻名薄壳归属逐态检查。

第8薄壳仍由负壳守卫持有，第9交接完成后才随主角显示；第10仅放入槽后显示、取回后隐藏；第12交还阶段结束后不在记录台继续留一份。这些仅选既有事实的呈现，不改薄壳真实剧情归属。
