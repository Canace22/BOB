# 原视频拾潮者 · 面右空中动作候选

当前交付 **11 帧、12 FPS、约 0.917 秒**的连续空中片段。角色面朝右，原视频画面中的位置向左移动。缺少初始起跳与后半段下落、落地，不能称为完整跳跃动作，也尚未接入游戏。

来源是用户原视频第 190–210 帧，每隔 2 个源帧取 1 帧，对应 7.9167–8.75 秒。原视频是 1520×608、24 FPS；每个输出保留 **190×150 原生像素**，没有放大、逐帧外接框缩放或新增姿势。

## 直接查看

- [原画面位移预览 WebP](preview-source-motion.webp) / [GIF](preview-source-motion.gif)：正常 12 FPS，播放一次，保留原片中的屏幕运动。
- [跟踪画布预览](preview-aligned.webp)：正常 12 FPS，播放一次，方便比较姿势。
- [清理后逐帧联系图](review/candidate-platform-contact.png)：实际输出，不是新绘制的姿势表。
- [平台导出 PNG 包](platform/exports/tide-picker-video-airborne-right-partial-native.zip)。
- [Framecraft 工程](platform/projects/71a7178e32174c18a78dcc913b56a16c.framecraft/)：名称为 **拾潮者_原视频面右空中段_11帧_12fps_原生190x150**。

打开工程时，**05 动画预览显示原 AI 蒙版；07 动画帧精度压缩显示实际透明清理结果**。07 使用 100% 尺寸、透明阈值 52、锐化 0。原 AI 输出与清理结果都保留在工程中。

## 实际处理与坐标

1. 先查看 190–228 的全部 20 个采样姿势，人工标记腰胸附近橙色灯的可见中心，记录每帧在原视频中的位置。
2. FFmpeg 先解码为 RGB，再按记录裁切固定 190×150 画布；没有根据角色外接框调整大小或按脚底逐帧贴地。
3. 逐帧调用 Framecraft 原有 `/api/matte`，使用 BiRefNet Lite、CPU、512 采样、`spill=0`。原始请求、响应头和校验值保留在 [requests/](requests/)。模型与运行依赖见 [本轮 AI 运行记录](../../crab-animation-platform-v1/qa-rekey/ai-runtime.json)。
4. 从完整试验中保留可靠的前 11 帧，再使用平台原有压缩接口清除 Alpha≤52 的像素，保存工程、重开核对并导出。

画布中的 `[70,79]` 是 **trackAnchor：灯标记的人工跟踪位置**。灯会随身体和附件摆动，不能直接当作解剖根部；游戏 `pivot` 保持 **null / 未验收**。每帧原片跟踪位置、裁切区域与时长在 [candidate/timeline.json](candidate/timeline.json)，原屏幕轨迹可以据此还原。轨迹不是已经校准的游戏世界位移。

已同时检查面罩到肩部的关系、头盔尺寸和骨鸣器叉端间距，记录在 [landmark-observations.json](review/landmark-observations.json)。三个代表姿态的头盔目测宽约 24–28px，叉端约 10–13px；原生像素少，手工点位误差约 ±2px，转动和透视也会改变投影。第 7–11 帧姿态变化较大，不能据这些数字宣称全段体积恒定或根部已经锁定。本轮保持原片比例，没有为了数据一致而缩放角色。

## 为什么只保留 11 帧

最初提取了第 190–228 帧，共 20 帧。第 12–16 张在 512 分割中几乎只剩钩，第 17 张身体严重半透明。原片这些姿势仍可见，问题来自分割结果。仅对第 12、16 张增加到 1024 试验：前者丢失大片披风，后者把整个平台一起留下，因此没有混合不同分辨率的输出，也没有继续扩大处理。

[原片全段联系图](review/source-motion-contact.png)、[20 帧原 AI 结果](review/processed-contact.png)和 [1024 失败样例](review/ai1024/)保留作依据。`frames/` 是完整试验输出，包含失败帧；可继续验收的原 AI 段在 `candidate/frames/`，透明清理后的 11 帧在 `platform/processed/`。

前两帧原 AI 蒙版还有低透明度蟹壳残影，最高 Alpha 分别为 17、51。平台阈值 52 已去掉这些残影，同时也会去掉同透明度的细边，不能称为原 Alpha 无损。独立检查确认 Alpha>52 的像素保持完全一致，Alpha 面积保留约 98.07%–99.72%；没有改变画布或角色尺寸。第 1 帧披风细边、少量原片气泡及局部肢体细节仍需美术复核，透明清理不能补绘缺失部分。

## 已执行检查

| 检查 | 结果 |
| --- | --- |
| 帧序、尺寸与 Alpha | 11 张独特 PNG，均为 190×150，没有空帧或画布边缘接触；原第 2 帧底部残影已去除 |
| 平台处理是否改变主体像素 | Alpha>52 的原像素逐个一致；只清除阈值以内像素，不重采样、不锐化 |
| 工程重开与真实 UI 播放 | 11 帧、12 FPS、单次；播放和重播均到第 11 帧停止。07 第 2 帧同倍率检查确认残影消失、主体保持 |
| 实际导出包 | ZIP 内 11 张 PNG 与平台处理文件逐字节一致；原平台 manifest 仍写 `loop:true`，接入元数据单独覆盖为 `false`，pivot 为 null |
| 动态预览 | WebP 11 帧、916ms；GIF 11 帧、910ms，存在 GIF 百分之一秒量化误差；预览均不作为完整跳跃或游戏验收证据 |

证据：[平台文件核对](platform/review/file-checks.json)、[真实 UI 记录](review/ui-checks.json)、[输出与预览核对](review/final-checks.json)。尚未验证游戏状态切换、贴地、碰撞、落地恢复、左右方向配套或用户美术认可。

## 复用时注意 RGB 裁切

直接在 YUV420 视频上裁奇数坐标，FFmpeg 可能按色度采样对齐，导致输入与“完整 RGB 帧再裁切”不一致。本次第 190 帧曾因此出现不同分割结果：旧裁法相对认可的原生裁片，最大 RGB 通道差为 195；改为 `select,format=rgb24,crop` 后，解码像素逐个相等，差值为 0。

修复后的裁片在 [source190-exact-rgb.png](review/source190-exact-rgb.png)，问题记录在 [rejected-yuv-crop/reason.json](review/rejected-yuv-crop/reason.json)。[process_video_jump.py](process_video_jump.py)保留真实的裁切坐标、平台参数与全部 20 帧试验入口；它会重新生成完整试验，不能把其所有输出直接当作上面的 11 帧交付段。

本目录没有重新绘制玩家，也没有修改游戏代码、共享台账或发布入口。

`review/`中的PNG/JPG检查图与失败试验的完整`frames/`仅在本地保留，不随Git入库；其参数、JSON记录、可用的11帧候选/制作输入、预览和平台工程仍保留。新checkout应从制作输入和请求记录复核，不能依赖本地检查图链接。
