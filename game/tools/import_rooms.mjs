// One-time migration helper. Writes new scenes only; existing scenes remain the source of truth.
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const game = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rooms = JSON.parse(readFileSync(path.join(game, '../legacy/godot/first-level/assets/rooms.json')));
const q = JSON.stringify;
const vec = (x, y) => `Vector2(${x}, ${y})`;
function scene() {
  const resources = [], parts = [];
  return {
    resource(type, file) {
      const id = `r${resources.length}`;
      resources.push(`[ext_resource type=${q(type)} path=${q(file)} id=${q(id)}]`);
      return `ExtResource(${q(id)})`;
    },
    raw(s) { parts.push(s); },
    node(name, type, parent, properties = {}, extra = '') {
      parts.push(`[node name=${q(name)} type=${q(type)}${parent == null ? '' : ` parent=${q(parent)}`}${extra}]
${Object.entries(properties).map(([k, v]) => `${k} = ${v}`).join('\n')}`);
    },
    sprite(name, parent, file, x, y, width) {
      const texture = this.resource('Texture2D', `res://art/${file}`);
      const pixels = readFileSync(path.join(game, 'art', file)).readUInt32BE(16);
      this.node(name, 'Sprite2D', parent, { texture, position: vec(x, y), scale: vec(width / pixels, width / pixels) });
    },
    label(parent, text, x = -90, y = -160) {
      this.node('Prompt', 'Label', parent, { text: q(text), position: vec(x, y), 'theme_override_font_sizes/font_size': 16 });
    },
    save(file) {
      if (existsSync(file)) throw new Error(`Refusing to overwrite ${file}`);
      mkdirSync(path.dirname(file), { recursive: true });
      const blocks = parts.join('\n\n').split(/\n\n(?=\[)/);
      const ordered = [...blocks.filter(b => b.startsWith('[sub_resource')), ...blocks.filter(b => !b.startsWith('[sub_resource'))];
      writeFileSync(file, `[gd_scene format=3]\n\n${resources.join('\n')}\n\n${ordered.join('\n\n')}\n`);
    },
  };
}
const ability = { A1: 'ability.dash', A2: 'ability.float', A3: 'ability.anchor' };
for (const room of rooms) {
  const file = path.join(game, 'content/rooms/R1', `${room.id}.tscn`);
  if (existsSync(file)) continue;
  const s = scene();
  const script = s.resource('Script', 'res://src/world/room.gd');
  const scenery = s.resource('PackedScene', `res://content/rooms/R1/scenery/${room.id}_scenery.tscn`);
  s.node(room.id, 'Node2D', null, { script, room_id: q(room.id), display_name: q(room.name), dimensions: vec(room.width * 64, room.height * 64), fall_damage: ['R1-02', 'R1-03'].includes(room.id) ? 1 : 0 });
  s.raw(`[node name="Scenery" parent="." instance=${scenery}]`);
  s.node('Entries', 'Node2D', '.');
  const start = room.platforms[0];
  s.node('default', 'Marker2D', 'Entries', { position: vec(3 * 64, start.y * 64 - 3) });
  s.node('camp', 'Marker2D', 'Entries', { position: vec(3 * 64, start.y * 64 - 3) });
  s.node('Gameplay', 'Node2D', '.', { z_index: 2 });
  for (const door of room.doors) {
    const inset = door.side === 'left' ? 1.15 : door.side === 'right' ? -1.15 : 0;
    s.node(door.id, 'Marker2D', 'Entries', { position: vec((door.x + inset) * 64, door.y * 64 - 3) });
    const requires = [...new Set((door.condition.requiresAll ?? []).map(a => ability[a]))];
    if (room.id === 'R1-04' && door.id === 'E04') requires.push('ability.dash');
    const flags = (door.condition.completionFlags ?? []).map(f => f === 'BOSS_R1' ? 'boss.r1_shell_crab' : f);
    if (door.id === 'E34') flags.push('shortcut.blowhole');
    const name = `Door_${door.id}`, parent = `Gameplay/${name}`;
    s.node(name, 'Node2D', 'Gameplay', {
      position: vec(door.x * 64, door.y * 64), script: s.resource('Script', 'res://src/world/door.gd'),
      edge_id: q(door.id), target_room: q(door.to), target_entry: q(door.id),
      prompt: q(`E ${door.id} → ${door.to}${requires.length ? ' · 能力门' : ''}`),
      required_abilities: `PackedStringArray(${requires.map(q).join(', ')})`, required_flags: `PackedStringArray(${flags.map(q).join(', ')})`,
      ...(door.to === 'R3-01' ? { boundary_flag: q('complete.r1') } : {}),
    });
    s.sprite('Sprite', parent, 'scenery/v02/gate.png', 0, -70, 130);
    s.label(parent, `E ${door.id} → ${door.to}`);
  }
  if (room.checkpoint) {
    s.node('Camp', 'Node2D', 'Gameplay', { position: vec(room.checkpoint.x * 64, room.checkpoint.y * 64), script: s.resource('Script', 'res://src/world/checkpoint.gd'), room_id: q(room.id), prompt: q('E 营地 · 休息并保存') });
    s.sprite('Sprite', 'Gameplay/Camp', 'props/shell_camp.png', 0, -34, 130);
    s.label('Gameplay/Camp', 'E 营地 · 休息并保存', -90, -112);
  }
  for (let i = 0; i < room.enemies.length; i++) {
    const e = room.enemies[i], boss = room.id === 'R1-04';
    s.raw(`[node name="Enemy${i}" parent="Gameplay" instance=${s.resource('PackedScene', `res://src/enemies/${boss ? 'shell_crab_boss' : 'corpse_crab'}/${boss ? 'shell_crab_boss' : 'corpse_crab'}.tscn`)}]\nposition = ${vec(e.x * 64, e.y * 64 - 1)}`);
  }
  for (let i = 0; i < room.rewards.length; i++) {
    const r = room.rewards[i], name = `Reward${i}`, parent = `Gameplay/${name}`;
    const dash = room.id === 'R1-04', habitat = room.id === 'R1-05';
    const flag = dash ? 'pickup.r1_dash' : habitat ? 'habitat.r1_clearflow' : `${room.id}.reward.${i}`;
    const image = dash ? 'dash_cocoon_closed' : habitat ? 'habitat_shell_nest' : room.id === 'R1-06' ? 'module_quiet_fungus' : i === 1 ? 'migration_memory' : 'life_fragment';
    s.node(name, 'Node2D', 'Gameplay', {
      position: vec(r.x * 64, (room.id === 'R1-03' ? 11.3 : dash || habitat ? 14 : r.y + 0.8) * 64),
      script: s.resource('Script', 'res://src/world/pickup.gd'), flag_id: q(flag), prompt: q(`E ${dash ? '承接贴流冲 · Shift' : r.label}`),
      ...(dash ? { ability_id: q('ability.dash'), required_flags: 'PackedStringArray("boss.r1_shell_crab")', collected_texture: s.resource('Texture2D', 'res://art/props/dash_cocoon_open.png') } : {}),
    });
    s.sprite('Sprite', parent, `props/${image}.png`, 0, -42, 90);
    s.label(parent, `E ${dash ? '承接贴流冲' : r.label}`, -100, -120);
  }
  if (room.id === 'R1-03') {
    s.raw('[sub_resource type="RectangleShape2D" id="bridge_shape"]\nsize = Vector2(64, 16)');
    s.node('Bridge', 'StaticBody2D', 'Gameplay', { position: vec(28 * 64, 12.8 * 64), collision_layer: 1, collision_mask: 0, visible: false });
    s.node('Shape', 'CollisionShape2D', 'Gameplay/Bridge', { position: vec(32, 8), shape: 'SubResource("bridge_shape")', disabled: true });
    s.sprite('Sprite', 'Gameplay/Bridge', 'props/tongue_ledge.png', 32, 16, 64);
    s.node('Lever', 'Node2D', 'Gameplay', { position: vec(25.5 * 64, 11.3 * 64), script: s.resource('Script', 'res://src/world/lever.gd'), bridge: 'NodePath("../Bridge")', prompt: q('E 打开壳闩'), open_texture: s.resource('Texture2D', 'res://art/props/shell_latch_open.png') }, ' node_paths=PackedStringArray("bridge")');
    s.sprite('Sprite', 'Gameplay/Lever', 'props/shell_latch_closed.png', 0, -30, 60);
    s.label('Gameplay/Lever', 'E 打开壳闩', -40, -85);
    s.node('Membrane', 'Node', 'Gameplay', { script: s.resource('Script', 'res://src/world/membrane.gd'), shelf: 'NodePath("../../Scenery/World/Shelf_P2")' }, ' node_paths=PackedStringArray("shelf")');
  }
  if (room.id === 'R1-04') {
    s.node('Arena', 'Node2D', 'Gameplay', { script: s.resource('Script', 'res://src/world/arena.gd') });
    s.sprite('Curtain', 'Gameplay/Arena', 'props/arena_curtain_closed.png', 448, 800, 150);
  }
  for (let i = 0; i < room.hazards.length; i++) {
    const h = room.hazards[i];
    if (room.id === 'R1-03') continue; // Authored load membrane has its own component.
    s.node(`Hazard${i}`, 'Node2D', 'Gameplay', { position: vec(h.x * 64, h.y * 64), script: s.resource('Script', 'res://src/world/hazard.gd'), width: h.w * 64, rescue_only: room.id === 'R1-05' });
    if (room.id !== 'R1-05') s.sprite('Warning', `Gameplay/Hazard${i}`, 'fx/danger_line.png', h.w * 32, -12, h.w * 64);
  }
  s.save(file);
}
for (const boss of [false, true]) {
  const kind = boss ? 'shell_crab_boss' : 'corpse_crab', file = path.join(game, 'src/enemies', kind, `${kind}.tscn`);
  if (existsSync(file)) continue;
  const s = scene();
  s.node(kind, 'CharacterBody2D', null, { script: s.resource('Script', 'res://src/enemies/enemy_base.gd'), collision_layer: 4, collision_mask: 1, boss, speed: boss ? 78 : 48, radius: boss ? 60 : 30, approach_distance: boss ? 145 : 85, attack_reach: boss ? 175 : 100, victory_flag: q(boss ? 'boss.r1_shell_crab' : '') }, ' groups=["enemy"]');
  s.raw(`[sub_resource type="RectangleShape2D" id="body"]\nsize = ${vec(boss ? 120 : 60, boss ? 125 : 65)}\n\n[sub_resource type="RectangleShape2D" id="attack"]\nresource_local_to_scene = true\nsize = Vector2(130, 88)`);
  s.node('Shape', 'CollisionShape2D', '.', { shape: 'SubResource("body")', position: vec(0, boss ? -62.5 : -32.5) });
  s.node('Health', 'Node', '.', { script: s.resource('Script', 'res://src/combat/health.gd'), maximum: boss ? 180 : 30 });
  s.node('Hurtbox', 'Area2D', '.', { script: s.resource('Script', 'res://src/combat/hurtbox.gd'), health: 'NodePath("../Health")', collision_layer: 16, collision_mask: 0, monitoring: false }, ' node_paths=PackedStringArray("health")');
  s.node('Shape', 'CollisionShape2D', 'Hurtbox', { shape: 'SubResource("body")', position: vec(0, boss ? -62.5 : -32.5) });
  s.node('Hitbox', 'Area2D', '.', { script: s.resource('Script', 'res://src/combat/hitbox.gd'), collision_layer: 0, collision_mask: 8, monitorable: false });
  s.node('Shape', 'CollisionShape2D', 'Hitbox', { shape: 'SubResource("attack")' });
  s.sprite('Visual', '.', `enemies/${kind}.png`, 0, boss ? -77.5 : -35, boss ? 210 : 96);
  s.sprite('Warning', '.', 'fx/danger_line.png', 0, -8, boss ? 175 : 100);
  s.save(file);
}
