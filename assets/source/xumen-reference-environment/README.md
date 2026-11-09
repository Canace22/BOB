# 本轮参考图 · 单屏环境场景

范围：1280×720 单屏蓝色洞穴；仅环境、展示角色和轻微环境动态。构图母版是 `original/reference.png`；2026-10-28后续使用用户提供的 `视频_bxK-0201.mp4` 作为局部运动参考，记录见 `motion-refinement.md`。独立场景位于既有 WhalebellyRuins 工程内；主游戏R1-01共用该环境。

## 打开与运行

打开 `../../../godot/WhalebellyRuins/project.godot`，选择 `scenes/environment/xumen_reference.tscn`，按 **F6** 运行当前场景。F5 仍进入原有游戏。也可执行工程根目录 `preview-reference-environment.ps1`；加 `-Pan` 显示微量视差。固定 Godot **4.7.2.stable.official.ed1daf0bf**。

场景根节点 Inspector 提供 `Animate Environment`（保持当前姿态/继续）、`Camera Drift`（默认关）、`Motion Strength`（统一运动速度，0冻结）、`Foliage Amplitude Px`（默认1.8）、`Fish Amplitude Px`（默认8）。角色为原姿态静态 Sprite2D，无键盘移动。关闭窗口退出。独立展示不加载玩法及存档。

## 文件与编辑

- `original/`：用户原图，SHA256 记录于 `provenance.json`。
- `generated/`：3 张补绘原件，保持生成分辨率；用于被遮挡区域与动态图层背后的补全。
- `masks/*.svg`：44 个可编辑矢量选区母版，源图坐标系1280×720。
- `elements.json`：50 个元素/装饰簇/生成器合同，包含来源、图层、运动、位置、节点与验收证据。
- `layer-layout.json`：原生导出配方；`../../runtime/xumen-reference-environment/manifest.json`：47 个有效位图，其中46个场景贴图、1个气泡纹理。
- Godot 场景：逐张 Sprite2D，可选中、换图、移位、隐藏。`root_sway.gdshader` 为根部权重；`reference_environment.gd` 为有限环境循环。
- `review/`：视觉说明与拒收记录；引擎截图、运行报告在工程 `evidence/reference_environment/`。

母版是原图＋SVG选区＋补绘PNG＋布局JSON＋Godot节点/材质；没有虚构PSD图层文件。每张裁片左上角是锚点，通过 `source_rect.xy` 还原位置。贴图不适合作为大幅镜头运动的无限场景。

## 已接入动态

6组垂须、4簇软植株、4簇藻丝按双波分簇摆动，末端位移上限1.8px，根部和地形保持固定。2组鱼群分别使用28秒/34秒节奏，横向完整行程8px，保留原始朝向；这是小范围漂游，并非逐尾游动动画。36气泡分为33个远泡与3个近泡：远泡7–13px/s、2.5–6.5px；右侧近泡21–27px/s、9–15px，位于道路前、深色框景后。全部预热、边缘淡入淡出并回收。灯与光束分相位变化，上限分别2%/1.2%。默认固定镜头；可选微量视差保持既有限幅。静态硬壳、道路材质高光保留在贴图内。

## 再导出顺序

1. 修改 `BOB/tools/build_reference_environment_masks.py` 或 SVG母版；注意运行脚本会重建SVG。
2. 运行该脚本更新配方，再用 Godot 执行 `res://tools/reference_environment/export_assets.gd`。
3. 运行 `BOB/tools/build_reference_environment_scene.py` 更新裁片位置；会重建本场景，请先保存手工布局改动。
4. Godot `--headless --editor --import --quit`，然后执行 `audit_scene.gd`，复核图层与固定机位；用 `--script res://tests/reference_environment_motion.gd` 检查冻结/恢复与预热，再用场景 `-- --qa` 实际运行72秒。只有需要复核微量视差时才附加 `--pan`。新动态证据保存于 `evidence/reference_environment/motion_refinement/`。

不要重新运行初始清单生成器覆盖已补充的验收结果。新的导出改变纹理后，旧截图和报告必须重新生成。

## 适用边界

这是按参考图重构的2D展示场景，不宣称逐像素无损复原。隐藏区由AI补绘，顶部水体局部色调、细小轮廓和鱼群逐尾形状与原图仍有差异。垂须裁片保留部分固着屋顶/洞壁像素并以权重锁定；不能把这些裁片当作已完全清理的通用单物件素材移到另一张地图。当前验收以本机位及约定小幅视差为准，放大运动或换构图需要继续清理。

## 后续地图接入

本环境已接入主游戏R1-01，F5可运行实际关卡；F6独立展示模式仍保留。游戏模式移除静态展示角色，由原控制器接管；地形碰撞/出入口绑定记录和验证见[接入说明](integration/README.md)。
