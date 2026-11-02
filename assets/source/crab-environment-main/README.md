# 母蟹训练场 · 鱼群与 V3 垂须

本批将 main 已有的三种鱼和 V3 垂须接入独立母蟹训练场。打开[训练场](https://canace22.github.io/BOB/godot-boss/)，Enter 开始、Esc 暂停；实际发布版本以[游戏进度](../../../game/progress.md)为准。

2026-11-02 继续选择性复用 zhaosongju 同一来源版本的独立柔光与气泡：两束错相柔光、三片水域共14个气泡，全部在角色后方。保留当前训练场的洞窟、地面、镜头和碰撞，以及已有22条鱼与3簇垂须。前景裁片含另一房间的骨架/路面，直接叠加会重复地形，本批不接；七房主线、角色技能和默认入口也未合入。

## 素材与来源

来源固定为 main 提交 `49ed188ac1f90ac8f1aaf61fa370169aa6edfb69`。四张 PNG 图集原样复制，没有重绘、改色或重采样；[来源清单](provenance.json)记录原路径和 SHA256。原制作源保留在来源提交，不为这次接入复制整套历史工程：

- [鱼群制作源](https://github.com/Canace22/BOB/tree/49ed188ac1f90ac8f1aaf61fa370169aa6edfb69/assets/source/fish-schools-v01)：银鳍、青背、微光鱼各32帧，单格320×224，图集2560×896。原提示词副本见 [fish-prompts.json](fish-prompts.json)。
- [V3 垂须制作源与 Krita 母版](https://github.com/Canace22/BOB/tree/49ed188ac1f90ac8f1aaf61fa370169aa6edfb69/assets/source/baleen-loop-v3)：48帧、12FPS、4秒，单格384×384、图集3072×2304，公共根点(192,127)。本地保留 [元数据](baleen-manifest.json)与[制作来源](baleen-provenance.json)。

鱼来自绘画的局部变形烘焙，垂须来自绘画形变与 Wan 材质细化；这次只复用这些动画，不计新增创作帧。循环自然度与用户美术确认分别判断。

柔光的原始生成图、母版、提示词和来源保存在[制作源](../xumen-soft-light/README.md)。气泡是原参考画 `(883,232,12,12)` 的真实局部裁片，源导出脚本仅隔离透明边缘，没有生成程序圆环；完整原画保留在[来源提交](https://github.com/Canace22/BOB/tree/49ed188ac1f90ac8f1aaf61fa370169aa6edfb69/assets/source/xumen-reference-environment)，本地原有同名未跟踪制作目录保持原状。新增两张运行图与原脚本路径、哈希见[氛围来源清单](ambience-provenance.json)。

`AmbientSoftLight` 复用来源的独立纹理、12秒柔光和内部微动；材质从顶点传递调色，只乘一次贴图，保留训练场的冷暗背景色。`AmbientBubbles` 复用上浮、错相和边缘渐隐方式，改为场景配置的局部水域与稀疏数量。两者继承 World 的暂停/顿帧，不读取屏幕纹理或生成程序贴图；仍不是正式逐帧特效动画。

## 场景怎么调整

在 [crab_environment_motion.tscn](../../../game/content/rooms/prototype/crab_environment_motion.tscn) 调整位置、等比缩放和调色。三组鱼使用源清单的前8/6/8名成员，共22条；采用新的16秒水平路径与边界渐隐，尾摆保持源成员相位及每周期次数。此路径适配训练场，并非原展示场景的62条完整队形复刻。

垂须复用一簇三次，相位0/13/29帧，根点固定；洞顶遮挡直接裁取现有环境板的同位置上沿，并将动画裁在背景板的1480×592画幅内。鱼群在背景板前、垂须后；全部位于战斗角色后方。没有新增碰撞、玩法或鱼群AI，主线房间保持原样。

运行 PNG 由 [game/art/manifest.json](../../../game/art/manifest.json)同步，Godot 使用0.88质量WebP导入压缩，PNG原件不变。更新源图后运行 `node tools/godot.mjs sync-art`；调整布局不必重新同步。现有加载器没有这些素材的替代图，缺文件应在检查阶段修复，不能视为已验收。

## 验证

1. `node tools/godot.mjs check` 与 `node tools/godot.mjs test`：图集尺寸、等比尺度、根点、完整循环和暂停/顿帧继承。
2. 导出Web并运行 `game/tests/web_environment_motion.mjs`：观察完整周期、实际贴图、全部48个垂须帧、三组鱼摆尾、真实按键移动/跳跃/远程、暂停恢复。
3. `game/tests/web_crab_prototype.mjs`：现有战斗、三阶段、死亡重试、暂停、刷新和冲刺对照。
4. 查看实际截图和录像：根部衔接、鱼群明暗、读招/脚下路线与前后遮挡；不能把帧号检查当作美术验收。

新增柔光/气泡也由同一环境脚本观察实际纹理和时钟；headless 检查气泡回收位置、透明度容差及四种动件的暂停/顿帧。缺图没有替代纹理，必须修复文件后再交付。既有图层和人物的连续播放仍需实际看图，来源分支的历史验收不代替本轮。

浏览器脚本使用独立上下文，支持 `PLAYWRIGHT_MODULE`、`CHROME_PATH`、`GAME_URL`、`TEST_LABEL`；不写主线存档。具体结果和发布提交记录在游戏进度，截图/录像仅本机保留。撤下本批时一并撤回布景实例与训练场状态观测的引用，保留资产库原件。
