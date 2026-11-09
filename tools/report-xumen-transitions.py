"""Local-only evidence index. Never publish recordings or test saves."""
from pathlib import Path
import json,html
R=Path(__file__).resolve().parents[1];O=R/'game/build/qa/xumen-transitions'
state=json.loads((R/'assets/source/xumen-transitions-v2/production.json').read_text(encoding='utf8'))
edges=[('E01','外伤坡 → 须筛','../xumen-e01/after/1900.png','23专项 / Chrome12+动态7','7da138f6'),
       ('E02','须筛 → 舌台','E02-4100.png','14专项 / Chrome10','3c6f24f8'),
       ('E03','舌台 → 骨腔','E03-6284.png','14专项 / Chrome10','6af59ef0'),
       ('E04','骨腔 → 流膜育窝','E04-8387.png','15专项 / Chrome11 / 实际Boss战','5b86292a'),
       ('E33','须筛 → 喷气孔上层','e33-online/upper-return.png','27专项 / Chrome9 / 52秒动态','a9902202'),
       ('E35','须筛 → 鲸须记忆袋','e35-local/upper-return.png','29专项 / Chrome9 / 52秒动态','91b75ea8')]
cards=[]
for edge,name,img,checks,source in edges:
    pub=state.get('publication_'+edge,{})
    status='线上通过' if pub.get('deployment')=='success' or edge=='E01' else '本地通过 / 线上待复核'
    cards.append(f'<article><h2>{edge} · {name}</h2><p>{status} · {checks}</p><a href="{img}"><img src="{img}" alt="{edge} Godot实际截图"></a><p>本批源码 {source}；画面为对应批次实机取样，非概念图。最终整章版本见页首。</p></article>')
videos=[]
for folder in ['e33-online','e35-online']:
    for path in (O/folder).glob('*.webm'):
        videos.append(f'<h3>{folder} · 实际键盘录像</h3><video controls preload="none" src="{folder}/{path.name}"></video>')
pub=state.get('publication_E35',{})
title='须门遗港 · 六条接头制作与实机验收'
body=f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title>
<style>body{{margin:0;background:#091b27;color:#d9e5df;font:16px/1.75 system-ui,"Microsoft YaHei",sans-serif}}main{{max-width:1400px;margin:auto;padding:32px}}h1,h2{{color:#f1ddba}}a{{color:#8ad8d1}}article,section{{background:#112b38;padding:20px;border:1px solid #30505a;border-radius:12px;margin:18px 0}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(380px,1fr));gap:20px}}article{{margin:0}}img,video{{width:100%;display:block}}small{{color:#aec4c5}}code{{overflow-wrap:anywhere}}table{{border-collapse:collapse;width:100%}}td,th{{border:1px solid #38535d;padding:8px;text-align:left}}</style>
<main><h1>{title}</h1><p>先E01样板，逐条验收后扩展E02、E03、E04、E33、E35。原七房、26地形碰撞、角色技能、能力门、Boss和V6保留；不是扩建新地图。</p>
<section><h2>当前发布</h2><p><a href="https://canace22.github.io/BOB/godot/">正式Godot试玩</a> · 源码 <code>{pub.get('source','91b75ea8，线上待核对')}</code><br>Pages <code>{pub.get('pages','待核对')}</code> · {pub.get('online_keyboard','待线上复核')}</p></section>
<section><h2>本地最后一批</h2><p>check 0错误；工程57；整章实际输入38（含Boss与死亡复活）；独立进程读档2；E35专项29；E33回归27；资源1150项missing=[]。E01/E02当前GPU再次查看，全部接头有同机位/去前景证据。</p>
<p>上行支路浏览器使用既有房间预览和F9能力练习作为明确夹具；随后真实按键下返、上行和跨界，同一角色保留。原生下穿可落回hub主路；Web另用W短制动验证最低台高度。没有注入位置，不声称正常取得后期能力。两次E33失败记录保留，没有修改碰撞迎合测试。</p>
<table><tr><th>无录制暖环境</th><th>中位</th><th>P95</th></tr><tr><td>E33 · RTX5060 / 1280×720</td><td>16.655ms</td><td>17.669ms</td></tr><tr><td>E35 · 同机同规格</td><td>16.663ms</td><td>17.697ms</td></tr></table><p>非战斗/跨设备帧率保证。最终压缩启动149.36MiB，沿用Web分片；不是下载耗时。</p></section>
<div class="grid">{''.join(cards)}</div>
<section><h2>独立素材与动态</h2><p>E01独立骨拱/骨路/前景及三簇垂须；E02—04为各自专用骨膜变体；E33/E35分别高幅绘画、连续骨壁、三种台面，八/十级全部配准原顶面。主路与支路刚性骨路均不变形。鱼的帧动作与世界路径分开，气泡预热、渐隐及有界回收，共用host.clock暂停。</p>
<p>原件、提示词及可编辑ORA/蒙版/坐标在 <a href="../../../../assets/source/xumen-e01-seam-v1/README.md">E01源</a>、<a href="../../../../assets/source/xumen-transitions-v2/README.md">主路源</a>、<a href="../../../../assets/source/xumen-vertical-v1/README.md">支路源</a>。运行位图已入台账并同步game/art，使用内置Imagegen，未调用外部付费生成。</p></section>
<section><h2>验收边界</h2><p>技术及AI视觉复核通过与用户整体审美认可分别记录。更深旧房的裁片轮廓仍可继续精修，不宣称全章原画已全面重绘。Web音频stream播放/循环通过；原生WASAPI设备限制仍在，本轮未新增人工听感签收。QA使用隔离存档与浏览器，没有改写用户存档。</p><p>A/D移动，空格跳跃，S+空格下穿，W浮游制动，Esc暂停；能力门沿用原设计。F9练习不保存能力进度。</p></section>
<section><h2>录像与复跑</h2>{''.join(videos)}<p>截图/JSON/原始录像均为本地证据，不随Pages发布。每批具体指令、选型和恢复动作见production.json、elements.json与game/progress.md。项目Godot Skill和通用场景配方已补入上行视野切边/邻房组合蒙版经验。</p></section></main></html>'''
(O/'六条接头制作与验收.html').write_bytes(body.encode('utf8'))
print(O/'六条接头制作与验收.html')
