import {writeFileSync,mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

// Rebuilds authored scene nodes only. Never paints or stretches any image.
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');
const dest=path.join(root,'game/content/story/xuting_environment.tscn');
const resources=[
 ['Script','res://src/story/story_environment.gd','env'],
 ['Texture2D','res://art/story-c01/environment/xuting-panorama.png','panorama'],
 ['Texture2D','res://art/story-c01/environment/baleen-buttress.png','barrier'],
 ['Texture2D','res://art/story-c01/environment/returning-silt.png','silt'],
 ['Texture2D','res://art/story-c01/environment/bone-platform.png','bone'],
 ['Texture2D','res://art/story-c01/environment/hanging-root.png','root'],
 ['Texture2D','res://art/story-c01/environment/shell-nest.png','nest'],
 ['Texture2D','res://art/story-c01/environment/shell-camp.png','camp'],
 ['Texture2D','res://art/story-c01/environment/fungus-bed.png','food'],
 ['Script','res://src/world/scenery/chapter/fish_group.gd','fish'],
 ['Script','res://src/world/scenery/local_environment/elements/bubble_emitter.gd','bubbles'],
 ['PackedScene','res://content/whalebelly/environment/elements/BALEEN-LEFT.tscn','baleen'],
];
const shapes=[['Floor',3200,240],['Barrier',320,130],['Perch',270,16],['Boundary',40,1000]];
let scene='[gd_scene load_steps='+ (resources.length+shapes.length+1) +' format=3]\n\n';
for(const [type,p,id] of resources)scene+='[ext_resource type="'+type+'" path="'+p+'" id="'+id+'"]\n';
for(const [id,w,h] of shapes)scene+='\n[sub_resource type="RectangleShape2D" id="'+id+'"]\nsize = Vector2('+w+', '+h+')\n';
const v=(x,y)=>'Vector2('+x+', '+y+')';
function node(name,type,parent,props={},extra=''){
 scene+='\n[node name="'+name+'"'+(type?' type="'+type+'"':'')+(parent===null?'':' parent="'+parent+'"')+extra+']\n';
 for(const [key,value]of Object.entries(props))scene+=key+' = '+value+'\n';
}
function sprite(name,parent,tex,x,y,scale,props={}){
 node(name,'Sprite2D',parent,{position:v(x,y),scale:v(scale,scale),texture:'ExtResource("'+tex+'")',centered:'false',...props});
}
node('XutingEnvironment','Node2D',null,{script:'ExtResource("env")'});
sprite('Panorama','.','panorama',0,0,1.5625,{z_index:-30});
node('Scenery','Node2D','.',{z_index:-4});
sprite('MenderNest','Scenery','nest',294,685,.15,{modulate:'Color(0.62, 0.70, 0.70, 1)'});
sprite('CampShelter','Scenery','camp',515,632,.15,{modulate:'Color(0.80, 0.84, 0.80, 1)'});
sprite('InnerNest','Scenery','nest',2460,692,.135,{modulate:'Color(0.50, 0.63, 0.62, 1)'});
sprite('ForageLeft','Scenery','food',1162,728,.065,{modulate:'Color(0.42, 0.50, 0.42, 1)'});
sprite('ForageRight','Scenery','food',1835,728,.065,{modulate:'Color(0.42, 0.50, 0.42, 1)'});
node('Terrain','Node2D','.',{z_index:-2});
// Preserve the complete irregular painted contour: cropped midsections exposed
// vertical cuts below the road. Natural ends overlap by about sixty pixels.
for(let i=0;i<4;i++)sprite('Road'+i,'Terrain','bone',i*900-200,647,.5,{
 modulate:'Color(0.54, 0.63, 0.63, 1)'});
for(const [name,x]of [['Left',1050],['Right',1810]]){
 sprite(name+'Root','Terrain','root',x+6,634,.16,{modulate:'Color(0.43, 0.53, 0.54, 1)'});
 sprite(name+'Perch','Terrain','bone',x-10,614,.14,{modulate:'Color(0.63, 0.72, 0.72, 1)'});
}
sprite('BaleenDivider','Terrain','barrier',1393.08,568.6,.23941068,{modulate:'Color(0.72, 0.79, 0.78, 1)'});
node('Collisions','Node2D','.');
for(const [name,shape,x,y,oneWay]of [
 ['Road','Floor',1600,900,false],['Divider','Barrier',1570,715,false],
 ['LeftPerch','Perch',1185,658,true],['RightPerch','Perch',1945,658,true],
 ['LeftEdge','Boundary',-20,500,false],['RightEdge','Boundary',3220,500,false]
]){
 node(name,'StaticBody2D','Collisions',{position:v(x,y),collision_layer:1,collision_mask:0});
 node('Shape','CollisionShape2D','Collisions/'+name,{shape:'SubResource("'+shape+'")',...(oneWay?{one_way_collision:'true',one_way_collision_margin:8}:{})});
}
node('Motion','Node2D','.',{z_index:-12});
node('FishLeft','Node2D','Motion',{script:'ExtResource("fish")',bounds:'Rect2(650, 345, 380, 140)',population:9,phase:0.4});
node('FishRight','Node2D','Motion',{script:'ExtResource("fish")',bounds:'Rect2(2190, 330, 370, 140)',population:7,species:1,phase:2.2});
for(const [name,x,phase,scale]of [['FringeLeft',680,0,.24],['FringeCenter',1540,13,.29],['FringeRight',2300,29,.22]]){
 node(name,null,'Motion',{position:v(x,95),scale:v(scale,scale),external_clock:'true',phase_offset_frames:phase,modulate:'Color(0.60, 0.72, 0.73, 0.72)'},' instance=ExtResource("baleen")');
}
node('BubblesLeft','Node2D','Motion',{script:'ExtResource("bubbles")',bounds:'Rect2(740, 350, 240, 350)',population:7,external_clock:'true',size_range:v(3,6),bubble_opacity:.25,seed_id:3});
node('BubblesInner','Node2D','Motion',{script:'ExtResource("bubbles")',bounds:'Rect2(2220, 420, 200, 330)',population:6,external_clock:'true',size_range:v(3,7),bubble_opacity:.26,seed_id:7});
node('ReturningSilt','Node2D','.',{z_index:-5});
for(let i=0;i<9;i++)sprite('Wisp'+i,'ReturningSilt','silt',0,0,.018+(i%3)*.004,{centered:'true'});
node('Markers','Node2D','.');
for(const [name,x,y] of [
 ['PlayerSpawn',150,780],['MenderStart',430,780],['MenderEnd',2550,780],
 ['Camp',620,780],['EncounterStart',900,780],['EnemyHomeLeft',1230,780],
 ['EnemyHomeRight',1900,780],['Exit',2990,780],['ReturningCurrent',2780,658],
])node(name,'Marker2D','Markers',{position:v(x,y)});
mkdirSync(path.dirname(dest),{recursive:true});
writeFileSync(dest,scene);
console.log(path.relative(root,dest));
