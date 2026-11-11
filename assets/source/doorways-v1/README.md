# 七房门与通道

本批以现行分房场景为准，不改房间连接、能力取得或 V6 存档。

## 入口设计

14 个门点分别配置在 `game/content/whalebelly/r1/` 的 `Doorways` 节点中，目标使用稳定房间 ID；坐标、解锁要求和目的地落点仍读取房间数据。

| 当前房间 | 目的地 | 设计与理由 |
| --- | --- | --- |
| 外伤坡 | 须筛 | 右侧独立骨质通道内景，高 200；可向右穿行，门前显示目的地并支持 E 进入。详见[尺度接入](../xumen-scale-v1/README.md) |
| 须筛 | 外伤坡、舌台 | 画面内骨拱，门前 E 进入 |
| 须筛 | 喷气孔上层、鲸须记忆袋 | 高台上的骨拱，门前 E 进入；保留各自能力条件 |
| 舌台 | 须筛、负壳蟹 | 两侧骨拱，门前 E 进入 |
| 负壳蟹 | 舌台 | 左侧骨拱，门前 E；门外仍可使用原灯台 |
| 负壳蟹 | 流膜育窝 | 守关门：Boss 存活时保留关闭外观，击败后显示内景与进入提示 |
| 流膜育窝 | 负壳蟹 | 左侧骨拱，门前 E；门外可使用原灯台 |
| 流膜育窝 | 首关出口 | E 确认抵达；完成后提示后续区域未开放，不假装加载新章节 |
| 喷气孔上层 | 须筛 | 左侧骨拱，门前 E，保留浮游条件 |
| 喷气孔上层 | 远侧闩 | 保留现有封闭门，说明后续区域未开放、需要原路返回，不显示可进入按钮 |
| 鲸须记忆袋 | 须筛 | 左侧骨拱，门前 E；不增加右侧装饰门的连接 |

主路并非所有门都是自动通道：判断依据是当前画面的朝向和地形，不是门在左边还是右边。无连接的装饰不增加传送能力。

## 素材与静动判断

- 骨框、红绳、通道内壁：static。硬结构不摆动，也不额外增添粒子。
- 内景样板：`tunnel-original.png`，内置 imagegen 生成的 1024×1536 RGBA 位图；原件保留，运行副本 `assets/runtime/sprites/doorways-v1/tunnel.png`，清单同步到 `game/art/doorways/tunnel.png`。各门按高 145–170 等比缩放，不拉伸。
- 近侧门槛：同一位图底部 192 像素作为前景裁片，遮住进入时的脚部；没有另造程序几何。
- 角色：复用现有跑步帧，向门方向最多迈 22 像素，逐物理帧检查碰撞。不是新增角色动作素材。
- 转场：0.2 秒淡黑、停留黑帧 0.08 秒，在完全遮住时加载目标房间，再用 0.25 秒淡入；转场锁输入并临时保护角色。取消原来截取整屏再叠化的做法。
- 提示：短文本贴近门楣，按绑定键显示短目的地提示，例如 `[E] 主线 · 舌台` 或 `[E] 返回 · 须筛`；能力门说明条件；进入后隐藏。返程门需要离开小范围后重新激活。

本机没有安装项目入口曾引用的个人通用场景 Skill。本批依据仓库保留的执行合同、配方库、Godot Skill 与美术规范执行，不将这些早期说明称为通用主源最新版。

## 生成简报

工具：内置 imagegen，透明背景，单资产生成。保存原输出，无后续重绘。

> Create a production 2D hand-painted game sprite: ONLY the recessed INTERIOR of a small organic whalebone tunnel doorway, tall rounded arch shape, straight-on front view, centered on a genuinely transparent background. Full sprite fits inside canvas with transparent margins. Deep-sea dark fairy-tale gouache texture, muted ivory eroded porous bone INNER walls receding through two or three smaller nested arches into nearly black blue depth, very restrained distant teal ambient light. Bottom has a short dark reddish bone threshold extending subtly toward viewer. Outer silhouette softly irregular but alpha clean, not rectangular. Interior is opaque dark painted material and must NOT be transparent. No exterior full door frame, no red ropes, no lamps, no characters, no text, no UI, no decorative particles, no large surrounding landscape. This is an inset to place inside existing ivory bone arches with red ropes in a side-scrolling underwater game. Very readable depth at 120 pixels tall. Aspect ratio portrait 2:3. Do not make a glowing magic portal; a physical narrow tunnel through layered organic bone. Outer edge dark so it fits inside existing doorway opening.

## 复验

- `node tools/godot.mjs check`、`node tools/godot.mjs test`。
- Godot 执行 `--script res://tests/whalebelly/doorways.gd`：逐门房间夹具、真实 Input、双向连接、Boss 门、封闭门、首关完成、营地和安全落点；桌面版同时输出截图。
- 浏览器执行 `game/tests/web_doorways.mjs`：独立上下文真实键盘、自然首段往返和房间预览下的门验证。夹具与自然路线分别记录。
- 证据只保存在 `game/build/qa/doorways/`；运行和线上结果见 `game/progress.md`。技术结果不替代用户整体审美认可。

已知边界：既有共用远景中的拼接边界不属于本批门的修改范围。缺失门位图没有新增替代美术，资源检查失败必须修复，不能以缺图画面验收。
