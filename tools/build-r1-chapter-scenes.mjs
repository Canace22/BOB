// Editable authored extraction/motion specification. Never changes terrain or room links.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const source='assets/source/r1-chapter-scenes', runtime='assets/runtime/sprites/r1-chapter-scenes';
if(fs.existsSync(`${source}/chapter.json`)&&!process.argv.includes('--rebuild-spec'))throw Error('Specifications already exist; edit the masters in place. Explicit --rebuild-spec is required to regenerate.');
const rooms=JSON.parse(fs.readFileSync('game/art/whalebelly/rooms.json','utf8'));
const boxes={
 'R1-02':{baleen:[[565,8,790,408]],vines:[[215,192,72,136],[1400,308,60,125]],fish:[[430,240,220,100],[1010,550,350,110]],bubbles:[[290,360,100,295],[730,310,105,295]],lamps:[]},
 'R1-03':{baleen:[[350,0,590,280],[1040,0,520,410]],vines:[[330,600,65,145],[1035,565,62,175]],fish:[[550,285,270,100],[1330,365,230,90]],bubbles:[[250,230,110,300],[700,275,130,300],[1250,330,100,240]],lamps:[[45,425,75,140],[1535,450,75,135]]},
 'R1-04':{baleen:[[310,25,525,365],[820,0,630,370]],vines:[[555,650,65,135],[1180,650,55,160]],fish:[[1000,300,230,90]],bubbles:[[520,320,110,290],[860,340,95,270],[1200,320,90,275]],lamps:[[25,530,84,130]]},
 'R1-05':{baleen:[],vines:[[545,600,80,115],[900,610,90,120]],fish:[],bubbles:[[245,205,110,355],[705,300,105,275],[1325,260,95,285]],lamps:[]},
 'R1-06':{baleen:[],vines:[[445,680,65,140],[970,385,65,150],[1080,400,60,155]],fish:[],bubbles:[[170,170,110,490],[700,420,90,360]],lamps:[[45,690,85,135]]},
 'R1-07':{baleen:[[200,30,410,350],[560,0,460,330],[1110,40,370,390],[700,630,380,280]],vines:[[465,340,60,125],[850,335,62,155],[1070,285,65,160]],fish:[[220,315,270,130],[700,310,250,100]],bubbles:[[240,290,90,420],[650,400,90,400],[1120,350,105,390]],lamps:[[35,410,85,125]]}
};
const spec={version:1,chapter:'R1',scope:'six already-designed rooms; R1-01 retained',rooms:[]};
for(const [id,layout] of Object.entries(boxes)){
 const room=rooms.find(r=>r.id===id), [w,h]=room.size;
 const dir=`${source}/master/${id}`;fs.mkdirSync(dir,{recursive:true});fs.mkdirSync(`${source}/originals/${id}`,{recursive:true});fs.mkdirSync(`${runtime}/${id}`,{recursive:true});
 for(const file of ['reference/r1/'+id+'.png','clean/'+id+'.png','clean/'+id+'-far.png']){
  const dest=`${source}/originals/${id}/${file.includes('-far')?'far':file.startsWith('clean')?'actors-removed':'reference'}.png`;
  if(!fs.existsSync(dest))fs.copyFileSync('game/art/whalebelly/'+file,dest);
 }
 const elements=[];
 const add=(suffix,kind,layer,rect,extra={})=>{const e={id:`${id}-${suffix}`,kind,layer,rect,status:kind==='static'?'static':'motion',evidence_basis:'observed artwork; timing proposed and tested in engine',collision:'none: decoration; authored world collision retained',interaction:'none: existing gameplay owned by campaign',sound:'none: preserve existing ambience',restore:'deterministic clock reset on room reload',...extra};elements.push(e);return e;};
 for(const [suffix,layer]of[['FAR','Far'],['CEILING-WALLS','Middle'],['ROAD-PLATFORMS','World'],['NEAR-FRAME','Foreground']])add(suffix,'static',layer,[0,0,w,h],{primary_method:'masked source pixels exported to PNG',alternative:'manual repaint only if a hidden surface fails',reason:'preserve contours/materials; no terrain deformation'});
 let n=0;
 for(const rect of layout.baleen){const name=`BALEEN-${++n}`;const [x,y,rw,rh]=rect;add(name,'flex','Middle',rect,{root:'top',amplitude:7,period:8+n*2,phase:n*.87,selector:'warm',primary_method:'tessellated bitmap mesh; pinned root and downstream phase delay',alternative:'painted frames/Krita',reason:'retain original pale strands and editable attachment; low amplitude water flow'});}
 n=0;for(const rect of layout.vines)add(`VINE-${++n}`,'flex','World',rect,{root:'top',amplitude:3,period:9+n,phase:1+n*.9,selector:'plant',primary_method:'same pinned mesh with reduced amplitude',alternative:'segmented bones baked to frames',reason:'attached hanging organic growth; rigid platform pixels excluded'});
 n=0;for(const rect of layout.fish)add(`FISH-${++n}`,'fish','Far',rect,{population:14+n*4,species:n%2,period:24,phase:n*1.7,primary_method:'existing 32-frame bitmap swim + independent bounded school path',alternative:'new painted swim cycle if silhouette mismatches',reason:'fish visible in source; avoid moving a static fish silhouette'});
 n=0;for(const rect of layout.bubbles)add(`BUBBLES-${++n}`,'bubbles','Middle',rect,{population:7,primary_method:'existing bitmap emitter, prewarmed bounded lifetimes and edge fade',alternative:'native particles using the same authored sprite',reason:'small slow waterborne bubbles; no new gameplay'});
 n=0;for(const rect of layout.lamps)add(`LAMP-${++n}`,'lamp','World',rect,{period:7+n,amplitude:.045,primary_method:'owned lamp pixel cutout and smooth intensity modulation',alternative:'PointLight2D with a matched bitmap falloff',reason:'preserve baked material highlights and warm focus without extra lamp copies'});
 add('WATER-LIGHT','water','Far',[w*.32,h*.29,w*.34,h*.27],{period:13,amplitude:.025,primary_method:'separate locally masked background-water pixels; subtle luminance drift',alternative:'local refraction only after surface mask approval',reason:'water is behind the platforms; no air shoreline or full-screen distortion'});
 const drawables=elements.filter(e=>['flex','lamp','water'].includes(e.kind));
 for(const [i,e]of drawables.entries()){
  e.mask_file=`${id}/${e.id}-mask.svg`;e.runtime_file=`r1-chapter-scenes/${id}/${e.id}.png`;
  const [x,y,rw,rh]=e.rect;
  // Editable selection; colors are ownership masks, never replacement scenery.
  fs.writeFileSync(`${dir}/${e.id}-mask.svg`,`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><rect width="100%" height="100%" fill="black"/><rect x="${x}" y="${y}" width="${rw}" height="${rh}" rx="${Math.min(18,rw/4)}" fill="white"/></svg>\n`);
  e.index=i;
 }
 const item={id,name:room.name,size:room.size,reference:`res://art/whalebelly/reference/r1/${id}.png`,source_clean:`res://art/whalebelly/clean/${id}.png`,clean_file:`${source}/generated/${id}-clean.png`,original_scene:`res://content/whalebelly/r1/${id}.tscn`,runtime:`${runtime}/${id}`,master:dir,elements,doors:room.doors,source_sha256:crypto.createHash('sha256').update(fs.readFileSync('game/art/whalebelly/reference/r1/'+id+'.png')).digest('hex')};
 spec.rooms.push(item);
 fs.writeFileSync(`${dir}/elements.json`,JSON.stringify(item,null,2)+'\n');
}
fs.writeFileSync(`${source}/chapter.json`,JSON.stringify(spec,null,2)+'\n');
console.log('Prepared six room manifests and editable ownership selections. Assets not yet accepted.');
