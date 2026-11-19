# 后续十二房 · 原画建筑补全V3

2026-11-16。承接remaining-19-v2，按用户本轮附图17_R2-03、22_R3-01、40_R5-01继续补场景建筑与居民环境。保留已确认19房规则；不恢复36房旧门／旧授能、不恢复已删除柱块，不新增角色身份或改变Boss数量。

## 创作与实际接入

- **心室观察台／R2三房**：新制红膜洞顶与两侧血管膜网，复用6处原生悬膜与12簇小菌芽。硬体不动，膜网本批是静态分件；原端足群流、血巢核心和水光保持原逻辑。
- **胃枢**：新制蜂孔赭褶洞框、低矮红索暖壳营，替换本房高骨孔营地图像；壳营位置／存档交互、余索／贝驮身份与坐标保持。保留前批的红索与空杯壳工作位，再复用5簇小菌芽；原肠环候选没有接回，避免重复大形。
- **R4四房／R5头部三房**：共用原画骨白材质的完整上拱与侧缘，少量淡紫白附着。按整房和全景镜头覆盖需求等比放置，全部在中后层，不作为碰撞或可站边线。
- **三槽记忆**：竖向独立图腾退出画面，新制一块横向三孔骨壁片并与右侧颅骨背景相接。三个独立flag仍按pressure／bone／silence控制；只改显示坐标与像素大小。旧可扫描声膜仍位于前层，扫描／静默与交谈逻辑保持。原画的发光圆珠按现有语义图标呈现，不声称逐像素复刻。
- **归海释放槽**：独立制作左厚右开的红腱海窗缘；无右侧直柱，不复画幼体、闸与碗，保留原释放路径和尾海背景。

当前新增6张选用位图，36个Framing实例（12个完整洞框＋1块骨壁＋6处原生悬膜＋17簇原生菌芽），另替换胃枢壳营1个prop。前批33处低矮台腹保持；不把前批角色／动作重复算为本批新增。

## 图片交付与提示词

全部通过**内置image_gen**以原画为风格／材质参考生成，未使用CLI，也没有改变用户提供的原画。属于参考引导补绘，不是原像素精确分离。全套最终提示词、输出来源和候选关系在[generation.json](generation.json)，八份原始输出在originals（六件选用、两件保留为失败候选），来源SHA／尺寸／bbox见[source-contract.json](source-contract.json)。

| 当前ID | 最终位图（相对BOB根） | 用途 |
| --- | --- | --- |
| r2-membrane-cavern-frame-v3 | assets/runtime/scenes/reference-architecture-v3/r2-membrane-cavern-frame-v3.png | 肺心红膜洞框 |
| r3-gastric-cavern-frame-v3 | assets/runtime/scenes/reference-architecture-v3/r3-gastric-cavern-frame-v3.png | 胃枢蜂孔赭褶洞框 |
| r3-low-shell-camp-v3 | assets/runtime/scenes/reference-architecture-v3/r3-low-shell-camp-v3.png | 胃枢低壳营 |
| r5-cranial-cavern-frame-alpha-v3 | assets/runtime/scenes/reference-architecture-v3/r5-cranial-cavern-frame-alpha-v3.png | 骨白洞框（R4与头部R5） |
| r5-three-socket-wall-v3 | assets/runtime/scenes/reference-architecture-v3/r5-three-socket-wall-v3.png | 横向三孔骨壁 |
| r5-tail-window-frame-v3 | assets/runtime/scenes/reference-architecture-v3/r5-tail-window-frame-v3.png | 尾腱海窗缘 |

六件原尺寸1536×1024 RGBA，库原件／制作原始输出／game/art/world-kit副本SHA相等。全使用等比缩放，无拉长、翻转地台造柱或纯色几何代替。白骨第一候选带会误认成锚点的圆环，已去除；第二候选有大范围白雾Alpha，进一步清理后使用alpha-v3，未用泛白层遮住水域。失败候选保留，不在清单渲染。

## 静动判断与引擎接入

| 元素 | 判断 | 方法 |
| --- | --- | --- |
| 骨拱、赭褶、三槽壁、壳营、菌芽 | static；原画形体与可读性 | 原生RGBA，中后层，无新增碰撞 |
| 红膜洞框 | static（本批）；原画不能证明具体摆动 | 不让整片屋顶摇晃；以后独立可动须片须先做锚点分件 |
| 光、水色、泡、微粒、群流、鸣贝与幼体 | motion；前批已有实际运行 | 保留各自时钟／进度／帧图集，回归暂停和状态 |
| 居民 | static驻留交谈 | 未制作行走／理索／递物动作，不用静图平移冒充动作 |

Framing生成入口：`game/tools/build_world_framing.mjs`，由现有build_world_rooms调用。每件独立节点，默认Z=-12／-13，在Far和原Middle之后、World演员／平台之前；小菌芽Z=-1。at依catalog pivot与axis等比配准。未改变相机默认跟随或Tab全景操作。

洞框首次只按房宽放置，窄房全景侧边露出了图片外裁线；最终覆盖宽采用`max(roomWidth, roomHeight*1280/720)*1.08`，原图等比扩大至全景实际可见宽，外边越出视口。不是把整张画拉伸。三槽按新PNG暗孔实际中心逐一配准，骨壁向右接近原颅面；旧声膜显示层在其前，亮图标不与玩家头部重叠。

## 本轮已执行验证

1. **工程检查**：check零错误，原有5条长脚本告警；最终134项单测通过。资源审计missing为空。
2. **来源／玩法**：既有60项来源与物理合同通过，R1七场景SHA、完整后区world/rooms.json、所有十二房碰撞与单向设置保持。新增22项来源／复制／角色坐标／flag语义检查通过。
3. **原生GPU**：266项通过，覆盖十二房分层贡献、水光、台腹、四边镜头、暂停／零速／恢复，新增Framing真实像素、无碰撞、等比缩放和横向三槽。已实际查看十二房全景、跟随、四角拼板，以及重点三房和三槽前后状态的全尺寸截图。
4. **原Input路线**：后区67项通过，血巢／鸣贝／覆膜、三印记、返回交通椎与开闸均完成；另1项新进程读档通过。起点冲刺／浮游是夹具，每场先确认真实受击，再用无敌验证路线与击败流程，不算自然难度验收。
5. **角色与状态**：18项通过，居民提示、育囊瓣、潮压缓流、鸣贝八帧、声壁／三槽、幼体八帧和开闸游出均保留。此项包含位置／进度夹具，不冒充自然解锁录像。

证据仅在`game/build/qa/reference-architecture-v3/`；[逐房原画／前后／状态对照](../../../docs/鲸腹遗城原画集/须门遗港地图布局/后续十二房建筑补全.html)。改前图直接复制前批真实渲染，未用隐藏当前图层伪造。只写独立QA档；Dummy音频避开本机WASAPI问题，不代表听音通过。没有性能、自然通关难度或逐像素还原的承诺。整体美术供用户审阅。本批没有提交、推送或发布。

## 复跑与经验

输入配方在`game/content/whalebelly/world/recipes/`；导入原始输出用import-assets.py，示范摆位用prepare-layout.py。它们会写本批资产与visual字段，人工继续调图后勿盲目重跑覆盖；共享生成入口仍为`node game/tools/build_world_rooms.mjs`。同步只选择本批六件目标，避免全量重采样旧PNG。运行`verify.mjs`及现有remaining-19-v2/verify.mjs，分别检查新源和冻结玩法合同。

成功经验：完整洞框不仅要覆盖房宽，还要覆盖全景长宽比造成的房外视域。透明切件要在目标深色背景上检查残留白雾，Alpha“存在”不代表空洞清洁。参考图里的圆环若误出现在新静态建筑上，会暗示可牵引点，应在素材阶段去除；不要让美术意外改变玩家预期。角色工作位、三槽配准与宏观洞框分开验收，不能靠全景好看代替交互镜头检查。
