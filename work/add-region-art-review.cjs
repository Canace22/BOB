const fs=require('fs');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
const esc=s=>String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let html=fs.readFileSync(root+'/地图设计册.html','utf8');
for(let i=1;i<=5;i++){
 const id='R'+i,m=JSON.parse(fs.readFileSync(root+'/data/region-art/'+id+'.json','utf8'));
 const start=html.indexOf('id="region-'+id+'"'),end=html.indexOf('<h4 class="structure-heading">',start);
 if(start<0||end<0)throw Error('Region not found '+id);
 if(html.slice(start,end).includes('区域原画复核与提示词'))continue;
 const block='<details class="art-production"><summary>区域原画复核与提示词</summary><p>'+esc(m.review)+'</p><p>'+esc(m.caveat)+'</p><p><a href="data/region-art/'+id+'.json">查看生成记录</a></p><details><summary>英文提示词</summary><pre>'+esc(m.prompt)+'</pre></details></details>';
 html=html.slice(0,end)+block+html.slice(end);
}
html=html.replace('三张新绘原画对应世界、胃肠叠层与断脊双路','沿用上轮三张原画，分别对应世界、胃肠叠层与断脊双路');
const retainedStart=html.indexOf('<section id="base-art">');
if(retainedStart>=0){const nextSection=html.indexOf('<section ',retainedStart+1);const end=nextSection<0?html.length:nextSection;let retained=html.slice(retainedStart,end);retained=retained.replace(/05\s*\/\s*[^<]+/, '05B / RETAINED STUDIES');html=html.slice(0,retainedStart)+retained+html.slice(end);}
fs.writeFileSync(root+'/地图设计册.html',html);
fs.copyFileSync(__filename,root+'/data/add-region-art-review.cjs');
console.log('Regional review and caveats displayed for all five areas');
