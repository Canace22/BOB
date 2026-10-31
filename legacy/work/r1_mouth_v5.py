from pathlib import Path
import shutil,base64,re,json,hashlib
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
src=Path('C:/Users/Kingsoft/.codex/generated_images/01a15e43-0218-75b2-af77-efe609e99875/exec-192240e0-b712-4559-889b-c9c66161cfb2.png')
dst=p/'images/head-mouth-v5.png';shutil.copy2(src,dst)
archive=p/'archive/pre-mouth-v5';archive.mkdir(parents=True,exist_ok=True)
f=p/'首关全景与拆解册.html'
if not (archive/f.name).exists():shutil.copy2(f,archive/f.name)
shutil.copy2('C:/Users/Kingsoft/AppData/Local/Temp/codex-clipboard-3210e072-c865-4ba3-a96c-f8a3aaec4f06.png',p/'references/mouth-v5-open-reference.png')
shutil.copy2('C:/Users/Kingsoft/AppData/Local/Temp/codex-clipboard-0b485def-4942-4465-8ca3-abc37492c2d8.png',p/'references/mouth-v5-markup.png')
svg=(p/'maps/head-interior-v4-labeled.svg').read_text('utf8')
svg=re.sub(r'data:image/png;base64,[A-Za-z0-9+/=]+','data:image/png;base64,'+base64.b64encode(dst.read_bytes()).decode(),svg)
svg=svg.replace('固定鲸头轮廓 · 内部重绘与七房分区','吻端上下颌分离 · 口腔全景与七房分区')
# R1-01 landing now occupies the lower front lip; move the conceptual marker down.
svg=svg.replace('366.8,495.6','366.8,538.6').replace('cy="495.6"','cy="538.6"').replace('y="503.6"','y="546.6"')
(p/'maps/head-mouth-v5-labeled.svg').write_text(svg,encoding='utf8')
page=f.read_text('utf8').replace('images/head-interior-v4.png','images/head-mouth-v5.png').replace('maps/head-interior-v4-labeled.svg','maps/head-mouth-v5-labeled.svg')
replacements={
'01 / 鲸头不变，重绘口腔内的冒险空间':'01 / 上下颌分开，露出鲸须与口腔入口',
'以你指定的图 1 为外形基准，保留宽钝吻端、窄口裂、下颌弧线、右下鳍和海床视角。内部采用你提供的关卡原画语言：象牙色须幕、珊瑚粉舌台、靛蓝纵深、琥珀壳灯与红绳机关。':'按最新图二调整框出的吻端：上颚形成独立悬挑，下颌形成入口落脚台，两者之间留出清楚的蓝色水体，不再粘连。鲸须自上颚垂下，末端与下方地形保留空隙；中后段布局、右下鳍和海床视角延续上一版。',
'固定鲸头外形，重新绘制分层鲸须、舌台跳跃路线与负壳蟹战场':'上下颌前端分离，鲸须悬垂的开放入口与原有口腔关卡',
'内部重绘 V4 · 主路线从左向右展开':'开口修订 V5 · 上下颌前端不接触，主路线从左向右展开',
'外形经目视比对保留，不声称像素完全一致。':'整体鲸头形态延续上一版，前端开口按最新参考调整，不声称未修改区域像素完全一致。',
'外形基准：用户指定原图':'上一轮外形基准（窄口版本）',
'本轮外形锁定原图':'上一轮窄口版本参考',
'href="docs/内部重绘v4复核.md">本次内部重绘复核':'href="docs/吻端开口v5复核.md">本次吻端开口复核',
'href="data/interior-v4-prompt.txt">本轮英文绘图提示词':'href="data/mouth-v5-prompt.txt">本轮英文绘图提示词',
'本轮只更新鲸头内部全景和分区投影。':'本轮局部调整吻端上下颌的分离开口，并同步更新全景和分区投影。'
}
for a,b in replacements.items():
 assert a in page,a
 page=page.replace(a,b)
page=page.replace('<details><summary>上一轮外形基准（窄口版本）</summary>','<details><summary>本次开口参考</summary><img src="references/mouth-v5-open-reference.png" alt="用户指定上下颌分离参考" loading="lazy" style="max-width:420px"></details><details><summary>上一轮外形基准（窄口版本）</summary>')
f.write_text(page,encoding='utf8')
(p/'docs/吻端开口v5复核.md').write_text('''# 吻端上下颌开口修订 V5

2026-10-27。用户要求红框内前端上下颌不粘连，采用第二张参考的张口结构；此要求替代前轮保留窄口裂的约束。

执行：内置 image_gen 一次局部编辑，源图 images/head-interior-v4.png；标记与参考保存在 references/mouth-v5-markup.png 和 references/mouth-v5-open-reference.png。完整英文提示在 data/mouth-v5-prompt.txt；新图 images/head-mouth-v5.png。上轮图和HTML已保留。

目视检查：前端上下颌具有明显蓝色水体间隔，无皮肤桥连接；上方长须下垂，下方为独立入口台。中后段的舌台、悬台、Boss和脑区结构保持。入口处生成了一个额外的小型探索者尺度示意，与中央角色均为概念标尺，不代表多人玩法。未进行像素一致性承诺。

页面主图和内嵌图像的七房SVG已同步；当前文案删除窄口裂与外形完全不变的要求。PNG/SVG/HTML静态检查见 data/mouth-v5-validation.json。浏览器预览与用户审美验收未运行；没有更改工程、碰撞或通关路线。
''',encoding='utf8')
record={'tool':'builtin image_gen','source':str(src),'input':'images/head-interior-v4.png','references':['references/mouth-v5-markup.png','references/mouth-v5-open-reference.png'],'output':'images/head-mouth-v5.png','prompt':'data/mouth-v5-prompt.txt','sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'calls':1,'third_party_paid':False,'cost':'unknown'}
(p/'data/mouth-v5-generation.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf8')
with (p/'RESUME.md').open('a',encoding='utf8')as out:out.write('\n最新V5吻端修订：用户要求上下颌不粘连，最新首图 images/head-mouth-v5.png，七房投影 maps/head-mouth-v5-labeled.svg。读 docs/吻端开口v5复核.md；前轮窄口裂约束作废。\n')
check=Path('G:/鲸落万物生/BOB/work/r1_interior_v4_check.py').read_text('utf-8-sig').replace('head-interior-v4.png','head-mouth-v5.png').replace('head-interior-v4-labeled.svg','head-mouth-v5-labeled.svg').replace('interior-v4-validation.json','mouth-v5-validation.json')
exec(compile(check,'mouth-v5-check','exec'))
