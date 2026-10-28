const fs=require('fs'),path=require('path'),assert=require('assert/strict'),crypto=require('crypto');
const root='G:/鲸落万物生/outputs/拾潮者_2D动作原画';
const html=fs.readFileSync(root+'/动作原画册.html','utf8'),plan=JSON.parse(fs.readFileSync(root+'/data/动作图板计划.json','utf8'));
const ids=[...html.matchAll(/\sid="([^"]+)"/g)].map(m=>m[1]);assert.equal(ids.length,new Set(ids).size);
for(const m of html.matchAll(/(?:href|src)="([^"]+)"/g)){const ref=m[1];if(ref.startsWith('#'))assert(ids.includes(ref.slice(1)),ref);else assert(fs.existsSync(path.resolve(root,ref)),ref);}
const images=plan.sheets.map(s=>{const b=fs.readFileSync(root+'/images/'+s.id+'.png');assert(b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])));assert.equal(s.poses.length,s.rows*s.cols);assert(fs.existsSync(root+'/data/'+s.id+'.json'));return{id:s.id,width:b.readUInt32BE(16),height:b.readUInt32BE(20),poseCells:s.poses.length,sha256:crypto.createHash('sha256').update(b).digest('hex')};});assert.equal(new Set(images.map(i=>i.sha256)).size,5);
const report={sheets:5,keyPoseCells:50,images,assetAndLinkChecks:'passed',visualReview:'所有五张已目检，02/03/04已定向修图；局部比例与遮挡清稿要求在各图review中说明。',browserInteractionTested:false,engineAnimationTested:false,transparentSpriteSheets:false};fs.writeFileSync(root+'/data/验收记录.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
