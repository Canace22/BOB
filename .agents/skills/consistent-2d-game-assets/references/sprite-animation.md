# Sprite animation sequences

Use this workflow when delivering moving sprites. Static props and pose reference sheets do not need it.

## Define one action

Separate **action states** from **frames within an action**. Idle, walk, and attack can select three different states; alternating these illustrations does not create a walk cycle. Each animated state needs an ordered sequence with its own timing.

For an initial walk cycle, use 4–8 distinct phases; eight is a useful starting point when both legs and weight transfer must read. Choose fewer frames for deliberately limited animation. More frames do not repair inconsistent drawing or incorrect timing.

Write a brief before generation:

- Action, in-place or translating motion, loop or one-shot, phase order, and total duration or per-frame durations.
- Fixed viewpoint and facing; anatomical left/right limb identity when legs or arms cross.
- Character master, costume, attached props, weapon hand, and any deliberately animated loose parts.
- Equal cell layout, output canvas, pixels per unit, shared root/pivot, ground plane, and padding for the entire motion envelope.
- Target runtime size, movement speed, and entry/exit states to test.

An eight-phase in-place walk can use: left contact → weight down → right leg passing → weight up → right contact → weight down → left leg passing → weight up. The next frame is the first contact again; do not append a duplicate of the first frame as the last cell. A sword attack may instead use preparation → anticipation → swing → contact → follow-through → recovery, then return to idle. Do not loop it as locomotion.

## Generate a coherent sheet

Use the same accepted character and game view as references for the full sequence. Prefer one evenly spaced atlas for a short coherent motion, provided each cell retains enough pixels for its runtime size. Inspect the actual result: a requested grid is not evidence that the generator produced the requested count or order.

```text
Asset type: transparent game sprite sequence for [one action].
The reference character is the identity, costume, proportion, and viewpoint master.

Create exactly [count] sequential frames in [columns] equal columns and [rows] equal rows.
Read left to right, then top to bottom. Phases: [explicit phase list].
Playback: [loop / one-shot], [duration]. [Last phase leads into first / recovery leads into idle].

Keep the same camera, facing, limb lengths, torso volume, head design, costume,
lighting, and pixels per unit in all frames. Preserve anatomical limb identity.
Keep [weapon] attached to [hand] with a stable grip; [other prop invariants].
Use a shared root position and ground plane; show the action's real weight shift.
No camera orbit, global scale changes, or redesign between cells.
Fit the complete feet, hands, cape, and weapon path inside each cell with clear padding.
Genuinely transparent background; no ground patch, baked contact shadow, labels, or extra poses.
```

If the output repeats the same pose, changes identity, swaps the weapon hand, or scrambles the phases, fix that defect before adding more frames. For a two-step gait, explicitly check that the opposite leg takes the forward contact in the second half; eight files with the same leg extended are not eight valid phases. Video interpolation is also only a candidate until limb lengths, attachment stability, and intermediate silhouettes have been checked.

## Pack without manufacturing stability

Keep source pixels and alpha intact during deterministic extraction. Record cell bounds and order explicitly; do not infer playback order from arbitrary filenames.

- Use one global scale for the sequence and one output canvas size. Do not resize every visible bounding box to the same height or width: stride, crouch, cape spread, and sword extension legitimately change those bounds.
- Register a stable root or pelvis axis against the master, with a shared ground reference. Preserve the small vertical motion belonging to weight transfer; do not align every head or every lowest alpha pixel independently.
- Track each grounded foot's contact interval. A lifted foot, sword tip, or cape hem must not redefine the frame's ground anchor.
- Keep transparent padding sufficient for the entire sequence. Check that no neighboring cell, stray pixel cluster, limb, or weapon has been included or clipped.
- Keep contact shadows separate when the game draws them. Mirroring a sequence is acceptable only if its asymmetric design and weapon-hand semantics allow it; it does not count as new temporal phases.

Measurements such as head height, torso width, root offset, and limb length help locate drift. Interpret them against the intended pose rather than enforcing identical bounding boxes. Report measured tolerances and defects from the actual frames; do not hide them by stretching individual frames.

## Judge the motion in playback

Create and actually view a looping animated preview or a browser recording, then verify the sequence in the target game. A static contact sheet helps inspect drawing quality but cannot prove smoothness. For a loop, watch several repetitions including the last-to-first seam. For a one-shot, watch both entry and recovery into its next state.

Use these checks, adapting the inputs to the project:

1. **Phase and timing:** all intended phases appear in order at the planned durations. Adjacent frames are not repeated standing poses. Check the last-to-first displacement and silhouette as well as the middle frames.
2. **Registration and anatomy:** the root does not jump sideways, body volume does not pump, limb lengths stay plausible, and the weapon does not change hand, grip, or attachment. Distinguish deliberate weight shift from registration error.
3. **Ground contact and speed:** play at actual walking and running speeds. Grounded feet should not skate conspicuously. For in-place locomotion, match phase progression to travelled distance or another explicit stride model; stop progression when actual displacement stops, including walking into a wall.
4. **State transitions:** start, stop, reverse or turn, attack, recover, and pause/resume. Walking must not alternate with idle as a substitute for missing frames. A one-shot should complete or cancel according to gameplay state, without an unintended loop.
5. **Scene integration:** view at actual gameplay scale on representative terrain, facing each supported direction, with normal depth sorting and effects. Inspect transparency and clipping during the largest pose.

Keep technical and visual evidence distinct. Report decoded frame count, computed duplicates or other measured checks, and observed playback separately. Error totals must come from an actual detector or recorded inspection; use “not checked” for an unperformed check instead of writing a hard-coded zero. Passing frame-index assertions or a build does not establish natural motion, and agent visual review does not establish user acceptance.

On failure, correct one identified defect and replay the same scenario. Preserve the source and previous usable sequence for recovery. After three failed retries on the same defect, stop generating, keep the best candidate, and describe the unresolved problem and a deterministic editing or revised-reference option.

## Deliver the sequence

For generated sheets, verify the actual pixel dimensions and row baselines before extraction: requested dimensions may differ from the output, and the second row may have an editorial vertical offset. Preserve one source scale and record explicit crop rectangles and pelvis translations. If repeated corrections keep the same leg leading both half-cycles or enlarge thighs across attached props, retain the best candidate and switch to a layered joint-based workflow; technical playback success does not resolve anatomical continuity. See `assets/source/tide-picker-locomotion-v01/README.md` for a scoped candidate and rejected correction record. A Blender project that sequences textured cards is a 2D timing master, not a skeletal animation rig.

Save the source atlas, actual prompt and references, extraction script or crop manifest, and ordered frame files. Record canvas dimensions, shared scale, root/ground convention, facing, frame order, durations or stride relationship, looping policy, and transition behavior. Include the contact sheet, animated preview or recording, runtime evidence, and known limitations. Keep an unaccepted candidate distinguishable from the active runtime asset.

### Continuous-video candidates

- A cropped source video cannot yield complete body sprites by adding transparent padding. When complete reference art exists, a scoped alternative is to reproject the measured motion onto that art, preserve rigid shell/prop regions and zero grounded-foot motion. Record it as processed video-driven 2D baking, preserve the source motion field, and inspect any warp distortion. Merge identical seam poses with explicit durations instead of appending a duplicate first frame. Validate the actual player's state selector: an existing static-cutout idle override can hide a successfully imported animation. See `assets/source/tide-picker-idle-v03/README.md` and the main-scene regression `tests/idle_animation.gd`.

- Distinguish source frame count, selected chronological frames, derived loop-bridge frames, and final playback FPS. More native frames do not prove a complete alternating gait. Preserve actual prompts/job IDs, including rejected trials.
- Reused historical video must retain its original job identity and preview FPS; retiming it does not make it a newly generated source. Save lossless source pixels separately from viewing MP4s.
- Optical-flow loop bridges can hide a large pose discontinuity by morphing the feet or equipment. Inspect the bridge at slow speed, mark derived frames in the manifest, and do not call it seamless solely from pixel-delta scores.
- If an expressive breathing prompt creates gestures or changes a rigid helmet, retain the stable source and record any localized corrective deformation explicitly. Fixed feet and rigid-head motion require separate weights; this is processed video, not additional AI-generated action frames.
- Neutral background shadows often survive automatic matting. Inspect on light and dark backgrounds and preserve foot interiors when removing the shadow. A packed Blender image-card timeline is a timing master, not a rig. Example: `assets/source/tide-picker-locomotion-v02-video/README.md`.

## 环境分件补充（Godot实机验证）

- 鱼群使用独立个体时，避免同一个正弦路径让所有鱼同时翻转；可使用有预热分布、边缘透明回收的持续游动。尾摆帧与路径分别定义循环。
- 动态贴图要留足透明余量；含屋顶/洞壁的裁片必须拆成固定根片和动片，不能只把UV位移整体加大。
- CanvasItem光纹Shader注意`COLOR`已可能含贴图采样；再次乘采样会把alpha平方，导致动画几乎看不见。用vertex传递调制色，在fragment只采样/混合一次，并通过实际像素变化复查。
- 录制模式的帧时间包含编码，不等于实时帧率。另跑无录制场景测量。参考实现与证据见`assets/source/xumen-motion-elements/README.md`。

## Blender绘画裁片的烘焙帧

- 用原画纹理驱动带UV网格时，保留固定根部和透明余量；同一相机、帧尺寸和原点输出所有帧。不要逐帧紧裁。
- 检查残留背景小岛，再批量渲染；位图连通性、尖端蒙版与色域只能辅助提取，必须复查细丝未被误删。
- 用额外的循环闭合帧验证形态键几何，但导出帧不重复闭合帧；同时验固定点误差、首尾像素变化和实际Godot场景。
- 母版打包绘画纹理，明确自动生成器会重建母版，避免覆盖人工Texture Paint/曲线修改。渲染后的PNG序列是2D动画，不能宣称为逐帧手绘。参见assets/source/baleen-blender/README.md。

- 背景裁片不能直接作为加法光束：原画中的几何会随图层位移错位。移除裁片时还应检查背景是否有配套扣除蒙版；恢复原背景连续性，再叠加不含场景物体的独立透明光效，比较镜头两端与关闭光效后的画面。

- 补齐前景边角时，逐一检查所有承载同一原画区域的静态图层，不能只新增前景而保留底层重复轮廓。底部与侧边相接的分件应保持同一视差，并保留画外像素余量；按真实游戏缩放和相机边界验证，另做全景视差压力图，区分相机越界与素材断边。

- 桥下或屋檐出现直线截断时，分别检查遮挡层和原素材裁切蒙版。只隐藏补底后稍有改善不能证明根因已消除；必须与原图局部轮廓对照。补回悬挂组织时排除已由动态节点拥有的区域，关闭粒子另拍对照，避免重复叠影或用特效掩盖裁片缺口。参考本项目xumen-underbridge-repair。


### 用户指定固定FPS与整秒时长

先读取实际解码帧数/FPS，用ceil(duration)×目标FPS确定帧槽，不以平台标称秒数代替；6秒生成片可能有145帧/24FPS，实际需上取整7秒。尾部补间若有重影应舍弃；改选相位匹配连续区间并重定时时，明确区分完整源时长、选段时长和播放时长，逐帧记录来源，不声称原速直接抽帧。固定FPS优先时不得暗中使用速度倍率；顶墙、暂停和命中停顿仍须冻结动画时钟，保留移动速度则明确记录可能滑步。当前主场景可能已切换控制器，应从main_scene追踪实际实例，不能只改历史player.gd。例：tide-picker-walk-v03及tests/walk_animation.gd。

- 复用视频去底脚本前检查新动作的道具运动范围。Walk的硬编码骨叉修复蒙版不可直接套到大幅摆叉Run；中性背景阈值也可能误删象牙高光。用亮度保护和明暗底实际渲染复查，无法补回的画外像素要明确记录。源片时长向上取整时，记录是补尾还是整体重定时，固定播放FPS与源片动作速度分别陈述。见`assets/source/tide-picker-run-v03/README.md`。
