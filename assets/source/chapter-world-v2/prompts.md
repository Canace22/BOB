# ImageGen production prompts

Exact invocation text from this task. Absolute reference paths are normalized to repository-relative paths or generated basenames. Rejected candidates are not runtime assets. No independent third-party license is asserted.

## 11. garden.png
Time: 2026-11-02T10:08:38.708Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/concept.png"],transparent_background:false,prompt:"New production BACKGROUND ONLY for BOB 2D side-scrolling game, chapter1 'Baleen Garden' inside a long-dead whale's mouth. Reference is palette/illustrative technique master ONLY. Same hand-painted teal+ivory ecological dark fairy-tale, beautifully crafted large painted forms, not photoreal or 3D. Landscape 1920x1080. Huge arching pale whale jaw recedes in upper half, long hanging baleen combs in loose clusters on left and right (do NOT cover center), multiple tiny inhabited shells suspended from fine organic fibers at top left / upper right, small AMBER lamps inside. Vast ocean haze through rear filtering slits and distant bone arches, particles in beams. Cool dark blue teal depth with desaturated ivory anatomy, restrained rust-coral membrane details. Layered sense of huge whale and tiny resident ecology. Clear empty lower third and central 60% for independently placed walkable terrain/characters; all visible distant architecture low contrast and soft, dark enough for ivory hero and guard to stand out. NO foreground floor/platforms/land, no existing boss or hero, no characters in backdrop, no UI, no text. Edge-to-edge painted full landscape, no vignette border. Main identity is whale baleen/filter garden, not generic cave or castle. Brightest details at far upper corners, central combat plane visually quiet."});
store("chapterGarden",result); generatedImage(result);

```

## 12. well.png
Time: 2026-11-02T10:09:52.882Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/concept.png"],transparent_background:false,prompt:"New production BACKGROUND ONLY for same hand-painted 2D game, second chapter 'Folded Well' inside ancient whale esophagus. Reference establishes painted materials and dark teal/ivory palette; remove characters and walkable floor. Landscape 1920x1080. Massive folded pale organic membranes descending diagonally into a deep dark teal well; old curved bone struts reinforce layers at left and right. Dramatic scale and vertical depth. Small amber inhabited shell nests attached high on the side walls, thin red cords securing repairs, occasional muted coral red patches. Central and LOWER 65% is quiet soft blue-green deep-water haze with low-contrast distant curved folds, clear for foreground platforming and boss; brighter ivory details remain around upper rim and sidewalls. No long whale baleen strands here: this organ has folded muscular lining and cross braces. NOT a stone cavern, ruined castle, meat gore or purple crystals. Same beautiful gouache illustrated ecological fairy tale as reference, readable broad brush shapes not photoreal render. NO player, boss, monsters, UI, text, foreground floors/platforms or baked gameplay objects. Full bleed."});
store("chapterWell",result); generatedImage(result);

```

## 13. kit-background.png (rejected matte)
Time: 2026-11-02T10:11:04.226Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/concept.png"],transparent_background:true,prompt:"Production transparent 2D game environment asset kit in exact 4 columns x2 rows of EQUAL SQUARE cells, 2:1 overall ratio. Eight ISOLATED bitmap assets consistent with reference game's hand-painted bone ivory, desaturated teal, muted rust-red ecological whale interior. Strict side-on platformer view, no perspective top view. One object per cell with 5% clear padding, all complete. Reading left to right: 1) thick wide bone-and-old-membrane GROUND BLOCK, near-horizontal walkable top occupying x5..95% y38%, deep porous naturally torn supporting mass extends to y95%, edges suitable for slight overlap with another block; 2) different thick wide GROUND BLOCK same proportions and horizontal top y38%, more curved bone struts underneath and muted red membrane, NOT purple; 3) small standalone horizontal BONE LEDGE x8..92%, flat top y38%, tapering curved bony support below to y80%, complete; 4) tall narrow curved BALEEN ROOT PIER spanning y5..95%, width40%, dark ivory supporting pillar with fine fibrous sides, flat small ledge at middle. Bottom row: 5) open SHELL ARCH doorway 70% width 85% height, ivory chipped ribs, two red cords and subtle amber lamp, transparent hole; 6) CAMP LANTERN on small shell pedestal, amber glass enclosed in pierced ivory cap, red cord, grounded; 7) inhabited rounded SHELL NEST hanging on two thin fibrous cords, warm amber windows, clear complete hanging support; 8) weathered organic cross-brace LEVER: ivory socket, red cord, bronze grip, no text. No characters. Separate assets not a scene. The ground blocks and ledge have visible porous support underneath, not floating flat lines. No ground shadows around objects, no connecting scenery, no text/labels/grid. Genuine TRANSPARENT RGBA empty space and holes. Preserve illustrated broad brush forms like reference hero/boss, not photorealistic."});
store("chapterKit",result); generatedImage(result);

```

## 14. kit.png
Time: 2026-11-02T10:12:45.576Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-world-v2/kit-background.png"],transparent_background:true,prompt:"Remove background from this exact 8 object asset sheet. Actual alpha background must be ZERO everywhere outside each object, including inside the archway and around the thin cords. Existing background is an erroneous semitransparent gray rectangle with grid lines; remove ALL of it, not just lighten it. NO haze, no matte, no lines separating cells, no white/black backdrop, no shadows. Preserve every object's dimensions, cell positions, outline, shading, colors and bone texture. 4 columns x2 rows same layout/aspect ratio 2:1. Foreground objects fully opaque with antialiased edges. This is a technical transparent cutout request, not new artwork."});
store("chapterKitFixed",result); generatedImage(result);

```

## 15. scavenger.png
Time: 2026-11-02T10:14:18.995Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/assets/source/chapter-guard-v2/neutral.png"],transparent_background:true,prompt:"Create a NEW SMALL scavenger beetle for same 2D game as reference, matching ivory/deep-teal hand-painted illustration, outline weight and lighting. This is not a miniature guard: low smooth oval segmented ivory carapace, SIX short dark teal jointed legs, two short ivory mouth pincers, amber eyes, NO giant shell shield, NO straps or buckle, no horns. Fixed side game view facing LEFT. Genuine transparent RGBA sprite animation sheet 4 columns x2 rows equal square cells, aspect2:1. Body small squat width65% cell, height35%, root center x55%, ground y75%, lots of empty padding. TOP ROW 4 sequential slow crawling phases: near front extended contact, near pair bent passing as far legs support, opposite legs extended contact, far legs passing as near support. Both tripods alternate visibly, same size, roots aligned. BOTTOM ROW 4 sequential snap-lunge action: low crouch mouth closes loading rear legs; rise and mouth pincers open wide in anticipation; rear legs push body forward left in low leap mouth wide extended; land/recover crouched mouth closes. Keep body size/shape and limb count consistent, clear continuous anatomical changes, no global scaling/rotating copies. Every foot and pincer complete within cell with padding. No effects, floor, shadows, terrain, background, labels, lines or grid. Transparent cutout with crisp edges like reference."});
store("chapterScavenger",result); generatedImage(result);

```

## 16. residents candidate (rejected matte)
Time: 2026-11-02T10:20:08.566Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["REPOSITORY/game/art/player/idle_0.png","REPOSITORY/assets/source/chapter-guard-v2/neutral.png"],transparent_background:true,prompt:"Transparent sprite sheet for two NEW friendly inhabitants in same hand-painted 2D whale-fall game. References define style/palette ONLY, do not copy hero or guard design. Exact4 columns x2 rows equal square cells, aspect2:1. Top row four successive poses of the SAME small nest-mender: squat ivory spiral-shell-bodied creature, four short teal tentacle feet and two fine teal working arms, one amber eye beneath shell rim, tiny amber lantern suspended at chest, no weapon; facing RIGHT, weaving a thin red cord through a small ivory shell shard held near chest. Poses: arms apart holding shard and cord, near hand draws cord toward chest, near hand reaches through hole, pulls cord taut returning to start. Bottom row four successive poses of SAME elderly guardian: taller upright arthropod with worn ivory shoulder armor over deep teal body, bent old posture, amber eyes under shell hood, four strong legs, two long teal arms holding ONE long pale bone staff diagonally in BOTH hands; facing LEFT. Action phases: knees bend staff held low; shoulders and arms push staff up-left; fully braces staff upward with body weight and straightened legs; relaxes staff halfway after bearing the load. The bone staff must remain same length and grip identity in all4 poses, entire staff always inside cell. All poses shared root floor y88%, same character-specific scale within each row, shell outline/head size stable. Warm amber/ivory/deep teal/rust-red, crisp readable painted silhouette like references, no photorealism. All sprites fully contained with margins. Genuine transparent RGBA, no backdrop, white matte, shadows, floor, dust, text, grid or labels."});
store("chapterResidents",result); generatedImage(result);

```

## 17. residents.png
Time: 2026-11-02T10:21:15.460Z
```javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({referenced_image_paths:["generated/exec-6134b8c5-6d15-4971-a6a7-6d5543cc387c.png"],transparent_background:true,prompt:"Remove background from this exact eight-character-pose sprite sheet. Actual alpha must be ZERO outside figures, in between feet/arms/staff, everywhere in empty background. Remove ALL gray-white backdrop, soft shadows, vignette and dividing grid. Preserve the SAME eight drawings, all poses, exact proportions and cell positions, complete hands/staff/feet, 4 columns by2 rows. No redesign. Foreground characters opaque with crisp antialiased silhouette; no glow/matte/haze. Transparent PNG cutout, no text or backdrop. Canvas ratio2:1."});
store("chapterResidentsFixed",result); generatedImage(result);

```
