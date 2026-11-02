// Node 20+. Real keys in an isolated browser; snapshots are read-only observations.
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'crab-prototype');
mkdirSync(output, { recursive: true });
const fallback = process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const executablePath = existsSync(chromium.executablePath()) ? chromium.executablePath() : fallback;
const browser = await chromium.launch({ executablePath, headless: process.env.HEADED !== '1', args: ['--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
const context = await browser.newContext({ viewport: { width: 1280, height: 720 },
  ...(process.env.RECORD_VIDEO === '1' ? {recordVideo: {dir: output, size: {width: 1280, height: 720}}} : {}) });
const page = await context.newPage();
page.setDefaultTimeout(120000);
const url = process.env.GAME_URL ?? 'http://127.0.0.1:4191/BOB/godot/?prototype=crab';
const errors = [], held = new Set(), shots = new Set(), trace = [], checks = [], damage = [];
const comboPhases = new Set(), shieldEvents = [], effectClips = new Set(), effectEvidence = [];
const verifyEffects = process.env.VERIFY_EFFECTS === '1';
const pressureOnly = process.env.PRESSURE_ONLY === '1';
let completeState, rangedState, pressureState, deathState, retryState, dashState;
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
page.on('requestfailed', request => errors.push(`${request.failure()?.errorText} ${request.url()}`));
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const capture = name => page.screenshot({ path: path.join(output, `${name}.png`) });
const waitStage = stage => page.waitForFunction(expected => JSON.parse(window.render_game_to_text()).stage === expected, stage);
async function key(name, pressed) {
  if (held.has(name) === pressed) return;
  if (pressed) { held.add(name); await page.keyboard.down(name); }
  else { held.delete(name); await page.keyboard.up(name); }
}
async function release() { for (const name of [...held]) await key(name, false); }
async function ready() {
  await page.waitForFunction(() => typeof window.render_game_to_text === 'function', null, { timeout: 120000 });
  await waitStage('ready');
  await page.locator('canvas').click({ position: { x: 600, y: 450 } });
  const s = await state();
  assert.equal(s.room, 'prototype.crab');
  assert.equal(s.save_enabled, false, 'training disables campaign autosave');
  assert.deepEqual(s.flags, [], 'training does not award campaign flags');
  assert.equal(s.max_hp, 6, 'training has six health');
  assert.equal(s.skills.shield, 1, 'new session begins with one guard');
  return s;
}
async function begin() {
  await page.keyboard.press('Enter');
  await waitStage('fighting');
}
function observe(s) {
  trace.push(s);
  if (trace.length > 240) trace.shift();
  assert.equal(s.save_enabled, false, 'autosave remains disabled during training');
  assert.deepEqual(s.flags, [], 'no campaign progress is granted');
  if (['tell', 'active'].includes(s.boss.state)) {
    assert(s.boss.combo_index >= 1 && s.boss.combo_index <= s.boss.combo_total, 'combo counter matches current attack');
    if (s.boss.combo_total > 1) comboPhases.add(s.boss.phase);
  }
  if (['phase', 'stagger'].includes(s.boss.state)) assert.equal(s.boss.active, false, 'transition and stagger have no damage');
}

async function observeEffects(s) {
  if (!verifyEffects) return;
  const p = s.player.animation.effects, b = s.boss.effects;
  for (const fx of [p.trail, p.impact, b.contact, ...b.wakes, b.resonance, b.received]) {
    if (!fx.visible) continue;
    assert(fx.file.startsWith('res://art/fx/combo-v1/'), 'new artwork is really loaded');
    assert(fx.alpha <= 0.851, 'effects keep their opacity budget');
    if (!effectClips.has(fx.id)) {
      effectClips.add(fx.id); effectEvidence.push({id: fx.id, state: s});
      await capture(`fx-${fx.id}`);
    }
  }
  if (s.boss.state === 'phase' && !shots.has(`transition-${s.boss.next_phase}`)) {
    shots.add(`transition-${s.boss.next_phase}`); await capture(`transition-${s.boss.next_phase}`);
  }
  if (s.boss.state === 'tell') {
    assert(!b.contact.visible && b.wakes.length === 0, 'previous attack dust never covers a new tell');
  }
}

async function fightWithoutDash() {
  const began = Date.now();
  let lastTap = 0, jumpUntil = 0, lastHp = 6, regenerated = false, reblocked = false, guardHp;
  while (Date.now() - began < 180000) {
    const s = await state(), p = s.player, b = s.boss;
    observe(s);
    await observeEffects(s);
    if (b.animation === '10_walk' && b.frame >= 2 && !shots.has('walking')) {
      shots.add('walking'); await capture('walking');
    }
    if (s.hp !== lastHp) { damage.push({ time: s.time, from: lastHp, to: s.hp, boss: b.kind, state: b.state }); lastHp = s.hp; }
    if (s.stage === 'won') {
      assert(regenerated && reblocked, 'melee replenishes a consumed guard and the new guard blocks another hit');
      return s;
    }
    assert.notEqual(s.stage, 'lost', 'no-dash combat route must survive');
    if (b.phase > 1 && !shots.has(`phase-${b.phase}`)) { shots.add(`phase-${b.phase}`); await capture(`phase-${b.phase}`); }
    if (b.state === 'stagger' && !shots.has('stagger')) { shots.add('stagger'); await capture('stagger'); }
    if (!regenerated && s.skills.blocks >= 1 && s.skills.shield === 1) {
      regenerated = true; guardHp = s.hp;
      shieldEvents.push({ event: 'melee_recharged', state: s });
      await capture('guard-recharged');
    }
    if (regenerated && !reblocked) {
      if (s.skills.blocks >= 2) {
        assert.equal(s.hp, guardHp, 'recharged guard absorbs the next attack without health loss');
        reblocked = true;
        shieldEvents.push({ event: 'recharged_guard_blocked', state: s });
        checks.push('melee_recharges_guard_and_blocks_next_hit');
      } else {
        await release();
        await page.waitForTimeout(20);
        continue;
      }
    }
    if (b.state === 'tell' && !shots.has(b.kind)) {
      shots.add(b.kind);
      await capture(`tell-${b.kind}`);
      console.log(`SAW ${b.kind} hp=${s.hp} boss=${b.hp}`);
    }
    if (b.state === 'active' && !shots.has(`active-${b.kind}`)) {
      shots.add(`active-${b.kind}`); await capture(`active-${b.kind}`);
      assert(b.frame >= (b.kind === 'charge' ? 7 : b.kind === 'slam' ? 5 : 4), 'damage uses contact poses');
    }
    const dx = b.x - p.x, distance = Math.abs(dx), toward = Math.sign(dx);
    let movement = 0, tap;
    const attackState = b.state === 'tell' || b.state === 'active';
    if (attackState) {
      // The mother crab is solid and far taller than the hero's jump. Jump
      // only over its low claw; retreat from the high slam and full shell.
      const bossFacesPlayer = Math.sign(p.x - b.x) === b.facing;
      const clearance = b.kind === 'slam' ? 320 : 370;
      if (['slam', 'charge'].includes(b.kind) && bossFacesPlayer && distance < clearance) movement = -toward;
      if (['sweep', 'second'].includes(b.kind) && b.state === 'tell' && p.floor && distance < 330
          && b.timer > (b.kind === 'second' ? 0.32 : 0.43) && Date.now() >= jumpUntil) {
        jumpUntil = Date.now() + 450;
      }
    } else if (['recover', 'phase', 'stagger'].includes(b.state)) {
      const longRecovery = b.state === 'stagger' || (['slam', 'charge'].includes(b.kind) && b.state === 'recover');
      if (longRecovery && b.timer < 0.18 && s.hp <= 2 && s.energy >= 2 && p.floor && p.mode === 'idle') {
        tap = 'f';
      } else if (p.mode !== 'heal') {
        if (distance > 195) movement = toward;
        else if (p.mode === 'idle' && p.facing !== toward) movement = toward;
        else if (distance <= 205 && p.facing === toward && (b.phase === 1 || comboPhases.has(b.phase))) {
          if (p.mode === 'idle') tap = longRecovery && b.timer < 0.65 && s.energy >= 2 ? 'k' : 'j';
          else if (p.mode === 'attack' && p.kind === 'short1' && p.elapsed >= 0.14) tap = 'j';
        }
      }
    } else {
      // Let the boss choose at melee distance, rather than damage it through
      // the whole observation phase. This records every advertised move.
      if (distance > 210) movement = toward;
    }
    await key('a', movement < 0);
    await key('d', movement > 0);
    await key('Space', Date.now() < jumpUntil);
    if (tap && Date.now() - lastTap > 90) { await page.keyboard.press(tap, { delay: 18 }); lastTap = Date.now(); }
    await page.waitForTimeout(20);
  }
  throw new Error('No-dash boss route exceeded three minutes');
}

async function checkSlamCounter() {
  await begin();
  await key('d', true);
  await page.waitForFunction(() => {
    const s = JSON.parse(window.render_game_to_text());
    return s.boss.counter_window && s.boss.timer < 0.87 && s.boss.x - s.player.x < 260;
  }, null, {timeout: 35000, polling: 'raf'});
  await key('d', false);
  await page.keyboard.press('k', {delay: 25});
  await capture('counter-tell');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.state === 'stagger', null, {timeout: 1800});
  const s = await state();
  assert.equal(s.energy, 2);
  assert.equal(s.boss.active, false);
  await capture('counter-landed');
  checks.push('timed_heavy_interrupts_slam_before_contact');
  await page.reload({waitUntil: 'domcontentloaded'});
  await ready();
}

async function checkReadableSweep() {
  await begin();
  await page.waitForFunction(() => {
    const s = JSON.parse(window.render_game_to_text());
    return s.boss.state === 'tell' && s.boss.kind === 'sweep' && s.boss.timer < 0.12;
  }, null, {timeout: 30000, polling: 'raf'});
  await key('d', true);
  await page.waitForFunction(() => {
    const s = JSON.parse(window.render_game_to_text());
    return s.boss.x - s.player.x <= 205;
  }, null, {timeout: 2000, polling: 'raf'});
  await key('d', false);
  await page.keyboard.press('j', {delay: 18});
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.feedback === 'shell');
  const chip = await state();
  assert.equal(chip.boss.damage, 2);
  assert.equal(chip.boss.combo_total, 1);
  await capture('shell-deflection');
  // Check the dodge on a fresh round: taking a screenshot after a greedy
  // anticipation hit must not consume the player's jump timing budget.
  await page.reload({waitUntil: 'domcontentloaded'});
  await ready();
  await begin();
  await page.waitForFunction(() => {
    const s = JSON.parse(window.render_game_to_text());
    return s.boss.state === 'tell' && s.boss.kind === 'sweep' && s.boss.timer >= 0.44;
  }, null, {timeout: 30000, polling: 'raf'});
  await key('Space', true);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.state === 'active');
  await capture('sweep-jump-contact');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.state === 'recover');
  await key('Space', false);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).player.floor);
  const landed = await state();
  assert.equal(landed.boss.braced, false);
  assert.equal(landed.hp, chip.hp, 'correct jump loses no health');
  assert.equal(landed.skills.blocks, chip.skills.blocks, 'correct jump consumes no guard');
  await key('d', true);
  await page.waitForFunction(() => {
    const s = JSON.parse(window.render_game_to_text());
    return s.boss.x - s.player.x <= 205;
  }, null, {timeout: 1000, polling: 'raf'});
  await key('d', false);
  await page.keyboard.press('j', {delay: 18});
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.feedback === 'exposed', null, {timeout: 1500});
  const reward = await state();
  assert.equal(reward.boss.damage, 10, 'landing counterattack deals full damage');
  assert.equal(reward.boss.state, 'recover', 'counterattack fits inside the advertised window');
  await capture('sweep-reward');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).time >= 6.1);
  assert.equal((await state()).help_visible, false, 'help folds during combat');
  await page.keyboard.press('h');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).help_visible);
  await page.keyboard.press('h');
  await page.waitForFunction(() => !JSON.parse(window.render_game_to_text()).help_visible);
  checks.push('shell_chip_jump_full_damage_recovery_and_help_toggle');
  await release();
  await page.reload({waitUntil: 'domcontentloaded'});
  await ready();
}

async function checkProjectilePause() {
  await key('u', true);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).skills.charge === 1);
  await page.waitForTimeout(320);
  assert.equal((await state()).skills.shots, 0, 'holding a full charge never auto-fires');
  await capture('full-charge');
  await key('u', false);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).skills.projectiles.length > 0);
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).paused === true);
  const paused = await state();
  assert(paused.skills.projectiles.length > 0, 'pause catches a projectile in flight');
  await page.waitForTimeout(400);
  const frozen = await state();
  assert.deepEqual(frozen.skills, paused.skills, 'pause freezes projectile position, cooldown, shots and hits');
  await capture('projectile-paused');
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).paused === false);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).skills.charged_hits === 1);
  const impact = await state();
  assert(Math.abs(impact.boss.effects.received.y - (impact.player.y - 32)) < 1, 'projectile impact stays at the shot height');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).skills.cooldown === 0);
  await page.keyboard.press('u', {delay: 35});
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).skills.hits === 2);
  const fired = await state();
  assert.equal(fired.energy, 4);
  assert.equal(fired.skills.charged_hits, 1, 'a short tap fires a separate quick shot');
  checks.push('hold_release_and_tap_with_projectile_pause');
}

async function fightRangedOnly() {
  const began = Date.now(), phases = new Set();
  let jumpUntil = 0;
  while (Date.now() - began < 180000) {
    const s = await state(), p = s.player, b = s.boss;
    observe(s);
    await observeEffects(s);
    phases.add(b.phase);
    assert.equal(s.energy, 4, 'ranged-only route never spends or needs energy');
    assert.equal(s.skills.shield_charge, 0, 'ranged hits do not charge the melee passive');
    assert.equal(b.stagger, 0, 'ranged hits do not accumulate melee stagger');
    assert.notEqual(s.stage, 'lost', 'ranged-only combat route must survive');
    if (s.stage === 'won') {
      assert.deepEqual([...phases].sort(), [1, 2, 3], 'ranged-only route sees all three phases');
      assert(s.skills.charged_hits > 2 && s.skills.hits > s.skills.charged_hits, 'both shot types land');
      return s;
    }
    // Stay on the left with room to jump. The corner-safe attack selection
    // must remain beatable with U and Space alone, including double sweeps.
    const lowTell = ['sweep', 'second'].includes(b.kind) && b.state === 'tell' && Math.abs(b.x - p.x) < 330;
    if (lowTell && p.floor && b.timer > (b.kind === 'second' ? 0.26 : 0.39) && Date.now() >= jumpUntil) {
      jumpUntil = Date.now() + 450;
    }
    await key('Space', Date.now() < jumpUntil);
    if (p.mode === 'idle' && s.skills.cooldown <= 0) await key('u', true);
    if (p.mode === 'aim' && s.skills.charge === 1 && !b.braced) await key('u', false);
    // A real hit can interrupt a charge. A fresh press is required to re-arm.
    if (p.mode === 'hurt') await key('u', false);
    await page.waitForTimeout(20);
  }
  throw new Error('Ranged-only boss route exceeded three minutes');
}

try {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  const initial = await ready();
  assert.equal(initial.dash_enabled, false);
  await capture('ready');
  if (!pressureOnly) {
  await checkReadableSweep();
  await checkSlamCounter();
  await begin();
  // Step clear of the left boundary so the charge has its required escape
  // space. At the spawn point that attack is correctly filtered out.
  await key('d', true);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).player.x >= 1000);
  await key('d', false);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.state === 'tell');
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).paused === true);
  const paused = await state();
  if (paused.boss.state === 'tell') shots.add(paused.boss.kind);
  await page.waitForTimeout(500);
  const frozen = await state();
  assert.equal(frozen.time, paused.time, 'pause freezes combat clock');
  assert.equal(frozen.boss.timer, paused.boss.timer, 'pause freezes attack timer');
  assert.equal(frozen.boss.frame, paused.boss.frame, 'pause freezes animation frame');
  assert.equal(frozen.player.x, paused.player.x, 'pause freezes player position');
  if (verifyEffects) assert.deepEqual(frozen.boss.effects, paused.boss.effects, 'pause freezes all boss effect clocks');
  await capture('paused');
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).paused === false);
  checks.push('pause_freezes_and_resumes');
  // Deliberately take the first attack, then verify the melee route can earn
  // another guard. This is real collision, with no health/state injection.
  await release();
  const blockDeadline = Date.now() + 30000;
  while ((await state()).skills.blocks < 1 && Date.now() < blockDeadline) {
    await observeEffects(await state());
    await page.waitForTimeout(15);
  }
  assert.equal((await state()).skills.blocks, 1, 'opening attack reaches the guard');
  const firstBlock = await state();
  assert.equal(firstBlock.hp, 6, 'opening guard absorbs the first hit');
  assert.equal(firstBlock.skills.shield, 0);
  shieldEvents.push({ event: 'opening_guard_blocked', state: firstBlock });
  completeState = await fightWithoutDash();
  await release();
  assert.equal(completeState.dash_enabled, false);
  for (const move of ['sweep', 'slam', 'charge', 'phase-2', 'phase-3', 'stagger']) assert(shots.has(move), `combat observes ${move}`);
  assert(comboPhases.has(2) && comboPhases.has(3), 'later phases visibly use multi-hit sequences');
  assert.equal(completeState.boss.hp, 0);
  if (verifyEffects) {
    await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.effects.resonance.visible);
    await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.effects.resonance.frame === 1);
    await observeEffects(await state());
    for (const id of ['short1', 'short2', 'heavy', 'hit', 'sweep', 'slam', 'charge', 'resonance']) assert(effectClips.has(id), `real keys show ${id}`);
  }
  await capture('victory');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.opacity === 0);
  await capture('retreated');
  checks.push('no_dash_melee_victory_three_phases_combos_and_stagger');

  await begin();
  await key('a', true);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).player.x <= 805);
  await key('a', false);
  await page.keyboard.press('d', { delay: 45 });
  await checkProjectilePause();
  rangedState = await fightRangedOnly();
  await release();
  await capture('ranged-victory');
  checks.push('ranged_only_victory_three_phases_without_energy');
  }

  await begin();
  await release();
  // Commit to melee and mash without reading tells or dodging.
  await key('d', true);
  await page.waitForFunction(() => {
    const s = JSON.parse(window.render_game_to_text());
    return s.boss.x - s.player.x < 195;
  });
  let sawReply = false;
  const until = Date.now() + 90000;
  while (Date.now() < until) {
    const s = await state();
    if (s.stage !== 'fighting') break;
    if (s.boss.phase === 1 && s.boss.kind === 'second') sawReply = true;
    await page.keyboard.press('j', {delay: 25});
    await page.waitForTimeout(70);
  }
  await key('d', false);
  assert(!sawReply, 'shell contacts never add a surprise phase-one return sweep');
  pressureState = await state();
  assert(['won', 'lost'].includes(pressureState.stage), 'pressure comparison reaches an outcome');
  // Fixed recovery replaces the old contact-dependent punishment. Record the
  // balance outcome honestly; death/retry remains a separate lifecycle check.
  if (pressureState.stage === 'won') {
    await begin();
    await release();
    await waitStage('lost');
  }
  deathState = await state();
  assert.equal(deathState.hp, 0);
  await capture('defeat');
  await begin();
  retryState = await state();
  assert.equal(retryState.hp, 6, 'retry restores six player health');
  assert.equal(retryState.boss.hp, retryState.boss.maximum, 'retry restores boss health');
  assert.equal(retryState.boss.phase, 1, 'retry clears second phase');
  assert.equal(retryState.boss.opacity, 1, 'retry restores visible body');
  assert.equal(retryState.player.dead, false);
  assert.equal(retryState.boss.stagger, 0, 'retry clears stagger accumulation');
  assert.equal(retryState.skills.shield, 1, 'retry restores opening guard');
  assert.equal(retryState.skills.shield_charge, 0, 'retry clears guard progress');
  for (const key of ['shots', 'hits', 'blocks', 'cooldown']) assert.equal(retryState.skills[key], 0, `retry resets ${key}`);
  assert.deepEqual(retryState.skills.projectiles, [], 'retry removes projectiles');
  if (verifyEffects) {
    assert.equal(retryState.player.animation.effects.hits, 0);
    assert(retryState.boss.effects.resonance.alpha < 0.4 || !retryState.boss.effects.resonance.visible, "retry clears the victory cue before the new opening");
    checks.push('authored_combo_effects_phase_victory_and_reset');
  }
  await capture('retry');
  checks.push('blind_melee_no_surprise_reply_and_retry');

  // A reload is an ordinary user action returning to the training menu;
  // it also verifies the independent prototype does not resume campaign data.
  await release();
  await page.reload({ waitUntil: 'domcontentloaded', timeout: 120000 });
  await ready();
  await page.mouse.click(1100, 90);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).dash_enabled === true);
  await begin();
  const beforeDash = await state();
  await key('Shift', true);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).player.mode === 'dash', null, { timeout: 3000, polling: 'raf' });
  dashState = await state();
  await capture('dash');
  await key('Shift', false);
  await page.waitForTimeout(300);
  const afterDash = await state();
  assert(Math.abs(afterDash.player.x - beforeDash.player.x) > 120, 'dash moves the player through real input');
  assert.equal(afterDash.save_enabled, false);
  assert.deepEqual(afterDash.flags, []);
  checks.push('reload_ready_and_dash_comparison');
  assert.deepEqual(errors, [], 'no resource, browser or engine errors');
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: true, url, checks, effectClips: [...effectClips], effectEvidence, shots: [...shots], comboPhases: [...comboPhases], damage, shieldEvents, completeState, rangedState, pressureState, deathState, retryState, dashState, errors }, null, 2));
  console.log(`PASS training route; ${output}`);
} catch (error) {
  await release().catch(() => {});
  await capture('failure').catch(() => {});
  const current = await state().catch(() => null);
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: false, url, checks, effectClips: [...effectClips], effectEvidence, shots: [...shots], comboPhases: [...comboPhases], damage, shieldEvents, completeState, rangedState, pressureState, current, errors, trace, error: error.stack }, null, 2));
  console.error(current, errors);
  throw error;
} finally {
  await release().catch(() => {});
  await context.close();
  await browser.close();
}
