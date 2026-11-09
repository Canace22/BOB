# 须门遗港：连续母版＋手绘贴图地形

覆盖现有七房和六条连接。主路使用一个连续顶面，四个旧房接点不再切换地面原画；上层保留原平台和两个能力入口。角色、敌人、Boss、能力和V6不更换。

- `originals/`：八份内置绘图工具原件；来源与生成ID见 generation.json。world-composition 为构图方向，实际可走顶面来自 layout.json。
- `masters/unified-world.ora`：11584×3520 的四层可编辑母版；位置由 layout.json/scene.json 保存。Krita可打开ORA；Godot节点场景可直接编辑。
- `build.py`：处理同一手绘材质、独立边缘/支撑/物件，构造母版再切Far/Middle；不能直接把概念图当可玩关卡。
- `scene_export.py`：输出 game/content/whalebelly/environment/unified/unified_world.tscn；网格是位图承载，不新增碰撞。
- `elements.json`：逐元素与生成规则、首选方式、状态和验收入口。
- `review/`：仅母版缩略图；实际截图/录像在 game/build/qa/xumen-unified（本地证据，不入发布包）。

## 已修正

凹形rim整条UV会产生坡面拉丝，改为逐段四边形网格；半透明切片重叠会画出格线，改为无重叠相邻切片。自由排版物件表不能按等分网格裁，否则植物根部悬空/夹入邻物；改明确选区并按底端落地。垂须以帧图中的根线对齐新上颌，旧房动件整体停用防重复。主路厚度110，保留舌台下潜支路可见空间。前景透明边缘做24px渐隐，不能靠前景遮住接缝验收。

## 复跑

在仓库根用 work/wan22-production/helpers/Scripts/python.exe 运行 build.py、scene_export.py，然后 node tools/godot.mjs sync-art/check/test。Godot4.7.2运行 tests/whalebelly/unified_scene_qa.gd、connected_world_qa.gd，后者顺序再带 -- --reload-connected。固定机位用 unified_scene_visual.gd；录像/性能用 unified_scene_motion.gd。不要并行写QA存档。

Web导出必须包含 art/xumen-unified/*.json。浏览器测试读 connected_world.unified 的当前时钟，旧 e01/authored/shafts 为兼容实例，隐藏停更，不能用它们的存在或历史通过当作新画面验收。

## 边界

中景是全区同源绘画等比扩展，并非每一像素都是原生世界分辨率；细节密度低于可玩层。AI视觉复核与用户审美认可分开；本版本尚未获用户画面反馈。真实声音播放与人工听感也分开记录。性能、发布版本和未解决项以 production.json 和 game/progress.md 最新记录为准。
