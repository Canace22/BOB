import test from 'node:test';
import assert from 'node:assert/strict';
import { CampaignGame, CAMPAIGN_SAVE_KEY, validateCampaignSave, campaignHazardPhase } from '../campaign-engine.js';
import { CAMPAIGN_ROOM_BY_ID, UNIT } from '../campaign-levels.js';
import { Game, SAVE_KEY } from '../engine.js';

const DT = 1 / 120;
function setup(room = 'R1-01') {
  const events = [], game = new CampaignGame((type, payload) => events.push({ type, payload }));
  game.start(); if (room !== 'R1-01') game.enter(room);
  return { game, events, step: (frames, input = {}) => { for (let i = 0; i < frames; i++) game.step(DT, input); } };
}
function stand(game, point) { Object.assign(game.state.player, { x: point.x - 15, y: point.y - 48, vx: 0, vy: 0, grounded: true }); }

test('the new campaign has isolated saves and entering a room cannot grant abilities or boss victory', () => {
  const { game } = setup();
  assert.notEqual(CAMPAIGN_SAVE_KEY, SAVE_KEY);
  const legacy = new Game(); legacy.start();
  assert.equal(validateCampaignSave(legacy.serialize()), null);
  for (const room of ['R1-02', 'R1-03', 'R1-04', 'R1-05']) game.enter(room);
  assert.equal(game.state.abilities.size, 0); assert(!game.state.flags.has('BOSS_R1'));
  const save = game.serialize(); assert(validateCampaignSave(save));
  assert.equal(validateCampaignSave({ ...save, abilities: ['A1'] }), null);
  assert.equal(validateCampaignSave({ ...save, checkpoint: { room: 'R1-04', x: 1000, y: 1 } }), null);
  assert.equal(validateCampaignSave({ ...save, checkpoint: { room: 'R1-06', ...CAMPAIGN_ROOM_BY_ID['R1-06'].spawn } }), null);
});

test('unwon boss gates stay closed; boss damage stops on defeat and A1 requires its explicit interaction', () => {
  const { game, step } = setup('R1-04'), room = game.room;
  const exit = room.exits.find(exit => exit.to === 'R1-05');
  stand(game, exit); game.interact(); assert.equal(game.state.room, 'R1-04');
  const boss = game.state.enemies[0]; boss.hp = 8; boss.phase = 'recovery'; boss.timer = 1;
  Object.assign(game.state.player, { x: boss.x - 35, y: boss.foot - 48, facing: 1, grounded: true });
  game.state.arenaActive = true; step(1, { attack: true });
  assert.equal(boss.hp, 0); assert.equal(boss.attack, null); assert.equal(boss.preview, null);
  assert(game.state.flags.has('BOSS_R1')); assert(!game.state.abilities.has('A1'));
  game.enter('R1-04'); assert.equal(game.state.enemies.length, 0, 'victory does not respawn a boss');
  stand(game, room.objects.find(object => object.grants === 'A1')); game.interact();
  assert(game.state.abilities.has('A1'));
  const count = game.state.collected.size; game.interact(); assert.equal(game.state.collected.size, count);
  stand(game, exit); game.interact(); assert.equal(game.state.room, 'R1-05');
});

test('idle contact is safe, telegraphs precede active damage, and one attack cannot repeatedly drain life', () => {
  const { game, step } = setup('R1-02'), enemy = game.state.enemies[0];
  Object.assign(game.state.player, { x: enemy.x + enemy.w / 2, y: enemy.foot - 48, grounded: true });
  enemy.phase = 'idle'; enemy.timer = 5; step(30);
  assert.equal(game.state.life, 4, 'touching an idle body has no damage');
  enemy.phase = 'telegraph'; enemy.facing = 1; enemy.move = 'sweep'; enemy.timer = .65;
  step(60); assert.equal(game.state.life, 4); assert.equal(enemy.phase, 'telegraph');
  step(24); assert.equal(game.state.life, 3); assert.equal(enemy.phase, 'active');
  step(30); assert.equal(game.state.life, 3, 'one active volume and 1-second protection prevent stacked damage');
});

test('death restores a registered camp and resets transient enemies while preserving permanent rewards', () => {
  const { game } = setup('R1-04'), camp = game.room.camps[0]; stand(game, camp); game.interact();
  game.state.flags.add('BOSS_R1'); game.state.abilities.add('A1'); game.state.collected.add('GRANT_A1');
  game.enter('R1-03'); game.state.enemies[0].hp = 1;
  game.state.life = 1; game.hurt(1);
  assert.equal(game.state.room, 'R1-04'); assert.equal(game.state.life, 4); assert.equal(game.state.resonance, 4);
  assert.equal(game.state.enemies.length, 0); assert(game.state.flags.has('BOSS_R1')); assert(game.state.abilities.has('A1'));
  const save = game.serialize(); assert(validateCampaignSave(save));
  const resumed = new CampaignGame(); resumed.start(JSON.parse(JSON.stringify(save)));
  assert.deepEqual(resumed.state.checkpoint, game.state.checkpoint); assert.equal(resumed.state.deaths, 1);
  game.enter('R1-03'); assert.equal(game.state.enemies[0].hp, game.state.enemies[0].maxHp);
});

test('A1 travels exactly 2.6U, cannot repeat airborne, and cannot pass through a thin solid wall', t => {
  const { game, step } = setup(); game.state.flags.add('BOSS_R1'); game.state.abilities.add('A1');
  Object.assign(game.state.player, { x: 100, y: 100, grounded: false, facing: 1 });
  step(20, { dash: true }); assert(Math.abs(game.state.player.x - 100 - 2.6 * UNIT) < .001);
  step(1); const x = game.state.player.x; step(1, { dash: true }); assert.equal(game.state.player.x, x);
  assert.equal(game.state.dash.available, false);
  const room = CAMPAIGN_ROOM_BY_ID['R1-01'], prior = room.barriers;
  t.after(() => { if (prior === undefined) delete room.barriers; else room.barriers = prior; });
  room.barriers = [{ x: 170, y: 0, w: 8, h: 400 }];
  Object.assign(game.state.player, { x: 100, y: 100, facing: 1 });
  game.state.dash.available = true; game.state.dash.cooldown = 0; game.previous = {};
  game.step(.16, { dash: true }); assert.equal(game.state.player.x, 140);
});

test('heavy attacks and interrupted rest consume resonance without free healing, and camp refills both', () => {
  const { game, step } = setup(); step(3);
  game.attack(true); assert.equal(game.state.resonance, 2); assert.equal(game.state.attack.kind, 'heavy');
  game.state.life = 2; step(1, { rest: true }); assert.equal(game.state.resonance, 0); assert(game.state.rest > 0);
  game.hurt(1); assert.equal(game.state.rest, 0); step(180); assert.equal(game.state.life, 1);
  stand(game, game.room.camps[0]); game.interact(); assert.equal(game.state.life, 4); assert.equal(game.state.resonance, 4);
});

test('future branches stay locked and the R1 endpoint reports batch completion instead of the final ending', () => {
  const { game, events } = setup('R1-02');
  stand(game, game.room.exits.find(exit => exit.to === 'R1-06')); game.interact(); assert.equal(game.state.room, 'R1-02');
  game.state.flags.add('BOSS_R1'); game.state.abilities.add('A1'); game.enter('R1-05');
  stand(game, game.room.exits.find(exit => exit.to === 'R3-01')); game.interact();
  assert(game.state.flags.has('BATCH_R1')); assert.equal(game.state.mode, 'playing');
  assert(events.some(event => event.type === 'batch-complete')); assert(!events.some(event => event.type === 'ending'));
});

test('hazards have readable warning and safe windows; an active hazard still hurts during a dash', () => {
  const { game, step } = setup('R1-02'), hazard = game.room.hazards[0];
  const position = { x: hazard.x + hazard.w / 2, y: 16 * UNIT };
  assert.equal(campaignHazardPhase(hazard, .2).phase, 'warning');
  assert.equal(campaignHazardPhase(hazard, .8).phase, 'active');
  assert.equal(campaignHazardPhase(hazard, 2).phase, 'safe');
  for (const time of [.2, 2]) {
    stand(game, position); game.state.hazardTime = time; step(1);
    assert.equal(game.state.life, 4);
  }
  stand(game, position); game.state.hazardTime = .8; game.state.dash.remaining = .1;
  step(1); assert.equal(game.state.life, 3);
  assert.equal(game.state.dash.remaining, 0, 'recovery interrupts dash instead of crossing the hazard');
  assert(game.state.invulnerable > 0);
});

test('H1 requires a completed dash crossing and landing, not a ground dash or failed gap attempt', () => {
  const { game, step } = setup('R1-05'), s = game.state;
  s.flags.add('BOSS_R1'); s.abilities.add('A1');
  step(3); step(20, { dash: true }); step(70);
  assert(!s.flags.has('DASH_PRACTICED'), 'dashing across the same starting deck is not the teaching challenge');
  stand(game, game.room.objects.find(object => object.id === 'H1')); game.interact();
  assert(!s.collected.has('H1'));

  game.enter('R1-05'); Object.assign(s.player, { x: 5.5 * UNIT - 15, y: 14 * UNIT - 48, grounded: true });
  step(2); step(20, { right: true, dash: true }); step(100);
  assert(!s.flags.has('DASH_PRACTICED'), 'falling into the soft bed returns to the same deck without credit');

  Object.assign(s.player, { x: 5.5 * UNIT - 15, y: 14 * UNIT - 48, grounded: true });
  step(2); step(30, { right: true, jump: true }); step(20, { right: true, dash: true }); step(50, { right: true });
  assert(s.player.grounded); assert(s.player.x + 15 >= 10 * UNIT);
  assert(s.flags.has('DASH_PRACTICED'));
  stand(game, game.room.objects.find(object => object.id === 'H1')); game.interact();
  assert(s.collected.has('H1')); assert(s.flags.has('H1'));
});

test('landing on or leaving the H1 side ledge cannot count as crossing a teaching gap', () => {
  const { game, step } = setup('R1-05'), s = game.state;
  const entry = game.room.platforms.find(platform => platform.id === 'R1-05-entry');
  const ledge = game.room.platforms.find(platform => platform.id === 'R1-05-habitat-side-ledge');
  for (const [origin, landing, x] of [[entry, ledge, 4 * UNIT], [ledge, entry, 5.5 * UNIT]]) {
    stand(game, { x, y: landing.y });
    Object.assign(s.dash, { used: true, remaining: 0, fromPlatform: origin.id });
    step(1);
    assert(s.player.grounded);
    assert(!s.flags.has('DASH_PRACTICED'), `${origin.id} to ${landing.id} is not a 4U gap`);
  }
});

test('overlapping camp and return-exit interaction ranges select the nearest target for both prompt and action', () => {
  const { game } = setup('R1-04'), room = game.room;
  const camp = room.camps[0], exit = room.exits.find(candidate => candidate.to === 'R1-03');
  stand(game, camp); assert.match(game.context(), /登记营地/);
  game.interact(); assert.equal(game.state.room, 'R1-04');
  assert.deepEqual(game.state.checkpoint, { room: 'R1-04', x: camp.x - 15, y: camp.y - 48 });
  assert(validateCampaignSave(game.serialize()));
  stand(game, exit); assert(game.near(camp), 'the camp range overlaps this exit');
  assert.match(game.context(), /返回舌台/);
  game.interact(); assert.equal(game.state.room, 'R1-03');
  assert.equal(game.state.checkpoint.room, 'R1-04', 'returning through the door does not replace the registered camp');
});
