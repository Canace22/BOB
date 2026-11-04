---
name: godot-game-dev
description: 在BOB的game/正式Godot工程开发、修复与接入，执行资源审计、headless及真实浏览器验收并发布Web版。
---

# BOB Godot正式开发

先读[架构](../../../docs/architecture.md)、[工程规则](../../../game/AGENTS.md)和[进度](../../../game/progress.md)，核对 `project.godot`。当前默认入口是 `content/whalebelly/main.tscn`。完整旧工程、模块化五房、旧资源与专用测试已移到 `codex/archive-legacy-20261103`，按[归档说明](../../../docs/legacy-archive.md)独立检出。

## 开发与资源

- 源码在 `game/src/campaign/`，房间在 `game/content/whalebelly/r1/`，当前环境在 `game/content/whalebelly/environment/`。保持稳定ID、原角色技能、七房内容和V6存档；不以旧静态版本替代已恢复的动态效果。
- 素材先入 `assets/` 并维护台账，再写 `game/art/manifest.json`、运行 `node tools/godot.mjs sync-art`。当前清单不依赖 `legacy/`；正式画面遵循根2D美术规则。
- 已有精灵/图集的整理与压缩用个人 `2d-sprite-animation` Skill的Framecraft流程。可批量调用真实本机接口，原件与实际输出一并存 `.framecraft`，保存后重开。BOB已验证配方见[压缩批次](../../../assets/source/framecraft-runtime/README.md)。
- 手绘素材优先原尺寸保真PNG、阈值0、锐化0；逐张比较尺寸、可见RGBA与Alpha，只清理全透明像素的隐藏RGB。若输出更大，保留原文件并记录实际平台结果。调色板会改变颜色/半透明边缘，不能将它称为无损。
- 不把进入同步清单当作当前在用。归档前从正式入口、七房、现用角色参数场和预览检查引用，保守展开动态加载；使用 `node game/tools/audit_resources.mjs` 和 `runtime-resources.json`。确认旧版专用的资源、消费者、专用测试及同步项一起移出。原画库和未来区域素材不因尚未接入而自动归档。
- 保存完整归档分支并普通推送后，再移出当前分支；只改本批相关文件。已存在的无关修改保留。一次性恢复工具与历史清单不当作当前验收入口。

## 验证

1. 仓库根运行 `node tools/godot.mjs check` 和 `node tools/godot.mjs test`。固定Godot4.7.2，日志中的脚本错误和 `ERROR:` 都算失败；现用测试与旧版已归档测试分别计数。
2. 对图片批次运行 `python assets/source/framecraft-runtime/compress.py --verify`，检查源工程、哈希、像素、Alpha和当前清单来源存在。验证实际导出文件，不只相信界面设置。
3. 当前主线连续路线使用 `tests/whalebelly/campaign_route_test.gd`，仅写QA存档；真实按键Web验证使用 `web_whalebelly.mjs`，不能再用旧模块版的 `web_playthrough.mjs`。
4. `node tools/godot.mjs export-web` 后，运行 `node game/tests/serve_web.mjs` 的独立4187服务；用Node20+和Playwright执行 `node game/tests/web_whalebelly.mjs`。`PLAYWRIGHT_MODULE`指定现有模块，`GAME_URL`指定入口，`TEST_LABEL`隔离证据。
5. 查看 `game/build/qa/` 的实际截图，检查角色接地、素材比例、透明边缘、遮挡、中文和动态效果；技术检查不等于用户美术认可。截图、自动报告和视频只留本地。

## 存档与发布

主线V6在 `user://whalebelly/`。`CampaignSaveBridge`只在目标不存在时复制有效旧档。测试、捕获及隔离试玩不导入真实进度；浏览器使用独立上下文，不刷新用户正在玩的页面。

按根[持续交付流程](../../../AGENTS.md#持续迭代与边做边玩)提交已验证批次，提交不含AI署名。运行 `node tools/deploy-pages.mjs`，普通推送 `gh-pages`，保留在线历史目录。只更新根入口时用 `--entry-only`；`--build-only`产生未提交staging后须先核对，不重置未知修改。

推送后检查部署成功、线上 `godot/build.json` 的源码提交和当前入口，再跑受影响线上按键路线。把源码/发布提交、结果和限制写入 `game/progress.md`；推送成功不能直接当作上线成功。

## 恢复与边界

检查部署状态与线上 `godot/build.json` 的源码提交，再对线上入口运行同一浏览器路线。把源码提交、发布提交、结果和限制记入 `game/progress.md`。发布失败保留稳定远端，不把本地成功记成已上线。

## 已验证的恢复方式

- 旧工程迁入新结构时，先盘点实际运行入口、角色/战斗、房间与碰撞、机关、动画/Shader、声音、HUD、存档及试玩场。冻结归档或独立环境预览不能代替可玩内容恢复。先在 `game/` 中保留完整兼容模块并跑原功能/连续路线，再渐进拆分；不得用较早的模块化版本覆盖较新的已开发功能。
- Whalebelly 恢复入口为 `content/whalebelly/main.tscn`，运行模块在 `src/campaign/`；原模块化入口已移至归档分支，历史路径为 `src/main/main.tscn`。资源与制作源清单见 `docs/whalebelly-game-recovery.md`，V6 进度由 `CampaignSaveBridge` 隔离并只在目标不存在时导入。当前工作前再次核对 `project.godot`，不要沿用旧入口假设。
- 运行路径迁移同时检查动态拼接的资源名、原有参数和中文字体。Web 无系统中文字体时，Label 必须显式使用嵌入字体或继承已配置的 Theme；本机可读不证明 Web 可读。增量 Web 导出应刷新压缩文件哈希对应的 HTML 加载器。
- 用户要求校验产物与视频不入库时，测试源码和简短结论可保留，生成的截图、JSON、日志、录像及历史导出结果仅存本地；源素材路径/哈希清单用于溯源，不混入测试结果。

- 首屏性能：先用 `game/tests/web_startup.mjs` 记录线上冷/暖启动、Resource Timing 传输字节；HEAD 的未压缩长度不代表浏览器实际下载量。测速时避免其他下载/路线回归争用同一网络。
- 导出后由 `tools/prepare-web.mjs` 生成 gzip 和内容哈希，`game/web/preload.js` 只接管两个启动文件并使用独立资源缓存；原始包保留供无解压 API 的浏览器回退。`STARTUP_FALLBACK=1` / `STARTUP_NO_CACHE=1` 分别验证解压缺失和缓存不可用。
- 新增中文后按[字体制作说明](../../../assets/source/noto-sans-sc/README.md)重建子集并同步；字体覆盖测试必须通过。场景图压缩改 `.import`，不缩图或改裁片坐标；复核游戏实际截图。

- 导出模板缺失：安装对应固定版本的官方 Web 单线程模板，再重新导出；不降级引擎或改成线程版绕过。
- 首次导入依赖缺失：先确认清单源文件和 LFS 实体，再同步；UI Theme 在场景中加载，避免把尚未导入的字体设成项目启动主题。
- 构建目录也会被 Godot 导入：命令入口在 `game/build/` 创建 `.gdignore`，导出预设再次排除 `build/*`；导出清单不能出现验收截图或旧导出资源，Git 忽略规则本身不会阻止打包。
- Playwright 缺 Chromium：使用 `CHROME_PATH` 的现有浏览器或安装匹配浏览器；不要把浏览器无法启动算作玩法失败。
- 按键后立刻读状态会早一帧：等待目标条件，不用瞬时截图/读数判定暂停失败。
- 线上大包首载/刷新可能超过浏览器工具默认 30 秒：等待 `render_game_to_text` 就绪，传入明确的超时选项；不能把 `networkidle` 超时直接判成存档损坏。
- 入口仍靠近返回门：自动路线应先走到奖励范围再按交互，避免把连续 E 当成奖励领取失败。

## 场景与环境表现分支

R1后续六房环境使用`game/content/whalebelly/environment/chapter/`，实际房间实例化`ChapterEnvironment`；原件/母版/根线在`assets/source/r1-chapter-scenes/`。先读`pipeline-state.json`并运行`node tools/audit-r1-chapter-scenes.mjs`，哈希没变的合格资产不重生成。具体命令、当前房间与证据看`game/progress.md`。新验收使用`chapter_environment_qa.gd`、`chapter_branches.gd`与`web_chapter_scenes.mjs`；旧主循环内巡航使用旧点跳策略，仅留历史溯源，不能代替适配当前控制器的回访验收。不要调整玩法/碰撞来迎合过时驱动；自动过门要以门事件判定，死亡回档不能记为连接成功。

涉及场景制作、参考图还原与环境动件时，默认配合[场景与环境动态制作](../scene-environment-motion/SKILL.md)主动识别和制作。本Skill继续负责正式工程路径、玩法、测试和发布；不重复建立生产流程。

- 基础跳跃表现应按真实运动阶段选择已有位图帧，避免把固定时长的起跳/落地整段直接播放到空中。落地覆盖必须可被移动、跳跃和战斗打断；独立跑步适配器同时核对逻辑动画态与实际显示态。回归入口为game/tests/whalebelly/locomotion_visual.gd，覆盖真实主场景输入、姿态与控制响应。

- 新资源引用要覆盖动态拼接路径；字体必须嵌入并检查中文覆盖。本机正常不证明Web正常。
- `game/build/` 要有 `.gdignore`，导出排除测试/工具/证据；Git忽略不等于Godot不会打包。
- Web模板缺失时安装固定版本的官方单线程模板，不降级引擎。Chromium缺失可用 `CHROME_PATH` 或已安装Chrome，不把工具缺失算玩法失败。
- Pages检出只展开 `/godot/`、根入口和 `.nojekyll`，使用 `blob:none` 保留其余版本的Git树。Git2.32需要先 `sparse-checkout init --no-cone`，再 `set` 路径；不要把 `--no-cone` 传给旧版 `set`。拉取后的合并用 `--no-stat`，避免统计差异时触发无关美术大文件的懒下载。
- 并发Pages发布导致非快进拒绝时，保留本地发布提交，重新fetch远端并正常merge（`--no-stat`），检查 `/godot/` 外与远端一致后普通push；不强推，也不为重试重复导出。真实内容冲突先检查归属，再处理。
- Web大包启动等待只读状态就绪，使用明确超时；不以 `networkidle` 超时判存档损坏。按键后等待状态条件，不做同一帧瞬时判定。
- 场景、参考图与环境动态继续配合[场景环境Skill](../scene-environment-motion/SKILL.md)，本Skill负责正式工程接入、测试和发布。

- 跨分支合并归档变更时，除静态引用外还要实跑所有房间：本地Chapter环境依赖旧目录中的EnvironmentBubbleEmitter及动态拼接的鱼群路径。保留在用共享组件，并改接当前whalebelly素材路径，不能以归档目录为由删除仍被使用的依赖。

## 角色视频动作接入的已验证约定

- 旧动作ID可能与当前语义不同，先列显式映射；保留既有Campaign host、存档与解锁边界。F9临时练习不能写入正式能力进度，退出后以真实门事件验证切房。
- 蓄力输入的松开不能仅依赖短暂的just_released边沿；已跟踪且当前未按下可作为释放确认，同时在受击、暂停、死亡与切房清除跟踪。以真实按住/松开、输入锁恢复和两向撞墙用例回归，不只直接调用request_action。
- 蓄力、飞行、落地和退出姿态应读取实际技能阶段。呈现尾帧不得延长物理锁定；body与世界FX的帧数/事件起点独立配置。
- 默认游玩镜头与参考/截图全景须分开验证，至少覆盖每个真实房间、Tab切换和过门；记录镜头缩放变化对性能比较的影响。
- 实机视频须记录控制方式与练习/测试夹具，源视频和脚本直接注入伤害不冒充正常游玩。帧编码期间的耗时不能作为60fps性能证据；另测无录制运行并记录同机外部负载。实例与回归脚本见 `docs/action36-controls.md`、`game/tests/whalebelly/action36_*.gd`。

- 世界空间效果的`top_level`不保证继承预期的场景绘制层；显式核对最终Z层。直接设`z_index=-1`可能把环与残影放到整张背景后。以实际角色层为基准设置绝对层，并同时保留地面原点、方向、尺寸和碰撞；用发力帧截图及两向历史残影复验，不能只靠节点存在断言。

- 完整替换Pages的godot子树时，旧包blob下载可能长时间停滞。先只稀疏检出根入口，按明确godot/前缀移除索引旧项，再复制验证后的导出并加入该稀疏路径；不请求旧大包来立即删除。提交前比较顶层tree，所有非godot历史目录必须与原HEAD一致。只更新根入口的发布仍需保留现有godot检查。
- Windows的`fs.cpSync`过滤器可能收到`\\?\`前缀路径。发布排除原始大包时先统一为`path.toNamespacedPath`再求相对路径，不能直接比较`dirname`字符串；`node tools/test-web-download-parts.mjs`用实际文件复制复现并验证分片、原始回退和历史目录保留。
- 部分克隆的Pages检出提交也使用`git commit --quiet`，避免默认提交摘要为统计已删除旧PCK而触发大型blob懒下载。若提交已写入而摘要卡住，确认提交存在后只终止本任务的摘要/下载进程，保留提交并正常合并最新远端后推送，不重新导出或强推。

- Godot Web若在重建房间时出现Sample._duplicateAudioBuffer/createBuffer错误，保留堆栈并在新浏览器上下文复现，不能静音掩盖。24秒环境音本批改用Web专属AudioServer.PLAYBACK_TYPE_STREAM，桌面默认不变；验收同时检查真实切房、后续按键和playing/type/muted，环境音内容与短音效保留。

## UI 接入已验证方法

- 先比较设计稿与真实数值：当前生命5、蓄振99、常用消耗33。视觉分段须表达实际支付次数并保留精确数字；无共生后端时显示不可用，不将设计稿静态配置复制为状态。
- UI 根可用 ALWAYS 处理暂停菜单，世界保持暂停；关闭后清除动作/跳跃缓冲，等游戏按键释放再恢复，分别验证按住移动和攻击关闭菜单。模态栈恢复原页面焦点，角色重建解绑旧信号。
- Noto 可变字体默认可能是 Thin100；字体子集显式实例化 Regular400，重建后检查中文覆盖与亮背景实机可读性。
- 隐藏原生窗口截图可能读到旧帧；等待渲染帧并 force_draw 后捕获。原生窗口受显示器宽度钳制，超宽验收用实际浏览器 viewport，不能只把截图命名为2560。
- UI 浏览器回归可输出只读控件矩形，真实鼠标按 viewport 和黑边换算点击；不可用脚本调用按钮回调冒充鼠标验收。独立浏览器上下文、QA存档和设置路径隔离；伤害/Boss夹具与自然路线分别记录。

## 独立 Boss 接入主线

- 先固定来源分支/提交，只迁入在用动作、AI及制作源；用主线适配器连接稳定击败ID、奖励和V6，避免带回旧主角、UI和存档。用户要求保留现有地形和角色技能时，适配集中在Boss侧：受击代理提供壳边锚点/完整受击区域，读取已有弹体命中记录区分攻击类型，不修改主角技能、攻击范围或回资源规则。分别验证弹刀、收招、反制、死亡解除碰撞和已击败旧档。
- 跨分支恢复的未跟踪LFS图片可能仍是指针，先核对文件头与大小再同步。获取来源分支对应LFS实体并恢复实际字节后，修复此前失败留下的`valid=false`导入记录，用固定版本`--import`重导入；只跑脚本扫描不证明图片已成功导入。
- 原有“贴身连按十次”路线不能验收新Boss；更新只读状态驱动的真实输入策略，保留明确的房间夹具/连续路线边界。主线实例与复跑入口见[母蟹接入](../../../docs/mother-crab-integration.md)。
- 现用入口：tests/whalebelly/ui_system_qa.gd、tests/web_ui_system.mjs，产物仅在build/qa/ui-system。详见docs/ui-system.md；不要用历史原型HTML充当正式游戏验证。
