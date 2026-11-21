# 须门鲸头、原画腹腔与尾鳍

[整鲸母版](whale-overview.png)为 2340 × 724。左端的鲸须、蟹台、颌骨和暖色骨缘取自玩家选定的[须门七房原画](../world-continuity-v1/images/02-r1-continuous.png)。胸腹取自[鲸体剖面·空间分区](../../../docs/鲸腹遗城原画集/V2/images/A02_鲸体剖面_空间分区.png)，保留肋后心室、蓝白肺室、可辨认的胃腔、下层通道和红色脏器。后腹逐渐收进尾柄，短而宽的双叶参照[连续世界旧全图](../world-continuity-v1/images/01-world.png)的横向透视。海水里的远鲸提供尺度参照。

## 制作与复现

1. 在 2700 × 900 定位稿上由左到右排入两组现成位图。须门原画等比缩至 1440 × 480，左上为 (0, 91)。腹腔原画等比缩至 2578 × 1031，左上为 (370, -70)。露出纵向接合部与尾部，用内置 ImageGen 补接，得到[首轮底稿](tail-paint.png)。
2. 用鲸须、平台、骨缘和器官分支在底稿上匹配两张原画。原画内区等比回贴；在边缘按[地标位移](registration.json)校正底稿，避免上下颌重影。位移网格单位为该原画缩放后的像素，表内向量从原画位置指向底稿采样位置。
3. 从恢复后的躯干取后半幅，在右侧预留尾柄和尾鳍，以旧全图的双叶裁片规定透视。在这个局部单独补画，得到[尾部原件](tail-detail.png)。合成时从全图 x = 1640 起接边，左侧直接保留前一步的结果。此轮两条生成提示见[制作提示词](prompts.md)。
4. 在仓库根执行 `Godot --headless --path game --script ../assets/source/world-map-tail-v2/compose.gd`，再执行 `Godot --headless --path game --script res://tools/sync_art.gd -- --only=world-map/whale-anatomy-overview.png`。脚本固定使用 Godot 4.7.2 的等比 Lanczos 缩放。[合成脚本](compose.gd)

地图为静态位图。房间标记由既有 UI 按[地图配方](../../../game/content/whalebelly/world/recipes/_world.json)的 `map.world` 叠加，须门区域页继续使用鲸头特写。宽屏和小窗口均按原比例完整显示。实机截图与检查结果见[正式工程进度](../../../game/progress.md)。
