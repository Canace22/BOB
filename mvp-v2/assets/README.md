# Asset provenance

`abyss-backdrop-v2.png` is the clean distant environment layer for the 2D MVP.

- Generated on 2026-10-26 using the built-in `image_gen` tool (no CLI/API fallback).
- Original output: `C:/Users/HYQRMF3/.codex/generated_images/01a1776f-a644-7992-8a27-f7ebbb24cc73/exec-906b0643-a723-4f09-8e2b-86f324bc8ce2.png`.
- New full-frame illustration; no image was passed as an edit target or reference input. V2 art was inspected to establish palette and organic architecture direction.
- Visually checked: no characters, creatures, gameplay platforms, text, UI, storyboard frames, or water surface line. Central and lower space are atmospheric and open. Runtime renders traversable surfaces and characters separately.

## Exact generation prompt

```text
Use case: stylized-concept
Asset type: production-ready distant backdrop for a 2D side-view exploration game, single full-frame wide 16:9 raster illustration.
Primary request: A beautiful quiet underwater interior of a colossal fallen whale, a vast organic vaulted cavity. This is only the far background layer; all playable surfaces and characters will be rendered separately by the game.
Scene: very distant softly receding curved bone arches and organic walls in an immense flooded chamber. Soft light shafts filter from far above through blue water, with sparse suspended dust and subtle mineral mottling. Shapes frame the far left, far right and upper edge; the broad center and lower half stay open, atmospheric, and softly textured.
Style: sophisticated painterly fantasy environment art, tactile brushed texture, delicate worn bone surfaces fading into water haze, calm mysterious mood. Muted desaturated deep teal and blue with restrained grey-green highlights, gentle contrast.
Composition: flat side-view game-friendly distant scene, panoramic 16:9, one continuous image. No foreground objects. Only soft distant architectural curves and water haze; nothing that could be mistaken for a playable platform.
Constraints: NO people, NO character, NO diver, NO protagonist, NO humanoid silhouette, NO helmet, NO creatures or fish, NO large face-like shapes. NO horizontal ledges, NO walkways, NO platforms, NO ropes, NO doors, NO props, NO collectibles, NO gameplay objects. NO water surface line or stomach pool, NO prominent mouth baleen. NO interface, NO text, NO border, NO panel divisions, NO storyboard, NO inset. Opaque background.
```

## Reusable transparent bone terrain

`bone-ledge-v2.png` is a reusable isolated bone ledge module, generated on 2026-10-26 with the built-in `image_gen` tool and `transparent_background: true`.

- Reference input, inspected first and passed through `referenced_image_paths`: `docs/鲸腹遗城原画集/V2/images/L09_肋骨穹顶.png`.
- Source output: `C:/Users/HYQRMF3/.codex/generated_images/01a1776f-a644-7992-8a27-f7ebbb24cc73/exec-0c7fadc2-b9fb-43ce-93f3-2039f2a43942.png`.
- This is a source-guided extraction and reconstruction of the concept sheet's porous bone material as a new isolated game asset. It is not a pixel-identical crop of the original ledge and not a whole-scene background.
- Visually checked: single horizontal bone module, no characters, creatures, plants, ropes, props, text, or storyboard panels. Its main top rim is near-horizontal; the end caps have small irregular rises and should be treated as decorative silhouette, while gameplay collision remains a flat plane.
- Preserve the PNG alpha. Renderer should use measured alpha bounds and align the main rim to the collision surface instead of aligning transparent image padding to the platform top.

### Exact bone module prompt

```text
Use case: background-extraction
Asset type: ONE reusable transparent terrain sprite for a side-view 2D game.
Input image 1: visual material and shape reference, the L09 rib-vault concept-art sheet. Extract and reconstruct ONLY its pale weathered porous whale-bone ledge material as a practical isolated platform module. Do not reproduce its full scene or storyboard.
Primary request: one long low horizontal bone ledge / beam, in strict side elevation. Its visible solid body should be about five times wider than tall. A clean nearly flat horizontal walkable upper edge, subtly chipped but without bumps obstructing standing. Irregular hanging jagged bony underside with small natural holes, worn struts and porous organic erosion, clearly inspired by the reference's upper-right ledge. The top surface is a thin readable warm ivory rim; front and underside cool grey-beige, shaded like the source art. Both ends cleanly terminate, one continuous beam, no separate pieces.
Style: match the source's finely painted, tactile, weathered whale bone; enough crisp structure to read at game size. Soft neutral upper-left lighting, no cast shadow outside the object.
Composition: one wide landscape image containing only the complete isolated ledge, centered, filling most of the width with minimal transparent padding. Preserve actual alpha transparency around the silhouette and inside the holes. Useful as a reusable terrain module to be scaled and repeated by the game.
Constraints: transparent background, no background color or checkerboard pixels. NO environment, NO water, NO sky, NO floor, NO ground shadow. NO character, NO diver, NO helmet, NO fish, NO creature. NO rope, NO hanging string, NO plants, NO coral, NO kelp, NO mushroom, NO props, NO light orb. NO text, NO frame, NO border, NO inset, NO multiple sprite sheet panels. This is source-guided reconstruction/extraction, not a whole scene.
```
