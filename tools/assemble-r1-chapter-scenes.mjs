import fs from 'node:fs';
const spec=JSON.parse(fs.readFileSync('assets/source/r1-chapter-scenes/chapter.json','utf8'));
const wanted=process.argv.slice(2);
for(const room of spec.rooms){
 if(wanted.length&&!wanted.includes(room.id))continue;
 const map=JSON.parse(fs.readFileSync(`${room.master}/export-map.json`,'utf8'));
 const ext=[],nodes=[],sub=[];let resource=0;
 const resourceId=(type,file)=>{const id=String(++resource);ext.push(`[ext_resource type="${type}" path="${file}" id="${id}"]`);return `ExtResource("${id}")`;};
 const node=(name,type,parent,properties='')=>nodes.push(`[node name="${name}" type="${type}"${parent===null?'':` parent="${parent}"`}]\n${properties}\n`);
 const env=resourceId('Script','res://src/world/scenery/chapter/room_environment.gd');
 const flex=resourceId('Script','res://src/world/scenery/chapter/pinned_bitmap.gd');
 const school=resourceId('Script','res://src/world/scenery/chapter/fish_group.gd');
 const bubble=resourceId('Script','res://src/world/scenery/local_environment/elements/bubble_emitter.gd');
 node('ChapterEnvironment','Control',null,`clip_contents = true\nmouse_filter = 2\noffset_right = ${room.size[0]}\noffset_bottom = ${room.size[1]}\nscript = ${env}\nroom_id = "${room.id}"`);
 for(const [layer,z] of [['Far',-30],['Middle',-15],['World',0],['Foreground',10]]){
  node(layer,'Node2D','.',`z_index = ${z}`);
  if(layer==='Far')node('Underpaint','Sprite2D',layer,`texture = ${resourceId('Texture2D',`res://art/r1-chapter-scenes/${room.id}/underpaint.png`)}\ncentered = false\nposition = Vector2(-16,-16)`);
  let material='';
  if(layer==='Far'){
   const water=room.elements.find(e=>e.kind==='water');
   sub.push(`[sub_resource type="ShaderMaterial" id="WaterLight"]\nshader = ${resourceId('Shader','res://src/world/scenery/chapter/water_light.gdshader')}\nshader_parameter/water_mask = ${resourceId('Texture2D','res://art/'+water.runtime_file)}\n`);
   material='\nmaterial = SubResource("WaterLight")';
  }
  if(room.id==='R1-03'&&layer==='World'){
   sub.push(`[sub_resource type="ShaderMaterial" id="Membrane"]\nshader = ${resourceId('Shader','res://src/world/scenery/chapter/membrane.gdshader')}\n`);
   material='\nmaterial = SubResource("Membrane")';
  }
  node('Surface','Sprite2D',layer,`texture = ${resourceId('Texture2D',`res://art/r1-chapter-scenes/${room.id}/${layer}.png`)}\ncentered = false\nposition = Vector2(-16,-16)${material}`);
 }
 for(const element of room.elements){
  const rect=element.rect, kind=element.kind;
  if(kind==='static'||kind==='water')continue;
  if(['flex','lamp','water'].includes(kind)){
   const entry=map.elements.find(e=>e.id===element.id);if(!entry)throw Error('Not exported '+element.id);
   let props=`position = Vector2(${entry.origin.join(',')})\ntexture = ${resourceId('Texture2D','res://art/'+element.runtime_file)}`;
   if(kind==='flex')props+=`\nscript = ${flex}\namplitude = ${element.amplitude}\nperiod = ${element.period}\nphase = ${element.phase}`;
   else props+=`\ncentered = false\nmetadata/pulse_period = ${element.period}.0\nmetadata/pulse_amplitude = ${element.amplitude}`;
   node(element.id,kind==='flex'?'MeshInstance2D':'Sprite2D',element.layer,props);
  }else if(kind==='fish')node(element.id,'Node2D',element.layer,`script = ${school}\nbounds = Rect2(${rect.join(',')})\npopulation = ${element.population}\nspecies = ${element.species}\nphase = ${element.phase}`);
  else if(kind==='bubbles')node(element.id,'Node2D',element.layer,`script = ${bubble}\nbounds = Rect2(${rect.join(',')})\npopulation = ${element.population}\nseed_id = ${Number(room.id.slice(-2))*23+rect[0]}\nexternal_clock = true\nbase_speed = 14.0\nbubble_opacity = 0.26\nsize_range = Vector2(2.4,6.2)`);
 }
 const text=`[gd_scene load_steps=${resource+sub.length+1} format=3]\n\n${ext.join('\n')}\n\n${sub.join('\n')}\n${nodes.join('\n')}`;
 fs.writeFileSync(`game/content/whalebelly/environment/chapter/${room.id}.tscn`,text);
 const target=`game/content/whalebelly/r1/${room.id}.tscn`;
 if(!fs.existsSync(`${room.master}/original-room.tscn.txt`))fs.copyFileSync(target,`${room.master}/original-room.tscn.txt`);
 let original=fs.readFileSync(target,'utf8');
 if(!original.includes('id="chapter"')){
  original=original.replace(/(\[gd_scene[^\]]+\])/,`$1\n\n[ext_resource type="PackedScene" path="res://content/whalebelly/environment/chapter/${room.id}.tscn" id="chapter"]`);
  original+='\n[node name="ChapterEnvironment" parent="." instance=ExtResource("chapter")]\n';
 }
 for(const name of ['Far','Middle','Foreground'])original=original.replace(new RegExp(`(\\[node name="${name}" type="Node2D" parent="\\."\\]\\r?\\n)`),'$1\nvisible = false\n');
 original=original.replace(/(\[node name="WorldOriginalPixels" type="Sprite2D" parent="World"\]\r?\n)/,'$1\nvisible = false\n');
 fs.writeFileSync(target,original);
 const manifestPath='game/art/manifest.json', manifest=JSON.parse(fs.readFileSync(manifestPath,'utf8'));
 const prefix=`r1-chapter-scenes/${room.id}/`;
 manifest.entries=manifest.entries.filter(e=>!e.dest.startsWith(prefix));
 for(const filename of fs.readdirSync(room.runtime).filter(n=>n.endsWith('.png')))manifest.entries.push({src:`${room.runtime}/${filename}`,dest:prefix+filename});
 fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n');
 console.log('Assembled',room.id,'without changing terrain, doors, actors, ability gates.');
}
