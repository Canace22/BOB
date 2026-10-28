# 搬壳母蟹 Boss 原型关键姿态

2026-10-28。使用内置 imagegen，根据用户明确选定的搬壳母蟹参考重绘。身份参考副本在 `references/shell-mother-crab.png`，来自 `assets/runtime/sprites/shell-mother-crab/base.png`。参考原件不覆盖；待机只是原件的透明画布/比例派生，不计新创作。

本批是**关键静态姿态**，不是逐帧动画：待机复用既有位图，新增低扫蓄力/挥出、双钳抬高/下砸、收钳横冲。后摇/败退复用待机，转阶段复用抬钳；横冲前摇与生效共用收钳姿态。动作间尚无连续过渡，不登记为正式动作动画。

用户在制作中明确：鲸鱼很大、主角很小，螃蟹应有类似林克面对岩石人的巨大体量，并明确选择背多层空心巨贝壳的母蟹。最初按旧负壳蟹制作的一整批图片、低姿态试稿和历史说明都归档在 [superseded/](superseded/README.md)，不接入游戏。原先“跳过整只螃蟹”的设计不再适用。

## 来源与导出

- `raw/` 保留选用的生成源图；`prompts/` 保留实际提示词和修正链。
- 图像为同一角色的参考重绘，不宣称像素一致。来源继承项目已有素材；用户要求用于 BOB，没有新增独立第三方授权声明。
- `export.py` 只做确定性等比缩放、透明画布放置及 QA 合成，不绘制角色，不拉伸变形。源根坐标和等比倍率以脚本 `SPECS` 为准；按壳体结构校准，不能按各帧外接框缩成一样大。
- 输出 `assets/runtime/sprites/crab-boss-prototype/`；公共画布 1024×768，脚底根 `(400,704)`，朝右。Godot `Sprite2D` 使用 `centered=false`、`offset=(-400,-704)`、统一等比 `scale=0.6`，朝左时 x 取负。待机原件等比缩至一半后进入公共画布，实际世界宽约452px、高294px；抬钳最高点更高，不通过每帧缩放抵消动作幅度。
- `export.json` 记录源大小/根位置/倍率、导出大小、alpha 1/8/32 包围盒和 SHA-256。运行时文件由 `game/art/manifest.json` 同步到 `game/art/enemies/crab_prototype/`。
- 待机参考原本偏左向，导出时仅做水平镜像以和右向招式一致；原件保留。低扫首稿在 `raw/candidates/sweep-active-high-v1.png`，最终 `raw/sweep_active.png` 使用单独降低攻击钳的修正版，修正提示词保留。

复跑（Python 需要 Pillow）：

```sh
python assets/source/crab-boss-prototype/export.py
node tools/godot.mjs sync-art
```

导出同时在 `game/build/qa/crab-art/contact.png` 生成深浅双背景、统一比例的确定性接触表（检视缩放0.4，游戏缩放0.6），仅保留本地验收证据。透明边缘和原始可见像素不能通过统一 alpha 截断来“修干净”。台账由 `register_catalog.py` 只维护本批5个新姿态，复用待机不重复计数。

## 验收边界

独立检查姿态剪影、透明底、脚底根和统一比例，结果见 [acceptance.md](acceptance.md)。最终伤害范围、跳跃净空、遮挡、左右翻转、真实键盘战斗与存档隔离由 Godot 原型实机验收记录在 [game/progress.md](../../../game/progress.md)。用户未作美术确认，生成与静态检查通过不代表碰撞和动作读招已经通过。
