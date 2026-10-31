# 拾潮者 · 视频动作 V02

状态：**动作评审稿，仍需美术精修，未获用户签收，未替换主关卡角色。**

用户反馈 V01 八帧版表现力和连续性不足。本批改用本机 Wan2.2 TI2V 5B 的连续视频选帧，清理透明底、调整节奏、制作短循环桥接，再进入 Blender 时序母版与 Godot 独立评审场景。没有使用付费视频服务。角色外观延续用户参考图；其他动作参考《空洞骑士》的起手、有效、回收与空中状态划分，本批先解决基础移动，不把攻击技能列为已完成。

## 查看与文件

- [交互预览](preview-loop.html)：同屏播放、暂停、逐帧、慢放、深浅背景、放大与约94像素高的观察尺寸。
- 三动作录像（本地文件：`review/combined-preview.mp4`）、[循环动画](review/combined-preview.webp)。
- [Blender母版](tide-picker-video-v02.blend)：IDLE/WALK/RUN 三个场景，贴图已打包；逐帧显隐关键帧和源帧编号可检查。这是 **2D图像卡片时序工程**，没有3D角色骨骼，也没有逐帧分层绘画源。
- [运行帧与图集](../../runtime/sprites/tide-picker-locomotion-v02-video/manifest.json)：214张512×512透明PNG，三张8列图集，固定锚点(256,458)。
- Godot唯一工程：`godot/WhalebellyRuins/scenes/characters/locomotion_video_preview.tscn`。空格暂停，右箭头逐帧，1正常、2慢放。仅资产预览，不写游戏存档。
- 原始源片：`native-sources/*.webp`，每组81帧704×704无损归档；`review/*_r1.mp4`、`run_reused.mp4`是24FPS观看副本。`raw/`的原始PNG也保留在本机，并放入交付ZIP；不重复提交到Git。

## 帧数和来源

|动作|选取源帧（从0计）|视频选帧|桥接帧|交付总帧|播放|周期|
|---|---|---:|---:|---:|---:|---:|
|IDLE|idle_r1 / 0–79|80|8|88|24 FPS|3.667秒|
|Walk|walk_r1 / 8–79|72|6|78|48 FPS|1.625秒|
|Run|run_reused / 14–55|42|6|48|48 FPS|1秒|

“视频选帧”表示连续源帧经透明底与固定坐标变换后导出，**不表示未经处理的原图**。IDLE另加受控局部呼吸：头盔整体最高抬升7像素，胸口轻微扩张，脚底权重为0。该修正只解决过静问题，不能说是视频模型直接生成的强呼吸。

20张桥接帧使用OpenCV DIS双向光流，从最后姿势过渡到第一姿势；它们是计算补间，不是20张新生成的原生动作。`manifest.json`逐张记录来源与处理。没有复制静帧凑数量，没有倒放走路/跑步。桥接可能出现局部融合，不能据此宣称完美无缝。

RUN明确复用此前 `outputs/拾潮者_Wan22动作技能/raw/run_v2/`，原任务 `d6e43809-f3b1-4419-96d6-f1d45f6ecd9d`，原预览16FPS。本批重新选段、调速、去阴影与统一比例，不冒充本轮新生成。其原始姿态较小，整组统一放大1.30倍，源地面550映射到630，再将704画布统一导出512；其余动作整组比例1。没有逐帧按包围盒缩放，也没有逐帧将腾空的脚贴回地面。

## 生成记录与取舍

模型为本机已安装 Wan2.2 TI2V 5B fp16，UMT5 fp8 CPU编码；704×704、81帧、24步、CFG5、shift8、uni_pc/simple。实际正负提示词、种子、输入和ComfyUI任务ID保存在 `jobs/`、`inputs/`。完整提示词以各任务workflow为准。

|稿件|观察|处理|
|---|---|---|
|idle_r1|外观较稳，但呼吸幅度很弱|保留，加局部呼吸修正|
|idle_r2|把深呼吸生成成大幅挥手|拒绝作为标准待机|
|idle_r3|头盔拉长、武器变化，新增白色气流|拒绝|
|walk_r1|有连续收腿、经过和伸展，原速度很慢|选段调速；腿的远近身份仍需修|
|walk_r2|腿长时间保持同一伸展姿势|拒绝|
|run_r1 / run_r2|没有形成有效的完整奔跑步态|拒绝|
|历史run_v2|有收腿、伸展、离地与披风跟随|复用；脚形、灯和叉仍有漂移|

连续失败后停止盲目重复生成。下一步应按选定片段锁定头盔、灯、骨鸣器与双脚分层修绘，再用明确的两脚接触表修正步态；不能用更多帧掩盖解剖与道具问题。

## 验收与限制

已执行：

1. 214张PNG均512×512，透明角，逐像素哈希无重复；三个源片各81帧。详见 `review/asset-checks.json` 和 `provenance.json`。
2. Godot4.7.2导入、真实OpenGL渲染；`tests/locomotion_video_assets.gd`检查214个帧区域、透明角、播放推进、暂停、末帧循环、动作切换，通过。
3. Blender4.2成功保存打包母版，三场景首帧渲染见 `review/blender-*.png`。
4. 浏览器实际打开三组动作，检查放大与小尺寸显示、暂停和逐帧；Godot画面见工程 `evidence/locomotion-v02-video/playback-a.png` 和 `playback-b.png`。

视觉仍未通过正式资产验收：Walk远近腿身份不够稳定；Run蹼足有变窄/变形、披风与灯具局部变化；透明边缘存在细碎缺口，循环桥接局部可见融合。IDLE表现比原视频更明显，但仍是克制呼吸。三种状态之间没有制作专门的起步/刹停/转身过渡。技术检查不等于自然步态通过，也不等于用户认可。

## 重建

本机工具环境：`work/wan22-production/venv`用于ComfyUI提交，`helpers`用于Pillow/numpy/scipy/OpenCV处理。`generate.py`按任务文件去重，恢复时先status再fetch。`finish.py`按`selection.json`生成透明序列、循环和Godot资源；`build_blender.py`由Blender4.2后台运行；`export_review.py`保存无损源片和比较录像；`package.py`打包并检查ZIP。

重建会覆盖本V02派生文件；若已经人工改过Blender或PNG，先另存新版本。原始PNG若不在工作副本中，可从交付ZIP恢复，或逐帧解码`native-sources`无损WebP；原PNG文件的编码哈希与解码后像素哈希不是同一概念。
