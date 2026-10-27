---
name: consistent-2d-game-assets
description: Generate, extract, validate, and deliver consistent 2D game assets from gameplay screenshots or approved art references. Use for characters, props, environments, sprites, complete static coverage, atlas exports, and project asset libraries that must preserve an established game style.
---

# Consistent 2D Game Assets

Produce reusable 2D game assets that still look native after deterministic placement in the target game scene.

## BOB project routing

Read [the collaboration rules](../../../AGENTS.md) and [the global art style](../../../assets/art-style.md) before production. Use this skill for generation, extraction, variants, animation, atlases, and asset-library delivery; use [BOB art integration](../bob-art-integration/SKILL.md) for repository paths, catalog fields, runtime loading, coordinate conversion, and in-game acceptance. Keep `mvp/` and `mvp-nightmare/` implementation evidence separate.

## Core decisions

- Prefer an approved gameplay screenshot as the primary style reference. It carries perspective, scale, palette, line weight, lighting, texture density, and neighboring-object context at once.
- Generate a new asset inside the target scene before isolating it when visual consistency matters more than exact reproduction.
- Treat model-based “extraction” as reference-guided redrawing. It may alter structure, proportions, colors, and small details even when the prompt says “exactly.”
- When the scene-generated object must be preserved exactly, use a mask, segmentation, manual path, or deterministic crop instead of asking a generative model to extract it.
- Validate reusable assets with ordinary image compositing or the game engine. A generative reintegration is only a preview because the model may repair both the asset and the background.
- Keep source screenshots and approved assets unchanged. Save every candidate and accepted result as a new file.

## Route the task

1. If the user provides a gameplay screenshot, use it as the edit target and main visual reference.
2. If the user provides approved isolated assets but no screenshot, build a small reference board or temporary scene containing representative assets at their real relative scale.
3. If no approved art exists, create one baseline scene first. Treat it as provisional until accepted; do not manufacture a large asset batch from an unapproved baseline.
4. If the request covers multiple assets or production delivery, read [references/production-workflow.md](references/production-workflow.md).
5. When composing or repairing prompts, read [references/prompt-templates.md](references/prompt-templates.md).
6. Before declaring assets ready for use, read and apply [references/qa.md](references/qa.md).
7. For sprite animation, read [references/sprite-animation.md](references/sprite-animation.md) before generating or packing frames. Idle, walk, and attack are different action states; they do not constitute three frames of a walk cycle.
8. When deriving assets from design documents or several kinds of reference, read [references/design-to-assets.md](references/design-to-assets.md) to resolve source roles, preserve gameplay cues, and set a measurable runtime scale.
9. When delivering a searchable asset library or editable resource manager, read [references/asset-library.md](references/asset-library.md) for provenance, review states, derived exports, and persistence checks.

## Minimum asset brief

Gather or infer only what is needed to proceed. Ask the user only when a missing choice would materially change the result.

- Intended use and asset family
- Gameplay view and facing direction
- Real in-game footprint or comparison object
- Required states and variants
- Moving, interactive, and detachable parts
- Shadow policy and light direction
- Required output format, transparency, padding, and anchor

For a complex object, decide the layer split before generation. Building, door, fence, ground decal, shadow, vegetation, and animated creatures should normally remain separate when they move, interact, recolor, or sort independently.

## Default workflow

1. Inspect only relevant screenshots and approved assets. Identify stable visual rules rather than relying on a style label alone.
2. Reserve a clear patch in the target scene or choose an existing empty area.
3. Generate the complete asset in that scene. Specify actual gameplay use, footprint, approach direction, required parts, and the exact area allowed to change.
4. Review the in-scene result before extraction. Reject incorrect perspective, scale, silhouette, or interaction layout early.
5. Isolate the asset using a deterministic mask when fidelity matters. Use transparent generative extraction only when small redesigns are acceptable.
6. Split independently controlled parts and remove baked-in scenery that will not travel with the asset.
7. Place the PNG directly into the target scene without generative editing. Check it on the actual ground, at actual scale, and near existing objects.
8. Make one targeted correction per retry. Preserve accepted properties explicitly. Stop after three failed retries on the same defect and report the persistent failure instead of silently generating indefinitely.
9. Deliver the final assets with prompt records and practical metadata.

## Variant production

- Start variants from an accepted master asset and the same approved scene reference.
- Change one dimension at a time when possible, such as season, damage state, material, or growth stage.
- Keep silhouette, viewpoint, footprint, anchor, line weight, and lighting invariant unless the variant requires a change.
- Generate complete lifecycle sets together when visual relationships matter, but save each state as a separate reusable file.
- For animation, define the phases of one action and whether it loops or plays once. Keep one scale and root convention across its frames, and judge it in motion using the [sprite animation workflow](references/sprite-animation.md). A contact sheet alone does not establish animation quality.

## Delivery contract

For each accepted asset, provide or record:

- Transparent source image and, when useful, an in-scene preview
- Pixel dimensions and intended in-game footprint
- Anchor or pivot location
- Facing direction and light direction
- Layer or attachment relationships
- State or variant name
- Final prompt and reference images used
- Known limitations or required manual cleanup

Do not claim “production-ready” until the asset passes deterministic scene placement and transparent-edge checks.
