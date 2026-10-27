import {mkdir,writeFile,readFile} from 'node:fs/promises';
import {pathToFileURL,fileURLToPath} from 'node:url';
import path from 'node:path';
const out=path.resolve(process.env.ASSET_OUTPUT_DIR || path.join(path.dirname(fileURLToPath(import.meta.url)), 'native-exports'));
const bone='#e5d3af', dark='#142d38', blue='#8bc4d4', amber='#edb55f', teal='#6fa99d';
const assets=[];
const line=(d,color=bone,width=7)=>`<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round"/>`;
const circle=(x,y,r,fill='none',stroke=bone,width=6)=>`<circle cx="${x}" cy="${y}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${width}"/>`;
const rect=(x,y,w,h,r,fill='none',stroke=bone,width=5)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${width}"/>`;
function add(id,name,covers,content,options={}){assets.push({id,name,kind:options.kind||'ui',coversRequirementIds:covers,content,size:options.size||128,view:options.view||128,...options});}
function icon(id,name,covers,content){add(id,name,covers,`<g stroke-linecap="round" stroke-linejoin="round">${content}</g>`);}
const allPanels=['ui-map','ui-module-camp','ui-pause-settings','ui-travel-selection','ui-dialogue-memory'];
add('ui-panel-frame','骨白界面边框',allPanels,rect(8,8,496,496,27,'#112833ee',dark,10)+rect(8,8,496,496,27,'none',bone,5),{size:512,view:512,nineSlice:[36,36,36,36]});
add('ui-slot-frame','模块槽边框',['ui-module-camp'],rect(9,9,110,110,17,'#0c202bd9','#68858a',5),{nineSlice:[25,25,25,25]});
add('ui-slot-selected','模块选中边框',['ui-module-camp'],rect(9,9,110,110,17,'#0c202bd9',amber,6)+rect(15,15,98,98,12,'none','#c78c3e',1.5),{nineSlice:[25,25,25,25]});
add('ui-keycap','可重绑定按键底框',['ui-interaction','ui-pause-settings'],rect(14,19,100,90,13,'#1b3540dd',bone,5),{nineSlice:[30,32,30,32]});
add('ui-slider-track','设置滑杆轨道',['ui-pause-settings'],rect(8,52,240,24,12,'#75858b','#253d48',3),{size:256,view:256,height:128,viewHeight:128,nineSlice:[20,0,20,0]});
add('ui-slider-thumb','设置滑杆滑块',['ui-pause-settings'],circle(64,64,27,dark,dark,8)+circle(64,62,23,bone,'#f3e8cf',3));
icon('ui-map-player','地图当前位置',['ui-map','ui-travel-selection'],circle(58,64,31,'none',amber,7)+circle(58,64,19,amber,amber,2)+`<path d="M88 54L110 64 88 74Z" fill="${amber}" stroke="${dark}" stroke-width="4"/>`);
icon('ui-map-camp','地图壳营地',['ui-map','ui-travel-selection'],`<path d="M28 55Q27 29 45 35Q49 18 63 27Q78 17 84 35Q104 28 104 53L77 96H53Z" fill="${bone}" stroke="${dark}" stroke-width="5"/>`+line('M39 45L61 89M57 35L65 89M76 34L69 89M92 44L73 89',dark,3)+line('M51 101H79',bone,5));
icon('ui-map-travel','地图调律节点',['ui-map','ui-travel-selection'],circle(64,64,39,'none',bone,4)+circle(64,64,25,'none',amber,6)+circle(64,64,9,amber,amber,2));
icon('ui-map-door','地图未达门',['ui-map'],line('M36 102V27Q64 13 92 27V102',bone,7)+line('M51 91V37L79 32V93',teal,4)+circle(70,64,3,bone,bone,1));
icon('ui-map-memory','地图记忆标记',['ui-map','ui-dialogue-memory'],`<path d="M39 20L84 27 100 92 47 108 25 56Z" fill="${dark}" stroke="${bone}" stroke-width="5"/>`+line('M48 48Q66 33 79 48M44 65Q67 47 84 64M48 82Q68 65 86 80',blue,4));
const gear=Array.from({length:24},(_,i)=>{const a=i*Math.PI/12,r=i%4<2?43:34;return `${64+Math.cos(a)*r},${64+Math.sin(a)*r}`}).join(' ');
icon('ui-setting-gear','设置符号',['ui-pause-settings'],`<polygon points="${gear}" fill="${bone}"/>`+circle(64,64,16,dark,dark,2));
icon('ui-setting-volume','音量符号',['ui-pause-settings'],`<path d="M23 49H42L65 29V99L42 79H23Z" fill="${bone}"/>`+line('M81 47Q99 64 81 81M94 32Q123 64 94 96',bone,6));
icon('ui-setting-music','音乐符号',['ui-pause-settings'],line('M43 89V35L96 25V79',bone,8)+line('M43 47L96 37',bone,7)+`<ellipse cx="31" cy="92" rx="17" ry="12" fill="${bone}"/><ellipse cx="84" cy="82" rx="17" ry="12" fill="${bone}"/>`);
icon('ui-setting-brightness','亮度符号',['ui-pause-settings'],circle(64,64,21,bone,bone,2)+Array.from({length:8},(_,i)=>{const a=i*Math.PI/4;return line(`M${64+34*Math.cos(a)} ${64+34*Math.sin(a)}L${64+47*Math.cos(a)} ${64+47*Math.sin(a)}`,bone,6)}).join(''));
icon('ui-setting-controller','手柄符号',['ui-pause-settings'],`<path d="M35 39Q64 45 93 39Q108 40 115 91Q115 111 95 93L82 80H46L32 94Q12 111 14 90Q20 41 35 39Z" fill="${bone}" stroke="${dark}" stroke-width="5"/>`+line('M39 51V73M28 62H50',dark,5)+circle(88,56,4,dark,dark,1)+circle(100,67,4,dark,dark,1));
const life=`<path d="M64 18C89 33 101 59 92 84Q85 107 64 111Q43 107 36 84C27 59 39 33 64 18Z"`;
icon('ui-life-full','生命格·充盈',['ui-life'],life+` fill="${amber}" stroke="${bone}" stroke-width="5"/>`+line('M64 89V47M64 73Q42 67 49 56M64 64Q85 58 80 47',bone,4));
icon('ui-life-empty','生命格·空',['ui-life'],life+` fill="${dark}" stroke="#71898d" stroke-width="5"/>`+line('M64 91V48', '#56757b',3));
icon('ui-resonance-full','蓄振格·充盈',['ui-resonance','ui-module-camp'],line('M39 29V56Q39 80 64 80Q89 80 89 56V29',bone,9)+line('M64 80V109',bone,9)+line('M24 31Q14 55 25 75M104 31Q114 55 103 75',blue,4));
icon('ui-resonance-empty','蓄振格·空',['ui-resonance'],line('M39 29V56Q39 80 64 80Q89 80 89 56V29M64 80V109','#607c84',7));
icon('ui-pressure-full','浮膜余压·充盈',['ui-pressure'],circle(64,64,40,'#32687e',blue,5)+line('M40 76Q64 46 88 76M49 85Q64 66 79 85',bone,5)+circle(49,43,5,'#e5f3f3','none',0));
icon('ui-pressure-empty','浮膜余压·空',['ui-pressure'],circle(64,64,40,dark,'#607c84',5)+line('M40 76H88','#607c84',5));
icon('ui-ability-dash','能力·贴流冲',['ui-progression'],line('M20 46H72M14 65H65M25 84H72',blue,6)+line('M70 32L105 65 70 97',bone,8));
icon('ui-ability-float','能力·浮膜',['ui-progression'],`<path d="M24 73Q23 27 64 21Q105 27 104 73Q90 57 80 73Q64 53 48 73Q37 57 24 73Z" fill="#396c7d" stroke="${bone}" stroke-width="5"/>`+line('M42 83Q37 99 43 108M64 83V111M86 83Q92 98 86 108',blue,4));
icon('ui-ability-anchor','能力·锚定',['ui-progression'],circle(64,39,23,'none',bone,7)+line('M64 62V104M43 92L64 108 85 92',amber,7));
icon('ui-ability-parry','能力·迎珠',['ui-progression'],circle(64,62,24,'#b5c8cb',bone,5)+circle(64,62,40,'none',blue,3)+line('M38 112L50 94M79 30L93 14',amber,5));
icon('ui-ability-fissure','能力·敛膜潜隙',['ui-progression'],line('M47 20Q15 64 47 108M81 20Q113 64 81 108',bone,7)+line('M42 64H86M70 49L87 64 70 79',blue,6));
icon('ui-progress-pressure','进度·潮压稳定P',['ui-progression'],line('M24 40Q44 23 64 40T104 40M24 65Q44 48 64 65T104 65M24 90Q44 73 64 90T104 90',blue,6));
icon('ui-progress-bone','进度·骨音调律B',['ui-progression'],line('M47 30Q64 17 81 30V76Q64 87 47 76ZM64 83V107',bone,7)+line('M25 43Q13 62 25 81M103 43Q115 62 103 81',amber,4));
icon('ui-progress-silence','进度·安全静默S',['ui-progression'],circle(64,64,38,'none',bone,5)+circle(64,64,8,teal,teal,2));
icon('ui-motion-slot','运动槽标记',['ui-module-camp'],`<path d="M89 19Q56 31 38 52Q30 72 23 105L42 92 56 101 70 83 84 91Q88 58 104 38Z" fill="${teal}" stroke="${bone}" stroke-width="4"/>`+line('M72 43L45 81',blue,3));
icon('ui-valve-three-ticks','导流阀三档刻线',['settlement-valve'],line('M22 50L38 60M56 24V43M97 44L83 56',bone,6));
const fx=(id,name,covers,content,units=2)=>add(id,name,covers,content,{kind:'effect',size:256,view:128,scale:{axis:'width',units}});
fx('fx-short-swipe','短击弧线',['fx-resonance'],line('M24 102Q105 94 106 25',bone,7)+line('M31 99Q92 79 104 31',blue,3),1.8);
fx('fx-heavy-ring','重鸣共振环',['fx-resonance'],circle(64,64,47,'none',bone,4)+circle(64,64,36,'none',blue,2)+circle(64,64,21,'none','#8fbdccaa',1.5),3);
fx('fx-dash-trail','贴流冲拖线',['fx-dash-membrane'],line('M13 35Q60 48 113 42M7 63Q57 72 119 60M20 95Q62 89 112 82',blue,4)+line('M37 50L98 52M43 79L106 74',bone,2),2.2);
fx('fx-pearl-rings','鸣贝三圈预告',['fx-pearl-telegraph'],circle(64,64,48,'none',bone,2)+circle(64,64,36,'none',blue,3)+circle(64,64,24,'none',bone,2),2.3);
fx('fx-parry-spark','迎珠回击闪线',['fx-pearl-telegraph'],line('M64 14V36M64 92V114M14 64H36M92 64H114M28 28L43 43M85 85L100 100M28 100L43 85M85 43L100 28',amber,5)+circle(64,64,18,'none',bone,5),1.3);
fx('fx-danger-line','危险方向标带',['fx-danger-telegraph'],line('M10 64H114','#edaa79',6)+line('M90 43L114 64 90 85','#edaa79',6),4);
fx('fx-danger-landing','落点预告椭圆',['fx-danger-telegraph'],`<ellipse cx="64" cy="77" rx="51" ry="20" fill="none" stroke="#edaa79" stroke-width="4" stroke-dasharray="12 7"/>`+line('M64 16V48M53 37L64 49 75 37',bone,5),3);
fx('fx-echo-open-ring','旧位空心回声圈',['fx-echo-ring'],`<path d="M108 41A49 49 0 1 1 90 22" fill="none" stroke="${blue}" stroke-width="4"/>`+`<path d="M97 45A36 36 0 1 1 80 31" fill="none" stroke="#d7d6d7" stroke-width="2"/>`,2);
fx('fx-silence-ring','静默合拢圈',['fx-echo-ring'],circle(64,64,45,'none',bone,4)+circle(64,64,36,'none','#89b9b0aa',1.5),2);
fx('fx-fissure-outline','柔膜缝双瓣提示',['fx-fissure-warning'],line('M58 10Q9 61 58 118M70 10Q119 61 70 118',blue,4),1.8);
const gradient='<defs><radialGradient id="soft"><stop stop-color="white" stop-opacity=".95"/><stop offset=".35" stop-color="white" stop-opacity=".5"/><stop offset="1" stop-color="white" stop-opacity="0"/></radialGradient><radialGradient id="amber"><stop stop-color="#ffd78c" stop-opacity=".8"/><stop offset=".3" stop-color="#efb251" stop-opacity=".25"/><stop offset="1" stop-color="#d38934" stop-opacity="0"/></radialGradient><linearGradient id="beam" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#b8e4f6" stop-opacity=".5"/><stop offset="1" stop-color="#7ba3c2" stop-opacity="0"/></linearGradient></defs>';
fx('fx-particle-soft','水下软光粒子',['fx-underwater-atmosphere'],gradient+circle(64,64,55,'url(#soft)','none',0),.12);
fx('fx-particle-drift','定向流粒',['fx-underwater-atmosphere'],`<ellipse cx="64" cy="64" rx="35" ry="4" fill="${blue}" fill-opacity=".65"/>`,.3);
fx('fx-cold-beam','水下冷光遮罩',['fx-underwater-atmosphere'],gradient+`<path d="M50 0H66L121 128H3Z" fill="url(#beam)"/>`,8);
fx('fx-fungus-glow','密封菌光遮罩',['fx-underwater-atmosphere','fx-habitat-response'],gradient+circle(64,64,62,'url(#amber)','none',0),2.5);
fx('fx-water-mist','水雾遮罩',['fx-underwater-atmosphere'],gradient+`<ellipse cx="64" cy="64" rx="63" ry="30" fill="url(#soft)" fill-opacity=".15"/>`,8);
fx('fx-hit-burst','受击短闪',['fx-hit-recovery'],`<path d="M64 12L72 47 105 28 84 57 119 67 84 76 98 107 72 84 61 119 54 82 24 105 45 75 10 62 46 55 29 23 56 45Z" fill="#e9dac0" fill-opacity=".8"/>`,1.2);
fx('fx-recovery-motes','调息恢复微光',['fx-hit-recovery','fx-habitat-response'],[ [30,85,5],[59,49,7],[82,90,4],[98,31,3],[36,28,2],[65,109,3] ].map(([x,y,r])=>circle(x,y,r,'#e4c58d','none',0)).join(''),1.8);
const waterProfiles=[
 ['r1-water-base','须门独立水体底层','R1','#0b2638','#113d55','#061725','06_R1.png'],
 ['r2-water-base','肺心独立水体底层','R2','#153b4c','#29566b','#0a202d','14_R2.png'],
 ['r3-water-base','胃肠独立水体底层','R3','#263c38','#3c5140','#121f21','21_R3.png'],
 ['r4-water-base','断脊独立水体底层','R4','#0d303b','#28505a','#071d29','30_R4.png'],
 ['r5-head-water-base','头耳独立水体底层','R5头','#152c43','#314b61','#091928','38_R5-head.png'],
 ['r5-tail-water-base','远尾独立水体底层','R5尾','#174552','#36737b','#0b2a3b','39_R5-tail.png']
];
for(const [id,name,region,top,mid,bottom,reference] of waterProfiles) add(id,name,['scene-water-depth'],`<defs><linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop stop-color="${top}"/><stop offset=".4" stop-color="${mid}"/><stop offset="1" stop-color="${bottom}"/></linearGradient><filter id="grain"><feTurbulence type="fractalNoise" baseFrequency=".008 .012" numOctaves="3" seed="31"/><feColorMatrix type="saturate" values="0"/></filter></defs><rect width="1536" height="864" fill="url(#water)"/><rect width="1536" height="864" filter="url(#grain)" opacity=".035"/>`,{kind:'background',region,size:1536,height:864,view:1536,viewHeight:864,scale:{axis:'width',units:32,space:'canvas'},layer:'L0',atlasEligible:false,parallax:.10,referenceFiles:[reference]});
await mkdir(path.join(out,'svg'),{recursive:true});
const modulePath=process.env.PLAYWRIGHT_MODULE;
const {chromium}=await import(modulePath ? pathToFileURL(path.resolve(modulePath)).href : 'playwright');
const browser=await chromium.launch({headless:true});
const exported=[];
try {
 const page=await browser.newPage();
 for(const asset of assets) {
  const source=`<svg xmlns="http://www.w3.org/2000/svg" width="${asset.size}" height="${asset.height||asset.size}" viewBox="0 0 ${asset.view} ${asset.viewHeight||asset.view}">${asset.content}</svg>`;
  const svgFile=path.join(out,'svg',asset.id+'.svg');const file=path.join(out,asset.id+'.png');await writeFile(svgFile,source);
  const data=await page.evaluate(async({source,size,height})=>{const image=new Image();image.src='data:image/svg+xml;base64,'+btoa(source);await image.decode();const c=document.createElement('canvas');c.width=size;c.height=height;c.getContext('2d').drawImage(image,0,0);return c.toDataURL('image/png').split(',')[1]}, {source,size:asset.size,height:asset.height||asset.size});
  await writeFile(file,Buffer.from(data,'base64'));
  const {content,view,...metadata}=asset;
  exported.push({...metadata,file,sourceFile:svgFile,method:asset.kind==='background'?'按对应区域配色的原生SVG渐变与低频噪声，独立L0水体，无器官景物；Chromium导出PNG。':'可编辑SVG原生绘制，按I02骨白/海蓝符号风格；Chromium导出PNG。',region:asset.region||'全局',world:asset.scale||null,pivotSuggestion:{type:'center',pixel:[asset.size/2,(asset.height||asset.size)/2]},referenceFiles:asset.referenceFiles||['53_I02_地图·营地·暂停.png'],qa:{status:'candidate',pending:['图标实际尺寸与深浅底检查']},notes:asset.kind==='background'?'独立L0水体，配合透明L1器官层，建议视差系数0.10；静态底层，不含光束/流粒动画。':asset.kind==='effect'?'静态纹理；时间、轨迹和发射规则在后续接入阶段实现。':'静态图形，动态文字、布局、数值和按键由界面代码负责。'});
 }
}finally{await browser.close();}
await writeFile(path.join(out,'vector-manifest.json'),JSON.stringify({assets:exported},null,2)+'\n');
await writeFile(path.join(out,'plan.json'),JSON.stringify({assets:exported.map(({id,name,coversRequirementIds})=>({id,name,coversRequirementIds}))},null,2)+'\n');
console.log(JSON.stringify({nativeStaticAssets:exported.length}));
