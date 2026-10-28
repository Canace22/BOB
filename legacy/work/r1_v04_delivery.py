from pathlib import Path
from html import escape
from html.parser import HTMLParser
import json,shutil,zipfile,hashlib
p=Path('G:/鲸落万物生/BOB/godot/first-level');d=p/'docs/v04';ref=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
out=Path('G:/鲸落万物生/outputs/须门遗港_首关场景_v0.4_路线与分层');out.mkdir(parents=True,exist_ok=True)
for sub in ['screenshots','originals','maps','docs']:(out/sub).mkdir(exist_ok=True)
rooms=json.loads((p/'assets/rooms.json').read_text('utf8'))
checks={}
for id,rel in {'art':'package-art/art.json','routes':'package-routes/routes.json','mechanisms':'package-mechanisms/mechanisms.json','play':'package-play/prototype.json','reload':'package-reload/persistence.json','branch':'branch/branch.json','latch':'latch/latch-reload.json','death':'death/combat.json'}.items():
 j=json.loads((p/'evidence/v04'/rel).read_text('utf8'));assert j['passed'],id
 checks[id]={'passed':j['passed'],'check_count':len(j.get('checks',[])),'evidence':'evidence/v04/'+rel}
qa={'checks':checks,'processes':json.loads((d/'package-qa.json').read_text('utf8')),'performance':json.loads((p/'evidence/v04/package-play/performance.json').read_text('utf8')),'reviewer':'AI + graphical Godot captures','human_review':'not_run','audio_listening':'not_run; reused existing audio','final_package_note':'Full package gameplay/route/mechanism/reload passed. Afterwards only atlas TextureRect replaced by fixed-scale Sprite2D and art fixture boss state restored; exported again and graphical art + normal startup rerun. Gameplay scripts unchanged after full regression.'}
assert all(x['exit']==0 and not x['errors']for x in qa['processes'])
(d/'qa-summary.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf8')
for f in (p/'evidence/v04/package-art').glob('*.png'):shutil.copy2(f,out/'screenshots'/f.name)
for name in ['A2-three-platforms','06-remote-latch','07-right-wall-rewards']:shutil.copy2(p/f'evidence/v04/package-routes/{name}.png',out/f'screenshots/{name}.png')
for idx,f in enumerate(sorted((p/'evidence/v04/package-play').glob('*room-3.png'))[:1]):shutil.copy2(f,out/'screenshots/gameplay.png')
for r in rooms:
 for sub,ext in [('originals','png'),('maps','svg')]:shutil.copy2(p/f'assets/reference/r1/{r["id"]}.{ext}',out/f'{sub}/{r["id"]}.{ext}')
elements=json.loads((ref/'data/elements.json').read_text('utf8'))['assets']
mapping={
'BG01':('Far/FarDrift/DeepWater','深水底色，远景视差0.10/0.12'),
'BG02':('Middle/OpenUpperJaw + LowerJawSkin；口腔Far纹理','01保持分离上下颌；口腔巨型面远近分层'),
'BG03':('R1-05 Far/FarDrift/DeepWater','食管肌膜素材复用，05移除错误须列与矩形覆盖'),
'BG04':('R1-06 Far/FarDrift/DeepWater','颅骨板与旧创伤背景，鼻口隔壁保留'),
'MD01':('Middle/UpperPalateAndBaleen','新独立须幕；Shader缓动；02/03/04/07'),
'MD02':('World/Tether_*；World/RedCord_*；DoorsAnchorsAndMechanisms','装饰线与可挂环区分，交互环固定世界坐标'),
'MD03':('原有背景/货壳/Boss背壳','复用，非全部独立可破坏物'),
'TR01':('World/Shelf_*/TongueLedge','新ledges；所有接触顶边仍按U坐标'),
'TR02':('World/Shelf_*/TongueLedge + RootedOrgan/Foundation','圆润端部与支撑重制；通用内外角成套素材仍待进一步精修'),
'TR03':('player.fall_recover + 05局部软床','实际失败恢复；并非底层连续自由行走返坡'),
'TR04':('R1-03 World/Shelf_P2 + room_routes','踩踏0.7秒后缓沉20px，接触面同步，卸载恢复'),
'DO01':('World/DoorsAnchorsAndMechanisms/E*','14个门端，按目标与稳定ID切换并返回'),
'DO02':('level.boss_started + boss arena limits','沿用战斗封场/胜后解除；独立门扇绘画动画未升级'),
'DO03':('E33/E34 + FLOAT0/1/2','真实A2浮升/补压/门条件，远端闩保持锁定'),
'DO04':('02三锚；07四锚 + player.choose_anchor','J抓取/换环，Space脱环，挂环禁攻击'),
'PR01':('level.draw_camp / checkpoint interaction','01/04营地，恢复并存档'),
'PR02':('level.draw_collect / room_routes rewards','03与07一次性碎片；复用简化视觉'),
'PR03':('04 A1授能点','Boss胜后E领取永久A1，旧逻辑回归'),
'PR04':('05 H1清流窝','保留永久生态状态和幼体反馈，搬壳逐帧未升级'),
'PR05':('06/07 World/Reward_*','静菌/记忆拾取已接入；正式新物件美术仍复用'),
'PR06':('level.open_bridge','v0.2局部壳闩短桥保留，已往返/重载验证'),
'CH01':('World/Actors/Player','沿用原主角与动作，新增浮升/挂环控制'),
'EN01':('World/Actors/enemies','02×1、03×2，原攻击时序复用'),
'EN02':('R1-04 World/Actors/enemies','Boss实际首访通关'),
'HZ01':('room_routes.gd','0.8秒方向预告后迁行，伤害保护/最近稳定台恢复'),
'HZ02':('R1-06 room_routes + A2 pressure','横流预告/周期危险；落台补压'),
'FG01':('Foreground/NearShellRidge + NearColony_*','新独立边缘素材，1.2视差，玩家遮挡淡出'),
'FG02':('Middle须束 + 已有边缘层','维持口腔限定；05/06无须'),
'FX01':('atmosphere灯节点 + player.lamp_light','复用灯光与摆动'),
'FX02':('atmosphere mode0/1','雾与定额漂粒，暂停同步'),
'FX03':('atmosphere mode0；H1反馈','低密度漂浮；06不放鱼群'),
'FX04':('atmosphere / event_fx','局部流纹与落地扰动，非游泳水体'),
'FX05':('World/EventEffects','真实命中/死亡/落地触发，原动作反馈复用')}
asset_rows=[]
for a in elements:
 id=a['id'];loc,note=mapping.get(id,('见既有代码','未新增独立实现'))
 asset_rows.append({'id':id,'name':a.get('name',id),'node_or_code':loc,'implementation':note})
(d/'element-mapping.json').write_text(json.dumps(asset_rows,ensure_ascii=False,indent=2),encoding='utf8')
(d/'delivery.md').write_text('''# v0.4 七房路线与四层场景交付
工程：G:/鲸落万物生/BOB/godot/first-level/project.godot
运行：G:/鲸落万物生/builds/须门遗港-v0.4-七房路线与分层/Whalefall.exe
图册：G:/鲸落万物生/outputs/须门遗港_首关场景_v0.4_路线与分层/场景交付册.html

七房原图与坐标已内置F8；14门端按ID连接，7房四层可独立查看；35条回访检查、49条场景检查、6条机关检查通过。五房实际首访通关、舌台支路、死亡/存档/壳闩重载通过；最后地图显示修正后重测原图/坐标/层/地图与正常启动，玩法代码未改。完整证据见qa-summary.json。

查看：F6巡览、1–7选房、F5全房、F7路线、F8原图坐标、F10分层、Tab总图。F9回访验证提供临时能力，W浮升、J挂环、Space脱环、E交互，退出恢复正常旅程。

边界：首访仍01–05，06/07后续能力回访段已可操作验证；不包含A2/A3正式获取的后续章节，外部R2/R3地图未制作。软床是局部触发恢复，不是连续可走返坡。地形长段仍有拉伸和模块重复；角色/Boss动作、门扇逐帧美术仍复用。原图与坐标冲突采用坐标与最新解剖规范，不声称逐像素复刻。AI审查，不代表用户审美签收；未新增主观声音试听。

制作：内置image_gen五项新素材，源/母版/运行分开保存，提示词见generation-prompts.json；无第三方付费服务。独立运行包采用官方Godot4.7.2便携程序+PCK，非发行模板裁剪包。
''',encoding='utf8')
(p/'RESUME-v04.md').write_text('''# v0.4 接续
读取docs/v04/execution.md、scene-manifest.json、element-mapping.json、qa-summary.json、delivery.md和.production状态。
正式工程仍godot/first-level；固定4.7.2.ed1daf0bf。七房场景scenes/r1，设计数据assets/rooms.json，原图及SVG assets/reference/r1。runtime/v04为5项新分层/模块资源；source/master保留未改原件。
本轮新增room_routes、route_blueprint、scene_inspector、world_graph、route_checks、route_mechanism_checks、v04_art_checks；main/level/player/game/scenery_motion/atmosphere已接入。
主路门按数据与门ID匹配返回，F9借A2/A3且禁止写档；远侧闩保持关闭；07右墙封闭。Inspector状态退出必须恢复层显隐、原进度和位置。
证据evidence/v04/package-*；branch/latch/death为项目图形或独立进程回归。A3测试夹具起点x25/y16，仅之后挂环与跨房属Input路线实测。
备份work/r1-before-route-v04.zip；v0.3运行包与原设计册未变。
不要重跑work/r1_route_art_v04.py或r1_route_code_v04.py，它们是一次性修改脚本，会重复节点。修改新场景后按实际影响重测。work/r1_v04_verify.py接受art/routes/mechanisms/play/branch/latch/death/reload/normal；最后导出work/r1_v04_package.py。map-only变化可--visual-only，必须记录复用测试的范围。
后续可做：统一门、奖励与敌人的正式分件动画；长地形专用模块；真实可步行失败坡（需单独更新几何合同）；后续区域A2/A3取得流程。当前不扩建后续区域。
''',encoding='utf8')
for name in ['qa-summary.json','scene-manifest.json','assets.json','generation-prompts.json','element-mapping.json','delivery.md','route-review.md','art-review.md']:shutil.copy2(d/name,out/'docs'/name)
def image_card(src,label):return f'<figure><a href="{src}" target="_blank"><img loading="lazy" src="{src}" alt="{escape(label)}"></a><figcaption>{escape(label)}</figcaption></figure>'
css='''*{box-sizing:border-box}body{margin:0;background:#07151f;color:#d3e0df;font:16px/1.7 "Microsoft YaHei",sans-serif}main{max-width:1400px;margin:auto;padding:32px}a{color:#91d9cb}h1,h2,h3{color:#f0d6a6;line-height:1.3}h1{font-size:42px}header{padding:32px 0}section{margin:36px 0;padding:26px;background:#0d2330;border:1px solid #29434b;border-radius:12px}nav{position:sticky;top:0;background:#07151feb;padding:12px;z-index:2;display:flex;gap:18px;flex-wrap:wrap;border-bottom:1px solid #29434b}figure{margin:0}img{width:100%;display:block;background:#08141c}figcaption{color:#9eafb1;padding:8px 0} .pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.tag{color:#88cbbb}table{width:100%;border-collapse:collapse;font-size:14px}td,th{border-bottom:1px solid #29434b;padding:9px;text-align:left;vertical-align:top}details{margin:18px 0}summary{cursor:pointer;color:#f0d6a6;font-size:18px}.scroll{overflow:auto}.tools{display:flex;gap:8px;flex-wrap:wrap;margin:15px 0}button{background:#183b49;color:#d9ece7;border:1px solid #59817d;border-radius:6px;padding:10px 18px;cursor:pointer}button.active{background:#8bd0bc;color:#102632}.note{border-left:3px solid #c5a878;padding:10px 18px;background:#112b38}code{color:#f0cba0}.small{font-size:14px;color:#a9bdc0}@media(max-width:850px){main{padding:15px}.pair{grid-template-columns:1fr}h1{font-size:30px}section{padding:15px}}'''
parts=[f'<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>须门遗港 v0.4 · 七房路线与分层场景</title><style>{css}</style><nav><a href="#top">交付</a><a href="#world">关系</a>'+''.join(f'<a href="#{r["id"]}">{r["name"]}</a>' for r in rooms)+'<a href="#elements">33元素</a><a href="#qa">验收</a></nav><main id="top"><header><span class="tag">GODOT 4.7.2 / R1 SCENE RESTORATION / v0.4</span><h1>须门遗港<br>七房原图 × 路线坐标 × 四层实景</h1><p>沿用首关设计册，制作可编辑的 Godot 场景。原图负责构图与材质；房级坐标负责平台、门、锚点和路线。以下实景均为真实引擎截图。</p><p><a href="../../builds/须门遗港-v0.4-七房路线与分层/操作说明.txt">操作说明</a> · <a href="../../builds/须门遗港-v0.4-七房路线与分层.zip">完整运行包</a> · <a href="../../godot/first-level/project.godot">可编辑工程</a> · <a href="docs/delivery.md">交付记录</a></p></header>']
parts+=[image_card('screenshots/gameplay.png','实际首访玩法截图：角色、敌人、平台与分层背景'),'<section><h2>如何查看与行走</h2><table><tr><th>功能</th><th>操作</th></tr><tr><td>巡览七房</td><td>F6；1–7切房；WASD镜头；F5全房/近景</td></tr><tr><td>设计对照</td><td>F7坐标叠加；F8原图与坐标；F10单层；Tab总图</td></tr><tr><td>回访路线验证</td><td>F9借用A2/A3，不写存档；W浮升，落台补压；J挂环/换环，Space脱环；E进门/拾取</td></tr><tr><td>正常首访</td><td>A/D、Space、Q、R、F、E、L；Boss胜后领取Shift冲刺；Esc暂停</td></tr></table><p class="note">首访仍是01–05。06/07回访段已实现并实测，A2/A3正式获得流程属于后续章节。F9退出会恢复进入前的位置与进度。R2-05、R3-01保留为外部边界。</p></section><section id="world"><h2>鲸头内的位置与连接</h2>',image_card('screenshots/world-connections.png','全景中的位置是压缩解剖投影，不是七房横向拼接'),'<p>口角旧伤 → 口腔须筛 → 舌背 → 舌根后口咽 → 咽后食管。A2支路经上颚旧脱层、颅侧创伤进入鼻道外侧；厚骨板隔开口鼻，不穿脑。A3支路到上颚须根记忆袋，必须从原门返回。</p><p><code>01 ⇄ 02 ⇄ 03 ⇄ 04 ⇄ 05 → R3-01</code><br><code>02 ⇄ 06 → R2-05（远端闩）；02 ⇄ 07（右壁封闭）</code></p></section>']
for r in rooms:
 id=r['id'];parts+=[f'<section id="{id}"><span class="tag">{id} / {r["width"]} × {r["height"]} U</span><h2>{escape(r["name"])}</h2><p>{escape(r["anatomy"]["part"])} · {escape(r["anatomy"]["position"])}</p><div class="pair">',image_card(f'originals/{id}.png','原设计图：视觉与氛围参考'),image_card(f'screenshots/{id}-composite.png','Godot实景：按精确坐标重建'),'</div><p>'+escape(r['firstVisit'])+'</p><details open><summary>精确路线与房门</summary><div class="pair">',image_card(f'maps/{id}.svg','设计坐标图：1U = 64px'),image_card(f'screenshots/{id}-coordinates.png','引擎坐标叠加：实际平台、门、锚点'),'</div><ol>'+''.join('<li>'+escape(t)+'</li>'for t in r['walkthrough'])+'</ol><div class="scroll"><table><tr><th>门ID / 去向</th><th>脚位 U</th><th>条件 / 位置</th></tr>']
 for door in r['doors']:
  condition=' + '.join(door['condition'].get('requiresAll',[])+door['condition'].get('completionFlags',[]))or'基础通行'
  if door['id']=='E34':condition+='；远侧SC_BLOWHOLE闩，本侧不可开'
  parts.append(f'<tr><td>{door["id"]} → {door["to"]}</td><td>({door["x"]}, {door["y"]})</td><td>{escape(condition)} / {escape(door["side"])}</td></tr>')
 parts+=['</table></div></details><details><summary>平台与元素层级</summary><table><tr><th>平台</th><th>左端x / 顶边y / 宽w（U）</th><th>类型</th></tr>'+''.join(f'<tr><td>{pl["id"]}</td><td>{pl["x"]} / {pl["y"]} / {pl["w"]}</td><td>{escape(pl["kind"])}</td></tr>' for pl in r['platforms'])+'</table><p class="small">Far → Middle → World/Shelf_* + Actors + DoorsAnchorsAndMechanisms → Foreground；雾与事件效果独立。</p></details>',f'<h3>四层独立查看</h3><div class="tools" data-room="{id}">'+''.join(f'<button data-layer="{k}" class="'+('active'if k=='composite'else'')+f'">{label}</button>'for k,label in [('composite','合成'),('far','远景'),('middle','中景'),('play','可玩层'),('front','前景')])+f'</div><img id="layers-{id}" src="screenshots/{id}-composite.png" alt="{r["name"]}分层实景" loading="lazy"><p class="small">远景0.10/0.12；中景0.5；可玩层1.0；前景1.2。运行截图的单层显隐不会修改碰撞。</p></section>']
parts+=['<section id="elements"><h2>33项元素与实际引用</h2><p>区分本轮新增、已实现复用和仍待精修的表现。物件的图像、坐标和交互不是同一个文件。</p><div class="scroll"><table><tr><th>ID / 元素</th><th>节点或代码</th><th>实现与边界</th></tr>'+''.join('<tr><td>'+escape(a['id']+' '+a['name'])+'</td><td>'+escape(a['node_or_code'])+'</td><td>'+escape(a['implementation'])+'</td></tr>'for a in asset_rows)+'</table></div></section>','<section id="qa"><h2>实际验收</h2><p>49项场景检查、35项回访路线检查、6项机关检查通过；首访五房通关、舌台支路往返、死亡复活、存档与门闩重载通过。所有最终独立包检查进程退出码0，日志无脚本错误。</p><div class="pair">',image_card('screenshots/A2-three-platforms.png','A2实际浮升到须筛上层'),image_card('screenshots/07-right-wall-rewards.png','A3实际抵达记忆袋右岸，右壁封闭'),'</div><p class="note">已实现与运行验证不等于用户审美定稿。长地形仍有拉伸与模块重复；角色/Boss动作和部分门、奖励美术沿用。软床采用局部触发恢复，不是可自由行走的底部返坡。未新增声音主观试听、低配机器和手柄验证。</p><p><a href="docs/qa-summary.json">检查证据索引</a> · <a href="docs/scene-manifest.json">七房节点及坐标清单</a> · <a href="docs/element-mapping.json">元素映射</a> · <a href="docs/assets.json">素材来源</a> · <a href="docs/generation-prompts.json">AI绘图提示词</a></p></section><footer class="small">原始设计册与v0.3运行包保留；新增素材由内置image_gen制作，源/母版/运行文件分开保存。原创鲸落IP。验收者：AI；截图：Godot实际渲染。</footer></main><script>document.querySelectorAll(".tools").forEach(row=>row.addEventListener("click",e=>{const b=e.target.closest("button");if(!b)return;row.querySelectorAll("button").forEach(x=>x.classList.toggle("active",x===b));document.getElementById("layers-"+row.dataset.room).src="screenshots/"+row.dataset.room+"-"+b.dataset.layer+".png";}));</script></html>']
page=out/'场景交付册.html';page.write_text(''.join(parts),encoding='utf8')
b=Path('G:/鲸落万物生/builds/须门遗港-v0.4-七房路线与分层');archive=b.with_suffix('.zip')
# with_suffix would remove .4; explicit sibling filename preserves version.
archive=b.parent/(b.name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for f in b.iterdir():
  if f.is_file():z.write(f,b.name+'/'+f.name)
with zipfile.ZipFile(archive)as z:assert z.testzip() is None
class Links(HTMLParser):
 def __init__(self):super().__init__();self.paths=[]
 def handle_starttag(self,tag,attrs):
  for k,v in attrs:
   if k in ['href','src']and v and not v.startswith(('#','http:','https:')):self.paths.append(v)
parser=Links();parser.feed(page.read_text('utf8'));missing=[a for a in parser.paths if not (out/a).exists()];assert not missing,missing
(d/'delivery-check.json').write_text(json.dumps({'page':str(page),'checked_local_links':len(parser.paths),'missing':missing,'zip':str(archive),'zip_crc':'passed','image_count':len(list((out/'screenshots').glob('*.png')))},ensure_ascii=False,indent=2),encoding='utf8')
print('Delivery gallery, archive and link/CRC verification complete:',page)
