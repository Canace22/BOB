# 当前19房美术与角色覆盖盘点

日期：2026-11-14。范围仅为当前R1七房加后续十二房；不增加36房完整地图或十二章剧情人物。基线：Vesion/V1.0.1，966a793e。

本文件是按原画和当前消费者核对的制作清单，不能作为所有美术已完成或用户已认可的声明。未查看的原图明确留待逐房视觉复核。

## 来源与核对口径

- 当前运行：`game/project.godot`、`game/art/manifest.json`、`game/content/whalebelly/world/recipes/*.json`、`world/rooms.json`、`game/src/campaign/enemies/kit_swarm_visual.gd`。
- 原始需求：`assets/source/whalefall-v5-2-complete/inventory/full-actor-inventory.json`、`full-props-ui-inventory.json`、`full-scene-inventory.json`。这些是2026-10-27的静态盘点，其“missing”字段不能覆盖后来已交付的文件。
- 美术来源：`assets/catalog.json`与`assets/runtime/sprites/<资源ID>/base.png`，背景家族文件名为`background.png`；实际运行以同步清单与场景引用为准，历史`integrationStatus`可能仅指旧Canvas版本。
- 本轮已实际查看原图：`references/51_N01_余索·贝驮·育囊.png`、`22_R3-01.png`、`17_R2-03.png`、`36_R4-06.png`、`40_R5-01.png`、`47_R5-08.png`（目录均为`assets/source/whalefall-v5-2-complete/`）。其余房间已读需求，静态构图待逐房复核。

## 19房覆盖矩阵

“当前”指本批制作前的代码与同步清单，不能用“可复用”代替接入完成。

| 房间 | 当前覆盖 | 对应原画中可复用的补充 | 动静判断与边界 |
| --- | --- | --- | --- |
| R1-01 外伤坡 | 独立绘景、环境动态、营地、门与主角 | 已有成熟场景，核验接地及返回门 | 骨路static；鱼/垂须motion已有制作源，不覆盖旧成果 |
| R1-02 须筛 | 独立绘景、尸蟹动作、三环与两条支路 | `anchor-bone-mount`、`red-tether-knot`可补附着解释 | 基座static；不擅加剪须虾战斗实例 |
| R1-03 舌台 | 独立绘景、两蟹、承重膜与护潮壳 | 奖励领取后空槽可复用`reward-socket-life` | 已有软膜形变motion；奖励视觉需与现用护盾语义保持一致 |
| R1-04 负壳蟹 | 母蟹七房接入、三招、击败持久化 | 原画封战软帘/能力茧另有独立图；先核实当前需求 | 母蟹已有动作；不新增第二只搬壳母蟹 |
| R1-05 流膜育窝 | 冲刺路线、营地、胃枢出口 | `habitat-shell-nest`、`empty-shell`可用于原画清流窝 | 结构static；生态反馈需独立交互，不能冒充既有玩法 |
| R1-06 喷气孔 | 浮游攀升、厚壳碎片、未开远侧口 | `blowhole-latch-closed/open`已有画片 | 闩static/开合程序过渡；本轮不接未制作的R2-05 |
| R1-07 记忆袋 | 圆环路线、浮游奖励、记忆回读 | `reward-socket-memory`、`migration-memory` | 拾取后状态static；不再次授能或重复奖励 |
| R3-01 胃枢 | 暖赭套件、营地、四环、强流门、漂脂 | **原图明确余索驻留**：`yusuo`；`r3-shell-nest-before/after`、`habitat-fungus-bed`、阀座 | 余索静态驻留/交谈；不能把单张站姿平移称行走。水流应跟pressure变缓 |
| R2-01 育床 | 肺膜套件、育囊静图、浮游补领 | `nursery-shell-support`、`nursery-valve-leaf`、`r2-membrane-patch` | 壳托static；根固定的孔瓣可程序开合，不能带动地形扭曲 |
| R2-03 心室观察台 | 肺膜套件、营地、端足横流 | **原图心肌大地标**：`r2-heart-rupture`；`r2-trachea-wall`仅适合相应软骨墙语境 | 心肌遗骸static，不能做复活心跳；群体motion沿当前群流逻辑 |
| R2-04 血巢潮群 | 44个`amphipod-swarm`实例，潮压授能 | **独有Boss形象未用**：`blood-nest-core`、`blood-nest-swarm`；`bypass-valve-base/lever` | 凝聚核心可独立显隐，群流与散群是程序驱动；原画旁通阀是可选机制，不是破防必需 |
| R4-01 组合门 | 骨列套件、组合条件 | `anchor-bone-mount`、`r4-training-groove`、阀/闸图 | 骨台与基座static；条件和闸状态应同源，不重写通关标记 |
| R4-03 上锚路线 | 固定环、鸣贝静图与吐珠行为 | `r4-training-groove`、`anchor-bone-mount` | 鸣贝硬体开合缺动作帧；现状不能称完整逐帧；不恢复已删迎珠强制弹升 |
| R4-05 悬脊鸣贝 | Boss合成静图、弹体与血条 | 原画是两侧交替吐珠及露软缘；可先补双侧独立结构 | 双贝关节开合仍缺连续帧；单张整体缩放不算开合动作 |
| R4-06 稳定交通椎 | 营地、尾槽下行口、头侧门 | **原图左台骨音节点**：`bone-sound-node`；`r4-tapering-vertebrae`；头侧门`ear-latch-closed/open` | 交通节点static＋音光回应；快速旅行后端当前未有，不将静态图当传送功能 |
| R5-01 三槽记忆 | 颅骨套件、三槽基底 | **原图壁上槽/覆膜声壁**：`r5-echo-wall-covered/revealed`；三样进度图标 | 声壁static/揭示；槽灯随pressure/bone/silence显示，不能凭装饰授标记 |
| R5-02 安全池 | 颅骨套件、营地 | `soft-membrane-fissure-closed/open`、`habitat-shade`视当前空间配置 | 软膜程序开合；本轮保持已有潜隙解锁，不再次授技能 |
| R5-04 缄声覆膜 | 膜类Boss静图＋Shader/位图预告、静默授能 | `r5-echo-wall-covered/revealed`可呈现击败后的声槽 | 膜类允许程序形变；败后停伤、露出声槽需跟保存一致 |
| R5-08 归海释放槽 | 导流闸闭/开两态、释放碗、结局菜单 | **原图有幼体归海**：`sea-larva`；`habitat-larva-trough` | 幼体仅单姿态，柔体游动必须补帧；不能仅沿路径平移就标正式动画；不自动引入旧稿释放幼体剧情 |

## 可直接组织实施的现成家族

### 驻留角色

- `yusuo`，`assets/runtime/sprites/yusuo/base.png`：N01铜盔、红索形象；胃枢原图明确出现。台账高1.1U，底部pivot已给。只可立即交付驻留与交谈外观；行走/递索动作缺帧。
- `beituo`，`assets/runtime/sprites/beituo/base.png`：N01背大壳小蟹；可在胃枢岸上作为驻留居民。台账高1.35U。搬壳、递壳与行走缺帧，不应靠整图抖动伪装。
- `nursery-sac`已进入育床；`nursery-shell-support`和`nursery-valve-leaf`尚未同步，可补原画组织关系。
- 新叙事里的老守护者、封梁卫、补巢者没有对应已确认独立角色资产；不能将旧余索/贝驮直接改名冒充这些角色。

### 区域门与机关

- `ear-latch-closed` / `ear-latch-open`均已有PNG，适合交通椎头侧的耳海条件门，不等于后四区所有门已各有专用原画。
- `soft-membrane-fissure-closed/open`用于软膜缝，而非硬骨门；须保持材料可读性。
- `blowhole-latch-closed/open`、`gut-latch-closed/open`、`arena-soft-curtain-closed/open`、`dash-grant-cocoon-closed/open`有静态两态，不能因有图擅加超出19房路线的门/奖励。
- `pressure-valve-base/handle`、`bypass-valve-base/lever`已拆主件和转轴件；有可编辑程序旋转的结构基础。

## 动作缺口

当前可复用的完整角色连续动作主要是正式主角和`corpse-crab-actions-v1`。`membrane-ray`、`blind-eel`、`slit-eel`、`fat-sniffer`、`bone-clinger`、`sea-larva`、`yusuo`、`beituo`均只有静态姿态。未有具体房间实例的生物不为凑数新增。

群体类和膜类可沿项目授权使用实例池/Shader；有关节硬体和柔体游动需补动作，不以实例数量、Sprite节点数量或整图位移冒充帧数。

## 本轮交互组件

`KitInteractable`为静态驻留居民和回声装置提供稳定ID、范围、只读进度文字分支、可持续阅读的交谈页；不自行监听E、不写存档或发放能力。奖励先于居民，居民先于门与营地；角色附近检测、宿主执行和UI提示保持一致。本轮接入及27项真实按键验证已完成，逐房最终采用内容见[交付记录](README.md)；上表保留为制作前盘点。
