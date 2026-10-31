import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, validateSave } from '../engine.js';
import { rooms } from '../levels.js';
import { getLiftPosition, getSwingPosition } from '../mechanics.js';

// Match the fixed simulation interval used by the browser, independent of RAF.
const DT = 1 / 120;
const course = rooms[3];

function harness() {
  const events = [];
  const game = new Game((type, message) => events.push({ type, message }));
  game.start();
  game.enter(3);
  return {
    game, events,
    // Durations use 60 Hz frame units to make the recorded route readable.
    frames(duration, input = {}) {
      for (let i = 0; i < Math.round(duration * 2); i++) game.step(DT, input);
    },
    until(predicate, input = {}, timeout = 12) {
      for (let i = 0; i < timeout / DT; i++) {
        if (predicate()) return;
        game.step(DT, input);
      }
      assert.fail(`Route timed out: ${JSON.stringify(game.state.player)}`);
    },
  };
}

function reachLift(h) {
  const { game } = h;
  h.frames(68, { right: true });
  h.frames(125, { up: true });
  assert(game.state.flags.has('course-climb'), 'the net must be climbed');
  assert.equal(game.state.player.y, 332, 'climbing reaches the first deck');
  h.frames(42, { right: true });
  h.frames(1, { interact: true });
  assert(game.state.flags.has('course-powered'));
  h.frames(17, { right: true });
  h.frames(35, { right: true, jump: true });
  h.until(() => game.state.player.riding === course.lifts[0].id);
}

function reachRing(h) {
  reachLift(h);
  const { game } = h;
  h.until(() => game.state.flags.has('course-lift') && game.state.player.y < 150);
  h.frames(73, { right: true, jump: true });
  h.frames(30);
  assert.equal(game.state.player.y, 152, 'lift jump reaches the high deck');
  assert.deepEqual(game.state.checkpoint, { room: 3, x: 1100, y: 152 });
  h.frames(40, { right: true });
  h.until(() => game.nearRing(course.swings[0]));
  h.frames(1, { interact: true });
  assert.equal(game.state.player.swinging, course.swings[0].id);
}

function reachLanding(h) {
  reachRing(h);
  const { game } = h;
  h.frames(45);
  h.until(() => {
    const ring = getSwingPosition(course.swings[0], game.state.time);
    return ring.vx >= 180 && ring.x >= 1500;
  });
  assert(game.state.flags.has('course-swing'));
  h.frames(0.5, { right: true, jump: true });
  assert.equal(game.state.player.swinging, null, 'Space releases the ring');
  assert(game.state.player.vx > 240, 'the jump retains the ring horizontal momentum');
  assert(game.state.player.vy < 0, 'the jump launches upward');
  h.frames(44.5, { right: true, jump: true });
  h.frames(30);
  assert.equal(game.state.player.y, 302, 'the swing jump reaches the far landing');
  assert(game.state.player.x > 1710 && game.state.player.x < 1990);
  assert.deepEqual(game.state.checkpoint, { room: 3, x: 1770, y: 302 });
}

test('the whole course is reachable using only controls at the browser 120 Hz timestep', () => {
  const h = harness();
  const { game } = h;
  reachLanding(h);
  h.frames(15, { right: true });
  h.frames(45, { right: true, jump: true });
  h.frames(20);
  h.frames(15, { right: true });
  h.frames(38, { right: true, jump: true });
  h.frames(20);
  h.frames(1, { interact: true });
  assert(game.state.flags.has('course-clear'), 'all facilities and endpoint lever open the course');
  h.frames(20, { right: true });
  h.frames(1, { interact: true });
  assert.equal(game.state.room, 2, 'the course forward exit enters the original lung room');
  assert.equal(game.state.deaths, 0, 'successful traversal needs no recovery or teleports');
});

test('a passenger stays on the lift through multiple complete ascending and descending cycles', () => {
  const h = harness();
  reachLift(h);
  const { game } = h;
  let highest = Infinity, lowest = -Infinity;
  for (let i = 0; i < 30 / DT; i++) {
    game.step(DT);
    const lift = getLiftPosition(course.lifts[0], game.state.time, game.state.flags);
    assert.equal(game.state.player.riding, course.lifts[0].id);
    assert(Math.abs(game.state.player.y + game.state.player.h - lift.y) < 0.001);
    highest = Math.min(highest, game.state.player.y);
    lowest = Math.max(lowest, game.state.player.y);
  }
  assert(lowest - highest > 290, 'the passenger travels the full vertical route');
});

test('pausing on a lift or bone ring freezes simulation and resumes without displacement', () => {
  for (const setup of [reachLift, reachRing]) {
    const h = harness();
    setup(h);
    const { game } = h;
    game.state.mode = 'paused';
    const clock = game.state.time, player = { ...game.state.player };
    h.frames(180);
    assert.equal(game.state.time, clock);
    assert.deepEqual(game.state.player, player);
    game.state.mode = 'playing';
    game.step(DT);
    assert(Math.abs(game.state.player.x - player.x) < 5);
    assert(Math.abs(game.state.player.y - player.y) < 5);
  }
});

test('falling onto the safety net supports recovery and saves earned course checkpoints', () => {
  const h = harness();
  reachLanding(h);
  const { game } = h;
  const saved = game.serialize();
  assert(validateSave(saved));
  const resumed = new Game();
  resumed.start(JSON.parse(JSON.stringify(saved)));
  assert.equal(resumed.state.room, 3);
  assert.deepEqual(resumed.state.checkpoint, game.state.checkpoint);
  assert.equal(resumed.state.player.x, 1770);
  assert.equal(resumed.state.player.y, 302);
  assert.deepEqual(resumed.state.course, { climb: true, lift: true, swing: true, clear: false });
  h.frames(70, { left: true });
  h.until(() => game.state.player.grounded && game.state.player.y > 590);
  assert.equal(game.state.deaths, 0, 'the catch net prevents lethal falls');
  h.frames(1, { interact: true });
  assert.equal(game.state.player.x, 1770);
  assert.equal(game.state.player.y, 302);
  assert(game.state.flags.has('course-swing'), 'retry keeps completed facilities');
  assert.equal(game.state.player.swinging, null);
  assert.equal(game.state.player.riding, null);
});

test('walking below the course or reaching its lever without all three facilities cannot unlock it', () => {
  const h = harness();
  h.frames(520, { right: true });
  h.frames(1, { interact: true });
  assert.equal(h.game.state.room, 3);
  assert(!h.game.state.flags.has('course-clear'));
  for (const missing of ['climb', 'lift', 'swing']) {
    const { game } = harness();
    // Set up each incomplete progress combination at the endpoint, then exercise F.
    for (const stage of ['climb', 'lift', 'swing']) if (stage !== missing) game.state.flags.add(`course-${stage}`);
    Object.assign(game.state.player, { x: 2220, y: 222, grounded: true });
    game.step(DT, { interact: true });
    assert(!game.state.flags.has('course-clear'), `missing ${missing} must block the lever`);
  }
});

test('original V2 room indices and checkpoint saves load without losing progress', () => {
  for (const checkpoint of [
    { room: 0, x: 850, y: 252 },
    { room: 1, x: 2180, y: 532 },
    { room: 2, x: 245, y: 532 },
  ]) {
    const old = {
      version: 2, room: checkpoint.room, checkpoint,
      flags: ['short-gate', 'long-gate', 'food', 'fed', 'drain', 'float'],
      abilities: ['float'], memories: ['song', 'drift'], visited: [0, 1, 2], elapsed: 123, deaths: 2,
    };
    assert(validateSave(old));
    const game = new Game();
    game.start(old);
    assert.equal(game.state.room, checkpoint.room);
    assert.deepEqual(game.state.checkpoint, checkpoint);
    assert(game.state.abilities.has('float'));
    assert(game.state.memories.has('drift'));
    assert.equal(game.state.elapsed, 123);
    assert.equal(game.state.deaths, 2);
    assert.equal(game.state.course.clear, false);
    assert.equal(validateSave({ ...old, checkpoint: { ...checkpoint, x: 999999 } }), null);
  }
});
