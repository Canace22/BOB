const fs=require('fs');
const d=JSON.parse(fs.readFileSync('G:/鲸落万物生/BOB/work/anatomy-placement.json','utf8'));
const dest='G:/鲸落万物生/BOB/work/anatomy-v52';fs.mkdirSync(dest,{recursive:true});
const rr={
R1:{name:'须门遗港',rangePercent:[0,27],part:'口角、口腔、舌根至咽后；喷气孔支路在头背侧',position:'鼻端0–27%；主路在头部腹侧口腔，选修喷气孔在头背侧。',via:'口咽→食管纵裂边→横膈食管裂孔附近→前胃',why:'口咽与前胃通过食管天然相续，通行宽度由尸体管壁纵裂及聚落落脚台提供。口腔去喷气孔则只能走头侧创伤通道，不是正常呼吸结构。'},
R2:{name:'肺心潮庭',rangePercent:[27,46],part:'横膈前的胸腔：背侧肺外表面、前腹侧心包、前纵隔与气管旁',position:'鼻端27–46%；肺在胸腔背侧，心包在前腹侧；前胸回流廊朝头向上。',via:'胃外缘→横膈旧撕裂→肺后缘；肺外表面→纵隔/心包破口→前胸气管旁',why:'肺心为胸腔内相邻但不天然互通的器官；路线靠胸膜剥离、心包破口与修补台连接。回喷气孔沿呼吸道走向上行。'},
R3:{name:'胃肠沉城',rangePercent:[45,66],part:'横膈后前胃至回折肠袢，部分关卡位于肝叶/肠系膜外表面',position:'鼻端45–66%；前胃居前腹腔，肝叶外缘在其腹侧，肠袢向尾再回折。',via:'前胃壁裂缘→胃外/肝缘→系膜脂槽→肠纵裂口→回折肠袢',why:'不是在实心肝脏内部穿洞；沿腹腔中器官表面与破口转场。回折肠袢邻近前胃，维护坡与胃壁旧破口构成回程捷径。'},
R4:{name:'鸣肋断脊',rangePercent:[28,82],part:'椎柱外侧、肋根与肌腱剥离廊，包含向头维护长廊',position:'主关卡约40–78%；椎旁连通带延伸至28–82%。始终在椎骨外侧，不在椎管/骨髓。',via:'腹腔背侧破口→椎旁上/下路→后腰宽台→腰尾分流；向头走长廊或向尾沿渐细尾椎',why:'连续椎列提供身体纵轴地标；头向和尾向是相反方向的长过渡，不能把头耳和尾根当成同一个房门左右两侧。'},
R5:{name:'耳海归墟',rangePercent:[18,26],secondaryRangePercent:[83,100],part:'头段为后颅底耳骨周围创伤腔；尾段为远端尾柄及尾鳍裂缘',position:'头段鼻端18–26%；尾段83–100%，两者隔着大部分躯干。',via:'椎旁头向回廊→颈后外侧→枕骨侧面→耳骨周围；返回椎旁→尾柄→尾鳍裂缘→外海',why:'耳海是叙事分区，不是单个解剖器官：六房在耳骨外周与颅底受损区，两房在远尾。内耳/耳蜗不放大成洞城，尾鳍瓣不长骨架。'}
};
const overrides={'R1-05':[27,32],'R5-01':[24,31],'R5-02':[23,30],'R5-03':[22,30],'R5-04':[22,31],'R5-05':[23,31],'R5-06':[23,30],'R5-07':[100,110],'R5-08':[110,120]};
const rooms=d.rooms.map(r=>{
 let a=r.longitudinalBandM;
 if(r.id.startsWith('R2'))a=a.map(x=>32+(x-28)*23/19);
 if(r.id.startsWith('R3'))a=a.map(x=>54+(x-45)*25/33);
 a=overrides[r.id]||a;a=a.map(x=>Math.round(x*10)/10);
 const percent=a.map(x=>Math.round(x/120*1000)/10);
 return {id:r.id,name:r.name,part:r.site,position:`鼻端${percent[0]}–${percent[1]}%（约${a[0]}–${a[1]}m）；${r.vertical}`,rangePercent:percent,rangeM:a,side:r.vertical,routeReason:r.formation,landmark:r.landmark,coordinateNote:r.coordinateNote};
});
const via={
E01:'口角创口→口腔侧壁',E02:'须筛下缘→舌背',E03:'舌背→舌根→口咽前庭',E04:'咽前台→咽后→塌陷食管纵裂边',E05:'咽后食管→胸腔内食管走向→横膈食管裂孔附近→前胃',
E06:'肺后缘胸膜面→肺叶外侧剥离层',E07:'肺外表面→胸膜破口→纵隔→心包外缘',E08:'心包外缘→心包旧破口→心室断壁旁',E09:'心室断壁旁→心包侧破口→前纵隔→气管旁',E10:'前胃外侧→横膈后面→横膈旧撕裂→肺后缘',
E11:'前胃裂缘→大胃褶',E12:'胃壁旧破口→腹腔→肝叶外缘',E13:'肝叶外表面邻隙→系膜脂质沉积槽',E14:'系膜→胃出口附近→肠管纵裂入口',E15:'肠纵裂边→同一肠袢的系膜搬盘台',E16:'回折肠袢→母蟹侧巢',E17:'回折肠袢侧腔→系膜维护坡→前胃外壁旧破口→胃枢',E18:'胃外缘→腹腔背壁/横膈背外侧创伤→椎旁外廊',
E19:'胸腰椎外侧→外露训练台',E20:'训练台→椎体侧上缘',E21:'训练台→椎体下外侧肌膜沟',E22:'椎旁上路→双贝宽骨台',E23:'椎旁下路→双贝宽骨台',E24:'后腰椎外缘→腰尾交界分流台',E25:'腰尾分流→向头椎旁维护长廊→胸椎外缘→颈后外侧→枕骨侧面→耳区创伤口',
E26:'枕骨外侧→耳骨外周积水凹部',E27:'耳骨外周凹部→软膜褶',E28:'软膜褶→暴露颅底骨面',E29:'覆膜后骨面→耳周腔后侧声槽台',E30:'后侧声槽→回折软膜短缝→薄缝训练台',E31:'腰尾分流→渐细尾椎外缘→尾柄幼体窝',E32:'尾柄外侧→尾鳍基部纤维裂谷→外海',
E33:'口腔上侧→上颚衬层剥离→颅侧旧创伤坡→鼻道破口→喷气孔内缘',E34:'前胸气管旁→喉/鼻道遗迹→鼻道纵裂修补台→喷气孔内缘',E35:'须筛→上颚须根附着面脱层袋',E36:'肺表面→肺缘剥离褶袋',E37:'胃枢→同一胃壁穹顶高褶',E38:'椎旁训练台→肌腱剥离侧袋',E39:'耳区安全池→共生短膜缝→耳周侧袋'
};
const edges=d.edges.map(e=>({id:e.id,from:e.from,to:e.to,nature:e.anatomyType,via:via[e.id],why:e.anatomyTransition,distanceClass:['E05','E25','E31','E34'].includes(e.id)?'长廊':['E07','E09','E10','E12','E14','E18','E33'].includes(e.id)?'跨器官':'局部',conditions:e.requiresAll||e.requires||[],unlock:e.unlock||null,sourceBasis:'既有拓扑边保留；via/破口/修补通道是本轮原创关卡连接设计，不是现实鲸体天然通路结论。'}));
const obj={version:'V5.2 解剖与巨鲸尺度修订',scale:d.scale,regions:Object.entries(rr).map(([id,r])=>({id,...r})),rooms,edges,sources:d.sources,designAssumptions:['120m古代巨须鲸为原创幻想物种，现实蓝鲸约30m级；0.30m主角保持不变。','位置带只是纵轴投影，局部房间横轴随折层和左右侧转向，不能把36房横向首尾拼成鲸长。','死后破损、组织剥离和聚落搭建解释空间；心脏、肺、胃均不维持生命活动。','四类连通：天然腔道走向、器官外侧邻接、死后创伤/剥离、聚落修补。','E17建议展示名“胃侧回折捷径（旧称食道闩）”，保留SC_ESOPHAGUS状态ID兼容旧数据。','E25是约60–70m向头回廊，E31为向尾过渡；只作为原边连续过渡，不新增战斗房。']};
fs.writeFileSync(dest+'/placement.json',JSON.stringify(obj,null,2));console.log({rooms:rooms.length,edges:edges.length});
