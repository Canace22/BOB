# 拾潮者 36 动作：视频到实时角色资产

本批连接既有 36 项动作视频、正式 `CampaignPlayer` 与主场景。36 项是本项目覆盖范围，不是《空洞骑士》全部动作；技能获取录像也不等于完整施法示范。参考结论以 `inputs/参考覆盖与验收.md` 为准。

**当前状态：36项已完成双向GPU与AI外观复核，连续主场景操作通过。** 最终结论见[接入复核](final-review.md)。`animations.json`保留制作阶段来源状态，实际验收按字节哈希写入独立`validation.json`及台账，不能把候选字样或生成成功当验收证据。全36项图集完整性无错误、无边界警告；源视频、独立方向片段、练习覆盖和正常游玩录像分别记录。用户审美确认仍为false。

## 文件与来源

- `inputs/actions.json`：36 项定义及最初源路径。
- `inputs/selected_sources.json`：实际原始单动作视频与模型来源。优先原片，未从带标题双栏合集裁角色。
- `inputs/integration_source_review.json`：人工逐片复核的选段、事件候选和尺度估计；原时间估计有误差，不能直接当作游戏时长。
- `overrides.json`：墙滑、墙跳、锚定、潜隙、浮游、通行证的定向补制与选段。旧失败候选保留原因。
- `jobs/`：生成请求与回执；视频仅在本机保存，不进入 Git。
- `build.py`：逐帧提取、去背景、分层、尺度/根位移注册、裁片打包和可复核预览。
- `semantic_matte.py`、`semantic-matte.md`：本地分割模型及实际加速器验证。模型权重和依赖在仓库外；遮罩缓存仅在 `review/`。
- `build_sprite_sheets.py`：run、parry、wall_jump、heavy、dive五组原生AI关键姿势表的固定尺度注册；原图与原提示词在 `sprite-sheets/`，基准图副本在 `inputs/character-reference.png`。不把这些帧称作视频提取。
- `build_ground_effects.py`：保留源地环提取的失败复现；正式地环由 `build_pure_effects.py` 从独立透明AI表注册，见[pure-effects-review.md](pure-effects-review.md)。`merge_final_assets.py` 合并世界效果、挂点和升级复用规则；效果拥有独立帧数及事件帧。
- `build_anchor_sockets.py`、`socket-overrides.json`：20帧真实握叉手部挂点；`registration-overrides.json` 保存滑翔定位离群点修复，并绑定源哈希与帧数。
- `isnet-batch-review.*`、`isnet-repair-review.*`：原版30项逐帧问题与10项修复版复核，均保存对应图集哈希；原版失败不被新结果覆盖。
- `extract_effects.py`、`effects-sources.json`：真实源片的普通/深鸣弹体，以及已有红绳位图的提取记录。
- `register.py`：仅更新本批台账与同步条目，保留其他来源；独立`validation.json`按当前body/fx哈希绑定三阶段验收，`--prune`默认只预览过期图集。[登记与清理说明](registration.md)。
- `../../runtime/sprites/tide-picker-action36/`：运行图集与 `animations.json`。同步副本为 `game/art/tide-picker-action36/`。

## 资产约定

每项动画使用一个固定尺度、共享脚底参考与身体根；工作画布 640×640、参考站高 160 像素，打包时按整段共同可见范围裁片。实际角色显示高度沿用房间配置的 80～110 像素。画布留白不是运行贴图开销，图集保留裁片与 pivot。

本体保护遮罩先于特效分层。象牙头盔、叉齿、红绳、腰灯及深色身体不能按颜色误删；背景地影不跟随身体。能从原画恢复的发光像素按原背景反混，并在第二层输出。不能恢复的遮挡或变形须明确返修，分割模型不能补出缺失结构。

地面移动的世界位移由 `CharacterBody2D` 控制，源画整体平移在制作阶段去除。空中段消除摄影/演示位移，保留肢体、披风、收腿等局部变化；不把每帧脚底强行贴到地面。跳跃按 rise/apex/fall/land 分段选择，落地环按实际碰撞位置生成。

只存一套可镜像本体。角色 `Visual` 的 facing 决定左右，装备采用约定的整身镜像，因此腰灯和持叉手也镜像；不是假称制作了两套身体侧固定装备。转身素材本身从右到左，视觉桥有专门方向补偿。已经发射的弹体和历史残影保持其世界方向，不跟随角色后续翻转。

元数据包含稳定 key、源路径与 SHA256、源帧时间、参考高、根坐标、帧数/FPS、loop、图集裁片/pivot、关键事件位置、跳跃阶段及返修来源。运行时事件来自技能/原动作时间轴，允许低帧率跨过事件点；源片五秒不作为技能时长。

## 复跑

Python 3.12，安装 Pillow、NumPy、SciPy、OpenCV 和经过验证的 ONNX Runtime；原片路径保持可读，模型位置见 `semantic-matte.md`。在仓库根运行：

```powershell
python assets/source/tide-picker-action36/rebuild.py --models-dir <已核验ONNX模型目录> --threads 4
# 查看本体、分层特效与方向预览；以下登记并不自动批准美术。
python assets/source/tide-picker-action36/register.py
node tools/godot.mjs sync-art
node tools/godot.mjs check
node tools/godot.mjs test
```

`rebuild.py`顺序执行ISNet候选、walk/strike1/dash/hurt的BiRefNet、旧地环失败复现、纯特效表、五组原生姿势表、逐帧挂点及显式复用，再检查图集；不调用生成API、不自动花额度。正式地环采用ground_ring-v2，旧源环只保留失败溯源。不带 `--semantic` 的旧色差算法与 `ground_effect_layers.py` 的失败分离试验仅用于诊断，不能当最终本体。不能同时启动两个写 `animations.json` 的进程。

## 已知制作边界

- 共鸣啸旧源举手时残留身侧空手，形成第三手，用户已指出且撤销旧外观结论。现使用7个两臂姿势保持到20时间槽，持叉臂持续握叉、原空手抬起施法后落回；见[定向修复及提示词](anatomy-fix/review.md)。完整rebuild末尾执行`build_abyss_anatomy.py`，不回退到错误本体。

- 原视频的运行、壁面与武器细节有个别生成变形；抠像不等于修复变形。
- 原下刺测试贝壳在接触帧与叉连通。当前选接触前 1.3～1.85 秒下刺段，实际反弹由敌人命中驱动，不携带贝壳。
- 墙跳补片转身融化；后段密查又发现第三个靴状附肢，最终改用wall_jump-v1八姿势表，保留被拒源记录。
- 潜隙第二版修复了拖叉，但中途姿态抬高；必须核验实际狭缝与碰撞，不用缩放掩盖问题。
- 跑步/偏转的原视频结构缺陷不能靠抠像修复。视频模型额度不可用后，内置image_gen参照同一基准图制作关键姿势；实际模型名未由工具暴露。run-v1/v2支撑腿重复已拒收，v3与parry已通过v4主场景样板。parry源图未成功输出透明底，经BiRefNet逐格抠像形成6姿势。后续wall_jump/heavy/dive同样保留实际原表、提示词、注册与复核记录。
- 原重鸣环与脚部遮挡无法靠颜色剥离补出干净靴子；原下砸短叉被生成成长杖。因此两者改用干净八姿势本体；原地环的脚/叉槽也拒用，改用无角色的八帧纯特效，普通Alpha混合，置于角色后方。
- 影潮穿行复用干净dash本体，配合运行时冷青色调与历史位置残影；深钟复用dive本体和纯地环。heavy/dive/dark_dive地环尺度1/1.6/2.1，深钟另加深青调制。原shadow_dash双重灰像、dark_dive定位跳变/暗环混入本体均被拒用。复用不伪称新增独立生成。
- 回拨采用八个已复核离散姿态，跳过融化手叉与过长停顿；这是快速关键姿势切换，不是连续视频挥弧。部分攻击保留接触处局部亮闪/膜翼，剩余FX与本体像素互补，不能再叠第二套同效果。
- 通行证动画只到持证阶段，门的状态来自交互条件；耐蚀是环境能力，不是攻击。
- 半透明源特效已与背景合成，反混是近似恢复；有色地面反射和场景物件不能作为角色特效带入。

动作、解锁、输入和逻辑映射见 [操作与参数](../../../docs/action36-controls.md)。实际验收状态、录屏和限制以 [工程进度](../../../game/progress.md) 最新批次为准，尚未通过的动作不得登记为正式完成。
