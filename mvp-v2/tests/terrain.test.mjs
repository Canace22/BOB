import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, validateSave } from '../engine.js';
import { rooms } from '../levels.js';
import { terrainHeightAt } from '../terrain.js';

const DT = 1 / 120;
const profile = (points, extra = {}) => ({ id: 'test-ground', kind: 'tissue', points: points.map(([x, y]) => ({ x, y })), bottom: 740, ...extra });

function harness(t, terrain, platforms = []) {
  const original = rooms[0];
  rooms[0] = { ...original, terrain, platforms, gates: [], objects: [], memories: [], exits: [], hazards: [] };
  t.after(() => { rooms[0] = original; });
  const game = new Game(); game.start();
  const place = (x, foot, grounded = true, vy = 0) => Object.assign(game.state.player, { x: x - 15, y: foot - 48, grounded, vx: 0, vy: vy });
  const frames = (count, input = {}) => { for (let i = 0; i < count; i++) game.step(DT, input); };
  return { game, place, frames, player: game.state.player };
}

test('walking follows uphill and downhill terrain in both directions without losing ground contact', t => {
  const surface = profile([[0, 580], [200, 580], [400, 480], [600, 580], [800, 580]]);
  const { game, place, player } = harness(t, [surface]); place(160, 580);
  for (const input of [{ right: true }, { left: true }]) for (let i = 0; i < 240; i++) {
    game.step(DT, input);
    assert(player.grounded);
    assert(Math.abs(player.y + player.h - terrainHeightAt(surface, player.x + 15)) < 0.001);
  }
});

test('a slope connects to a rectangular deck and back without airborne snapping', t => {
  const { game, place, player } = harness(t, [profile([[200, 580], [400, 500]])],
    [{ x: 0, y: 580, w: 200, h: 160 }, { x: 400, y: 500, w: 300, h: 30 }]);
  place(150, 580);
  for (const input of [{ right: true }, { left: true }]) for (let i = 0; i < 150; i++) {
    game.step(DT, input);
    assert(player.grounded);
  }
  assert(Math.abs(player.y + player.h - 580) < 0.001);
});

test('jumping leaves terrain, falls onto it, and does not stick while passing upward from below', t => {
  const { place, frames, player } = harness(t, [profile([[0, 580], [200, 580], [600, 480]])]);
  place(280, 560); frames(1, { jump: true });
  assert(!player.grounded); assert(player.vy < 0);
  frames(125);
  assert(player.grounded); assert.equal(player.y + player.h, 560);
  place(280, 620, false, -460); frames(12);
  assert(!player.grounded); assert(player.vy < 0);
  frames(120);
  assert(player.grounded); assert.equal(player.y + player.h, 560);
});

test('walking off an edge or across a small gap falls rather than snapping onto a distant slope', t => {
  const { place, frames, player } = harness(t, [profile([[0, 580], [200, 580]]), profile([[201, 600], [500, 620]])]);
  place(199, 580); frames(1, { right: true });
  assert(!player.grounded);
  assert(player.y + player.h < 600, 'gap breaks following even when crossed in one simulation step');
  frames(40, { right: true }); assert(player.grounded, 'gravity can land on the lower slope later');
  place(499, terrainHeightAt(rooms[0].terrain[1], 499)); frames(2, { right: true });
  assert(!player.grounded); assert(player.vy > 0);
});

test('locked terrain is absent; unlocking below its surface cannot teleport the player up', t => {
  const { game, place, frames, player } = harness(t, [profile([[0, 580], [800, 580]], { requires: 'drain' })]);
  place(150, 580); frames(3); assert(!player.grounded);
  place(150, 620, false, 60); game.state.flags.add('drain'); frames(1);
  assert(!player.grounded); assert(player.y + player.h > 620);
  place(150, 550, false); frames(40);
  assert(player.grounded); assert.equal(player.y + player.h, 580);
  game.state.flags.delete('drain'); frames(1); assert(!player.grounded);
});

test('terrain adds no stored state and existing V2 checkpoints retain their original save format', () => {
  const game = new Game(); game.start();
  const old = game.serialize(); delete old.habitats;
  old.flags.push('short-gate', 'long-gate'); old.memories.push('song');
  assert(validateSave(old));
  const resumed = new Game(); resumed.start(JSON.parse(JSON.stringify(old)));
  assert.deepEqual(resumed.state.checkpoint, old.checkpoint);
  assert(resumed.state.flags.has('long-gate'));
  assert(resumed.state.memories.has('song'));
  assert.equal(resumed.serialize().version, 2);
  assert(!Object.hasOwn(resumed.serialize(), 'terrain'));
});

test('every actual room spawn, camp, course checkpoint and inbound exit remains safe after loading', () => {
  for (let index = 0; index < rooms.length; index++) {
    const room = rooms[index];
    const anchors = [
      { name: 'spawn', ...room.spawn },
      ...(room.checkpoints || []).map(point => ({ name: 'course checkpoint', ...point })),
      ...room.objects.filter(object => object.type === 'camp').map(object => ({ name: object.id, x: object.x - 15, y: object.y - 48 })),
      ...rooms.flatMap(from => from.exits.filter(exit => exit.to === index && exit.spawn)
        .map(exit => ({ name: `entry from ${from.id}`, ...exit.spawn }))),
    ];
    for (const anchor of anchors) {
      const label = `${room.id}: ${anchor.name} (${anchor.x}, ${anchor.y})`;
      const game = new Game(); game.start();
      game.state.flags.add('fed'); game.state.flags.add('drain');
      game.enter(index, { x: anchor.x, y: anchor.y });
      const save = game.serialize(); assert(validateSave(save), label);
      const resumed = new Game(); resumed.start(JSON.parse(JSON.stringify(save)));
      for (let i = 0; i < 360; i++) resumed.step(DT);
      assert.equal(resumed.state.deaths, 0, label);
      assert(resumed.state.player.grounded, label);
      assert(Math.abs(resumed.state.player.y - anchor.y) < 0.001, label);
      assert.equal(resumed.state.player.x, anchor.x, label);
    }
  }
});

test('legacy stomach return save resumes above the reshaped bank instead of falling through it', () => {
  const old = {
    version: 2, room: 1, checkpoint: { room: 1, x: 2180, y: 532 },
    flags: ['short-gate', 'long-gate', 'food', 'fed', 'drain'],
    abilities: [], memories: ['song', 'drift'], visited: [0, 1, 3], elapsed: 123, deaths: 2,
  };
  assert(validateSave(old));
  const game = new Game(); game.start(old);
  for (let i = 0; i < 600; i++) game.step(DT);
  assert.equal(game.state.deaths, 2, 'loading cannot create a fall-respawn loop');
  assert(game.state.player.grounded);
  assert.equal(game.state.player.y + game.state.player.h, 580);
  assert.deepEqual(game.state.checkpoint, old.checkpoint);
  assert(game.state.memories.has('drift'));
});

test('the crab obstacle follows the raised bank and remains impassable until feeding', () => {
  const game = new Game(); game.start(); game.enter(1);
  for (let i = 0; i < 360; i++) game.step(DT, { right: true });
  const crab = rooms[1].objects.find(object => object.id === 'fed');
  assert.equal(game.state.player.y + game.state.player.h, crab.y, 'the player stands at the crab bank height');
  const blockedX = game.state.player.x;
  assert(blockedX < crab.x);
  for (let i = 0; i < 150; i++) game.step(DT, { right: true, jump: true });
  assert(game.state.player.x <= blockedX, 'the raised bank must not allow jumping over the unfed crab');
  game.state.flags.add('food'); game.interact();
  assert(game.state.flags.has('fed'));
  for (let i = 0; i < 90; i++) game.step(DT, { right: true });
  assert(game.state.player.x > crab.x + 100);
  assert.equal(game.state.deaths, 0);
});
