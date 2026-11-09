# 墙跳、重鸣、下砸本体替换候选

本记录是源图和确定性处理结果的 AI 审阅，不是用户美术批准，也不是主场景实机验收。原始图为新制作的透明八姿势精灵表，不是旧视频抽帧；不得覆盖旧来源记录后宣称原视频已修复。

## 本批处理

| key | 源文件 | 配准与尺度 | 时序接入要求 |
|---|---|---|---|
| wall_jump | sprite-sheets/wall_jump-v1.png | 固定 0.4；八个头盔中心只作整体平移，腿部收放保留；参考高度 160 | 蹬墙方向由物理决定；前姿态蹬离、后姿态转入下落 |
| heavy | sprite-sheets/heavy-v1.png | 固定 160/370；共同根点 [220,414]，脚底源像素变动不超过 3 | 实际 key 对应重鸣·涨潮环；发力姿态需与原有释放事件配准，世界环独立播放 |
| dive | sprite-sheets/dive-v1.png | 固定 160/365；前四格根轴平移，收腿帧保留抬脚；第 5–8 格共用 [220,409] | 前 1–2 格准备、3–4 格下降、5–6 格落地压缩、7–8 格恢复；必须由物理落地触发后半段 |

统一 384×384 临时画布和 [192,256] 根点，图集使用全动作共同裁切，三像素外边距。源图颜色不重画，透明度用主连通区域清理独立杂点，预乘 Alpha 重采样。没有逐帧统一包围盒缩放，没有将所有跳跃脚底压回地面，没有把地面冲击环烘焙进本体。

## 已查看的证据

- 三张原图及 `*-registered.jpg` 的深浅底全八姿势。
- `wall_jump-both-facing.jpg`、`heavy-both-facing.jpg`、`dive-both-facing.jpg` 的左右全八姿势，模拟约 96 像素参考高度。
- `replacement-batch-audit.json` 绑定实际源图和输出图集 SHA-256，保存每格 Alpha 边界、透明比例、输出尺寸和体积。

三组 24 格清理后 Alpha>12 的四边接触数均为 0；打包后每格最外一圈 Alpha 最大值为 0。下砸第 4 格披风在 Alpha>64 下距源格顶部 5 像素，脚底距底部 5 像素；放大原图及深浅底观察均没有平切边。角色手脚、叉齿、红绳和腰灯可辨识，未见先前墙跳视频第三只靴的缺陷。左右使用同一本体水平镜像规范，未存两套运行图集。

## 仍须主线程验收

这些是八关键姿势，快速动作衔接必须以现有技能时间轴选择帧，不能将 MP4 预览循环当作正式时序。墙跳末姿态脚底略低于虚拟根线是源姿态差异，物理碰撞不应跟随每帧轮廓。下砸腾空基准包含人工根轴估计，必须在实际落地、低顶和左右墙面检查连续性。重鸣和下砸只交本体，未在此批确认世界环与命中事件、音效或 UI。

未修改主 animations.json、game/art、全局 catalog 或 manifest。本脚本输出的本体图集须由主线程经完整接入与实机审查后登记。

## 重跑

在仓库根目录，Python 依赖路径沿用 semantic-matte.md 的 action36-deps 与 animation-repair-packages：

```powershell
& $taskPython assets/source/tide-picker-action36/build_sprite_sheets.py --keys wall_jump heavy dive --write-runtime
& $taskPython assets/source/tide-picker-action36/tools/review_sprite_sheet_batch.py
& $taskPython assets/source/tide-picker-action36/tools/test_registration.py
```

最后一项使用临时目录夹具，本次 10 项全过，其中新增了 FX 独立帧数/帧率登记回归。未运行登记、同步或清理命令。run/parry 的既有源元数据哈希保持不变。
