module.exports=function(data){
const get=id=>data.rooms.find(r=>r.id===id);
function plat(r,id,x,y,w,kind){const p={id,x,y,w,kind};r.platforms.push(p);return p;}
function move(r,to,p,x,side,points,ability,description){const d=r.doors.find(d=>d.to===to);if(!d)throw Error(r.id+to);d.x=x;d.y=p.y;d.platform=p.id;d.side=side;d.description=description;r.routes=r.routes.filter(t=>!(t.type==='access'&&t.description.includes(d.id)));r.routes.push({type:d.kind==='optional'?'hidden':'access',doorId:d.id,points,requires:ability,description:d.id+'→'+to+'：'+description});}
// 删除没有明确战斗、奖励或能力教学用途的通用高台和自动补出的阶梯。
for(const r of data.rooms){const preserve=r.region==='R2'||['R1-04','R3-07','R4-02','R4-03','R4-05','R4-07','R5-04'].includes(r.id);const remove=new Set();for(const p of r.platforms.filter(p=>p.id.startsWith('U'))){const reward=r.rewards.some(t=>Math.abs(t.y-(p.y-0.8))<0.01&&t.x>=p.x&&t.x<=p.x+p.w);if(!preserve&&!reward)remove.add(p.id);else p.kind=reward?'奖励落台':r.region==='R2'?'浮膜补压/换层台':'战斗避险/动作训练台';}
r.platforms=r.platforms.filter(p=>!remove.has(p.id)&&![...remove].some(id=>p.id.startsWith('S'+id+'-')));r.routes=r.routes.filter(t=>!([...remove].some(id=>t.description.includes('到'+id+'：'))));
// 额外低位背壁口也必须有独立坐标，不把多个门堆在同一锚点。
const used=new Set();for(const d of r.doors){let key=d.x+','+d.y;if(used.has(key)){const p=r.platforms.find(p=>p.id===d.platform);d.x=Math.min(p.x+p.w-0.7,d.x+1.5);key=d.x+','+d.y;}used.add(key);}
}
// 胃枢手工重画：低位肠路，普通阶梯肺口，独立母蟹闩，隔开的高位A2支线，右侧强流锚闸。
{
const r=get('R3-01');r.width=48;r.height=30;r.platforms=[];r.routes=[];r.traversalSegments=[];r.anchors=[];
const p0=plat(r,'H0',0,26,10,'入鲸宽岸'),p1=plat(r,'H1',11,26,13,'营地与菌圃'),p2=plat(r,'H2',25,26,11,'肠路宽台'),p3=plat(r,'H3',37,26,11,'肠口岸');
const stairs=[[6,24.5,4],[10,23,4],[8,21.5,4],[4,20,5],[0,18.5,6]].map((a,i)=>plat(r,'L'+i,...a,'普通跳肺口阶台'));
const mom=plat(r,'M0',0,23,5,'独立食道闩返台');
const high=[[23,22.5,4],[25,19,4],[23,15.5,4],[25,12,4],[23,8.5,4],[24,5,5]].map((a,i)=>plat(r,'A2H'+i,...a,'A2浮升补压台，非普通阶梯'));
const gate=plat(r,'G0',42,17,6,'P＋A3强流门独立岸');
r.anchors=[{x:36,y:23,reach:4.5,label:'强流固定环1'},{x:39,y:20,reach:4.5,label:'强流固定环2'},{x:42,y:17,reach:4.5,label:'强流固定环3'},{x:45,y:14,reach:4.5,label:'闸上固定环4'}];
r.hazards=[{x:35,y:21,w:7,type:'强流门前竖向水道',tell:'P调流前连续亮粒封线；P后亮粒变缓，固定红环显露',recovery:'未开时不能穿，失足回H2，不把未开门当死亡坑'}];
move(r,'R1-05',p0,1,'left',[[3,26],[1,26]],'步行','左下通须门，保持稳定返程。');
move(r,'R2-01',stairs[4],1,'left',[[8,26],[8,24.5],[12,23],[10,21.5],[6,20],[3,18.5],[1,18.5]],'普通跳＋A1世界门','左上肺口；各阶升高1.5U，无需先有A2。');
move(r,'R3-02',p3,47,'right',[[13,26],[23.5,26],[25.5,26],[35.5,26],[37.5,26],[47,26]],'普通跳','低位肠路，未获得A2也能往返。');
move(r,'R3-07',mom,1,'left',[[3,26],[8,24.5],[3,23],[1,23]],'普通跳＋已从母蟹侧开闩','左中独立食道闩，未胜母蟹时仅见背面，不能提前穿行。');
move(r,'R3-08',high.at(-1),26,'top',[[23,26],...high.map(p=>[p.x+2,p.y]),[26,5]],'A2','胃顶独立竖井，每台间升高3.5U，普通跳无法逐阶爬到；每台免费补压。');
move(r,'R4-01',gate,47,'right',[[34,26],[36,23],[39,20],[42,17],[45,14],[44,17],[47,17]],'P＋A3','右侧强流降速后挂固定环登独立岸，再拉锚闸；不与胃顶门共用门位。');
r.routes.unshift({type:'main',points:[[1,26],[9.5,26],[11.5,26],[23.5,26],[25.5,26],[35.5,26],[37.5,26],[47,26]],requires:'普通跳',description:'低位主路连接入鲸、营地和肠路，三个1U缝。'});
for(const [a,b]of [[p0,p1],[p1,p2],[p2,p3]])r.traversalSegments.push({from:a.id,to:b.id,gap:b.x-a.x-a.w,rise:0,requires:'普通跳',validated:'普通跳尺寸边界通过',failure:'落入无伤宽坡返回左岸'});
for(let i=0;i<high.length;i++)r.traversalSegments.push({from:i?high[i-1].id:p1.id,to:high[i].id,gap:0,rise:3.5,requires:'A2',validated:'需浮膜，未验证运动曲线',failure:'压力耗尽落回上一补压台/底床'});
r.checkpoint.x=14;r.checkpoint.y=26;r.travel.x=19;r.travel.y=26;r.rewards.forEach(t=>{t.x=16;t.y=25.2});r.camera='入室先框低位营地和两支路；靠左普通阶梯时上看肺口，靠胃顶时显示独立高井，靠右强流岸才展开右高门；不让A2门与P+A3门同屏重叠。';
r.walkthrough=['左下进入宽岸，沿1U间隙抵中央营地和余索；低位可直接往肠路。','左侧用5级普通跳台上肺口，不要求A2，进入后再获得浮膜。','母蟹回返口位于左中独立短台，先只见闩背，胜后从对面永久打开。','A2回访中央独立高井，各补压台升高3.5U；抵胃顶支线，不与普通肺口阶梯相接。','已有P＋A3时在右侧先降强流，再沿4个固定环登高门；失败回低位宽岸。'];
}
// 育床的世界边在拓扑数组里先列出出口；按游玩方向校正入口，不能让未获A2者直接从高口落入。
{
const r=get('R2-01'),low=r.platforms.find(p=>p.id==='P0'),high=r.platforms.find(p=>p.id==='P3');
move(r,'R3-01',low,1,'left',[[3,19],[1,19]],'A1世界门','胃枢来路接低位育床，先安全取得A2。');
move(r,'R2-02',high,27,'right',[[3,19],[11,16],[17,13],[24,10],[27,10]],'A2','三个3U升高与独立补压台，授能后浮升至肺膜高口；底床无旁路出口。');
}
// 将能力支线门放到真正高位/跨隙位置。未开世界门条件仍沿用拓扑。
{
const r=get('R1-02');r.platforms=r.platforms.filter(p=>!p.id.startsWith('U')&&!p.id.startsWith('SU'));r.routes=r.routes.filter(t=>t.type!=='branch');
const lift=[[3,13.5,4],[3,10,4],[3,6.5,4]].map((a,i)=>plat(r,'FLOAT'+i,...a,'A2浮升补压台'));move(r,'R1-06',lift[2],5,'top',[[5,17],[5,13.5],[5,10],[5,6.5]],'A2','须根流膜竖井，三段3.5U升高不能普通跳；顶孔通喷气孔。');
const q=plat(r,'ANCHOR_GATE',29,10,6,'A3固定环隐藏岸');r.anchors=[{x:26,y:13,reach:4.5,label:'须根环1'},{x:29,y:10,reach:4.5,label:'须根环2'},{x:32,y:7,reach:4.5,label:'门帘拉环'}];move(r,'R1-07',q,33,'upper',[[25,16],[26,13],[29,10],[32,7],[33,10]],'A3','红绳断端与透光提示高岸；挂固定环攀移后拉环开须帘，不能只按E。');
}
{
const r=get('R2-02'),q=plat(r,'BREATH_GATE',6,6,6,'A2呼吸囊高口');move(r,'R2-06',q,8,'top',[[8,13],[16,10],[8,6]],'A2','由两段补压台升向顶囊，普通跳不足以跨过3U以上高度。');
}
{
const r=get('R4-02'),upper=plat(r,'UP_ROUTE',29,9,7,'A4迎珠上路出口'),lower=plat(r,'LOW_ROUTE',30,20,6,'A3下锚路出口'),secret=plat(r,'CORD_GATE',4,9,5,'A3＋A4修索侧室岸');
move(r,'R4-03',upper,35,'right',[[20,17],[20,14],[27,12.5],[32,9],[35,9]],'A4','完整珠托升后分段落台，侧向迎珠进入上路线；每台重置组合。');
move(r,'R4-04',lower,35,'right',[[24,18.5],[32,20],[35,20]],'A3','下骨口可直接看到隔壁固定环；从低位进入锚定路线。');
r.anchors=[{x:15,y:10,reach:4.5,label:'修索侧室环1'},{x:12,y:8,reach:4.5,label:'修索侧室环2'},{x:8,y:6,reach:4.5,label:'修索门环'}];move(r,'R4-07',secret,5,'upper',[[20,17],[20,14],[17,12],[15,10],[12,8],[8,6],[5,9]],'A4＋A3','迎珠到中高台再逐环侧移，隐藏室与上下主路门分开；失足回低台。');
}
// A5门/内部穿缝：明确分开站立脚位、压膜中线、出缝脚位，穿缝永不标普通跳。
for(const id of ['R5-02','R5-03','R5-06']){const r=get(id),w=r.walls[0],p=r.platforms.find(p=>p.id==='P2');const slitCenter=+(w.slitY+w.slitHeight/2).toFixed(2);const a=[w.x-0.5,p.y],b=[w.x,slitCenter],cc=[w.x+w.w,slitCenter],d=[w.x+w.w+0.5,p.y];r.routes.push({type:'main',points:[a,b,cc,d],requires:'A5',description:'A5主路穿缝段：先落至P2稳定台→收膜至缝中线→穿1.2U→出缝展开；不能用普通跳穿封顶硬墙。'});
const main=r.routes.find(t=>t.type==='main'&&!t.requires?.includes('A5'));if(main){let idx=main.points.findIndex(v=>v[0]>w.x);if(idx>=0)main.points.splice(idx,0,a,b,cc,d);main.description+=' P2墙段使用A5，明线只显示几何，不代表普通跳。';}
r.traversalSegments.push({from:'P2-left',to:'P2-right',gap:1.2,rise:0,requires:'A5',kind:'shortSlit',slitCenterY:slitCenter,standY:p.y,validated:'短缝≤1.5U；需A5，非普通跳',failure:'未出时延迟闭合，取消则退原侧稳定台'});
}
{
const r=get('R5-02'),p=plat(r,'MEMORY_GATE',24,11,6,'A5侧囊门前台');move(r,'R5-06',p,29,'upper',[[25,15.5],[26,12],[26,11],[27,10.6],[28.2,10.6],[29,11]],'A2＋A5','先用已掌握浮膜到侧台，再潜入侧口1.2U柔膜缝；入口有穿膜漂粒与对侧微光。');r.walls.push({x:27,y:2,w:1.2,h:11,kind:'侧囊独立短缝隔墙',slitY:10.2,slitHeight:0.8,requires:'A5',failure:'留原侧稳定台'});
}
// 刷新所有access路径末点及条件说明，确保修订后不残留旧门坐标。
for(const r of data.rooms){for(const d of r.doors){const rt=r.routes.find(x=>x.doorId===d.id||x.type==='access'&&x.description.includes(d.id));if(rt&&!rt.doorId)rt.points[rt.points.length-1]=[d.x,d.y];}r.layoutRevision='V5.1几何复核：能力门对应实体高差/锚隙/封顶短缝；门位独立，装饰高台与可走台分开。';}
};

