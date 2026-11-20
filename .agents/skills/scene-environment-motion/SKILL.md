---
name: scene-environment-motion
description: BOB场景、参考图还原及环境动件的默认制作入口。加载个人通用场景动态Skill，主动识别静动元素、选型、制作样板、接入验收并持续沉淀成功方法。
---

# 场景与环境动态制作 · 项目入口

19房生态V1验证：同一房间全景能看到鱼流，不代表普通行走镜头能看到；先核对实际镜头和遮挡，再定水道高度。附生根位置须按完整曲面的可用跨度选点、再在短线段上插值，不能把每条采样段都当成独立平台过滤。流式表现会替换Sprite材质，时钟应写入当前绘制材质。固定根GPU差分、暂停/休眠、有界seek和按键通路的本批证据见[生态V1](../../../assets/source/ecology-19-v1/README.md)。

群体受力可分成有限个体的短冲量与局部水丝弯折，使用同一可暂停时钟、同一有界池回流，不改变主群的物理轨迹。参照视频时舍弃不适合游戏的追镜／大光圈，以未受影响个体作对照测位移与高光，再走真实Input命中；六只／38只对照与GPU／战斗记录见[血巢V6](../../../assets/source/bloodnest-combat-v6/README.md)。

开放群流与独立局部动作见[血巢玻璃虾V5](../../../assets/source/bloodnest-animation-v5/README.md)：先检查单只生物的实际像素尺寸；再组织切线朝向、透明入口／回收、三维感疏密和沿同一流路的位图水丝。不要把等距闭环和随机抖动当作唯美群流。群体表现只跟随既有战斗状态，局部Shader与路径须分别以GPU差分及暂停复验。

器官原画复刻／清底、端足局部动作与路径、固定根膜、菌光Alpha保护和可选单时钟登记见[肺心V4](../../../assets/source/r2-reference-motion-v4/README.md)。先验证大形；鲸已死亡，大器官静止，环境动态在独立对象上制作。GPU时钟夹具与自然玩法／用户审美分别记录。

原画建筑V3的完整洞框、深底残白检查和三槽实际配准见[本批记录](../../../assets/source/reference-architecture-v3/README.md)。洞框、骨壁及附着物保持静止；未拆固定端的整片膜不强制摇摆，已存在水光／气泡／帧动作继续按各自既有时钟运行。

后续十二房以完整原画depth替换同源far、整房／跟随双镜头、台腹全景像素贡献和新房间时钟验收的记录见[remaining-19-v2](../../../assets/source/remaining-19-v2/README.md)。原画烘焙的远群影仍记static，不重复拆成同一动态实例；新的RGB水光只作用Far，World/UI用隔离GPU差分保护。

先查当前用户 Skill 目录中的 `scene-environment-motion/SKILL.md`，不要使用其他机器的绝对路径。若通用主源已安装，读取它及本次需要的配方和执行合同。若本机未安装，明确记录缺口，并使用本仓库保留的[执行合同](references/production-contract.md)和[配方库](references/motion-recipes.md)执行项目范围内的工作；不将这些早期项目说明宣称为通用主源的最新版本。

- 场景制作/还原/优化、环境动态或单个环境元素默认使用，不要求用户再次点名。主动识别static/motion/inspect、说明选型，先单件样板再扩展和接入。
- 正式开发位置以根AGENTS和[Godot开发Skill](../godot-game-dev/SKILL.md)为准；已冻结的legacy只作定向参考，不能继续开发历史入口。
- 每批将成功原因、母版/脚本、证据和失败修正写回对应通用配方，项目细参数留在本项目；新迁移未经样板不标validated。
- 结合[素材一致性](../consistent-2d-game-assets/SKILL.md)检查外观；不固定模型/引擎/FPS，不扩展本次范围。只维护Skill时不生成资产。
- 通用主源不可用时查实际安装位置并说明缺口，不声称已加载。旧项目references是早期稿，现行执行以个人主源为准。

当前须门复杂地图恢复原画三层时，使用[三层接入记录](../../../assets/source/xumen-original-layers-v1/README.md)与工程内`painted-layers-v1.json`；旧World整图含平路，不能用它覆盖新布局。验证采用实际渲染逐层差分、落点／身体采样和四边镜头；节点存在与原图已同步不能替代层实际参与画面。原13列根线要检查Shader实际收到的值。技术接入、静帧复核和用户审美分别记录。


须门七房的鱼群／气泡／微粒复用与镜头可见性检查见[深海氛围批次](../../../assets/source/xumen-deepsea-atmosphere-v1/README.md)。默认外区组件参数保留；新池显式使用共享外部时钟，近泡排在玩家后面。


背景曝光／柔光的隔离GPU差分、World/UI保护与可选Shader兼容见[动态水光批次](../../../assets/source/xumen-background-current-v1/README.md)。仅登记Far层材质；默认零强度保留其它场景，光束采用纯光RGBA。
