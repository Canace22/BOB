from pathlib import Path
import base64, json, hashlib, shutil, html, sys
from PIL import Image
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
src=Path(sys.argv[1]); img=p/'images/head-interior-v4.png'
archive=p/'archive/pre-interior-v4';archive.mkdir(parents=True,exist_ok=True)
f=p/'首关全景与拆解册.html'
if not (archive/f.name).exists():shutil.copy2(f,archive/f.name)
shutil.copy2(src,img)
shutil.copy2('C:/Users/Kingsoft/.codex/generated_images/01a15e43-0218-75b2-af77-efe609e99875/exec-94ff05d5-69a7-41e5-92bc-51a0719a589a.png',p/'images/head-interior-v4-draft.png')
shutil.copy2('C:/Users/Kingsoft/AppData/Local/Temp/codex-clipboard-a1c65093-cbbc-4d85-9077-3985843701ff.png',p/'references/interior-v4-shape-lock.png')
s='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1800 1270"><rect width="1800" height="1270" fill="#081e29"/><style>text{font-family:Microsoft YaHei,sans-serif}</style><text x="40" y="40" fill="#f2d8ac" font-size="27">固定鲸头轮廓 · 内部重绘与七房分区</text><text x="40" y="74" fill="#adced3" font-size="18">编号为区域投影，虚线是路线关系；完整跳距与门位仍采用下方七房坐标图。</text>'
s+=f'<image x="40" y="100" width="1720" height="860" href="data:image/png;base64,{base64.b64encode(img.read_bytes()).decode()}"/>'
points=[('01',.19,.46,'口角旧伤 / 入口与壳灯'),('02',.34,.51,'上颚须下 / 悬台与红绳'),('03',.51,.55,'舌背褶面 / 阶梯与裂隙'),('04',.76,.57,'舌根口咽 / 必经负壳蟹'),('05',.94,.54,'咽后食管 / 冲刺通道'),('06',.86,.35,'后上颅侧旧伤 / A2回访'),('07',.53,.28,'前上须根脱层 / A3回访')]
coords=[(40+x*1720,100+y*860)for _,x,y,_ in points]
s+='<polyline points="'+' '.join(f'{x},{y}' for x,y in coords[:5])+'" fill="none" stroke="#ffd186" stroke-width="3" stroke-dasharray="8 9"/>'
for (n,x,y,label),(px,py)in zip(points,coords):
 s+=f'<circle cx="{px}" cy="{py}" r="24" fill="#0a2735" stroke="#ffcc83" stroke-width="2"/><text x="{px}" y="{py+8}" text-anchor="middle" fill="#fff2d1" font-size="22">{n}</text>'
for i,(n,x,y,label)in enumerate(points):
 s+=f'<text x="{40+(i%3)*580}" y="{1010+(i//3)*48}" fill="#efcd9d" font-size="21">{n}　{html.escape(label)}</text>'
s+='<text x="40" y="1180" fill="#bdd0d3" font-size="18">06 为颅侧旧伤分区投影，具体通路在侧壁，不穿脑或鼻道；07 为原路返回的支线。</text><text x="40" y="1215" fill="#bdd0d3" font-size="18">04 战胜后获得 A1，才进入 05；概念图不承担能力门、敌人数量、碰撞与跳距的精确表达。</text><text x="40" y="1250" fill="#8eaeb5" font-size="17">手绘概念 / 压缩巨鲸空间 / 非医学剖面 / 未接入引擎</text></svg>'
(p/'maps/head-interior-v4-labeled.svg').write_text(s,encoding='utf8')
page=f.read_text('utf8');a=page.index('<section id="panorama">');b=page.index('<section id="route">',a)
section='''<section id="panorama"><h2>01 / 鲸头不变，重绘口腔内的冒险空间</h2><p class="note">以你指定的图 1 为外形基准，保留宽钝吻端、窄口裂、下颌弧线、右下鳍和海床视角。内部采用你提供的关卡原画语言：象牙色须幕、珊瑚粉舌台、靛蓝纵深、琥珀壳灯与红绳机关。</p><figure><a href="images/head-interior-v4.png" target="_blank"><img src="images/head-interior-v4.png" alt="固定鲸头外形，重新绘制分层鲸须、舌台跳跃路线与负壳蟹战场"></a><figcaption>内部重绘 V4 · 主路线从左向右展开；小型探索者、壳灯和蟹群提供巨鲸尺度参照。点击查看原尺寸。</figcaption></figure><details open><summary>七房分区与主路线投影</summary><a href="maps/head-interior-v4-labeled.svg" target="_blank"><img src="maps/head-interior-v4-labeled.svg" alt="重绘全景上的七房分区与路线投影"></a></details><div class="grid"><article class="card"><h3>舌面成为可走的地形</h3><p>完整舌体保留在底部，上表面形成高低褶台、浅裂隙和可落脚的宽台。口角低坡引入基础跳跃，中央须筛下增加悬吊台和红绳节点，深处舌根留出战斗空间。</p></article><article class="card"><h3>前后层次服务可读性</h3><p>远层用暗蓝凹面与远侧须列；中层用分组垂须和壳生物；可玩层用暖粉台面与琥珀引导灯；近层用深色组织边缘。头部外皮仍作为完整边框。</p></article><article class="card"><h3>主路与回访路线</h3><p>01 入口→02 须筛→03 舌台→04 舌根 Boss→05 咽后食管。04 必须完成战斗，获得 A1 后继续。07 在前上须根，06 在后上颅侧旧伤；两者为后续能力回访区域，脑区不承载玩法。</p></article></div><p class="muted">全景压缩了七房距离，展示空间与美术关系。敌人数量、跳距、能力门和完整可达路径以七房坐标图为准；没有把图像中的装饰悬台自动当作新增可通行路线。外形经目视比对保留，不声称像素完全一致。</p><details><summary>外形基准：用户指定原图</summary><img src="references/interior-v4-shape-lock.png" alt="本轮外形锁定原图" loading="lazy"></details><details><summary>上轮结构底图（留档）</summary><img src="images/head-structure-v3-final.png" alt="上轮无装饰结构底图" loading="lazy"></details></section>'''
page=page[:a]+section+page[b:]
page=page.replace('href="docs/鲸头v3复核.md">本次鲸头结构重绘复核','href="docs/内部重绘v4复核.md">本次内部重绘复核')
page=page.replace('href="data/prompts.json">本轮英文绘图提示词','href="data/interior-v4-prompt.txt">本轮英文绘图提示词')
page=page.replace('头顶喷气孔内缘／鼻道上段｜','头顶喷气孔旁的颅侧旧伤／鼻道外侧｜')
page=page.replace('大片颅骨板、鼻道黏膜与颅侧旧伤','大片颅骨板、鼻道外侧软组织与颅侧旧伤')
page=page.replace('<h2>06 / 来源、交付与接续</h2>','<h2>06 / 来源、交付与接续</h2><p class="note">本轮只更新鲸头内部全景和分区投影。R1-06 部位说明以鼻道外侧旧伤为准；旧房间数据内的“鼻道上段”等历史标签待下轮数据整理，不能据此制作口鼻直通路线。旧分层板与房间原画是局部素材参考，不代表本轮全景的精确拆层。</p>')
f.write_text(page,encoding='utf8')
record={'version':'interior-v4','tool':'builtin image_gen','edit_target':'references/interior-v4-shape-lock.png','style_references':['references/user-1.png','references/user-2.png','references/user-4.png'],'draft':'images/head-interior-v4-draft.png','final':str(img.relative_to(p)),'source':str(src),'prompt':'data/interior-v4-prompt.txt','repair_prompt':'data/interior-v4-fix-prompt.txt','size':list(Image.open(img).size),'sha256':hashlib.sha256(img.read_bytes()).hexdigest(),'cost':'unknown; no third-party paid service','acceptance':'agent visual review; not user approval'}
(p/'data/interior-v4-generation.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf8')
print('Installed interior-v4 art, section and annotated map')
