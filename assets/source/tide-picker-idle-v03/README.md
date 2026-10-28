# 拾潮者 · 提灯守望 Idle V03

已接入 `godot/WhalebellyRuins` 主关卡的玩家站立状态。走动、跳跃、攻击、受击仍使用原有资源；原图对照与静态构图截图保留原始角色裁片。本批没有重新制作这些非Idle动作。

## 使用

- 主游戏：打开唯一工程，F5运行，停止移动后自动播放。
- 独立观察：`scenes/characters/idle_preview.tscn`，F6运行。空格暂停、右箭头逐帧、A/D转向、1正常速度、2慢放；同屏深浅背景与真实关卡尺寸。
- [Godot渲染的两个完整循环](review/idle-preview.mp4)、[深色动画](review/dark-loop.webp)、[浅色动画](review/light-loop.webp)、[关键帧](review/contact.png)。
- [运行图集与元数据](../../runtime/sprites/tide-picker-idle-v03/manifest.json)、[SpriteFrames](../../runtime/sprites/tide-picker-idle-v03/idle.tres)。引擎加载对应 `res://assets/runtime/tide-picker-idle-v03/` 副本。

## 制作来源与规格

`reference.png` 是本聊天用户提供的完整角色原画。`source.mp4` 为本聊天已生成的 Seedance 2.0 视频，任务 `vj_f85f7ee4-8f48-4eb8-aa99-8107706fc8dc`；原始145帧、24FPS、834×1112，画面存在裁切。本次未新增外部生成费用。

为补足视频缺失的头顶/双叉，制作时保留完整原画像素，提取视频光流并重投影运动。头盔、双叉、灯笼使用局部刚性场；整体运动幅度降为45%，脚部权重归零，以周期包络使首尾位移与速度闭合。这是**视频驱动的二维位图动画烘焙**，不是原始视频直接抽帧、3D骨骼动画或逐帧手绘。局部边缘仍可见轻微二维形变；本资产以关卡约94像素高的用途验收，不作为高清角色特写。

- 72个烘焙采样，合并首尾相同静止姿态后输出70张不同帧。
- 12FPS，首姿势停留3个帧时长，其余各1，总长准确6秒；没有在末尾重复添加首帧。
- 每帧256×320，透明RGBA，固定锚点(128,300)，单一整组比例，无逐帧包围盒归一化。
- 图集2048×2880，8列9行，未使用区域透明；Godot图集裁片启用filter_clip。
- 左向延续现有控制器的翻转约定，不代表新绘制了保持左右道具身份的左向原画。
- `master-rgba.png` + `motion-fields.npz` 为可编辑位图/运动母版；位移以int16/256存储。`master.webp`保留无损帧与时序，`build.py`可重建全部派生资源。不要用重建覆盖人工修订母版。

## 实际验收

Godot **4.7.2.stable.official.ed1daf0bf**、Compatibility、RTX5060。图形模式执行 `--script res://tests/idle_animation.gd`，**17项通过，0失败**，最终日志正常退出，无脚本错误或资源泄漏提示。检查包括完整透明图集、6秒周期、接地且无根位移、播放推进、暂停恢复、循环、跑动/跳跃/攻击与待机切换、左向、原图对照、跨房间加载。测试用隔离的QA状态，不加载或写入用户正式存档。

证据：[主场景与检查结果](../../../godot/WhalebellyRuins/evidence/idle-v03/)，[引擎日志](review/game-qa.log)，[渲染日志](review/preview.log)。渲染日志记录292帧/24FPS，约12.17秒，覆盖两个循环。录制时CPU/GPU时间不能作为正常游戏性能基准。

Agent已检查关键姿态、透明母版、深浅背景实机画面及主关卡左右向接地；用户审美签收尚未获取。状态/导入/渲染测试不等同于用户认可所有美术细节。Web游戏与便携发布包未更新，本轮交付为用户指定的Godot工程。

## 重建

Python依赖：OpenCV、NumPy、Pillow、SciPy。本机复用 `work/wan22-production/helpers/Scripts/python.exe` 执行 `build.py`。再用固定Godot版本 `--headless --path godot/WhalebellyRuins --editor --import`，随后运行专项测试。

测试脚本显式释放场景后再退出，避免短时间切房/退出留下未释放对象。原项目其它未提交修改不属于本批。
