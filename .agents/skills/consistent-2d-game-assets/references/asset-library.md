# Project asset libraries

Read this when the requested delivery includes a catalog or a page for viewing and managing art. Extend the project's existing manifest and conventions; a new database or service is not necessary for a read-only gallery.

## Keep identity and evidence connected

- Use stable asset IDs for requirements, states, composition recipes, exports, and engine references. Display names and filenames alone are fragile join keys.
- Keep the complete requirements inventory distinct from the delivered catalog. Show unfulfilled requirements even when there is no image, and derive coverage from resolved output IDs and required states. Count unique source assets separately from thumbnails, previews, and atlas copies.
- Preserve source roles: approved visual reference, generated redraw, deterministic extraction, or function-derived adaptation. Record inferred shapes as adaptations instead of claiming that the concept art explicitly contained them.
- Keep originals and editable sources separate from thumbnails, composition previews, and packed exports. Use thumbnails for the grid; use original pixels for transparency, detail review, and download.
- Link to the project's own copies of references and prompt/source files. Report broken IDs, paths, duplicate IDs, and stale exports rather than silently hiding affected entries.

## Make compositions reproducible

Resolve recipe components through the delivered catalog. Record the common world scale, original canvas and pivot, attachment/socket coordinates, draw order, and per-state transforms or masks needed to reproduce the preview. A rotating handle's mechanical axis is not necessarily its visible bounding-box center.

Use a fixed camera and registration when comparing states. Include empty sockets, removed rewards, open passages, and ecological before/after states when the design requires them. Check a passage's visible clear width and alpha at the intended opening; this is visual clearance, not proof that a collision body can pass. A rule describing a state without its required image or composition does not complete that state.

After import, rebuild the relevant previews from the final paths and IDs. Compare the rendered results or recorded measurements to the approved previews. An independent check should read the actual files and recipes, not simply echo a packer's success flag. Retain input revision/hash information so old evidence cannot masquerade as a check of changed assets.

## Separate review from editing

Make technical/visual review, user art approval, and game integration distinguishable in the UI and stored data. Do not infer user approval from a successful import or an agent's visual inspection.

For an editable manager, choose the smallest persistence mechanism appropriate to the requested use. A download-only viewer need not gain a backend. If edits are meant to update the project catalog, writing only to browser storage is insufficient: save to the designated source of truth, report failure, and confirm persistence after reload.

Keep draft edits while switching assets or failing a save, with an explicit discard route. Distinguish in-memory preservation from recovery after reload; describe and test the implemented behavior without claiming the draft was saved. Use a revision or equivalent conflict check when concurrent edits can overwrite each other. Archive/restore is useful when removal is requested without deleting source files; decide explicitly whether archived assets remain eligible for runtime exports and coverage. Archiving an entry must not silently rewrite the game's references.

## Verify the requested management behavior

Choose three to five relevant cases and run mutations against a temporary catalog copy:

1. Search/filter an existing asset and a missing requirement; open the correct original, source reference, and atlas page.
2. Edit metadata, save, reload, and verify the stored values and stable ID.
3. Switch selection with an unsaved draft; exercise the intended preserve/discard behavior.
4. Simulate a stale revision or failed save; verify that neither stored data nor the user's draft is silently lost.
5. Archive and restore an entry, then check the stated coverage/export policy and affected links.

Inspect the actual browser layout and loaded images at the requested screen sizes. Server tests and a populated JSON file do not establish that the user can view, edit, or download the assets.
