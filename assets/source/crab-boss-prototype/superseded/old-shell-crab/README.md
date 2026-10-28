# 负壳蟹 Boss 原型关键姿态

2026-10-28。使用内置 imagegen，根据正式工程现有螃蟹位图参考重绘。身份参考副本在 `references/shell_crab_boss.png`，来自 `game/art/enemies/shell_crab_boss.png`（同步来源为 `legacy/godot/first-level/assets/runtime/boss.png`）。参考原件不覆盖。

本批是**关键静态姿态**，不是逐帧动画：待机复用既有位图，新增低扫蓄力/挥出、双钳抬高/下砸、收钳横冲。后摇/败退复用待机，转阶段复用抬钳；横冲前摇与生效共用收钳姿态。动作间尚无连续过渡，不登记为正式动作动画。

用户在制作中明确：鲸鱼很大、主角很小，螃蟹应有类似林克面对岩石人的巨大体量。因此最终选用保持巨大壳堆的横冲稿，低姿态试稿保留在 `raw/candidates/`，不接入游戏。原先“跳过整只螃蟹”的设计不再适用。

## 来源与导出

- `raw/` 保留选用的生成源图；`prompts/` 保留实际提示词和修正链。
- 图像为同一角色的参考重绘，不宣称像素一致。来源继承项目已有素材；用户要求用于 BOB，没有新增独立第三方授权声明。
- `export.py` 只做确定性等比缩放、透明画布放置及 QA 合成，不绘制角色，不拉伸变形。源根坐标和等比倍率以脚本 `SPECS` 为准；按壳体结构校准，不能按各帧外接框缩成一样大。
- 输出 `assets/runtime/sprites/crab-boss-prototype/`；公共画布 1024×768，脚底根 `(400,704)`，朝右。Godot `Sprite2D` 使用 `centered=false`、`offset=(-400,-704)`、统一等比 `scale=0.8`，朝左时 x 取负。常态高约250px，含爪总宽约570px；抬钳最高点更高，不通过每帧缩放抵消动作幅度。
- `export.json` 记录源大小/根位置/倍率、导出大小、alpha 1/8/32 包围盒和 SHA-256。运行时文件由 `game/art/manifest.json` 同步到 `game/art/enemies/crab_prototype/`。

复跑（Python 需要 Pillow）：

```sh
python assets/source/crab-boss-prototype/export.py
node tools/godot.mjs sync-art
```

导出同时在 `game/build/qa/crab-art/contact.png` 生成深浅双背景、实际比例的确定性接触表，仅保留本地验收证据。透明边缘和原始可见像素不能通过统一 alpha 截断来“修干净”。

## 验收边界

独立检查姿态剪影、透明底、脚底根和统一比例，结果见 [acceptance.md](acceptance.md)。最终伤害范围、跳跃净空、遮挡、左右翻转、真实键盘战斗与存档隔离由 Godot 原型实机验收记录在 [game/progress.md](../../../game/progress.md)。用户未作美术确认，生成与静态检查通过不代表碰撞和动作读招已经通过。
