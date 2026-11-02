# ImageGen production prompts

Exact invocation text from this task. Absolute reference paths are normalized to repository-relative paths or generated basenames. Rejected candidates are not runtime assets. No independent third-party license is asserted.

## 1. concept.png
Time: 2026-11-02T09:50:06.564Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 2000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/game/art/enemies/crab_video/environment.png","REPOSITORY/game/art/player/idle_0.png"],transparent_background:false,prompt:"Create a single production concept frame for a side-view 2D hand-painted game, BOB / whale-fall city. Reference 1 establishes environment texture, broad warm bone foreground planes and teal depth. Reference 2 establishes readable character outline and gouache-shaded character detail. Rework the scene into the esophagus 'Folded Well': broad layered folds of ancient pale whale tissue, old shell braces, soft deep-sea blue-green haze, very restrained warm amber nesting lights. Not rocks or a castle. A clear horizontal ivory walkable shelf at 72% image height; unobstructed fighting area. At image center-right on shelf show an entirely new enemy, the burden-shell gatekeeper, facing LEFT in strict side game view. About 3 times the hero height, a squat deep-teal armored crustacean with four stout load-bearing legs, TWO broad blunt ivory gripping claws, and a huge upright rounded broken bivalve shell strapped over its back with exactly TWO rust-red bands. Distinctive shell silhouette like a worn shield with three blunt teeth along its FRONT lower edge; shell is 55% of overall silhouette. Small amber eye, no human face, no horns. Red strap clasp clearly exposed near the rear flank. Visually authored in same painted illustration style as hero, simplified large forms, readable silhouette, no photoreal texture/no 3D-render sheen. Include the small hero on left at relative scale using reference 2 identity faithfully. Guard is breathing calmly in neutral grounded stance, not attacking. This is one scene, no panels, no text, no UI, no logos. Landscape 1536x1024. Retain palette ink navy #081923, gray teal #294B54, ivory #C5C1A6, restrained teal #72B6AF, amber #DDA45D, muted red #944F4A. All body, claws, legs and shell fully visible. New scene should feel like a different specific organ along the same game's journey."});
store("guardConcept",result); generatedImage(result);

```

## 2. sweep-source.png (rejected framing)
Time: 2026-11-02T09:52:43.528Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/concept.png"],transparent_background:true,prompt:"Use case: identity-preserve. Asset type: genuine transparent side-view 2D sprite ANIMATION sheet. Reference concept is the identity and painterly style master for the large shell-bearing guard ONLY. Remove hero and all scenery. Draw exactly EIGHT successive poses of ONE claw sweep attack, in exactly FOUR equal columns and TWO equal rows on 2048x1024 canvas (each cell 512x512). No labels or gutters. Guard faces LEFT in all cells, never turns toward camera. Match reference: large broken ivory bivalve shield shell with chipped top, two rust-red horizontal binding bands and rear bronze buckle, deep desaturated teal body, four stout legs, small amber eye, two ivory claws. Keep same shell volume, two band positions, head/eye size and body length across entire sequence, same pixels per unit. Body root at cell x=290, ground y=465. Neutral guard occupies x=140..455 and y=90..465. Leave clear padding for claw sweep toward x=30. Eight ordered phases left-to-right top-to-bottom: 1 neutral grounded stance, front claw low; 2 elbow flexes drawing near claw backward toward chest with wrist rising; 3 claw drawn higher, body leans back subtly, far claw braces; 4 near claw reaches highest/coiled position preparing sweep; 5 near claw sweeps rapidly forward-left and down, full arm extension, two claw tips wide open; 6 claw reaches lowest extended follow-through at ground level x=30, weight goes to front legs, shell slightly tilted but same size; 7 elbow folds in and claw returns halfway, legs start lifting torso; 8 recovered neutral stance with claw low close to body, returning to phase1. Real anatomical articulated changes, NOT rotated copies. Far claw and four legs remain identifiable and attached. Shell shape stays consistent and large. Preserve original illustrated paint shading, limited clear large shapes suitable for 220px tall in-game character. Entire body/shell/claws/feet inside every cell; NO contact shadows, NO dust/effects, NO background remnants, NO checkerboard, no text. Genuinely transparent RGBA background."});
store("guardSweep",result); generatedImage(result);

```

## 3. sweep.png
Time: 2026-11-02T09:54:46.209Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/sweep-source.png"],transparent_background:true,prompt:"Correct only the sprite sheet's framing/layout/padding, preserve this exact character design and the eight claw-sweep poses in their existing order. Exactly 4 columns x2 rows of EQUAL SQUARE cells, entire output aspect ratio exactly 2:1. Make the guard 20% smaller WITHIN EVERY CELL by the SAME scale so all extended claws and shell extremities fit with generous clear margins. Each identical cell: fixed shell/back leg root at 65% cell width and feet baseline at 87% height; entire creature including maximally extended front claw must fit inside x=7%..93%, y=9%..89%. All eight cells keep same body and shell size, head size, camera facing LEFT, two red shell bands and golden buckle. The maximally extended claw in bottom left cell MUST be complete, not cropped. NO poses touch cell boundaries, NO neighboring overlap. Keep eight sequential action phases including raising, forward sweeping and recovering, not eight duplicates. Crisp genuine alpha edges, transparent empty background, no colored glow/fringe, no shadows, no background grid, no text. Same hand-painted detailed illustrative art."});
store("guardSweepFixed",result); generatedImage(result);

```

## 4. walk-candidate.png (rejected phase)
Time: 2026-11-02T09:56:38.123Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/sweep.png"],transparent_background:true,prompt:"Asset: continuous in-place WALK animation for EXACT SAME left-facing shell guard from reference, same painterly style, no scenery. Make 8 sequential poses, 4 columns x2 rows equal square cells, canvas aspect exactly 2:1. Use identical scale as reference: feet baseline 85% cell height, shell tallest point about 18%, back foot centered around 82% width, body root at 65% cell width; character plus claws contained within cell x10%..91%. Same broken shell silhouette, two red bands, rear golden buckle, tiny amber eye, four stout teal armored legs and two low ivory claws throughout. Animate four-leg alternating diagonal gait, not copies: 1 near front foot reaching LEFT ahead, near rear foot extended RIGHT behind, both planted, far pair middle; 2 near front accepts weight, near rear lifts and swings forward; 3 near pair passes beneath body as far pair supports, clearly raised bent near rear foot; 4 far front extends left and plants as near front lifts; 5 far front accepts weight, near rear plants forward, near front trails; 6 near front swings forward raised and far rear lifts; 7 near front passes and reaches ahead, far pair supports; 8 near front lowers just before contact, near rear pushes backward returning smoothly to pose1. Body shifts UP/DOWN by just 2% per step. Shell rigid, limbs genuinely articulated with feet lifting and planting; keep head diameter and shell width invariant, NO global resizing. Shell bands/buckle retain identity. Claws hang low and sway slightly without attacking. Fixed side view LEFT all cells, no camera turns, no effects, no baked shadows. Genuine transparent background, clear generous margins, absolutely no limb clipping, labels, floor or grid. This is 8 poses of walking, not attack/idle mixed."});
store("guardWalk",result); generatedImage(result);

```

## 5. walk.png
Time: 2026-11-02T09:58:38.492Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/neutral.png"],transparent_background:true,prompt:"Exact character identity reference. Create 8 continuous WALKING frames of this shell-bearing four-legged creature facing LEFT, 4 columns x 2 rows equal cells. The two front claws MUST remain tucked LOW exactly as the reference, with no arm raising/extension/swiping at any point. ONLY walking legs articulate, shell/head bounce slightly in weight transfer. Fixed side view, same rigid shell design/width/height, same tiny head/eye size, two horizontal red bands and rear bronze buckle. Real quadruped walk: (1) near front foot reaches left, near back pushes right; (2) near back lifts bent; (3) near back passes and near front moves beneath body; (4) far front plants forward-left and near front lifts; (5) near back plants forward-left, near front trails bent; (6) near front swings raised forward-left, far back lifts; (7) near front reaches left just off floor; (8) near front plants ahead, near back extends back ready to return to frame1. Lifted legs visibly clear floor. Far pair alternates with near pair. Do not depict detached limbs. The two ivory claws stay LOW touching near head, passive, never look like attacking. Sheet exact 2:1 ratio. Every cell same registration: feet plane at 85% cell height, shell top near 18%, shell body center x60%. Subject same size in every cell, complete all limbs, 8% minimum empty padding all sides. Hand-painted illustrative gouache with crisp silhouette, exactly reference palette/outline/texture density, not realistic. No shadows, terrain, effects, text or checkerboard. Actual transparent RGBA."});
store("guardWalkFixed",result); generatedImage(result);

```

## 6. slam.png
Time: 2026-11-02T10:00:21.897Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/neutral.png"],transparent_background:true,prompt:"Asset: continuous SHELL PRESS attack animation, same left-facing burden-shell guard from reference. 8 successive poses in equal 4-column 2-row grid, total aspect 2:1. Genuine transparent background. Preserve exact same giant chipped ivory shield-shell silhouette with two red bands and rear bronze buckle, tiny amber eye/head, deep teal body, two low ivory claws and four weightbearing legs. Same character scale in all cells. Shared ground y=87% cell height, body root x=60%. Ample 8% padding all sides throughout. Eight phases: 1 normal standing stance with low claws; 2 front two legs flex slightly and head dips under shell lip, rear legs begin extending; 3 rear legs extend fully, whole shell pitches forward toward LEFT 15 degrees, front claws braced on floor, strong anticipation; 4 maximum forward pitching preparation with front shell lip above ground, limbs stretched under weight; 5 shell FALLS forward-left down onto floor, front lip slams ground, front legs deeply folded, rear legs push, shell rotates 30 degrees without changing shape or size, head protected inside; 6 hold lowest heavy contact, rear buckle exposed, claws spread low; 7 legs begin extending to raise shell half way, visibly vulnerable; 8 return to original upright normal stance. Real bent-joint poses and weight transfer, no global resize. Preserve shell volume, head diameter, eye and buckle. Far legs remain coherent/attached, no extra legs. Same detailed hand-painted graphic style, no 3D sheen. Do not add floor/shadows, dust, sparks, slash effects, ghosting, labels, cells lines or scenery. Fit complete silhouette per frame. This is eight continuous temporal phases of one heavy attack."});
store("guardSlam",result); generatedImage(result);

```

## 7. breath-hit.png
Time: 2026-11-02T10:02:25.864Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/neutral.png"],transparent_background:true,prompt:"Transparent animation production sheet, same exact left-facing burden-shell guard. Eight cells in 4 equal columns x2 rows, aspect 2:1, no labels. TWO short sequences separated by row. TOP ROW: 4 sequential subtle breathing poses looping: neutral, inhale chest/head rises 2%, fullest breath legs straighten a little and claws open a little, exhale settles toward neutral. Shell never changes scale, limbs stay grounded, do not make identical copies. BOTTOM ROW: 4 sequential hit recoil poses played once: near head jerks back right and eyelid squeezes, front legs buckle slightly under impact while shell pitches back 5 degrees and claws bend inward, legs brace recovering with head lowering left, full recovered neutral. This is a reactive flinch not an attack, no claw extension and no blood. Same rigid chipped ivory shell, TWO red bands/rear bronze clasp, four teal legs, two ivory claws, tiny amber eye. Keep identical shell size, head diameter and root across all cells, same fixed left facing side camera. Per cell floor y85%, shell top y18%, shell center around x60%, ample padding (all silhouette x10..90%, y10..90%). Preserve beautiful hand-painted illustrative shading. Real subtle anatomical motion. NO floor, shadows, glow, effects, props, numbers, text, grid or background. Genuine transparent RGBA."});
store("guardBreathHit",result); generatedImage(result);

```

## 8. retire candidate (not integrated)
Time: 2026-11-02T10:03:57.971Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/neutral.png"],transparent_background:true,prompt:"Same exact left-facing burden shell guard design, create six consecutive frames of NONLETHAL DEFEAT / LOWERING GUARD animation. 3 columns x2 rows equal square cells on 1536x1024 canvas. Shared floor at85% cell height and body root x60%, identical pixel scale in all frames. 1: begins normal standing from reference, both red bindings intact; 2: legs buckle down a little and bronze rear buckle pulls loose, head lowers; 3: front legs fold into low kneel while giant ivory shell slips slightly backwards RIGHT, lower band visibly slack; 4: creature rests weight on bent legs, two claws open and lowered flat, no aggression, slack red strap droops by rear flank; 5: head raises modestly and small amber eye opens, indicating alive, shell remains lowered backward; 6: final settled resting sitting pose, four legs low, both claws folded flat on floor, eye open, slack strap, shell still resting on back. Preserve EXACT chipped shell structure and relative head/body/shell size, two red bands and golden buckle identity through action; no disappearance/redesign. Same hand-painted teal/ivory/rust-red illustration style. No blood, skeleton, corpse, dissolving/fading or particles. Do NOT mirror, no rotation of camera, no scaling between frames. Entire creature in each cell with safe margins. Actual transparent RGBA, no ground/shadow/scenery, text, grid or labels."});
store("guardRetire",result); generatedImage(result);

```

## 9. retire candidate alpha correction (not integrated)
Time: 2026-11-02T10:05:24.531Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["generated/exec-d3689682-eac0-4c87-87f0-97b0d44d7989.png"],transparent_background:true,prompt:"Background removal only. Preserve these EXACT six guard animation poses, exact positions/sizes, 3x2 layout and character identity. Remove every brown backdrop pixel, haze, shadow and glow from around and BETWEEN the legs/claws. Export all six characters on genuinely transparent alpha with clean antialiased edges. NOT a black background, NOT a checkerboard background, NO painted background whatsoever. Keep shell, eye, claws, legs, two straps and loosened buckle unchanged. Same 1536x1024 canvas. Do not change poses or redesign anything."});
store("guardRetireFixed",result); generatedImage(result);

```

## 10. retire.png
Time: 2026-11-02T10:06:32.149Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/neutral.png"],transparent_background:true,prompt:"Transparent PNG sprite sheet, 4 columns by 2 rows, equal square cells, wide 2:1 output. SAME guard character on TRANSPARENT ALPHA like input. 8 consecutive animation frames of him being disarmed, alive, settling into low resting pose. 1 neutral as reference. 2 eye squeezes and knees start folding. 3 buckle opens and rust-red lower strap hangs loose. 4 claws lower while knees bend further. 5 abdomen settles low with legs folded, heavy shell leans backward slightly. 6 both claws resting flat, shell stationary low. 7 small amber eye opens while head rises a little. 8 calm low seated pose eye open and claws down, lower strap loose. Same rigid chipped ivory shell, exactly two red bands, rear brass buckle, dark teal FOUR legs, two pale claws. Exact consistent body scale, fixed camera facing left. Each cell feet baseline 85%, shell top in initial frame18%, root x60%. Real articulation; do not make global scaled copies. All cells generous padding. Isolated transparent game sprite asset; absolutely no painted backdrop, NO brown vignette, no shadows, no floor, no halos, no checkerboard or labels. Empty areas must be alpha=0. Render as cutout sprites like reference. Hand-painted illustration style."});
store("guardRetireV3",result); generatedImage(result);

```
