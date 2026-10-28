const fs=require('fs'),path=require('path');
const sharp=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root='G:/鲸落万物生/BOB/work/anatomy-v52',out=root+'/diagrams';fs.mkdirSync(out,{recursive:true});
const data=JSON.parse(fs.readFileSync(root+'/placement.json','utf8'));
const C={bg:'#0b1c25',panel:'#122b36',line:'#335460',text:'#d2e1dd',muted:'#88a6ad',gold:'#d8bd82',natural:'#7bced3',damage:'#df9c67',built:'#e17f79',R1:'#78c5c2',R2:'#a9c8bc',R3:'#cfad79',R4:'#b5a7ca',R5:'#8eb6df'};
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const text=(x,y,s,size=22,fill=C.text,extra='')=>`<text x="${x}" y="${y}" font-size="${size}" fill="${fill}" ${extra}>${esc(s)}</text>`;
const rect=(x,y,w,h,fill=C.panel,stroke=C.line,rx=14)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="${fill}" stroke="${stroke}" stroke-width="2"/>`;
const line=(x1,y1,x2,y2,color=C.natural,width=4,extra='')=>`<path d="M${x1},${y1}L${x2},${y2}" fill="none" stroke="${color}" stroke-width="${width}" ${extra}/>`;
const arrow=(x1,y1,x2,y2,color='natural')=>line(x1,y1,x2,y2,C[color]||color,4,`marker-end="url(#${color})"`);
const wrap=(s,n)=>{const a=[];for(let i=0;i<s.length;i+=n)a.push(s.slice(i,i+n));return a};
const para=(x,y,s,n=38,size=21,color=C.muted)=>wrap(s,n).map((t,i)=>text(x,y+i*(size+12),t,size,color)).join('');
const start=(w,h,title,sub)=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" role="img" aria-label="${esc(title)}"><defs>${['natural','damage','built'].map(c=>`<marker id="${c}" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0 0L10 5L0 10Z" fill="${C[c]}"/></marker>`).join('')}</defs><style>text{font-family:'Microsoft YaHei','Noto Sans CJK SC',sans-serif}a:hover rect{stroke:#fff}a:focus rect{stroke:#fff}</style><rect width="${w}" height="${h}" fill="${C.bg}"/>${text(60,64,'WHALEFALL / ANATOMICAL PLACEMENT',18,C.muted,'letter-spacing="4"')}${text(60,120,title,44)}${text(60,164,sub,22,C.muted)}`;
const save=(name,s)=>fs.writeFileSync(out+'/'+name+'.svg',s+'</svg>');
function whale(x=0,y=0,s=1,fill='#203d49'){return `<g transform="translate(${x} ${y}) scale(${s})"><path d="M90 260 C85 175 155 140 260 135 C355 130 410 149 470 145 C700 90 1030 130 1310 240 L1400 250 Q1470 185 1600 155 L1535 270 L1595 370 Q1480 355 1400 300 C1170 465 610 470 280 375 Q140 355 90 300Z" fill="${fill}" stroke="#62838b" stroke-width="3"/><path d="M105 285Q225 310 340 294M300 388Q350 440 448 430L410 387" fill="none" stroke="#62838b" stroke-width="3"/></g>`}
function tag(x,y,w,label,color){return rect(x,y,w,40,'#102832',color,7)+text(x+w/2,y+27,label,19,color,'text-anchor="middle"');}
let svg=start(1800,2430,'鲸体总地图 · 关卡在什么部位','120 m 虚构古代巨须鲸 / 主角 0.30 m / 鼻端 0 → 尾端 120 m / 背上腹下');
svg+=rect(45,200,1710,680)+whale(30,145,1.04);
const X=m=>125+m/120*1570;
// Spatial anatomy: outer cavity routes, not generic tunnels inside every organ.
svg+=`<path d="M${X(28)} 355 Q${X(48)} 315 ${X(80)} 365L${X(100)} 424" fill="none" stroke="#b2bdad" stroke-width="18" stroke-dasharray="18 10" opacity=".75"/>`;
svg+=`<path d="M${X(29)} 397Q${X(50)} 355 ${X(82)} 408" fill="none" stroke="${C.R4}" stroke-width="7"/>`;
svg+=`<ellipse cx="${X(42)}" cy="450" rx="160" ry="73" fill="#527b86" opacity=".8"/><ellipse cx="${X(36)}" cy="510" rx="70" ry="50" fill="#84515b" opacity=".95"/><path d="M${X(55)} 378Q${X(52)} 510 ${X(54)} 650" fill="none" stroke="${C.gold}" stroke-width="8" stroke-dasharray="14 10"/><ellipse cx="${X(59)}" cy="515" rx="95" ry="50" fill="#826348"/><path d="M${X(65)} 435 C${X(77)} 375 ${X(81)} 430 ${X(73)} 463 S${X(66)} 525 ${X(78)} 520" fill="none" stroke="#7b7550" stroke-width="38"/><ellipse cx="${X(24)}" cy="515" rx="33" ry="20" fill="#8494ac" stroke="${C.R5}" stroke-width="4"/>`;
svg+=`<path d="M${X(23)} 295l5 -26m15 24l5 -26" stroke="${C.natural}" stroke-width="10"/><path d="M${X(23)} 305Q${X(29)} 333 ${X(33)} 420" fill="none" stroke="${C.natural}" stroke-width="7"/><path d="M${X(26)} 470Q${X(38)} 425 ${X(54)} 493" fill="none" stroke="${C.R1}" stroke-width="8"/>`;
for(let n=7;n<=21;n+=1.4)svg+=line(X(n),402+(n-7)*.9,X(n),477+(n-7)*1.1,C.R1,3);
svg+=tag(102,650,285,'R1 口腔与咽后 · 0–27%',C.R1)+line(250,650,X(14),470,C.R1,2);
svg+=tag(500,715,305,'R2 胸腔 · 27–46%',C.R2)+line(650,715,X(41),550,C.R2,2);
svg+=tag(830,715,305,'R3 腹腔 · 45–66%',C.R3)+line(980,715,X(59),565,C.R3,2);
svg+=tag(1060,275,430,'R4 椎旁外廊 · 连通带 28–82%',C.R4)+line(1100,315,X(65),382,C.R4,2);
svg+=tag(120,735,345,'R5 耳周创伤区 · 18–26%',C.R5)+line(310,735,X(24),535,C.R5,2);
svg+=tag(1320,635,360,'R5 尾柄与尾鳍 · 83–100%',C.R5)+line(1450,635,X(104),490,C.R5,2);
svg+=text(425,250,'头背侧：双喷气孔',21,C.natural)+line(510,260,X(24),288,C.natural,2);
svg+=text(660,430,'肺：胸腔背侧',19)+text(515,517,'心包 / 心残壁',17)+text(815,395,'横膈',19,C.gold)+text(842,524,'前胃',20)+text(1030,521,'回折肠袢',19)+text(1420,525,'纤维尾鳍，无新骨架',18,C.R5);
svg+=text(75,825,'地理位置是轴向投影；房间沿器官表面、侧层与回折路径展开，不是36个盒子首尾拼接。',23,C.muted);
svg+=line(X(0),925,X(120),925,C.muted,2);
for(let m=0;m<=120;m+=20)svg+=line(X(m),916,X(m),934,C.muted,2)+text(X(m),960,m+' m',19,C.muted,'text-anchor="middle"');
svg+=text(60,1020,'36 房位置索引',32)+text(60,1057,'短条为该房的轴向落位带；不是房间碰撞足迹。点击房号可打开逐房原画。',21,C.muted);
const groups=[['R1','须门遗港',data.rooms.filter(r=>r.id.startsWith('R1'))],['R2','肺心潮庭',data.rooms.filter(r=>r.id.startsWith('R2'))],['R3','胃肠沉城',data.rooms.filter(r=>r.id.startsWith('R3'))],['R4','鸣肋断脊',data.rooms.filter(r=>r.id.startsWith('R4'))],['R5','耳海头段',data.rooms.filter(r=>r.id.startsWith('R5')&&Number(r.id.slice(-2))<=6)],['R5','远端尾根',data.rooms.filter(r=>r.id.startsWith('R5')&&Number(r.id.slice(-2))>=7)]];
groups.forEach(([id,title,rs],i)=>{const xx=60+(i%3)*580,yy=1100+Math.floor(i/3)*620;svg+=rect(xx,yy,540,580)+text(xx+22,yy+43,id+' '+title,27,C[id]);rs.forEach((r,j)=>{const ry=yy+65+j*61;svg+=`<a href="../原画册.html#room-${r.id}">`+rect(xx+14,ry,512,54,'#173440','#2c4c58',6)+text(xx+24,ry+24,r.id+' '+r.name,19,C.text)+line(xx+24,ry+42,xx+355,ry+42,'#36535d',5)+line(xx+24+r.rangePercent[0]*3.31,ry+42,xx+24+r.rangePercent[1]*3.31,ry+42,C[id],7)+text(xx+506,ry+44,r.rangePercent.join('–')+'%',16,C.muted,'text-anchor="end"')+'</a>';});if(rs.length<5)svg+=para(xx+24,yy+245,'头耳与尾根之间不存在直接房门。经R4-06沿椎旁向头或向尾行进；骨音旅行必须已亲访并调律。',24,22,C.text);});
svg+=text(60,2360,'真实蓝鲸约30m级；120m为本IP幻想尺度。耳区在后颅底侧下方，肺心与消化道不天然互通。',21,C.gold);
save('总地图_鲸体落位',svg);

// Connection cross-sections: icons show tissue boundaries, routes distinguish their cause.
let tr=start(1800,1920,'连接剖面 · 为什么能抵达下一关','蓝：天然腔道走向 / 橙：死后破口与剥离 / 红：聚落修补、锚环与开闩');
const panels=[
['E05','口咽 → 食管 → 前胃',['口咽','食管纵裂边','横膈食管裂孔','前胃'],['natural','damage','natural'],'食管方向天然相续，通行宽度由死后纵裂边提供；不把健康食管扩大成宫殿。'],
['E10','胃外侧 → 横膈旧伤 → 肺后缘',['胃壁外缘','胃壁旧破口','横膈旧撕裂','肺后缘胸膜'],['damage','damage','built'],'跨越消化器官与胸腔的隔界，必须显示胃壁与横膈两道受损边界；不是胃的天然分叉。'],
['E17','回折肠袢 → 胃侧回程',['回折肠袢','系膜维护坡','前胃外壁破口','胃枢'],['natural','built','damage'],'肠袢向头回弯后与胃外壁邻近。旧称“食道闩”仅是旧名，不是肠管天然接食管。'],
['E18','腹腔背侧 → 椎旁外廊',['胃外侧','腹背创伤口','椎体外缘','固定闸'],['damage','damage','built'],'沿外露椎体和肌腱面通行；P稳定海水流、A3拉聚落闸。路线不在椎管或骨髓里。'],
['E25','腰尾分流 → 向头长回廊',['后腰 / 腰尾','椎旁向头60–70m','颈后 / 枕骨侧','耳周创伤区'],['built','natural','damage'],'头耳不是分流台旁边的一间房。用连续椎列与头向过渡镜头交代长距离，不新增战斗房。'],
['E34','前胸回流 → 喉 / 鼻道 → 喷气孔',['心包侧破口','气管旁 / 喉遗迹','鼻道纵裂台','头顶双孔内缘'],['damage','natural','built'],'先从心区退到纵隔与气管旁，再沿呼吸道方向上行。没有心室直接长到头顶的气柱。']
];
panels.forEach(([id,title,nodes,colors,desc],i)=>{const xx=60+(i%2)*870,yy=220+Math.floor(i/2)*475;tr+=rect(xx,yy,810,440)+text(xx+24,yy+42,id+'  '+title,26,C.gold);
 const boxes=nodes.map((n,j)=>({x:xx+25+j*190,y:yy+145,w:165,h:86,n}));
 // Tissue silhouettes surrounding channels, each annotated rather than pretending a universal pipe.
 tr+=`<path d="M${xx+26} ${yy+100}Q${xx+180} ${yy+65} ${xx+320} ${yy+105}T${xx+780} ${yy+105}L${xx+780} ${yy+275}Q${xx+600} ${yy+305} ${xx+420} ${yy+270}T${xx+26} ${yy+275}Z" fill="#29414a" stroke="#587079" stroke-width="2"/>`;
 boxes.forEach((b,j)=>{tr+=rect(b.x,b.y,b.w,b.h,'#102832','#627b80',24);tr+=wrap(b.n,7).map((t,k)=>text(b.x+b.w/2,b.y+34+k*25,t,20,C.text,'text-anchor="middle"')).join('');if(j<3){const col=colors[j];tr+=arrow(b.x+b.w+2,b.y+43,boxes[j+1].x-5,b.y+43,col);if(col==='damage')tr+=`<path d="M${b.x+b.w+5} ${b.y-16}l8 15l-8 15l8 15l-8 15l8 15l-8 15" fill="none" stroke="${C.damage}" stroke-width="3"/>`;}});
 tr+=para(xx+26,yy+325,desc,33,21,C.muted);
 });
tr+=rect(60,1670,1680,165)+text(87,1712,'补充 E31 / 尾向过渡约15–20m',27,C.R5)+para(87,1754,'从R4-06沿渐细尾椎外缘前进到R5-07尾柄窝；继续R5-08穿纤维尾鳍裂缘到外海。尾鳍瓣没有新骨架。',65,22,C.text);
tr+=text(60,1880,'关系类型是本轮关卡设计解释；实际鲸体不是开放空洞迷宫。米数为幻想世界布局估算。',21,C.gold);
save('连接剖面_六个关键转场',tr);

let scale=start(1800,1600,'尺度与镜头 · 巨鲸不是小房间集合','固定尺寸：虚构鲸长120m = 400U；拾潮者身高0.30m = 1U');
scale+=rect(60,220,1680,500)+whale(85,230,.95);
scale+=line(170,680,1600,680,C.gold,3)+line(170,665,170,695,C.gold,3)+line(1600,665,1600,695,C.gold,3)+text(885,661,'120 m / 400 U',26,C.gold,'text-anchor="middle"');
// one-unit is actually 1/400 body length in this meter-scale panel, clearly too small for identity.
scale+=`<rect x="219.4" y="623.2" width="1.2" height="3.6" fill="#f1c772"/>`+text(243,630,'同尺主角仅约3.6px高，不能靠放大主角表现巨鲸。',20,C.muted);
scale+=rect(60,770,800,430)+text(86,815,'局部游玩镜头',30,C.text);
scale+=rect(100,850,720,290,'#173440','#526f76',0);
scale+=`<path d="M110 1050H320v-40H530v25H810" fill="none" stroke="#b1d3cb" stroke-width="6"/><path d="M140 900Q450 790 770 920" fill="none" stroke="#3d5864" stroke-width="16"/><circle cx="390" cy="997" r="3" fill="#ddd6bf"/><path d="M390 1000v7l-4 3m4 -3l4 3" fill="none" stroke="#8ebbb9" stroke-width="4"/>`;
scale+=text(120,1105,'镜头约5–8m高 → 主角占高约4–6%',22,C.gold)+text(87,1170,'单房宽约7.2–14.4m；局部可玩边清楚，远景曲面继续延伸。',20,C.muted);
scale+=rect(900,770,840,430)+text(928,815,'角色身份放大框 · 与左图不同比例',29,C.text);
scale+=`<circle cx="1080" cy="931" r="45" fill="#d8d2bb"/><circle cx="1090" cy="928" r="24" fill="#182d35"/><path d="M1055 972L1025 1050L1105 1038L1120 980Z" fill="#417579"/><path d="M1067 1027v38l-22 7m47 -42v33l22 5" stroke="#729498" stroke-width="12" fill="none"/><circle cx="1060" cy="1005" r="12" fill="#dca14d"/>`;
scale+=para(1195,910,'圆潜水盔、单暗镜、青短披风与单腰灯锁定身份。此框只用于辨识角色；不能拿放大框的角色去量鲸体。',21,23,C.muted);
scale+=rect(60,1250,1680,250)+text(86,1298,'地图总宽 ≠ 鲸体总长',32,C.gold)+para(86,1346,'36房横向宽度合计1235U，即370.5m。路线分布在不同器官表面、前后侧层、折返肠袢与分支中；不能把它们一字拼接，也不能将示意图当成精确碰撞总图。',67,23,C.text)+text(86,1457,'区域原画看尺度与空间意图；房间结构图看门位、接触面与动作距离。',23,C.muted);
scale+=text(60,1555,'120m属于原创幻想设定，非真实蓝鲸尺寸；镜头数值是美术设计起点，尚未经过引擎实测。',21,C.gold);
save('尺度与镜头',scale);

// Small anatomical locator panels, same orientation and ranges as the source JSON.
for(const r of data.regions){let s=start(1000,590,r.id+' '+r.name+' · 鲸体定位','头左尾右 / 位置为鼻端到尾端的百分比');s+=whale(10,140,.58,'#172e38');const lo=60,span=850;
const bands=[r.rangePercent,...(r.secondaryRangePercent?[r.secondaryRangePercent]:[])];for(const b of bands){const x=lo+b[0]/100*span,w=(b[1]-b[0])/100*span;s+=rect(x,235,w,195,C[r.id]+'33',C[r.id],10)+text(x+w/2,456,b.join('–')+'%',21,C[r.id],'text-anchor="middle"');}
s+=para(60,505,r.position,40,20,C.muted);save('locator-'+r.id,s);}
(async()=>{for(const name of ['总地图_鲸体落位','连接剖面_六个关键转场','尺度与镜头'])await sharp(out+'/'+name+'.svg').png().toFile(out+'/'+name+'.png');console.log('3 main SVG/PNG and 5 SVG locators written');})();
