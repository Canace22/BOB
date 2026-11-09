import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const source=path.join(root,'assets/source/xumen-continuity-v1');
const write=(p,t)=>{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,t);};
const rooms=JSON.parse(fs.readFileSync(path.join(root,'game/art/whalebelly/rooms.json')));
const specs=[
 {id:'E01',a:0,b:1,strip:1}, {id:'E02',a:1,b:2,strip:1},
 {id:'E03',a:2,b:3,strip:2}, {id:'E04',a:3,b:4,strip:3},
 {id:'E33',a:1,b:5,strip:2}, {id:'E35',a:1,b:6,strip:1},
];
const inventory=[];
// Existing foreground/world collision stays intact. A single deep vista gives
// E01–04 a persistent jaw landmark instead of unrelated cave backgrounds.
for(let index=0;index<rooms.length;index++){
 const room=rooms[index];
 const scenePath=path.join(root,`game/content/whalebelly/r1/${room.id}.tscn`);
 let scene=fs.readFileSync(scenePath,'utf8');
 if(index===0){
  // Preserve the approved first-room assembly; its door gets the new glimpse,
  // but a fully occluded panorama must not be reported as a visible far layer.
  scene=scene.replace(/^\[ext_resource[^\n]+id="oral_[^\n]+\]\r?\n/gm,'');
  scene=scene.replace(/\[sub_resource type="ShaderMaterial" id="OralWater"\][\s\S]*?(?=\n\[)/,'');
  scene=scene.replace(/\n\[node name="ContinuousOralDepth"[\s\S]*?(?=\n\[node|$)/,'');
  const resources=[...scene.matchAll(/^\[(?:ext_resource|sub_resource) /gm)].length+1;
  scene=scene.replace(/load_steps=\d+/,'load_steps='+resources);
  fs.writeFileSync(scenePath,scene);
  continue;
 }
 const guardId='oral_guard';
 if(!scene.includes('id="oral_guard"')){
  const pos=scene.indexOf('[sub_resource')>=0?scene.indexOf('[sub_resource'):scene.indexOf('[node');
  scene=scene.slice(0,pos)+`[ext_resource type="Texture2D" path="res://art/xumen-continuity/depth-guard-${room.id}.png" id="oral_guard"]\n\n`+scene.slice(pos);
  scene=scene.replace(/load_steps=(\d+)/,(_,n)=>'load_steps='+(Number(n)+1));
  fs.writeFileSync(scenePath,scene);
 }
 if(!scene.includes('name="ContinuousOralDepth"')){
  const ext='[ext_resource type="Script" path="res://src/world/scenery/chapter/continuous_depth.gd" id="oral_script"]\n[ext_resource type="Texture2D" path="res://art/xumen-continuity/continuous-oral-depth.png" id="oral_texture"]\n[ext_resource type="Shader" path="res://src/world/scenery/chapter/continuous_depth.gdshader" id="oral_shader"]\n\n';
  scene=scene.replace(/load_steps=(\d+)/,(_,n)=>'load_steps='+(Number(n)+4));
  const p=scene.indexOf('[sub_resource')>=0?scene.indexOf('[sub_resource'):scene.indexOf('[node');
  scene=scene.slice(0,p)+ext+'[sub_resource type="ShaderMaterial" id="OralWater"]\nshader = ExtResource("oral_shader")\n\n'+scene.slice(p);
  // Frame-preserving uniform scale: vista spans a larger region than local play ledges.
  const scale=Math.max((room.size[1]+64)/724,(room.size[0]+64)/2172);
  const raw=[.0,.22,.42,.66,.95,.27,.40][index];
  const left=-(2172*scale-room.size[0])*raw-16;
  scene+=`\n[node name="ContinuousOralDepth" type="Sprite2D" parent="."]\nz_index = ${index===0?-75:-29}\nposition = Vector2(${left},-16)\nscale = Vector2(${scale},${scale})\ntexture = ExtResource("oral_texture")\nmaterial = SubResource("OralWater")\ncentered = false\nscript = ExtResource("oral_script")\n`;
  fs.writeFileSync(scenePath,scene);
 }
 scene=fs.readFileSync(scenePath,'utf8');
 scene=scene.replace('[sub_resource type="ShaderMaterial" id="OralWater"]\nshader = ExtResource("oral_shader")','[sub_resource type="ShaderMaterial" id="OralWater"]\nshader = ExtResource("oral_shader")\nshader_parameter/guard_mask = ExtResource("oral_guard")\nshader_parameter/room_size = Vector2('+room.size.join(',')+')');
 // Idempotent parameters when this assembly tool is resumed.
 scene=scene.replace(/(shader_parameter\/room_size = Vector2\([^\n]+\))\n(shader_parameter\/guard_mask[^\n]+\nshader_parameter\/room_size[^\n]+\n)+/g,'$1\n');
 fs.writeFileSync(scenePath,scene);
}
for(const spec of specs){
 for(const [from,to] of [[spec.a,spec.b],[spec.b,spec.a]]){
  const room=rooms[from],door=room.doors.find(d=>d.to===to),side=door.pos[0]<room.size[0]/2?-1:1;
  const id=`${spec.id}_${room.id}`;
  const target=`game/content/whalebelly/environment/continuity/${id}.tscn`;
  const y=door.pos[1]-400;
  // A quiet distant connective glimpse, placed behind existing terrain. No false floor.
  const x=side<0?-550:room.size[0]-950;
  const origin={x,y,width:1500,height:({1:288,2:285,3:291}[spec.strip])*1500/1774};
  let text='[gd_scene load_steps=7 format=3]\n\n';
  const scripts=['src/world/scenery/chapter/continuity_portal.gd','src/world/scenery/chapter/fish_group.gd','src/world/scenery/local_environment/elements/bubble_emitter.gd'];
  scripts.forEach((s,i)=>text+=`[ext_resource type="Script" path="res://${s}" id="s${i}"]\n`);
  text+='[ext_resource type="Shader" path="res://src/world/scenery/chapter/seam_mask.gdshader" id="shader"]\n';
  text+=`[ext_resource type="Texture2D" path="res://art/xumen-continuity/seam-${spec.strip}-Glimpse.png" id="t0"]\n`;
  text+='\n[sub_resource type="ShaderMaterial" id="Mask"]\nshader = ExtResource("shader")\nshader_parameter/strength = 0.38\nshader_parameter/part = 0.0\n';
  text+=`shader_parameter/scene_width = ${room.size[0]}\nshader_parameter/portal_ground = ${door.pos[1]}\n`;
  text+=`\n[node name="Continuity_${spec.id}" type="Node2D"]\nposition = Vector2(${x},${y})\nscript = ExtResource("s0")\nedge_id = "${spec.id}"\ndestination_id = "${rooms[to].id}"\nstrip = ${spec.strip}\nside = ${side}\nportal_y = ${door.pos[1]}\n`;
  for(const [layer,i] of [['Far',0],['Middle',1]]){
    text+=`\n[node name="${layer}" type="Node2D" parent="."]\nz_index = ${[-29,-14,1,11][i]}\n`;
    if(i===0)text+=`\n[node name="PlateFar" type="Sprite2D" parent="Far"]\ntexture = ExtResource("t0")\ncentered = false\nscale = Vector2(${1500/1774},${1500/1774})\nmaterial = SubResource("Mask")\n`;
  }
  text+=`\n[node name="Fish" type="Node2D" parent="Far"]\nscript = ExtResource("s1")\nbounds = Rect2(510,120,330,100)\npopulation = ${spec.id==='E04'||spec.id==='E33'?0:8}\nphase = ${from*.4}\n`;
  text+=`\n[node name="Bubbles" type="Node2D" parent="Middle"]\nscript = ExtResource("s2")\nbounds = Rect2(570,85,110,170)\npopulation = 4\nexternal_clock = true\nbase_speed = 8.0\nbubble_opacity = 0.18\n`;
  write(path.join(root,target),text);
  inventory.push({id,edge:spec.id,room:room.id,to:rooms[to].id,door:door.pos,origin,layers:['Far:source water glimpse','Middle:independent particles','World:retained original room','Foreground:retained original room'],status:'pending_static_and_gpu_review',motion:['independent fish swim atlas and path','prewarmed bounded bubbles'],collision:'none; original room ground remains sole authority'});
  const roomFile=path.join(root,`game/content/whalebelly/r1/${room.id}.tscn`);
  let scene=fs.readFileSync(roomFile,'utf8');
  const extId='seam_'+spec.id;
  if(!scene.includes(`id="${extId}"`)){
    scene=scene.replace(/load_steps=(\d+)/,(_,n)=>'load_steps='+(Number(n)+1));
    const pos=scene.indexOf('[sub_resource')>=0?scene.indexOf('[sub_resource'):scene.indexOf('[node');
    scene=scene.slice(0,pos)+`[ext_resource type="PackedScene" path="res://content/whalebelly/environment/continuity/${id}.tscn" id="${extId}"]\n\n`+scene.slice(pos);
    scene+=`\n[node name="Continuity_${spec.id}" parent="." instance=ExtResource("${extId}")]\n`;
    fs.writeFileSync(roomFile,scene);
  }
 }
}
const manifestPath=path.join(root,'game/art/manifest.json'),manifest=JSON.parse(fs.readFileSync(manifestPath));
const runtimeNames=fs.readdirSync(path.join(source,'runtime')).filter(name=>name!=='depth-guard-R1-01.png'&&/Glimpse|depth-guard|continuous-oral-depth|r1-anatomy-overview/.test(name));
manifest.entries=manifest.entries.filter(e=>!e.dest.startsWith('xumen-continuity/')||runtimeNames.includes(e.dest.split('/').at(-1)));
for(const name of runtimeNames){const dest='xumen-continuity/'+name;if(!manifest.entries.some(e=>e.dest===dest))manifest.entries.push({src:'assets/source/xumen-continuity-v1/runtime/'+name,dest});}
fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n');
write(path.join(source,'elements.json'),JSON.stringify({date:'2026-11-04',scope:'six existing chapter edges; bidirectional art owners',instances:inventory},null,2)+'\n');
console.log(JSON.stringify({edges:specs.length,portalInstances:inventory.length}));
