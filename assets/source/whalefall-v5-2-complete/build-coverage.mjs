import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const directory = path.dirname(fileURLToPath(import.meta.url));
async function json(name, fallback) {try {return JSON.parse(await readFile(path.join(directory,name),'utf8'));} catch(error) {if(error.code==='ENOENT' && fallback!==undefined)return fallback;throw error;}}
const actors = await json('inventory/full-actor-inventory.json');
const scenes = await json('inventory/full-scene-inventory.json');
const props = await json('inventory/full-props-ui-inventory.json');
const scenePlan = await json('production-plans/scenes.json',{assets:[],existingMappings:[]});
const propPlan = await json('production-plans/props.json',{planned:[],existingReuse:[]});
const actorPlan = await json('production-plans/actors.json',{newProduction:[]});
const interfacePlan = await json('production-plans/ui-fx.json',{assets:[]});
const aliases = {
 'shared-repair-cords':['red-tether'], 'shared-shortcut-latch':['permanent-latches'], 'shared-ability-gates':['ui-progression','anchor-pull-gate'],
 'shared-anchor-mount':['bone-anchor-ring'], 'r2-bypass-valve':['settlement-valve'],
 'r3-pressure-valve-platform':['settlement-valve','floating-platform'], 'r3-weight-seat-platform':['shell-mass-seat','floating-platform'],
 'r4-combination-gate':['anchor-pull-gate'], 'r4-safe-pearl-dispenser':['safe-pearl-emitter'], 'r5-soft-slit':['soft-membrane-fissure'],
 'r5-three-slot-panel':['progress-three-slots'], 'r5-release-sluice':['release-sluice'], 'shared-habitat-beds':['habitat-six-sites'],
 'shared-light-particles':['fx-underwater-atmosphere'], 'shared-current-warning':['fx-danger-telegraph'], 'r5-echo-rings':['fx-echo-ring']
};
const canonical = id => aliases[id] || [id];
const unique = values => [...new Set(values.filter(Boolean))];
const requirements=[];
for(const a of actors.entries.filter(a=>a.staticDeliverables?.length)) {
 const planned = (actorPlan.newProduction || []).filter(x=>x.inventoryEntryId===a.id);
 requirements.push({id:a.id,name:a.name,group:'actors',states:a.staticDeliverables.map(x=>x.name),
  outputIds:unique([...(a.coverage?.existingAssetIds||[]),...(planned.length?planned.flatMap(x=>[x.outputId || x.plannedId,...(x.requiredComponentOutputs||[]).map(c=>c.id)]):a.staticDeliverables.filter(x=>x.status!=='present').map(x=>x.id))]),
  outputPlanComplete:true,rooms:[],regions:a.regions,evidence:a.sourceEvidence.map(x=>x.quote).join(' '),sources:unique(a.sourceEvidence.map(x=>x.page+'#'+x.section)),
  animation:(a.futureAnimationStates||[]).map(x=>x.name),note:(a.notes||[]).join(' ')});
}
for(const s of scenes.assetFamilies.filter(s=>!aliases[s.id])) requirements.push({id:s.id,name:s.name,group:'scenes',states:s.requiredStates,outputIds:s.existingAssetIds||[],outputPlanComplete:false,rooms:s.roomIds,sources:s.sourceSections,evidence:s.evidence,note:s.productionNote});
for(const p of props.physicalFamilies) requirements.push({id:p.id,name:p.name,group:'props',states:p.requiredStates,outputIds:p.existingAssetId?[p.existingAssetId]:[],outputPlanComplete:Boolean(p.existingAssetId),sources:[p.source],evidence:p.evidence,note:p.note,rooms:[]});
const habitat=scenes.assetFamilies.find(s=>s.id==='shared-habitat-beds');
requirements.push({id:'habitat-six-sites',name:habitat.name,group:'props',states:habitat.requiredStates,outputIds:[],outputPlanComplete:false,rooms:habitat.roomIds,sources:habitat.sourceSections,evidence:habitat.evidence,note:'六处栖息地共享各自床、壳托、菌落、红冠和幼体；需要分别给出帮助前后的静态组合。'});
for(const [group,key] of [['ui','uiFamilies'],['fx','fxFamilies']]) for(const p of props[key]) requirements.push({id:p.id,name:p.name,group,states:p.components||p.requiredStates,outputIds:[],outputPlanComplete:false,sources:[p.source],evidence:p.evidence,rooms:[],note:group==='ui'?'静态阶段提供图标、面板与可复用视觉组件；动态文字、布局和按键由界面代码负责。':'静态阶段提供纹理或图形；时序、运动和动作同步在下一阶段制作。'});
const supplements=await json('inventory/supplementary-requirements.json',[]);
requirements.push(...supplements);
const plans=[...scenePlan.assets,...scenePlan.existingMappings,...propPlan.planned,...interfacePlan.assets];
for(const asset of plans) for(const id of unique((asset.coversRequirementIds||[asset.familyId]).flatMap(canonical))) {
 const row=requirements.find(x=>x.id===id);if(!row)continue;
 row.outputIds=unique([...row.outputIds,asset.id]);row.outputPlanComplete=true;
}
const derivedDependencies={'ui-module-camp':['symbiosis-modules'], 'fx-anchor-line':['red-tether'], 'fx-habitat-response':['habitat-six-sites','red-crown-colony','sea-larva']};
for(const [id, dependencies] of Object.entries(derivedDependencies)) {
 const row=requirements.find(x=>x.id===id);
 for(const dependency of dependencies) {const other=requirements.find(x=>x.id===dependency);if(other) {row.outputIds=unique([...row.outputIds,...other.outputIds]);row.outputPlanComplete=row.outputPlanComplete && other.outputPlanComplete;}}
 if(id==='fx-anchor-line')row.outputPlanComplete=Boolean(row.outputIds.length);
}
const floatRow=requirements.find(x=>x.id==='fx-dash-membrane');floatRow.outputIds=unique([...floatRow.outputIds,'float-membrane']);
const missingPlanIds = ['r3-hazard-surfaces','r3-falling-deposit','habitat-six-sites'];
for(const id of missingPlanIds) {const row=requirements.find(x=>x.id===id);if(row && row.outputIds.length===0)row.outputPlanComplete=false;}
const stateRules=await json('state-rules.json',[]);
for(const rule of stateRules) {
 const row=requirements.find(r=>r.id===rule.requirementId);
 if(row) {row.stateRules=rule.compositionRule || rule.rule;row.outputIds=unique([...row.outputIds,...(rule.staticComponents||[])]);}
}
const rooms=scenes.rooms.map(room=>({id:room.id,name:room.name,sizeU:room.sizeU,requirementIds:unique([...room.requiredFamilyIds.flatMap(canonical),...supplements.filter(r=>r.rooms?.includes(room.id)).map(r=>r.id)]),assemblyVerified:false,reference:room.simpleReferenceImage}));
const components=await json('review/components/components-recipe.json',{componentRecipes:[],habitatRecipes:[]});
for(const recipe of [...components.componentRecipes,...components.habitatRecipes]) {
 for(const id of recipe.coversRequirementIds || (recipe.id?.startsWith('H')?['habitat-six-sites']:[])) {
  const row=requirements.find(r=>r.id===id);
  if(row) row.recipeFile='assets/source/whalefall-v5-2-complete/review/components/components-recipe.json';
 }
}
for(const row of requirements) {
 if(row.group!=='ui' && row.group!=='fx') {row.initialAuditNote=row.note;delete row.note;}
}
requirements.find(r=>r.id==='tide-picker').note='左右基础静态形象已制作；手持物和腰灯按角色自身左右核对，动作帧另做。';
requirements.find(r=>r.id==='scene-water-depth').note='6张独立L0水体与6张透明L1器官层已制作；整合背景保留为可选用图。';
const previews=await json('previews.json',[]);
const output={previews,schemaVersion:1,updatedAt:new Date().toISOString(),phase:'static-first',note:'根据两份指定设计逐项盘点。静态文件、状态组合与后续动作分别登记；实际文件与审核状态以项目台账为准。',sources:props.sources,requirements,rooms};
if(new Set(requirements.map(x=>x.id)).size!==requirements.length)throw new Error('重复的需求ID');
for(const room of rooms) for(const id of room.requirementIds) if(!requirements.some(x=>x.id===id))throw new Error('房间引用未登记家族: '+id);
await writeFile(path.join(directory,'coverage.json'),JSON.stringify(output,null,2)+'\n');
console.log(JSON.stringify({requirements:requirements.length,rooms:rooms.length,groups:requirements.reduce((o,r)=>(o[r.group]=(o[r.group]||0)+1,o),{})}));
