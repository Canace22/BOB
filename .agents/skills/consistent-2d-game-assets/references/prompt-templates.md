# Prompt templates

Read this reference when generating or correcting assets. Replace brackets with concrete project information and remove unused lines.

## In-scene generation

```text
Use case: precise-object-edit
Asset type: reusable 2D game asset
Input image: the gameplay screenshot is the edit target and primary style reference.

Place [asset] in [exact empty area].

Gameplay use and footprint:
[what the player does with it, approach direction, real size or tile footprint]

Required visible structure:
[parts, openings, attachments, states, readable interaction points]

Consistency requirements:
Match the screenshot's camera angle, object scale, line weight, palette, texture density, light direction, shadow length, and ground contact.

Modification boundary:
Change only [area]. Preserve [camera, framing, terrain, existing objects, UI state] as closely as possible.

Avoid:
[unwanted materials, colors, decorations, text, logos, extra objects]
```

## Transparent reference-guided redraw

Use only when minor redesign is acceptable.

```text
Use case: background-extraction
Asset type: reusable transparent 2D game asset
Input image: the approved in-scene asset is the visual master.

Show [asset and included parts] alone on a genuinely transparent background.
Preserve its viewpoint, silhouette, proportions, internal layout, palette, line weight, texture, and lighting as closely as possible.
Keep [required shadow or ground decal] and remove [scene-specific terrain or neighbors].
Center the complete object with [padding]. Do not crop any edge.

Avoid:
redesign, extra decoration, background glow, colored matte, checkerboard, text, watermark
```

Do not describe this prompt as exact extraction. Compare the result against the visual master.

## Variant from an accepted master

```text
Use case: precise-object-edit
Asset type: variant of an approved 2D game asset
Input image: the accepted master asset is the identity and style reference.

Create the [variant name] state by changing only [target property].
Preserve silhouette, viewpoint, footprint, anchor, line weight, palette roles, lighting direction, and all unrelated structure.

Required state cues:
[visible changes needed for gameplay readability]

Avoid:
camera rotation, scale change, structural redesign, new decoration, text, background
```

## Targeted correction

```text
Correct only [one defect].
Keep [accepted silhouette, structure, viewpoint, palette, lighting, proportions, and transparent canvas] unchanged.
The corrected result must [observable acceptance condition].
Do not add new objects or reinterpret the design.
```

## Sprite animation sequence

Use the phase brief and sequence prompt in [sprite-animation.md](sprite-animation.md). Request phases of one action, rather than a sheet mixing idle, walk, and attack. Establish the important poses before adding in-betweens; approve continuity by playing the resulting sequence, not by counting cells.
