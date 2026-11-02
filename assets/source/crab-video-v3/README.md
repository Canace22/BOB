# 视频母蟹 V3 · 训练场实装

参考用户提供的[30 秒视频](https://xsj-ai-orange.seasungame.com/prod/video/20261030/ae2e5406-53a1-4150-b5e0-ff0cfe9fb254.mp4)，原片 1520×608、24 FPS、721 帧。用户认可补绘方向后要求沉淀 Skill 并实装 BOB。绘制使用内置 imagegen；脚本只裁切、缩放、拼图和导出。

## 来源与导出

- `references/video-scene.png` 为原场景截图；`environment.png` 为移除角色、弹体和浮壳后的重绘环境；实际提示词见 `environment-prompt.txt`。地面约在高度 71%，训练场平地碰撞 y=896。
- `sheets/` 保存 V3 九张 4×3 图集，其中七张进入运行导出；每帧 896×512，根锚点 `(512,448)`，原始朝左。身体保留原分辨率；首次半尺寸导出在实机明显发糊，已撤回。图集由不等宽生成网格拆分后统一重排。
- `effects/` 保存尘雾、碎壳、光球各四帧。运行只使用前两者，半尺寸 1024×256，每帧 256×256；尘雾根 `(128,224)`，碎壳中心 `(128,128)`。
- `generation_prompts.json`、`reference_mapping.json`、`animations.json`、`validation.json` 为完整 V3 制作批次记录；跳砸、吐球和光球保留制作源但尚未实装，不能把离线素材验证当游戏验收。
- 安装 `sharp` 后执行 `node assets/source/crab-video-v3/export-runtime.cjs`，输出到 `assets/runtime/sprites/crab-video-v3/`；随后在仓库根执行 `node tools/godot.mjs sync-art`。环境等比缩至 1480 宽，身体原尺寸，Godot `.import` 使用 0.88 WebP 质量。

## 运行映射

| 玩法状态 | 图集 | 时序 |
| --- | --- | --- |
| 等待/观察 | 01_idle | 8 FPS，0–10 循环，去掉重复端点 |
| 低扫/二扫 | 04_sweep | 前摇 0–3、伤害 4–7、后摇 8–11 |
| 单钳下砸 | 02_claw_slam | 前摇 0–4、伤害 5–7、后摇 8–11 |
| 重步冲撞 | 07_body_slam | 前摇 0–6、接触 7、后摇 8–11；原型冲撞机制 |
| 半血转换 | 06_shell_shake | 0.8 秒播放，加独立碎壳 |
| 接近目标 | 08_retreat | 复用踏步姿态，10 FPS，非新制正向行走循环 |
| 退场 | 09_sink_fade | 单次 8 FPS、1.5 秒淡出 |

伤害按 `CrabMoves` 已验证逻辑，身体帧按状态时间映射；尘雾固定在命中世界坐标。暂停/顿帧停住身体与特效；重试清理退场透明度和残留特效。

## 范围与限制

这是视频参考的关键帧重绘，不是原视频 360 抽样帧的逐像素修复或 24 FPS 补帧还原。七组共 84 播放单元，重复姿态数量见原清单。原交付包的九组动作没有变成九种攻击，本次仍是三招。

壳纹、肢体体积和三分之四/正面视角仍有跳变；移动使用已有踏步，不能等同正式行走周期。钳尖超过伤害范围的部分保留容错；按键机器人通关不证明真人能轻松读招。人物沿用 BOB 既有素材，与视频小人仍有差别。环境为静态板，侧台是布景，未新增可达平台。实际验收和发布见 [game/progress.md](../../../game/progress.md)。

通用方法见 [video-to-sprites](../../../.agents/skills/consistent-2d-game-assets/references/video-to-sprites.md)。
