# Soft tissue wall and low ceiling candidates

Two independent transparent bitmap assets were generated with built-in image_gen__imagegen, using one distinct generation call per asset and targeted edit calls for padding / opaque-core correction. No art pixels were edited with code. Original generated PNG bytes were copied into this folder. Full prompts are saved separately, output IDs and default source paths are in generation-record.json, final PNG SHA256 and reference hashes are in qa.json.

## Roles and scope

- tissue-ridge.png: static thick folded vertical soft-organ wall. Continuous solid maroon / grey-violet tissue; broad blunt ends; sparse rim encrustation.
- tissue-vault.png: static horizontal compact organ low ceiling. Thick continuous mass, rounded blunt ends, compact folded surface.
- Both are static because their primary role is opaque collision-covering terrain. No independent creature, fringe, or particle was added; no motion was inferred from a still reference.
- R1-05 original was inspected for organ folds, painterly texture, color, and shallow fibrous irregularity. Existing R1-05 overview was inspected as the rejected cap / narrow-pillar shape and as placement context.
- Only this soft/ folder was written. Game code, scenes, manifest, catalog, collisions, routes, and other agent families were not edited.

## Measured final PNGs

Coordinates are half-open [left, top, right, bottom] in source pixels.

| Asset | Canvas | Alpha>=32 visible bbox | Solid usable core (70% visible width x 80% visible height) | Core alpha | Minimum visible padding |
| --- | --- | --- | --- | --- | --- |
| tissue-ridge | 946 x 1663 | [93,151,848,1502] | [206,286,735,1367] | 252-254, no gaps | 9.08% |
| tissue-vault | 1774 x 887 | [139,164,1635,678] | [363,215,1411,627] | 252-254, no gaps | 7.84% |

These are visually solid cores, with no pixel below alpha240. The built-in generator yielded near-opaque alpha252-254 rather than mathematically alpha255; exact255 is not claimed. Central proportions are measured against the visible body, not the padded full canvas. The padded canvas central80% height is not solid, especially in the horizontal low ceiling. If an importer requires the entire canvas to cover a collider, these raw canvases are unsuitable: map the recorded core to the rectangle with uniform scale and preserve the exterior padding.

There is faint alpha1-7 noise outside the silhouette; raw nonzero bounds can touch canvas edges. Alpha8 / alpha32 bounds are recorded, no global alpha cutoff was applied because generated edge alpha was preserved.

## Review and remaining work

Observed agent review: maroon / grey-purple contiguous folded flesh; no grey bone pillar, mushroom cap, narrow supporting trunk, sharp terminal point, long thin hanging strands, character, door, UI, water scene, or floor. The final vault upper and lower contour is deliberately restrained to preserve the rectangular opaque core; it remains a dense tissue wall fragment. Both sprites are broadly rectangular terrain mass, with organic folded texture and blunt rounded edge transitions.

Completed checks:
1. Viewed original concept and current overview before generation.
2. Viewed each generated candidate and targeted only the observed defect.
3. Read-only Pillow inspection of canvas dimensions, true alpha, diagnostic alpha bounds, usable core and padding.
4. SHA256 records of final delivered bytes and source references.
5. Confirmed no game/scene/manifest/catalog writes by this worker.

Pending: deterministic actual-scale scene placement, overlap / collider coverage, light-dark compositing on target backgrounds, route review, and explicit user aesthetic acceptance. These files remain candidates; alpha checks are not user approval.

## Reusable finding

Visible alpha bounds alone are insufficient for solid terrain coverage: a shallow upper valley can invade the rectangular collision core despite a generous total bbox. Record an inner opaque rectangle separately from padded canvas and total alpha bounds. Padding correction can also reduce useful core coverage, so remeasure after every source-image revision. This finding is scoped evidence from this batch; global Skill files were not modified by this worker.
