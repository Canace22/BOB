const fs=require('fs');
const sharp=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root='G:/鲸落万物生/BOB/work/anatomy-v52',out=root+'/diagrams';
const d=JSON.parse(fs.readFileSync(root+'/placement.json','utf8'));
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const C={R1:'#78c5c2',R2:'#a9c8bc',R3:'#cfad79',R4:'#b5a7ca',R5:'#8eb6df'};
const body='M70 105 C68 65 130 43 210 45 C310 45 370 53 410 48 C580 25 800 48 970 95 L1000 100 Q1060 62 1130 48 L1090 111 L1130 174 Q1060 164 1000 126 C850 193 450 205 220 160 Q110 150 70 124Z';
const text=(x,y,t,size=18,col='#c9dedb',extra='')=>`<text x="${x}" y="${y}" font-size="${size}" fill="${col}" ${extra}>${esc(t)}</text>`;
const X=p=>70+p*10.6;
function level(r){const id=r.id,p=(r.rangePercent[0]+r.rangePercent[1])/2;if(id==='R1-06')return {y:60,label:'头背：双喷气孔内缘'};if(id==='R1-07')return {y:91,label:'上颚：须根附着处'};if(id.startsWith('R1'))return {y:id==='R1-05'?112:124,label:'头腹侧：口腔／咽后'};if(id.startsWith('R2'))return ['R2-03','R2-04'].includes(id)?{y:142,label:'胸腔前腹侧：心包／心残壁'}:id==='R2-05'?{y:98,label:'前胸：气管旁／纵隔'}:{y:90,label:'胸腔背侧：肺表面／胸膜'};if(id.startsWith('R3'))return {y:id==='R3-08'?117:148,label:'腹腔：器官表面与折层'};if(id.startsWith('R4'))return {y:75+Math.max(0,p-55)*.75,label:'背外侧：椎旁通廊，非椎管'};if(Number(id.slice(-2))<=6)return {y:143,label:'头部侧下：耳骨周围，非耳蜗'};return {y:id==='R5-07'?133:132,label:id==='R5-07'?'远尾：尾柄外侧':'尾端：纤维尾鳍裂缘'};}
for(const r of d.rooms){const color=C[r.id.slice(0,2)],p=(r.rangePercent[0]+r.rangePercent[1])/2,spot=level(r),x=X(p),start=X(r.rangePercent[0]),width=Math.max(7,(r.rangePercent[1]-r.rangePercent[0])*10.6);
let s=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 340" role="img" aria-label="${esc(r.id+' '+r.name+'在鲸体中的部位')}与轴向位置"><defs><clipPath id="body"><path d="${body}"/></clipPath></defs><style>text{font-family:'Microsoft YaHei','Noto Sans CJK SC',sans-serif}</style><rect width="1200" height="340" rx="12" fill="#102630" stroke="#36535c"/>`;
s+=text(28,26,'全鲸定位 / 120m虚构巨须鲸 · 头左尾右 · 背上腹下',15,'#91aeb3');
s+=`<path d="${body}" fill="#243f49" stroke="#65838a" stroke-width="2"/><path d="M80 119Q180 135 275 127" fill="none" stroke="#65838a" stroke-width="2"/><g clip-path="url(#body)"><rect x="${start}" y="35" width="${width}" height="165" fill="${color}" opacity=".16"/><ellipse cx="${x}" cy="${spot.y}" rx="${Math.max(11,width/2)}" ry="16" fill="${color}" opacity=".32" stroke="${color}" stroke-width="2"/></g><circle cx="${x}" cy="${spot.y}" r="7" fill="${color}" stroke="#d7e5db" stroke-width="2"/>`;
const labelY=spot.y<110?spot.y+37:spot.y-30,anchor=x>900?'end':x<300?'start':'middle',labelX=x>900?x-14:x<300?x+14:x;
s+=text(labelX,labelY,spot.label,17,color,`text-anchor="${anchor}"`);
s+=`<path d="M70 209H1130" stroke="#4c6971" stroke-width="1.5"/>`;
for(const n of [0,20,40,60,80,100])s+=`<path d="M${X(n)} 205v8" stroke="#718c91"/>`+text(X(n),232,n+'%',13,'#829fa5','text-anchor="middle"');
s+=`<path d="M${start} 209h${width}" stroke="${color}" stroke-width="5"/>`;
s+=text(28,270,r.id+' '+r.name+' ｜ '+r.part,22,color);
s+=text(28,302,r.position+'；轴向投影定位，不是精确碰撞足迹。',17,'#adc3c5');
s+='</svg>';fs.writeFileSync(out+'/room-locator-'+r.id+'.svg',s);}
(async()=>{for(const id of ['R1-06','R5-07'])await sharp(out+'/room-locator-'+id+'.svg').png().toFile(out+'/room-locator-'+id+'.png');console.log('36 SVG room locators and 2 PNG proofs written');})();
