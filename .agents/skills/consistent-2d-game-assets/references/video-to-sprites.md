# Video reference to playable sprites

Use this with `sprite-animation.md` when a user supplies a video and wants its motion or overall gameplay appearance. The video is a composition and timing reference, not only a source of isolated characters.

## Inspect and preserve

Keep the source URL, duration, dimensions and FPS, representative scene frames, action ranges, and frame timestamps. Separate body, detached shells/projectiles, impact dust, and environment. Record the selected source-frame mapping; sampling at 12 FPS does not restore missing frames in a 24 FPS source.

Before batching, inspect an idle, an extreme extended pose and a contact pose. Test segmentation on all three. Background-colored holes, missing claw tips and attached terrain need repair; increasing frame count will not fix them. Preserve an unedited extraction alongside repaired candidates.

## Repair without inventing fidelity

Use the available image-generation skill for painting, with accepted character and original video poses as references. Ask for fixed camera, limb identity/count, shell silhouette, complete extremities and real alpha. Repair one diagnosed problem per iteration. Model output is a reference-guided redraw, not restoration of the original pixels.

Reject cells with extra or missing limbs. If reusing an intact pose, store that selection explicitly and report the number of playback frames separately from unique poses. Avoid repeating the loop endpoint unless a deliberate hold is needed. Do not call duplicated poses or crossfades interpolation. Optical-flow candidates require silhouette and attachment checks before use.

## Extract and register

Generated grids may have uneven spacing. Locate transparent gaps near nominal boundaries, inspect every extracted cell, then repack into a true regular atlas. Preserve soft alpha; do not threshold away fine limbs or particles to make a detector pass.

Use a shared scale and body root. Record a ground contact point separate from the image bounds; extended claws, lifted legs and jump height must not shift the ground anchor. Explicit per-pose root corrections are preferable to normalizing every bounding box. Keep dust, balls and falling shells in separate atlases. Fade-out is runtime opacity; avoid baking the source scenery into translucent body pixels.

For exact lossless packing, raw RGBA row copies avoid alpha-premultiplication rounding introduced by some compositors. Verify that cropping each packed cell reproduces the exported frame, that alpha exists, and that the visible silhouette has padding. These checks do not establish good motion.

When different actions snap from side view to front view, repair the camera mismatch before adding transition frames. Use one approved neutral pose as the camera/identity master, and include the earlier action only as motion intent. For rigid shell or armor, template matching a stable detail can suggest horizontal root offsets; retain the match scores and visually inspect low-confidence results. Use one scale per action, not per-frame size normalization. If neighboring sprites overlap their rectangular crop bounds or a limb reaches the canvas edge, regenerate wider padding before export rather than hiding the defect with a tight crop.

## Reproduce the scene in engine

Compare hero height, boss height/width, ground screen height, camera framing, warm/cool balance and effect scale with the video. A clean environment plate must remove baked actors/projectiles and retain a readable collision surface. Save its actual prompt and reference; it is a new asset, not an exact reconstructed scene.

Drive attacks by anticipation/contact/recovery ranges tied to the combat timer, rather than looping the full sheet independently of the hitbox. Put dust at the actual world-space impact and keep it there when the boss moves. Lock facing according to gameplay. Freeze body and effect clocks during pause/hitstop; clear them on retry. Play death once and apply opacity explicitly.

Inspect in-engine idle, largest attack, both facings, approach, recovery, death, pause and retry. Check actual transparent edges, grounding, body collision and the visible reach against the damage region. Preserve source-to-runtime scaling metadata. A successful keyboard bot proves reachability and input, not that a human can read the drawings.

Choose runtime resolution by actual on-screen pixels. Downsampling a low-detail generated pose and then enlarging it in the engine compounds blur; keep the accepted resolution where this happens and reduce download size through the engine's texture compression instead. Compare actual engine screenshots before accepting a smaller atlas.

## Deliver and state limits

Keep source references, prompts, original selected atlases, frame/anchor maps and a reproducible runtime export. Ship only the runtime resolutions/actions actually loaded. Record local and deployed evidence separately, and list remaining texture/volume/viewpoint drift. Distinguish all authored actions from the subset implemented as damaging moves. Do not label a playable integration a frame-identical recreation of the video.
