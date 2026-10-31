---
name: "develop-web-game"
description: "仅用于 BOB legacy/web/ 历史 Canvas 2D 与 Three.js 原型的参考和回归；Godot 正式工程使用 godot-game-dev。"
---


> Godot 正式工程请使用 [godot-game-dev](../godot-game-dev/SKILL.md)。以下 Web 专项流程仅供 `legacy/web/` 历史原型参考与回归，不能用于继续开发旧版本；共享素材制作仍可参考美术规则。

# BOB Web 游戏开发

Build games in small steps and validate every change. Treat each iteration as: implement → act → pause → observe → adjust.

## BOB task routing

1. Read [the collaboration rules](../../../AGENTS.md), then determine whether the change affects `mvp/`, `mvp-nightmare/`, or the shared `mvp/deploy.mjs` release path.
2. Read only the affected version's README, `progress.md`, implementation files, and related tests. Preserve unrelated dirty changes.
3. Use the version's existing checks and playthrough scripts first. Read [BOB desktop verification](../bob-desktop-verification/SKILL.md) for exact commands, dependency limits, save isolation, and release-path checks.
4. Use the bundled generic Playwright client only for a focused interaction that the project scripts do not cover. Do not replace an existing project regression script without a concrete need.
5. Record the distinction between implemented runtime capability, authored content, and actual in-game integration. Concept art and design plans are not evidence that a mechanic or asset is implemented.

## Skill paths (set once)

Run from the repository root:

```bash
export BOB_REPO="$(git rev-parse --show-toplevel)"
export WEB_GAME_CLIENT="$BOB_REPO/.agents/skills/develop-web-game/scripts/web_game_playwright_client.js"
export WEB_GAME_ACTIONS="$BOB_REPO/.agents/skills/develop-web-game/references/action_payloads.json"
```

## Workflow

1. **Pick a goal.** Define a single feature or behavior to implement.
2. **Implement small.** Make the smallest change that moves the game forward.
3. **Ensure integration points.** Provide a single canvas and `window.render_game_to_text` so the test loop can read state.
4. **Add `window.advanceTime(ms)`.** Strongly prefer a deterministic step hook so the Playwright script can advance frames reliably; without it, automated tests can be flaky.
5. **Read the affected version's progress.** Preserve its existing structure and append concise implementation and verification evidence only when the project rules call for it; do not create a competing root progress file.
6. **Verify Playwright availability.** Ensure `playwright` is available (local dependency or global install). If unsure, check `npx` first.
7. **Run the relevant browser test.** Prefer the affected version's existing playthrough or recovery script. Use `$WEB_GAME_CLIENT` for focused gaps; do not invent another client unless required.
8. **Use the payload reference.** Base actions on `$WEB_GAME_ACTIONS` to avoid guessing keys.
9. **Inspect state.** Capture screenshots and text state after each burst.
10. **Inspect screenshots.** Open the latest screenshot, verify expected visuals, fix any issues, and rerun the script. Repeat until correct.
11. **Verify controls and state (multi-step focus).** Exhaustively exercise all important interactions. For each, think through the full multi-step sequence it implies (cause → intermediate states → outcome) and verify the entire chain works end-to-end. Confirm `render_game_to_text` reflects the same state shown on screen. If anything is off, fix and rerun.
    Examples of important interactions: move, jump, shoot/attack, interact/use, select/confirm/cancel in menus, pause/resume, restart, and any special abilities or puzzle actions defined by the request. Multi-step examples: shooting an enemy should reduce its health; when health reaches 0 it should disappear and update the score; collecting a key should unlock a door and allow level progression.
12. **Check errors.** Review console errors and fix the first new issue before continuing.
13. **Reset between scenarios.** Avoid cross-test state when validating distinct features.
14. **Iterate with small deltas.** Change one variable at a time (frames, inputs, timing, positions), then repeat steps 7–13 until stable.

Supplemental example for the initial version on its default port (actions required):
```
node "$WEB_GAME_CLIENT" --url http://127.0.0.1:4173 --actions-file "$WEB_GAME_ACTIONS" --click-selector "#start-btn" --iterations 3 --pause-ms 250
```

Example actions (inline JSON):
```json
{
  "steps": [
    { "buttons": ["left_mouse_button"], "frames": 2, "mouse_x": 120, "mouse_y": 80 },
    { "buttons": [], "frames": 6 },
    { "buttons": ["right"], "frames": 8 },
    { "buttons": ["space"], "frames": 4 }
  ]
}
```

## Test Checklist

Test any new features added for the request and any areas your logic changes could affect. Identify issues, fix them, and re-run the tests to confirm they’re resolved.

Examples of things to test:
- Primary movement/interaction inputs (e.g., move, jump, shoot, confirm/select).
- Win/lose or success/fail transitions.
- Score/health/resource changes.
- Boundary conditions (collisions, walls, screen edges).
- Menu/pause/start flow if present.
- Any special actions tied to the request (powerups, combos, abilities, puzzles, timers).

## Test Artifacts to Review

- Latest screenshots from the Playwright run.
- Latest `render_game_to_text` JSON output.
- Console error logs (fix the first new error before continuing).
You must actually open and visually inspect the latest screenshots after running the Playwright script, not just generate them. Ensure everything that should be visible on screen is actually visible. Go beyond the start screen and capture gameplay screenshots that cover all newly added features. Treat the screenshots as the source of truth; if something is missing, it is missing in the build. If you suspect a headless/WebGL capture issue, rerun the Playwright script in headed mode and re-check. Fix and rerun in a tight loop until the screenshots and text state look correct. Once fixes are verified, re-test all important interactions and controls, confirm they work, and ensure your changes did not introduce regressions. If they did, fix them and rerun everything in a loop until interactions, text state, and controls all work as expected. Be exhaustive in testing controls; broken games are not acceptable.

## Existing test hooks

Both BOB versions already expose the following hooks. Preserve and extend them when a new mechanic adds player-relevant state; do not create duplicate hooks.

### Text State Output (render_game_to_text)
Expose a `window.render_game_to_text` function that returns a concise JSON string representing the current game state. The text should include enough information to play the game without visuals.

Minimal pattern:
```js
function renderGameToText() {
  const payload = {
    mode: state.mode,
    player: { x: state.player.x, y: state.player.y, r: state.player.r },
    entities: state.entities.map((e) => ({ x: e.x, y: e.y, r: e.r })),
    score: state.score,
  };
  return JSON.stringify(payload);
}
window.render_game_to_text = renderGameToText;
```

Keep the payload succinct and biased toward on-screen/interactive elements. Prefer current, visible entities over full history.
Include a clear coordinate system note (origin and axis directions), and encode all player-relevant state: player position/velocity, active obstacles/enemies, collectibles, timers/cooldowns, score, and any mode/state flags needed to make correct decisions. Avoid large histories; only include what's currently relevant and visible.

### Time Stepping Hook
Provide a deterministic time-stepping hook so the Playwright client can advance the game in controlled increments. Expose `window.advanceTime(ms)` (or a thin wrapper that forwards to your game update loop) and have the game loop use it when present.
The Playwright test script uses this hook to step frames deterministically during automated testing.

Minimal pattern:
```js
window.advanceTime = (ms) => {
  const steps = Math.max(1, Math.round(ms / (1000 / 60)));
  for (let i = 0; i < steps; i++) update(1 / 60);
  render();
};
```

## Progress Tracking

Use `mvp/progress.md` or `mvp-nightmare/progress.md` according to the affected version. Record the command, environment, covered behavior, evidence location, and remaining TODOs. Do not treat an old report as proof of the current build.

## Playwright Prerequisites

Prefer the dependencies and import routes already documented by [BOB desktop verification](../bob-desktop-verification/SKILL.md). The bundled client tries `PLAYWRIGHT_MODULE`, then a project-resolvable `playwright`, then Codex's standard bundled copy. If all are unavailable, report the exact missing dependency before changing package manifests or installing global tools.

## Scripts

- `$WEB_GAME_CLIENT` — project-local Playwright action loop with virtual-time stepping, screenshot capture, and console error buffering. Pass an action burst via `--actions-file`, `--actions-json`, or `--click`.

## References

- `$WEB_GAME_ACTIONS` — project-local keyboard and mouse action examples for focused test bursts.
