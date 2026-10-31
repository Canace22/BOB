from pathlib import Path
from PIL import Image
import json,hashlib,html,re
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解');E=html.escape
im=Image.open(p/'images/head-cutaway-v2.png');print(im.size)
w,h=im.size
s='<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1800 1240"><rect width="1800" height="1240" fill="#081e29"/>'
s+='<style>text{font-family:Microsoft YaHei,sans-serif}.label{fill:#eff6ee;font-size:21px}.small{fill:#adc8cd;font-size:18px}</style><text x="40" y="40" fill="#f4d3a2" font-size="27">须门遗港 · 鲸头剖面与七房落位</text><text x="40" y="70" class="small">头前方 ←　局部侧壁剖开，显示口内组织　→ 躯干后方 ｜ 虚构巨鲸概念投影，非医学或碰撞比例图</text>'
s+='<image x="40" y="95" width="1720" height="860" xlink:href="../images/head-cutaway-v2.png"/>'
# leader labels, normalized positions refer to image
marks=[('01',.11,.48,70,605,'外伤坡 · 口角旧伤'),('02',.38,.51,360,805,'须筛 · 上颚须下缘'),('03',.53,.65,690,900,'舌台 · 舌背褶面'),('04',.66,.57,1110,800,'负壳蟹 · 舌根/口咽'),('05',.87,.62,1430,720,'流膜育窝 · 食管裂边'),('06',.80,.14,1350,110,'喷气孔上层 · 颅侧旧伤'),('07',.44,.32,470,110,'鲸须记忆袋 · 须根脱层')]
for num,x,y,lx,ly,label in marks:
 px=40+x*1720;py=95+y*860
 s+=f'<path d="M{px} {py}L{lx+80} {ly+20}" fill="none" stroke="#ffd38e" stroke-width="2"/><circle cx="{px}" cy="{py}" r="19" fill="#0c2835" stroke="#ffd38e" stroke-width="2"/><text x="{px}" y="{py+7}" text-anchor="middle" fill="#fff2c8" font-size="18">{num}</text><rect x="{lx}" y="{ly}" width="300" height="38" rx="8" fill="#0a2532" fill-opacity=".94" stroke="#658081"/><text x="{lx+12}" y="{ly+26}" class="label">{E(label)}</text>'
s+='<text x="40" y="1005" fill="#f0d0a1" font-size="25">读图重点</text>'
notes=['① 长吻与上颌形成口顶；象牙色鲸须附着上颚两侧，不是牙齿或钟乳石。','② 一整块厚舌由下颌承托，关卡台面仅占舌背/侧沟局部，不把舌体拆成洞穴大厅。','③ 舌根向后收束到口咽，再沿纵裂食管前往胃枢；咽后没有鲸须。','④ 06位于鼻道外侧旧伤；鼻口间厚隔壁保留，须筛只能经侧伤绕行。07为须根盲袋。','⑤ 01→02→03→04→05为首通；06需A2，07需A3。图中暗组织与装饰不是绕Boss捷径。']
for i,n in enumerate(notes):s+=f'<text x="40" y="{1045+i*35}" class="small">{E(n)}</text>'
(p/'maps/head-cutaway-labeled-v2.svg').write_text(s+'</svg>',encoding='utf8')
f=p/'首关全景与拆解册.html';page=f.read_text('utf8')
start=page.index('<section id="panorama">');end=page.index('<section id="route">',start)
replacement='''<section id="panorama"><h2>01 / 重绘：鲸头外轮廓与口腔剖面</h2><p class="note">根据本次反馈重新构图：保留长吻、上颌、下颌、眼位与头顶喷气孔，再剖开近侧口壁。连续厚舌、上颚须列和后部口咽共同决定关卡落位。</p><figure><a href="images/head-cutaway-v2.png" target="_blank"><img src="images/head-cutaway-v2.png" alt="重绘鲸头：完整头部侧影、上下颌、上颚鲸须、厚舌及咽喉"></a><figcaption>新绘无字原画 · 冷蓝鲸皮围合头部，鲸须挂上颚，舌体由下颌承托；躯干朝右继续。灯与壳窝只是巨物内部的微小维护痕迹。</figcaption></figure><details open><summary>中文解剖说明与七房位置索引</summary><a href="maps/head-cutaway-labeled-v2.svg" target="_blank"><img src="maps/head-cutaway-labeled-v2.svg" alt="鲸头剖面中文标注与七房落位"></a></details><div class="grid"><article class="card"><h3>口腔结构优先</h3><p>上颚与下颌围出口腔；鲸须根植上颚侧缘；舌面作为连续大结构，向后逐渐收束到舌根与口咽。最右食管裂边改为肌膜。</p></article><article class="card"><h3>回访部位纠正</h3><p>06在头部后上方的鼻道外侧创伤袋，07在较前的上颚须根脱层袋。鼻口厚隔壁保留；从须筛去06沿旧伤侧路绕行，不是天然口鼻直通。</p></article><article class="card"><h3>尺度与玩法分开核对</h3><p>沿用虚构120m巨鲸与0.3m拾潮者；图中微型角色是可读性符号。此图是剖面概念投影，非医学等比例，也非无缝碰撞地图。精确平台/奖励/危险以七房坐标图为准。</p></article></div><p class="muted">暖色灯与地标用于指引；通关不沿整个舌面任意行走。部分房间的间隙、环数和奖励为压缩表现，不能把背景舌面、暗组织边缘当作跨关捷径。当前可玩版仍只实现前五房。</p><details><summary>旧版对照：用户指出的鲸头识别不足</summary><p>旧图强调洞穴层次，缺少完整鲸头轮廓与连续口腔组织，已不作为首关整体解剖依据。</p><a href="images/panorama.png"><img src="images/panorama.png" alt="旧版洞穴式全景，仅留作对照" loading="lazy"></a></details></section>'''
page=page[:start]+replacement+page[end:]
page=page.replace('03 / 远景 · 中景 · 可玩层 · 前景','03 / 局部房间材质分析：远景 · 中景 · 可玩层 · 前景')
page=page.replace('这是新绘的分层解释板，','以下沿用上一轮局部房间分层解释板，不代表新鲸头剖面的器官位置；')
page=page.replace('全景及两张拆解板','重绘鲸头全景及两张局部拆解板')
page=page.replace('<a class="card" href="docs/验收记录.md">图像与页面验收 ↗</a>','<a class="card" href="docs/鲸头重绘复核.md">本次鲸头重绘复核 ↗</a>')
f.write_text(page,encoding='utf8')
source='C:/Users/Kingsoft/.codex/generated_images/01a15e43-0218-75b2-af77-efe609e99875/exec-16deca12-b2d5-48ab-b4c6-bb7998120d44.png'
record={'revision':'head-cutaway-v2','user_reason':'缺少鲸头形状和口腔内部结构','tool':'image_gen.imagegen','mode':'built-in reference-based redraw','source':source,'local':'images/head-cutaway-v2.png','prompt':'data/head-redraw-prompt.txt','size':[w,h],'sha256':hashlib.sha256((p/'images/head-cutaway-v2.png').read_bytes()).hexdigest(),'paid_external_service':False,'builtin_cost':'unknown','old_panorama_preserved':'images/panorama.png'}
(p/'data/head-generation-record.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf8')
print('Head redraw installed; original panorama preserved')
