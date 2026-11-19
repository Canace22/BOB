import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const rooms=[
 ['R3-01','胃枢','22','赭褶胃壁远景，余索红索与贝驮空壳工作位。'],
 ['R2-01','育床','15','蓝紫肺网、红膜台体、菌芽及育床刻痕骨面；育囊原授能条件保留。'],
 ['R2-03','心室观察台','17','破裂心肌地标、肺网深水与膜台腹体；营地、出口保留。'],
 ['R2-04','血巢潮群','18','肺心深层、战斗边台腹体；已有群流与血巢核心继续按战斗状态驱动。'],
 ['R4-01','组合门','31','深海椎列、独立前骨框景和厚骨台；门条件保留。'],
 ['R4-03','上锚路线','33','椎列与菌床骨肩；已有鸣贝八帧开合与原路径保留。'],
 ['R4-05','悬脊鸣贝','35','骨洞远景、战斗边台及现有单Boss八帧；不按旧双贝图增加敌人。'],
 ['R4-06','稳定交通椎','36','椎列深度、尾椎地标与骨音节点；营地、归海支路保留。'],
 ['R5-01','三槽记忆','40','巨颅腔远景与原生骨膜台腹；三槽仍分别读取潮压、骨音、静默。'],
 ['R5-02','安全池','41','颅腔深水与原遮蔽地标；保留上下台和返程落点。'],
 ['R5-04','缄声覆膜','43','颅壁、原生骨膜台体；已有覆膜形变、声壁刻槽及Boss流程保留。'],
 ['R5-08','归海释放槽','47','尾腱海窗原图与暖红前沿；六只幼体八帧及导流闸后游出保留。']
];
const assets='../../../assets/source/whalefall-v5-2-complete/references/';
const qa='../../../game/build/qa/remaining-19-v2/';
const figure=(caption,src)=>`<figure><figcaption>${caption}</figcaption><a href="${src}" target="_blank"><img src="${src}" loading="lazy" alt="${caption}"></a></figure>`;
const body=rooms.map(([id,name,ref,desc])=>`<article id="${id}"><h2>${id} · ${name}</h2><p>${desc}</p><div class="views">${figure('原画参考',`${assets}${ref}_${id}.png`)}${figure('改前 · 相同位置夹具',`${qa}before/${id}-follow.png`)}${figure('当前 · 真实游戏镜头',`${qa}current/${id}-follow.png`)}${figure('当前 · 全景',`${qa}current/${id}-overview.png`)}</div></article>`).join('\n');
const html=`<!doctype html><html lang="zh-CN"><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>后续十二房 · 原画接入审阅</title><style>body{margin:0;background:#091820;color:#dbe5e4;font:16px/1.7 system-ui}main{max-width:1540px;margin:auto;padding:40px 4vw}h1{font-size:36px}h2{color:#e7d6ac}a{color:#8bcedb}nav{display:flex;flex-wrap:wrap;gap:14px}article{margin:50px 0;padding-top:12px;border-top:1px solid #29434b}.views{display:grid;grid-template-columns:repeat(2,1fr);gap:18px}figure{margin:0}figcaption{padding:8px;color:#abbfbe}img{display:block;width:100%;background:#101e28}.note{border-left:3px solid #8bcedb;padding:14px 22px;background:#102731}@media(max-width:800px){.views{grid-template-columns:1fr}}</style><main><a href="地图布局.html">← 须门布局审阅</a><h1>后续十二房 · 原画与实机</h1><p>2026-11-16 · 当前19房规则 · 本地审阅</p><div class="note">补足肺心、胃肠、脊骨、颅腔与尾海的原画层次。保留须门七房、已删除柱体、当前玩法顺序、门／奖励／Boss条件。原画构图适配当前可玩平台，不把旧36房路线自动搬回工程。</div><p>以下截图来自真实主场景，使用相同位置／镜头夹具；改前来自600a9568阶段副本。截图不能替代自然通关、声音或用户美术认可。余索、贝驮是现有静态交谈角色；鸣贝与幼体沿用前批已接入的八帧动作。本批不是新建12房或新增角色。</p><nav>${rooms.map(([id,name])=>`<a href="#${id}">${name}</a>`).join('')}</nav>${body}<p>截图仅保存在本机 build/qa；制作与测试边界见 <a href="../../../assets/source/remaining-19-v2/README.md">本批记录</a>。未提交、推送或发布。</p></main></html>`;
const clips=`<h2>已有角色动作 · 本批实机回归</h2><p>鸣贝与幼体沿用前批八帧。以下为隔离位置／进度夹具录制的观感预览，不是新制动作或自然通关录像。</p><div class="views">${figure('鸣贝开合与战斗',qa+'clam.gif')}${figure('开闸后幼体游出',qa+'larvae-outflow.gif')}</div>`;
fs.writeFileSync(path.join(root,'docs/鲸腹遗城原画集/须门遗港地图布局/后续十二房实机.html'),html.replace('<article',clips+'<article'));
