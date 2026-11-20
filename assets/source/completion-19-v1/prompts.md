# 19房补齐 · 图像生成记录

工具：内置 `image_gen`。日期：2026-11-14。非 Chaos Canvas；未使用 CLI/API fallback。

## 鸣贝开合吐珠

参考：`assets/runtime/sprites/spine-resonant-clams/base.png`；身份、纹理与颜色主源。输出：`images/clam-spit-cycle-v1.png`。透明1536×1024、4列2行；脚线在每格393，后铰链固定，按战斗时钟选帧。

生产提示词：

Production game animation sprite atlas for an existing 2D side-view underwater action game. The provided single clam image is the identity, silhouette, shell texture and colour reference, NOT a background to retain. Create exactly EIGHT sequential frames of this same left-facing anchored bone clam performing one shell-open / pearl-spit / shell-close action, in a precise FOUR columns by TWO rows equally sized grid on a genuinely TRANSPARENT 1536x1024 canvas (each cell 384x512). Read left-to-right then top-to-bottom. Draw the subject relatively small within each tall cell so its full clam width is ~330 px and no shell touches any cell edge. Shared lower shell rests on same baseline y=420 in every cell. Rear hinge is on the right at the same point in all 8 cells. Fixed camera, fixed lower shell/footing, constant material palette and scale. Phases: 1 nearly closed resting shell; 2 upper shell starts opening; 3 upper shell half-open; 4 maximum open charge, soft orange mantle visible; 5 mantle contracts in a clear leftward spitting pose, but NO projectile, NO beam and NO extra effect drawn; 6 upper shell half closing; 7 shell almost closed; 8 shell fully relaxed closed matching frame 1. Only upper shell rotates around right hinge and soft interior contracts, lower shell does not move. This is rigid bivalve articulation, not whole-body stretching. Preserve the source's ivory porous spiked shell, dark blue gray bands, burnt orange soft mantle, painterly outline and hand-painted game art. No new limbs, no eyes, no letters, no grid lines, no captions, no ground, no background, no shadows outside the subject, no glow halo. Consistent coherent 8-pose character animation. Ensure each of 8 cells contains exactly one complete instance of same clam.

实际脚线与提示初值不同，以实测元数据393为准，不能逐帧缩放“修稳定”。

## 归海幼体游动

参考：`assets/runtime/sprites/sea-larva/base.png`。单一游动动作，固定头部、尾膜波传播；8帧4×2，384×512格，透明背景。路径和身体帧分离，属于受保护环境生物，无伤害、无新任务。

生产提示词：

Create a production transparent game sprite sheet for ONE looping swim action of the provided translucent blue SEA LARVA, matching its exact identity: round teardrop head with ONE dark blue eye on visible right side, no limbs, tapering double membrane tail, pale turquoise blue semitransparent hand-painted watercolor marine fantasy style. Exactly EIGHT sequential frames in FOUR columns and TWO rows, 1536x1024 pixels total, equal cells384x512. Read left to right then top to bottom. Every frame shows one complete right-facing horizontal-swimming larva, head in the same place at x=255 y=230 relative to cell, tail flowing left, full subject within x35..350 y140..340. Head remains stable and same size, the continuous tail bends in a sinusoidal wave that propagates from neck towards tip. Phases evenly spaced at 0,45,90,135,180,225,270,315 degrees, giving a real complete tail-undulation loop. Smooth anatomical deformation, no new body parts, no body/head scaling, no facing swaps, no drift inside grid, no camera change. Genuine transparent background with alpha and clear padding, retain translucent blue membranes and painterly outlines. No contact shadow, no glow halo, no text, no numbers, no grid lines, no scenery, no bubbles, no ground. This is ambient protected marine life in a deep-sea game, peaceful and nonhuman. The reference is the identity master, remove all reference backdrop.

首轮有外围柔光，单独返修提示：

Edit this existing eight-frame larva sprite atlas with ONE targeted correction: remove ALL exterior bloom, mist, fog, soft light spill and glow outside the actual larva silhouettes. Return genuine transparent empty pixels around every larva. Preserve the eight poses, head and tail positions, anatomy, relative cell scale, colour, shell/membrane texture, grid and exact 1536x1024 canvas. Do not redraw or move the subjects. This is an alpha-cleanup pass: the only semitransparency should be WITHIN or at the tiny antialiased edge of the real biological membrane. Large diffuse pale cyan clouds around the head or tail must become alpha-zero. No replacement background or checkerboard. Keep all eight subjects, 4 columns and 2 rows, 384x512 cells. NO added elements. Preserve the crisp subtle outline and translucent interior of the larva itself, including fine tail tips. Do not add shadows.
