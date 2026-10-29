# 海底鱼群 v01 · 资产库母版

2026-10-29。三种单鱼、三组鱼群、96张320×224透明动作帧、三张8×4图集；鱼群总周期16秒。来源为内置imagegen三张透明原画，由原画风格文字约束生成；没有图像条件输入。完整提示词和原件见 source/。

- 原画与可编辑曲线：[source/](source/)，`fish-motion.js`为动画母版，`export_and_check.py`烘焙帧和预览。
- 运行资源：[../../runtime/sprites/fish-schools-v01/](../../runtime/sprites/fish-schools-v01/)，含单帧、图集、透明组合图、成员与相位清单。
- Godot入口：[../../../godot/WhalebellyRuins/scenes/environment/fish_school_gallery.tscn](../../../godot/WhalebellyRuins/scenes/environment/fish_school_gallery.tscn)。现有工程F6运行，空格暂停，R重置，1/2/3显隐。
- 三组可复用场景：同工程 scenes/environment/elements/{silverfin,tealback,lantern}_school_v01.tscn。
- 完整可播放交付：`G:/鲸落万物生/outputs/海底鱼群动画_v01/预览.html`。
- 证据：review/；Godot实际渲染截图和检测在工程 evidence/fish_schools/。

制作方法：完整位图原件 → 同尺度裁片 → 有头部约束的身体/尾鳍条带变形 → 32相位烘焙 → 固定成员的群体路径、尺寸和相位错开。不是静态图整体平移，也不是手绘逐帧或3D转身。单鱼源alpha保留；sourceRect排除远离轮廓的微量alpha噪声。透明交付为PNG，不透明MP4仅为观看。

用户已确认采用。三组共62条鱼已替换主关卡共享环境中的旧48条鱼实例；主关卡、环境预览和样板统一复用。复制到其他房间须调整队形位置与遮挡。未制作受惊AI、碰撞或伤害。

重建：在完整交付目录执行 `python source/export_and_check.py`，或为脚本显式传交付目录路径。需要Playwright、imageio-ffmpeg。仅重用已有原画，不再次调用生图。preview-template.html是交付页副本，需与source/和runtime/结构配合。

经验：先在暗底验证真正alpha，不能把工具预览中的隐藏RGB当作烘焙光晕；画外回收、群体路径、单鱼摆尾必须共用可暂停时钟；群体循环与单鱼摆尾循环分别验证。重复制作规则已在本说明保留，本次无需新增Skill。

## 主关卡接入验收

2026-10-29：15项主场景检查、17项环境回归、15项独立包检查通过。主关卡移动/跳跃、树暂停、零速度、视差与房间返回均通过。银鳍在循环换边处平滑隐去，避免画面内跳回；独立包已更新。源结果和截图见 [integration/](integration/)。用户可启动 `G:/鲸落万物生/builds/WhalebellyRuins/WhalebellyRuins.exe`，F5工程入口与环境预览同步显示。
