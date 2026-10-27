# Production QA

Apply this reference before final delivery. Record failures instead of hiding them with a generated preview.

## Visual match

- Perspective lines agree with comparable scene objects.
- Asset scale and footprint are plausible at runtime zoom.
- Outline color and thickness do not stand out.
- Base colors, shadows, highlights, and accents stay within the scene palette.
- Texture density and edge sharpness match neighboring assets.
- Light direction, shadow length, and ground contact agree with the scene.

Check visible weight-bearing pixels against the local surface beneath them; a shared bottom pivot or uniform placement height does not guarantee contact on an uneven painted platform. Record canonical sprite pivots separately from per-instance placement offsets, and do not treat visual contact as collision validation.

## Reusability

- Background is genuinely transparent, not painted black, white, magenta, or checkerboard.
- No broad halo, matte spill, accidental terrain, or neighboring object remains.
- Required padding is present and no edge is cropped.
- Independent parts are separated when gameplay needs separate control.
- Shadow and ground decal are separate when they will change by terrain or lighting.
- Canvas size and anchor follow the family convention.

If a viewer appears to show a solid rectangular matte, inspect the actual alpha and composite onto light and dark backgrounds before diagnosing background leakage. RGB values under alpha zero are invisible in correct compositing; a viewer's treatment of those values is not evidence of a visible artifact.

When alpha bounds touch the canvas edge, report both the raw nonzero-alpha bounds and bounds at stated diagnostic thresholds (for example, alpha ≥ 8 and ≥ 32 on a 0–255 scale). Faint noise can expand raw bounds while the visible silhouette still has padding; inspect light/dark composites before calling it cropped or clean. Thresholds are diagnostic, not an automatic global alpha cutoff: trimming low alpha can destroy translucent membranes, fine edges, or effects.

## Fidelity

- Compare an extracted or redrawn asset with the approved in-scene master.
- Check silhouette, roof pitch, openings, fence layout, attachment count, character count, and relative positions.
- Label generative extraction as a redraw when any structure changed.
- Do not claim pixel fidelity without a deterministic mask or equivalent evidence.

## Deterministic scene tests

Run three to five relevant tests:

1. Place the PNG in the target scene using the engine or an ordinary compositor.
2. View it on both light and dark representative backgrounds.
3. Compare it beside an existing asset at the same world scale.
4. Exercise expected layer sorting, interaction, or animation state.
5. Inspect transparency and edges at 100% and runtime zoom.

## Batch consistency

For asset families, compare the whole batch together:

- Shared camera angle and ground plane
- Consistent pixels-per-unit and anchors
- Stable line weight and palette roles
- Deliberate variation without accidental clones
- Lifecycle states that still read as the same object

## Delivery status

For sprite sequences, also apply [sprite-animation.md](sprite-animation.md): inspect the loop seam or one-shot recovery in motion at actual gameplay scale and speed. A contact sheet or a successful build cannot substitute for this check. Keep visual review and user acceptance separate from technical validation.

Use honest status labels:

- `concept` for a visually promising idea without integration QA
- `candidate` for an isolated asset awaiting deterministic testing
- `accepted` after visual and deterministic scene checks pass
- `needs-cleanup` when manual mask, edge, palette, or alignment work remains

Define what `accepted` means in the receiving catalog. Track agent technical/visual review, explicit user art approval, and runtime integration separately; one status must not silently stand for all three. Record the reviewer, evidence, and asset revision where the project supports them. A changed source or registration needs the affected checks again; a renamed display label does not require regenerating the art.
