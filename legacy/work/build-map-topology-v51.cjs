const fs=require('fs'),path=require('path');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
fs.mkdirSync(path.join(root,'data'),{recursive:true});
const t=JSON.parse(fs.readFileSync('G:/鲸落万物生/outputs/鲸落万物生_V5_完整游戏设计/data/房间索引.json','utf8'));
t.version='V5.1';t.date='2026-10-22';t.scope='36房39边的概念设计拓扑；事件、门槛与首次开侧可复现静态验证；不等同引擎通关实测';
t.initial={room:'R1-01',flags:[]};
t.regions=[['R1','须门遗港','前期','走跳、短击、冲刺'],['R2','肺心潮庭','中期可先后','高度、浮膜与群流'],['R3','胃肠沉城','中期枢纽','遮光、掩体与固定锚'],['R4','鸣肋断脊','后期','迎珠上路与锚环下路'],['R5','耳海归墟','后期／尾声','头耳潜隙；沿脊椎返尾']].map(([id,name,stage,focus])=>({id,name,stage,focus}));
const byId=Object.fromEntries(t.rooms.map(r=>[r.id,r]));
const bosses=[['R1-04','BOSS_R1','A1'],['R2-04','BOSS_R2','P'],['R3-07','BOSS_R3',null],['R4-05','BOSS_R4','B'],['R5-04','BOSS_R5',null]];
t.events=bosses.map(([room,flag,reward])=>({id:'EV_'+flag,room,type:'bossVictory',requiresAll:[],grants:[flag,...(reward?[reward]:[])],action:'完成Boss战；停止伤害，先保存胜利'+(reward?'与'+reward:''),optional:flag==='BOSS_R3'}));
for(const [room,flag,reward] of bosses){byId[room].bossFlag=flag;byId[room].grantWhen=flag==='BOSS_R5'?'Boss胜利先保存；本房安全静默2秒再授S':reward?'本房Boss胜利并保存后授予'+reward:'本房Boss胜利并保存后可开食道闩及完成H4';}
for(const [room,a] of [['R2-01','A2'],['R3-05','A3'],['R4-02','A4'],['R5-02','A5']])t.events.push({id:'EV_'+a,room,type:'abilityInteraction',requiresAll:[],grants:[a],action:'安全授能点按E完成；动画结束即保存，走进房间不自动授能'});
t.events.push({id:'EV_S',room:'R5-04',type:'safeSilence',requiresAll:['BOSS_R5'],grants:['S'],action:'胜利后无伤害区静默2秒；空圆闭合为视觉提示；离房可回到同一点补领'});
t.events.push({id:'EV_END',room:'R5-08',type:'endingInteraction',requiresAll:['P','B','S'],grants:['END'],action:'归海同步交互；缺项不消耗资源，确认后保存尾声'});
const getEdge=(a,b)=>t.edges.find(e=>e.from===a&&e.to===b);
for(const [a,b,req]of [['R2-01','R2-02',['A2']],['R3-05','R3-06',['A3']],['R5-02','R5-03',['A5']]]){const e=getEdge(a,b);e.requires=req;e.evidence+='；V5.1补齐文字已要求的内部动作门';}
for(const [a,b,f]of [['R1-04','R1-05','BOSS_R1'],['R2-04','R2-05','BOSS_R2'],['R5-04','R5-05','BOSS_R5']]){const e=getEdge(a,b);e.completionFlags=[f];e.requiresCompletion=f+'胜利后开放出口';}
for(const [i,e]of t.edges.entries()){e.id='E'+String(i+1).padStart(2,'0');e.requiresAll=[...e.requires];e.completionFlags??=[];e.direction='twoWayAfterConditions';}
const shortcuts=[['R3-07','R3-01','SC_ESOPHAGUS','R3-07',['BOSS_R3'],'母蟹胜后，从竞技场后侧登宽坡，E拉红结闩；胃枢侧只能看见闩背。'],['R2-05','R1-06','SC_BLOWHOLE','R2-05',['BOSS_R2'],'血巢胜后沿回流到肺心远侧，E旋开孔瓣；须门一侧无把手。'],['R5-03','R5-05','SC_EAR','R5-05',['BOSS_R5'],'覆膜胜后从最后静默侧潜过短柔膜缝，E松双环闩；薄缝训练侧只能看见锁环。']];
for(const [a,b,flag,from,completionFlags,action]of shortcuts){let e=getEdge(a,b);e.unlock={flag,from,requiresAll:[...e.requires],completionFlags,action,persistent:true};e.note=action+'首次打开后永久双向；局部水压/死亡不复锁。';e.completionFlags=[];e.requiresCompletion=completionFlags.join('+')+'且从'+from+'完成开闩';}
for(const [a,b,name]of [['R3-01','R4-01','肋侧强流闸'],['R4-06','R5-01','头耳三槽门'],['R5-07','R5-08','尾根同步环']]){let e=getEdge(a,b);e.gate={name,firstInteractionAt:a,permanent:true,action:'核验'+e.requires.join('+')+'后E开启；缺项显示已知来源；本身不消耗能力或旗标'};}
t.checkpoints.forEach(c=>{if(!c.room)c.room='R5-07';c.note=c.room==='R1-04'||c.room==='R3-07'||c.room==='R4-05'?'所属房入口安全前室；战斗边界外，独立镜头停靠，不额外计房':'本房固定安全宽台；恢复生命与蓄振';c.activation='亲自到达后E登记；可免费更换模块';c.retryTargetSeconds=c.name==='蟹前'||c.name==='母蟹前'||c.name==='鸣贝前'||c.name==='心前'||c.name==='覆膜前'?15:null;});
const travelRooms={'胃枢':'R3-01','肺口':'R2-01','肠侧':'R3-05','脊椎':'R4-06','颅入口':'R5-01','尾根':'R5-07'};
t.travel.forEach((n,i)=>{n.id='T'+(i+1);if(!n.room)n.evidence='V5.1明确房级落位提案；V5仅区域级';n.room=travelRooms[n.name];n.activation={requiresAll:['B'],physicalVisit:true,localInteract:'E调律',flag:'TUNED_'+n.room};n.note='B前可记录发现但不能预调律；B后需回到节点E。两端均已调律且当前在节点才可旅行；目的地未亲访不可选。'});
t.habitats={count:6,rooms:[{id:'H1',room:'R1-05',name:'须门清流窝',action:'冲刺教学后将一只空壳安置在侧台，清流窝显露',requiresAll:['A1']},{id:'H2',room:'R2-01',name:'肺膜育床',action:'调平补压床旁壳托，孔瓣恢复规律开合',requiresAll:['A2']},{id:'H3',room:'R3-01',name:'胃枢菌圃',action:'把侧边遮光片旋至暗档，幼菌点亮，主通路不变',requiresAll:[]},{id:'H4',room:'R3-06',name:'肠侧搬壳巢',action:'母蟹胜后回迁居搬盘完成安置；战前可预摆，完成旗标等待胜利',requiresAll:['BOSS_R3']},{id:'H5',room:'R4-04',name:'肋骨红冠园',action:'经锚环到安全侧台，移开压冠空壳，红冠舒展',requiresAll:['A3']},{id:'H6',room:'R5-07',name:'尾下幼体槽',action:'尾根侧台旋开遮流瓣，幼体进入低速凹槽',requiresAll:['B']}],note:'V5.1房级落位提案；不新增房间；生态结果不构成终局门槛。'};
t.abilities=[
{id:'A1',name:'贴流冲',room:'R1-04',condition:'负壳蟹胜利',uses:['R1-05跨宽沟进入胃枢','R3-04撤离锁定冲撞','R4-03迎珠后一次空冲接上台'],revisit:'R1-02须筛同房高低回路：冲过帘侧宽沟，从内侧推开短返闩；不新增世界边',hidden:'R1-07接近奖励台时缩短暴露时间，入口仍要求A3',challenge:'R2-02膜鳐锁线后横移躲避',limit:'每次离地一次；迎珠不刷新；不穿酸/墙/持续激流'},
{id:'A2',name:'浮膜',room:'R2-01',condition:'安全育床E授能',uses:['R2-02上下换水道','R1-06升至喷气孔上层','R3-08升上胃顶沉积袋'],revisit:'R1-02→R1-06；R3-01→R3-08',hidden:'R2-06三段补压，固定碎片与记忆',challenge:'血巢潮群的上下缺口选择',limit:'压力4秒；补压台恢复；R3主路不需A2'},
{id:'A3',name:'锚定',room:'R3-05',condition:'肠入口E授能',uses:['R3-06固定环过酸槽','R3-01配P开强流闸','R4-04下路固定环稳过缺口'],revisit:'R1-02→R1-07鲸须记忆袋',hidden:'R4-07与A4组合取系索',challenge:'母蟹松壳可选弱化；挂环时不攻击',limit:'只抓预置环；主路间距≤4.5U；脱环再攻击'},
{id:'A4',name:'迎珠',room:'R4-02',condition:'低骨训练E授能',uses:['R4-03接完整珠上升','R4-07迎珠后锚定稳定','R5-01三槽门的迎珠槽交互'],revisit:'R4-02低骨房初见高侧台，获能力后同房回访；外域不新增硬门',hidden:'R4-07系索模块，两线索见断绳与透光孔',challenge:'悬脊鸣贝回珠18伤害；直接打亦可胜',limit:'Q侧向接完整带环珠；0.18秒窗口；不是下劈踩敌'},
{id:'A5',name:'敛膜潜隙',room:'R5-02',condition:'安全池E授能',uses:['R5-03短柔膜缝换边','R5-02→R5-06入记忆侧囊','R5-05从远侧开耳海返程捷径'],revisit:'R5-01初见隔膜旁同房声纹凹槽；返程潜入得叙事，不追加成长奖励',hidden:'R5-06固定碎片；两个入口暗示为穿膜漂粒和对侧微光',challenge:'缄声覆膜旧位置回声前换边',limit:'标记柔膜缝≤1.5U；不穿硬墙；未出缝不闭合'}];
t.progressionFlags=[{id:'P',room:'R2-04',event:'EV_BOSS_R2',meaning:'潮压稳定；开肋侧强流闸与尾槽'},{id:'B',room:'R4-05',event:'EV_BOSS_R4',meaning:'骨音调律；允许亲访节点调律、头耳门与尾槽'},{id:'S',room:'R5-04',event:'EV_S',meaning:'胜后安全静默完成；尾槽条件'}];
t.stages=[{id:'start',name:'初见须门',flags:[]},{id:'dash',name:'冲刺进入胃枢',flags:['BOSS_R1','A1']},{id:'lung',name:'肺心先行',flags:['BOSS_R1','A1','A2','BOSS_R2','P']},{id:'gut',name:'胃肠先行',flags:['BOSS_R1','A1','A3']},{id:'join',name:'两支汇合',flags:['BOSS_R1','A1','A2','BOSS_R2','P','A3']},{id:'bone',name:'骨音解锁',flags:['BOSS_R1','A1','A2','BOSS_R2','P','A3','A4','BOSS_R4','B']},{id:'final',name:'尾槽条件齐备',flags:['BOSS_R1','A1','A2','BOSS_R2','P','A3','A4','BOSS_R4','B','A5','BOSS_R5','S']}];
t.changes=['修复三个Boss授予描述错误引用R5-04静默事件','补齐三段内部动作门A2/A3/A5与R2/R5战后出口条件','三个捷径用机器字段明定首次开侧及永久开闩旗标','把未定位营地、交通、六生态节点落在既有房间；均标V5.1提案','区分房间到达、授能、Boss胜利、静默、开闩与调律六类事件'];
fs.writeFileSync(path.join(root,'data/地图拓扑.json'),JSON.stringify(t,null,2));
console.log({rooms:t.rooms.length,edges:t.edges.length,events:t.events.length});
