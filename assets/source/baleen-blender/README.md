# 四处垂须 · Blender 绘画裁片动画

2026-10-28。对应用户圈选图 `reference/marked-regions.png`。沿用同一 WhalebellyRuins 工程和原有环境构图，不新增玩法、碰撞或控制系统。

## 已制作与接入

| ID | 区域 | 原图坐标 x,y | 单帧尺寸 | 层级 |
|---|---|---|---|---|
| BALEEN-LEFT | 左侧近景乳白垂须 | 250,-16 | 430×360 | 4 |
| BALEEN-CENTER | 中央近景乳白垂须 | 630,-16 | 290×230 | 4 |
| BALEEN-RIGHT | 右侧近景乳白垂须 | 880,-16 | 350×330 | 4 |
| BALEEN-DISTANT | 右侧远景蓝色垂帘 | 860,100 | 220×300 | -31 |

每组72张RGBA PNG、12 FPS、6秒循环，8列×9行图集，共288张独立帧。Godot元素在 `scenes/environment/elements/BALEEN-*.tscn`，总场景 `xumen_reference.tscn`，主关卡R1-01与环境预览共用。

使用 Blender 4.2.0 实际渲染：已有绘画贴图 → 带UV网格 → 固定根部权重 → 四个循环形态键 → 正交相机 → Eevee透明PNG。不是Grease Pencil逐帧重画，也不是Godot实时Shader冒充动画帧。远景是原蓝色垂帘的内嵌裁片，固定外沿、轻微内部形变；未逐根重绘。近景保留旧六片静态根部，旧六片实时变形动件不再实例化。

## 可编辑文件

- `blend/baleen-painted-animation.blend`：四个同名Scene、网格、UV、Pinned_Roots / Flexible_Tips权重、动画形态键、相机；贴图已打包。
- `paint/*.png`：从既有原画分件提取并清理的绘画贴图，可在Blender Texture Paint修改。
- `frames/<ID>/000.png…071.png`：透明逐帧输出。Blender第1…72帧对应000…071；第73帧是首尾校验辅助帧，不重复导出。
- `jobs.json`：尺寸、世界坐标、层级、周期和幅度参数。
- `../../runtime/baleen-blender/`：运行图集副本；工程中对应 `assets/baleen_blender/`。
- `../xumen-motion-elements/master/editable-layout.svg`：包含四组第0帧的静态布局母版。

原件来源：用户本轮圈选图；近景来自已入库 `xumen-motion-elements` 须丝动片；远景来自 `xumen-reference-environment/generated/dynamic-backing.png`。没有新增付费生成服务。本地Blender MCP未连接，实际使用独立后台CLI；没有改动用户已打开的Blender文档。

## 修改与重建

在母版中选对应Scene，调整绘画贴图、形态键或时间曲线；第1～72帧输出RGBA，保持原相机、分辨率和坐标，不按每帧包围盒重新缩放。若手工修改母版，直接从母版渲染；`build_blender.py`会重建母版，因此不要用它覆盖未保存的手工版本。

自动重建顺序（Godot固定4.7.2，`--path`指向唯一工程）：

1. Godot `--headless --script res://tools/motion_elements/prepare_baleen_blender.gd`：重新提取原画裁片。会覆盖paint输入，手绘修改前先另存。
2. Blender `--background --factory-startup --python <本目录>/build_blender.py`：重建四Scene并渲染。可追加 `-- --only=BALEEN-CENTER` 定向渲染。
3. Godot `--headless --script res://tools/motion_elements/pack_baleen_frames.gd`：原生打包并复制运行纹理。
4. Python `BOB/tools/integrate_baleen_blender.py`：更新场景、ID和布局JSON。
5. Godot导入后运行 `tests/baleen_frames_qa.gd`、`tests/motion_elements_qa.gd`、`tests/motion_loop_render.gd`、`tests/water_surface_qa.gd`。
6. Python `BOB/tools/deliver_baleen_blender.py <ffmpeg路径>`：制作每组视频、更新同一交付页与SVG。实机录像需先由Godot写出。

## 已验证与限制

Blender几何：4组固定点误差最大0.000003像素，首尾误差0；实际最大变形左11.59、中央7.85、右9.82、远景2.85像素。幅度为多个波叠加，不能直接用单一参数当最终测量值。

帧检查：每组72张不同PNG，图像边缘透明；末帧到首帧变化未超过相邻帧最大变化的1.15倍。Godot渲染17项通过，6秒端点完全一致；只推进垂须时，y≥400道路/前景像素变化0。17项环境、4项循环、6项水面回归通过。水面仍只作用于顶部远景，未新增漂浮光纹。

实际截图与录像、性能、独立包日志见 `godot/WhalebellyRuins/evidence/baleen_blender/`。24秒固定画面和32秒视差录像是引擎实时渲染输出；录制吞吐不是游戏帧率，性能以单独 `live-fixed-runtime.json` 为准。

已查看实机抽样图和裁片，检查循环端点与根部几何；未逐帧人工审阅全部录像，未获得用户最终动态观感确认。原图细丝抠图在放大时仍可能有细小边缘差异。远景采用轻微内嵌形变而非完整逐丝物理模拟；不存在该范围外的玩法验收声明。

## 本轮性能与独立包

RTX5060 / 1280×720 / Compatibility，停止视频编码后独立运行20秒：P50 16.661ms，P95 17.233ms，116次绘制，纹理约204.1MiB。此前与FFmpeg并行的12秒采样P95 39.395ms单独保留为受干扰记录，不混作稳定基准。帧图集提高了纹理占用，后续低配目标可优化图集密度。官方Godot可执行文件+PCK已实际启动，退出0并查看独立包截图；不是Release模板构建。当前范围没有待补接节点。
