import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, validateSave } from '../engine.js';
import { HABITATS, getHabitatStatus } from '../ecology.js';
import { rooms } from '../levels.js';

const DT = 1 / 120;
function setup(habitat = HABITATS[0], ready = true) {
  const events = [];
  const game = new Game((type, message) => events.push({ type, message }));
  game.start();
  game.enter(habitat.room);
  const object = rooms[habitat.room].objects.find(o => o.id === habitat.id);
  Object.assign(game.state.player, { x: object.x - 15, y: object.y - 48, grounded: true });
  if (ready) game.state.flags.add(habitat.requires);
  events.length = 0;
  return { game, events };
}
function advance(game, seconds) {
  for (let frame = 0; frame < Math.round(seconds / DT); frame++) game.step(DT);
}

test('each habitat needs its local mechanism before repair can begin', () => {
  for (const habitat of HABITATS) {
    const { game, events } = setup(habitat, false);
    assert.deepEqual(getHabitatStatus(game.state, habitat.id), { phase: 'dormant', progress: 0 });
    assert.equal(game.context(), habitat.hint);
    game.interact();
    assert.equal(game.state.habitats[habitat.id], undefined);
    assert(!game.state.flags.has(habitat.id));
    assert(events.some(e => e.type === 'toast' && e.message === habitat.hint));
    assert(!events.some(e => e.type === 'save'));
    game.state.flags.add(habitat.requires);
    assert.match(game.context(), /\[ F \]/);
    game.interact();
    assert.deepEqual(getHabitatStatus(game.state, habitat.id), { phase: 'recovering', progress: 0 });
    assert(events.some(e => e.type === 'save'), 'starting recovery must be saved');
  }
});

test('repair grows through three states and announces maturity exactly once', () => {
  const habitat = HABITATS[0], { game, events } = setup(habitat);
  game.interact();
  assert(!game.state.flags.has(habitat.id), 'a repair action is not immediate restoration');
  advance(game, 4);
  const growing = getHabitatStatus(game.state, habitat.id);
  assert.equal(growing.phase, 'recovering');
  assert(Math.abs(growing.progress - 1 / 3) < 0.001);
  assert.match(game.context(), /恢复中/);
  advance(game, 8.1);
  assert.deepEqual(getHabitatStatus(game.state, habitat.id), { phase: 'restored', progress: 1 });
  assert.equal(game.state.habitats[habitat.id], habitat.duration);
  assert(game.state.flags.has(habitat.id));
  assert.match(game.context(), /已恢复/);
  assert.equal(events.filter(e => e.type === 'save').length, 2, 'save once at start and once at maturity');
  assert.equal(events.filter(e => e.type === 'sound' && e.message === 'success').length, 1);
  advance(game, 3);
  game.interact();
  assert.equal(events.filter(e => e.type === 'sound' && e.message === 'success').length, 1);
  assert(events.some(e => e.type === 'toast' && e.message === habitat.restoredText));
});

test('repeated repair input preserves progress and never duplicates the start save', () => {
  const habitat = HABITATS[0], { game, events } = setup(habitat);
  game.interact();
  advance(game, 3);
  const before = game.state.habitats[habitat.id];
  for (let press = 0; press < 4; press++) game.interact();
  assert.equal(game.state.habitats[habitat.id], before);
  assert.equal(events.filter(e => e.type === 'save').length, 1);
  advance(game, 9.1);
  assert.equal(getHabitatStatus(game.state, habitat.id).phase, 'restored');
});

test('pause, map, journal, ending and title do not advance ecological recovery', () => {
  const habitat = HABITATS[0], { game } = setup(habitat);
  game.interact();
  advance(game, 2);
  const before = game.state.habitats[habitat.id];
  for (const mode of ['paused', 'map', 'journal', 'ending', 'title']) {
    game.state.mode = mode;
    advance(game, 15);
    assert.equal(game.state.habitats[habitat.id], before, `${mode} must freeze recovery`);
  }
  game.state.mode = 'playing';
  advance(game, 10.1);
  assert.equal(getHabitatStatus(game.state, habitat.id).phase, 'restored');
});

test('a habitat matures while the player explores another room', () => {
  const habitat = HABITATS[1], { game, events } = setup(habitat);
  game.interact();
  advance(game, 2);
  game.enter(3);
  advance(game, 10.1);
  assert.equal(game.state.room, 3);
  assert.equal(getHabitatStatus(game.state, habitat.id).phase, 'restored');
  assert(events.some(e => e.type === 'toast' && e.message.includes('胃库沼泽')));
});

test('a mid-recovery save resumes its elapsed progress without sharing mutable data', () => {
  const habitat = HABITATS[0], { game } = setup(habitat);
  game.interact();
  advance(game, 4.5);
  const snapshot = game.serialize();
  assert.notEqual(snapshot.habitats, game.state.habitats);
  const saved = JSON.parse(JSON.stringify(snapshot));
  assert(validateSave(saved));
  const resumed = new Game();
  resumed.start(saved);
  assert.equal(getHabitatStatus(resumed.state, habitat.id).phase, 'recovering');
  assert(Math.abs(getHabitatStatus(resumed.state, habitat.id).progress - 0.375) < 0.001);
  assert.notEqual(resumed.state.habitats, saved.habitats);
  advance(resumed, 7.6);
  assert.equal(getHabitatStatus(resumed.state, habitat.id).phase, 'restored');
  assert.equal(saved.habitats[habitat.id], snapshot.habitats[habitat.id]);
  assert(!saved.flags.includes(habitat.id));
});

test('old V2 saves keep completed habitats and accept missing recovery data', () => {
  const { game } = setup();
  const old = game.serialize();
  delete old.habitats;
  old.flags.push(...HABITATS.map(h => h.id));
  assert(validateSave(old));
  const restored = new Game();
  restored.start(old);
  for (const habitat of HABITATS) assert.deepEqual(getHabitatStatus(restored.state, habitat.id), { phase: 'restored', progress: 1 });
  assert.deepEqual(restored.state.habitats, {});
  advance(restored, 15);
  assert.equal(restored.state.flags.size, new Set(old.flags).size);
});

test('save validation rejects unknown, nonnumeric, unbounded and non-object recovery data', () => {
  const { game } = setup(), save = game.serialize(), id = HABITATS[0].id;
  for (const habitats of [null, [], '12', false, new Date(), { unknown: 1 }, ...[-1, 12.1, NaN, Infinity, '4', null].map(n => ({ [id]: n }))]) {
    assert.equal(validateSave({ ...save, habitats }), null, `invalid habitats: ${String(habitats)}`);
  }
  for (const seconds of [0, 6, 12]) assert(validateSave({ ...save, habitats: { [id]: seconds } }));
});

test('a completed journey points to missing recovery, then missing memories, then completion', () => {
  const { game } = setup();
  game.state.flags.add('finished');
  assert.match(game.objective(), /鲸须菌席/);
  game.interact();
  assert.match(game.objective(), /正在恢复/);
  for (const habitat of HABITATS) game.state.flags.add(habitat.id);
  assert.match(game.objective(), /再寻找 4 枚记忆/);
  for (const memory of rooms.flatMap(r => r.memories)) game.state.memories.add(memory.id);
  assert.match(game.objective(), /全部完成/);
});
