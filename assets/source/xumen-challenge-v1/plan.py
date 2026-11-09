"""Create a concept-only chapter challenge contract from current campaign values."""
from pathlib import Path
import json,shutil,hashlib
SRC=Path(__file__).resolve().parent;ROOT=SRC.parents[2]
def save(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def main():
    for sub in ['inputs','images','review']: (SRC/sub).mkdir(parents=True,exist_ok=True)
    for source in ['game/src/campaign/campaign_profile.gd','assets/source/xumen-keyart-v2/inputs/runtime-layout.json']:
        dest=SRC/'inputs'/Path(source).name
        if not dest.exists():shutil.copyfile(ROOT/source,dest)
    rooms=[
      dict(id='R1-01',name='外伤坡',focus='安全热身→三段错层跳',gate='基础移动',difficulty=2,landings=[[0,390,611],[540,690,570],[840,1010,500],[1170,1671,632]],flies=[],route='营地安全段→低跳抬升→高低落点→原E01出口',catch='下层骨根回收坡通回前一安全台，原入口营地不变',preserve='原中央拱路总体弧线、左侧营地、顶部须幕和出口；改中央路段，入口400px无敌',enemyRule='无飞怪，无强制冲刺或浮膜',special=[]),
      dict(id='R1-02',name='须筛',focus='短跳限高＋连续错台＋观察飞掠',gate='主路基础跳跃；E33浮膜/E35锚定沿旧门槛',difficulty=3,landings=[[0,360,718],[480,650,640],[810,980,566],[1130,1280,650],[1430,1672,713]],flies=[[735,420],[1190,440]],route='低位主路四次起跳；左上E33与右上E35仍独立回访',catch='四处分开的回收凹台，由实心骨根隔开；不能沿平地下穿全关',preserve='左壁三高台、右侧原锚环与两条上行连接；骨根发光珊瑚保留',enemyRule='首只在宽台演示，第二只分屏激活；同屏最多2只，最多1只出击',special=[{'type':'low-roof','span':[420,570],'y':538,'purpose':'短跳可过；限高拱止于下一起跳区之前'}]),
      dict(id='R1-03',name='舌台',focus='双丘间接力跳＋下层回收＋空中短击',gate='主路基础跳；原碎片支台可用既有二段跳',difficulty=4,landings=[[0,280,565],[420,620,490],[780,940,550],[1100,1320,490],[1470,1672,600]],flies=[[700,350],[1010,385]],route='左丘→低膜台→右丘→原E03；保留独立下层回路',catch='下层完整回收路，失败不直接落进死坑',preserve='两只原尸蟹分置宽丘、中央下垂舌膜、右侧原奖励托台；不增加奖励数量',enemyRule='飞掠区在两丘之间，尸蟹与飞怪不同时压同一落点',special=[{'type':'optional-reward-platform','span':[1000,1130],'y':350,'purpose':'原奖励抬升为支线技术点，主路不强制取'}]),
      dict(id='R1-04',name='负壳蟹前庭',focus='侧台换位＋读招后回落反击',gate='原Boss/胜利旗标',difficulty=4,landings=[[0,360,644],[360,1290,700],[1290,1591,705]],flies=[],route='原前室→平整中央战场→原E04软帘',catch='中央连续实底；不加坑和飞怪',preserve='Boss本体、原前室与封帘；中央930px保持可读战场',enemyRule='Boss激活区飞怪数量0，避免额外弹幕叠加',special=[{'type':'boss-side-ledge','span':[480,650],'y':590,'purpose':'左侧短暂换位'}, {'type':'boss-side-ledge','span':[1120,1300],'y':555,'purpose':'右侧较高换位；不保证免疫Boss现有攻击'}]),
      dict(id='R1-05',name='流膜育窝',focus='三段跳冲接力＋错层落点',gate='原胜利后贴流冲A1可用',difficulty=4,landings=[[0,280,551],[540,760,560],[1020,1220,505],[1450,1612,558]],flies=[[650,370],[1120,330]],route='两端稳定台＋两中间膜岛，三沟260/260/230px',catch='三组软床和局部回收坡，保留可见下层',preserve='三沟三软床、两中岛、原出口位置；暖光生态装饰不改成门',enemyRule='仅在宽台等待区预告；飞掠固定走廊，单次1HP且小击退',special=[]),
      dict(id='R1-06',name='喷气孔上层',focus='浮膜控制落速＋高差连续攀升',gate='沿旧E33浮膜A2',difficulty=5,landings=[[0,300,791],[390,620,650],[710,830,550],[930,1170,490],[1260,1477,343]],flies=[[805,355]],route='侧伤口→大补压台→小接力台→大平台→原高位目标',catch='完整底部回收坡，落地恢复浮膜时间；每组后有宽台停顿',preserve='原三处大平台地标与底部回收坡、右上原奖励和封闩',enemyRule='一只；宽补压台停留0.5秒后才可预告，浮膜进入与落地保护期间不出击',special=[]),
      dict(id='R1-07',name='鲸须记忆袋',focus='四环串接＋释放精度＋原路回访',gate='沿旧E35锚定A3',difficulty=5,landings=[[0,320,565],[680,870,650],[1280,1572,575]],flies=[[1040,400]],route='原四环→窄中台→右端唯一原奖励→原路返回',catch='低处回收台返回上一稳台；不直接走到奖励端',preserve='四环、三落脚组、两缺口、右端原奖励；与喷气孔不新增连接',enemyRule='一只；锚定/释放前后0.8秒不出击，终点奖励区不攻击',special=[{'type':'anchors','points':[[420,270],[680,215],[960,275],[1220,220]],'purpose':'相邻目标距离均小于当前390px搜索距离'}])
    ]
    for r in rooms:
        r['image']='images/'+r['id']+'.png'
        r['landingIds']=[r['id']+'-P'+str(i) for i in range(len(r['landings']))]
        r['flyIds']=[r['id']+'-F'+str(i+1) for i in range(len(r['flies']))]
    d={'scope':'七房地形与低伤害飞怪的概念设计；不改Godot','status':'concept_proposed_not_implemented','baseline':{'source':'game/src/campaign/campaign_profile.gd','maxSpeed':265,'gravity':1050,'jumpSpeed':570,'nominalJumpHeight':570**2/(2*1050),'fallMultiplier':1.35,'doubleJumpSpeed':399,'dashDistance':160,'collision':[28,65],'health':5,'hurtInvulnerability':1.2,'anchorRange':390},'layoutSource':'inputs/runtime-layout.json','rooms':rooms,'enemy':{'id':'EN-LANTERN-RAY','name':'逆流灯鳍','kind':'敌对飞行幼鳐；与远景鱼群分离','bodySize':[40,26],'hitbox':[24,16],'hp':2,'damage':1,'damageNote':'当前整数生命制最小档，不高于普通尸蟹；不虚构半格伤害','patrolSpeed':48,'patrolRadius':90,'warningSeconds':.65,'activeSeconds':.55,'attackSpeed':160,'recoverSeconds':.75,'cooldownSeconds':2.8,'knockbackPixels':24,'hitStunSeconds':.08,'sameScreenLimit':2,'attackerLimit':1,'contactRule':'巡航本体无伤，仅预告后的固定横掠段有伤；不追踪修正路线','deathRule':'两次短击或一次叉鸣弹消散，播放小型发光颗粒；不掉新货币','fairness':['落点至少112px；首次只在宽台演示','每条飞掠走廊都有可等待的稳定台','飞怪击中落至回收面不追加同次环境伤害（本方案拟定，现有软床扣血规则待工程统一）','保留1.2秒受伤无敌，不被第二只连锁命中','原图远景鱼群不变成伤害体']},'counts':{'rooms':7,'worldEdges':6,'newFlyInstances':sum(len(r['flies']) for r in rooms),'newSpecies':1},'acceptanceBoundary':'数值是制作起点，图片不是碰撞；仅做解析可达性筛查与静态审核，未通过Godot试玩前不得称难度平衡完成'}
    save(SRC/'design.json',d)
    if not (SRC/'progress.json').exists():
        save(SRC/'progress.json',{'stage':'layout_specified','completed':['current engine profile read','seven-room proposal and enemy spec'],'next':'生成敌人概念板→逐房地形原画→接回图册并核对七房六边','runtimeChanged':False})
    print('Seven-room challenge concept specified; 8 proposed flying enemies, 1 species.')
if __name__=='__main__':main()
