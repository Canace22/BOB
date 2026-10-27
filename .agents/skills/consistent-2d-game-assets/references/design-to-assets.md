# From design documents to assets

Read this when a brief mixes design pages, character sheets, concept paintings, maps, or older prompts.

## Establish complete coverage before choosing batches

When the user asks for assets from whole design documents or an art collection, inventory the complete requested scope first. Do not silently reinterpret the request as a representative starter pack. Production batches may be small; the coverage contract remains the full request unless the user narrows it.

List unique character families and variants, bosses, friendly/ecological actors, props and mechanisms, environment layers and reusable materials, rewards, UI art and effects. Map scene pieces to every required room or scene. Record required visual states separately from action animation. Count families, state images and animation frames separately; reference-sheet counts and packed atlas frames are not completion percentages.

Track each requirement with a stable ID, source evidence, required variants/states, existing output links and actual review status. Mark a family partial when only one pose or state is delivered. Separate user-approved adaptations from unresolved design conflicts, and retain shared-template variants without inventing extra species. A room is not covered merely because a general background exists for its region.

Show the inventory beside the delivered catalog when a resource manager is part of the task, including pending requirements with no image. Never represent pending work with a fabricated accepted image or make the gallery's delivered-item count look like total coverage. Before final delivery, reconcile the inventory against files and report omissions explicitly. If the user chooses static assets first, complete that inventory before claiming the phase complete; preserve animation work as a separate later phase.

Before closing a full-design inventory, run an independent pass over the original references and rules rather than checking only whether listed IDs exist. Look specifically for cross-category objects such as narrative projections, enemy projectiles, detached rewards, and pickup aftermath. A completed checklist can still omit an entire required shape. Deferring animation does not justify omitting a separately visible projectile or projection.

## Assign each source a job

First determine whether the sources describe separate alternatives, revisions, or different levels of detail of one design. Do not invent two visual styles merely because two documents were supplied.

Record the relevant source and its role in the asset brief: character identity, environment material, geometry, gameplay rules, or scale. Resolve conflicts by the project's stated authority and revision context, not a universal file-format ranking. For example:

- When the design explicitly assigns collision geometry to current layout data or a structural map, use that for platform edges and door positions; a painting may compress space.
- Use an approved character sheet for identity and attachment placement, while the room reference supplies lighting and relative scale.
- Current rules can supersede an archived generation prompt. Check consequential differences such as exits, rewards, creature counts, and ability gates before reusing prompt text.

Record unresolved conflicts and continue with independent assets. Ask only if the conflict prevents a usable result; do not silently invent a new route or interaction to reconcile sources.

For a multi-cell creature or action sheet, identify the exact row/cell and pose used as the identity reference. Request one instance of the intended subject, not a copy of the sheet. State the visible structure counts that distinguish that design and viewpoint, such as one body and one snout; eye or limb counts must follow the reference and occlusion, not a rule applied to every creature. If forms are duplicated, correct that structure alone while preserving the accepted pose, silhouette, and materials.

## Preserve identity and gameplay meaning

- Describe asymmetric attachments in anatomical left/right, separately from screen direction. Before generating an opposite facing, check handed equipment, lamps, markings, and attachment points. A whole-image mirror changes those sides; use a suitable directional drawing or independent attachment layers when the design requires them to stay fixed.
- Preserve the project's visual cues for walkable surfaces, interactable objects, hazards, and decoration. If bright top edges mean a standing surface, decorative ledges should not borrow the same cue. A decorative hole should not look like a usable exit.
- Check important cues at runtime size by silhouette and shape as well as color. Keep glow, particles, and foreground occlusion from hiding contact edges or attack warnings.
- Split moving platforms, gates, detachable equipment, and effects from background decoration when their gameplay state or sorting must change independently.

## Preserve layer and state registration

When the design specifies independently scrolling layers, deliver separate source layers with alpha where needed. A combined backdrop is a fallback, not proof that far water and distant anatomy can scroll independently. Record layer role, parallax factor, full-canvas projection size, and a canvas-center pivot. Do not crop a parallax layer to its visible alpha bounds and then stretch it back to the declared camera width.

For state variants of the same body, retain a common pixel scale and root point. Removing a shell, opening a gate, or exposing a surface must not enlarge the remaining body to fill the old visible bounds. Record any registration drift and validate overlaid states; static switches do not prove animation continuity. Independently moving handles, doors, sockets, and overlays need attachment coordinates and deterministic composition recipes.

Map every required state to either a concrete image or a documented composition of images and simple runtime operations. Reusing a base with a rotation, fill mask, or opacity change is legitimate; silently treating a required component as implemented because its family has one file is not. Keep motion timing and playable interaction separate from static coverage.

## Validate at a measurable scale

Translate the game's stated units or camera height into a preview scale before placement. For example, if a 0.30 m hero is viewed in a 6 m-high camera, the hero should occupy about 5% of the viewport height; a large character turntable is not a scale reference for that scene.

Record pixels per game unit, intended object size, and pivot/contact point. Compare the visible sprite bounds rather than transparent canvas size. Use the same scale for related assets instead of fitting each image independently to a gallery tile.

Composite the actual PNGs without generative repair, then apply [qa.md](qa.md). Check silhouette readability, asymmetric attachment side, contact alignment, and interaction cues at the intended zoom. If the design has no measured camera or unit convention, label the chosen scale provisional; do not claim collision or playability validation from a concept painting.
