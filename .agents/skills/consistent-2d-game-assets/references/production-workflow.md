# Production workflow

Read this reference for asset sets, project-bound delivery, or repeated generation.

For this project's reference-image environment and independent motion workflow, use [the current scene production guide](../../../../docs/scene-and-environment-production.md). It maps layer extraction, authored-frame versus Shader/path motion, shared clocks, real scene bindings and evidence to existing assets and tools; keep historical batch records separate from current runtime facts.

## 1. Establish the art baseline

Choose one approved gameplay screenshot that represents the target area. Prefer a real runtime capture over a mood board. It should reveal:

- Camera projection and viewing angle
- Object scale and spacing
- Outline color and thickness
- Palette and saturation range
- Light direction and shadow length
- Texture and detail density
- Ground contact and occlusion rules

If several biomes or lighting conditions exist, keep a separate baseline for each rather than blending them into one prompt.

## 2. Define the asset contract

Record a compact brief before generating:

| Field | Example meaning |
| --- | --- |
| Family | farm building, tree, NPC, pickup |
| Footprint | world units, tiles, or comparison with a known object |
| View | top-down, isometric, side view, front-facing icon |
| Interactions | entrance, harvest point, damage area, clickable part |
| Layers | body, door, shadow, decoration, effect |
| States | normal, building, damaged, upgraded, seasonal |
| Output | PNG, transparent padding, sprite sheet layout |
| Anchor | bottom center, door threshold, feet, tile origin |

Describe the object by its use and visible structure, not by its name alone. “Shipping crate” is ambiguous; “waist-high wooden delivery bin with a hinged lid, front-facing pickup side, and a two-tile footprint” gives usable constraints.

## 3. Generate in context

Edit only a reserved part of the screenshot. State the modification boundary and list the rest of the scene as invariants.

The in-context result is the visual master for approval. Confirm:

- It fits the scene without post-hoc explanation.
- Its footprint supports gameplay.
- Entrances and interactable parts are readable.
- The silhouette remains clear at runtime zoom.
- The asset does not borrow accidental details from neighboring objects.

Reject structural problems now. Extraction will not reliably fix them.

## 4. Isolate and split

Choose one route.

### Exact preservation

Use segmentation, a mask, a manual path, or conventional image editing. Preserve source pixels and antialiased edges. This route is required when the user approved the exact in-scene object.

### Reference-guided transparent redraw

Use the accepted in-scene image as a reference and generate a transparent version. Allow for detail drift and compare it against the visual master. This route is useful for concept production and fast iteration, not exact extraction.

Split parts that need independent movement, sorting, recoloring, animation, collision, or reuse. Avoid baking a terrain patch or global lighting into the main object unless the game deliberately uses precomposed decals.

## 5. Normalize

- Trim excessive transparent canvas while keeping agreed padding.
- Remove colored matte spill and broad atmospheric glow.
- Preserve soft antialiasing around real edges.
- Normalize pixel dimensions and pixels-per-unit across the asset family.
- Place the anchor consistently.
- Keep shadows on their own layer when lighting or ground surfaces vary.

For animation sequences, do not normalize each frame to its own visible bounds. Use one shared scale, canvas, and root convention; preserve intentional body rise and fall. Follow [sprite-animation.md](sprite-animation.md) for frame packing and motion QA.

Avoid global saturation changes as the first fix. Compare palette roles such as outline, shadow, base material, highlight, and accent separately.

## 6. Deterministic integration test

Place the final PNG with an ordinary compositor or the target engine. Do not ask a generation model to place it for final QA.

Test at least:

1. Actual gameplay scale on the intended terrain.
2. A second representative terrain or background value.
3. Proximity to existing assets of similar size.
4. Expected runtime zoom or camera distance.
5. Relevant interaction, sorting, and animation states.

## 7. Iterate narrowly

Change one failure at a time and restate invariants. Useful correction targets include outline weight, roof pitch, saturation, footprint, shadow direction, edge halo, or anchor position.

After three failed retries for the same issue, stop. Preserve the best candidate, describe the unresolved defect, and recommend deterministic editing or a revised baseline.

## 8. Package the result

Use stable filenames such as:

```text
farm_chicken-coop_base_v01.png
farm_chicken-coop_shadow_v01.png
farm_chicken-coop_door-open_v01.png
farm_chicken-coop_preview_v01.png
```

Keep a short manifest containing footprint, anchor, layers, states, prompt, source references, and review status. Do not mix rejected candidates into the production asset folder.

For a project delivery, make source references, prompts, editable files, originals, and derived exports resolvable from the project rather than a temporary work directory. Preserve approved original bytes; record their dimensions and hashes to detect unintended replacement. Derive final compositions and exports from the delivered manifest, then rerun the relevant checks against those delivered files. A preview built from an earlier candidate directory cannot validate a later import. For an editable catalog or management page, follow [asset-library.md](asset-library.md).

## Optional static atlas export

An individual transparent PNG is already a sprite. Pack accepted static sprites into an atlas when the target workflow benefits from one texture, while retaining individual originals. A collection of different objects is not an animation sequence; keep action sequences explicitly separate, and leave full-screen backgrounds outside the atlas unless the loader requires otherwise.

Use the agreed pixels-per-unit for uniform scaling, not equal-size gallery cells. Record each frame rectangle, its normalized pivot after cropping/scaling, original source rectangle and original pivot. Distinguish the normalized frame's `sourceSize` from the original large canvas so a loader does not apply trimming twice. Match padding and edge extrusion to the target sampler. Validate frame bounds, overlap, transparent gutters and actual decoded crops against equivalently rendered source images before shipping; successful packing alone does not prove a correct atlas.

For Canvas-based packing, disable image smoothing when copying edge texels into the extrusion gutter, then restore the intended smoothing for the next sprite resize. Interpolating a one-pixel strip into a wider gutter can change its alpha and color instead of repeating the edge; check the copied strips, not only the interior frames.

For multiple pages, store each frame's page identity and export a complete page index. Validate that every eligible source ID appears exactly once across pages and that the downloadable archive contains the indexed files. Keep UI pixel sizes and nine-slice borders in their declared units instead of applying world-sprite scale indiscriminately. Rebuild affected exports when their source pixels or packing metadata change, and record the input revision or signature used by verification.

## Keep large batches bounded

Use a shared inventory and art contract as the handoff between batches. Delegate disjoint families with the relevant references, output location, and acceptance criteria; avoid copying the entire production history into every worker. Have workers return changed IDs, paths, unresolved issues, and concise verification evidence. Keep full prompts, tool output, and per-item measurements in files and inspect only what the current decision needs. Batch size is a scheduling choice, not a reduction of the agreed scope.
