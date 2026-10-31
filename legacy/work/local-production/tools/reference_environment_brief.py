from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1];S=R/'assets/source/xumen-reference-environment'
items=[]
def add(id,name,category,box,layer,motion='static',detail='',observed=True):
    items.append(dict(id=id,name=name,category=category,reference_box=box,layer=layer,instances=1,source='original/reference.png',asset=id+'.png',motion=motion,motion_description=detail or '保留原图静态材质与高光',origin='observed'if observed else 'inferred_hidden_fill',collision='not_applicable:本轮仅环境展示',interaction='not_applicable:无玩法或角色控制',audio='not_applicable:本轮未要求声音',acceptance='实际场景可见；固定镜头对齐本框轮廓，根部/位置/层级与原图一致；独显无非本层大片背景'))
add('ENV-DEPTH','深蓝远洞与水雾','background',[0,0,1280,720],-60)
add('ENV-UNDERPAINT','遮挡补绘与镜头边缘余量','background',[0,0,1280,720],-70,detail='仅补全被遮挡区域与小幅视差余量，不设计新地图',observed=False)
for i,(n,b) in enumerate([('左侧斜骨与远柱',[125,140,365,340]),('中央暗柱和交叉骨拱',[360,130,460,370]),('右侧远柱与斜骨',[775,145,440,420])]):add(f'MID-{i+1:02}',n,'middle',b,-50)
add('ROOF','上缘暗色洞顶','ceiling',[0,0,1280,126],0)
add('WALL-L','左侧多孔洞壁','wall',[0,28,156,456],0)
add('WALL-R','右侧多孔洞壁','wall',[1170,0,110,720],0)
add('ROAD','完整起伏拱形道路和支撑','terrain',[0,386,1280,334],10)
add('PORTAL','左侧骨壳洞口与红色附着物','portal',[1,324,127,151],12)
add('LAMP','洞口暖光与壳内亮区','light',[39,358,68,96],13,'smooth_luminance','原光照位置不变；亮度仅±2%，周期7秒，不叠加第二份完整光晕')
for i,b in enumerate([[110,37,207,274],[264,0,226,273],[443,0,187,220],[579,0,153,155],[735,0,153,129],[902,0,305,326]]):add(f'BALEEN-{i+1:02}','乳白垂须分簇'+str(i+1),'baleen',b,4,'root_sway','根部固定，末端水平振幅0.65–1.1像素，周期6–10秒，各簇错相')
for i,(n,b) in enumerate([('左壁藤壶/菌簇',[0,86,142,252]),('洞口脚边白色管簇',[0,410,146,77]),('左岸低矮管簇',[226,439,109,41]),('坡左象牙管簇',[335,393,177,61]),('拱顶孔状骨与海绵',[509,365,150,65]),('拱右多孔附生物',[686,391,151,78]),('右坡白色管簇',[831,436,147,69]),('右岸密集管簇',[1039,464,173,68]),('道路下缘左附生簇',[228,500,256,108]),('道路下缘中央附生簇',[576,475,260,119]),('道路下缘右附生簇',[925,535,287,158]),('底部远岸管簇',[649,614,280,50])]):add(f'DECOR-{i+1:02}',n,'sessile_cluster',b,11)
for i,b in enumerate([[270,410,44,53],[651,340,45,63],[795,447,35,44],[1145,427,40,79]]):add(f'PLANT-{i+1:02}','柔软海草'+str(i+1),'plant',b,12,'root_sway','根部固定，末梢0.45–0.8像素，周期7–11秒；硬壳/管状装饰仍静态')
for i,b in enumerate([[321,526,36,92],[447,534,46,82],[778,545,45,89],[1005,570,53,83]]):add(f'VINE-{i+1:02}','悬垂藻丝'+str(i+1),'plant',b,12,'root_sway','顶端固定，下端微摆0.55像素；不带动道路变形')
for i,b in enumerate([[553,150,221,81],[866,325,196,74]],start=1):add(f'FISH-{i+1:02}','远处鱼群'+str(i+1),'fish_school',b,-30,'drift','独立透明鱼群，保持源图尺度；横移±3像素、上下±0.5像素，周期20–32秒')
for i,b in enumerate([[143,170,89,220],[414,310,72,98],[786,119,154,282],[1036,358,95,128]]):add(f'BUBBLE-ZONE-{i+1:02}','气泡柱区域'+str(i+1),'bubble_emitter',b,-20,'rise_recycle','基于源图小泡纹理；分区循环上升7–13px/s、尺寸2–7px；清除旧烘焙泡，无出屏永久积累')
for i,b in enumerate([[626,0,150,295],[792,0,172,315],[909,47,144,263]]):add(f'BEAM-{i+1:02}','水下光束'+str(i+1),'light_beam',b,-35,'smooth_luminance','方向固定；不做第二套叠加照明，分离原像素后±1.2%平滑变化')
for i,b in enumerate([[0,482,443,238],[321,586,555,134],[832,620,448,100]]):add(f'FRONT-{i+1:02}','模糊暗前景'+str(i+1),'foreground',b,50)
add('CHARACTER','参考姿势展示角色（含骨鸣器/红绳/腰灯）','display_character',[142,393,78,76],20)
contract={'id':'xumen-reference-environment','reference_sha256':hashlib.sha256((S/'original/reference.png').read_bytes()).hexdigest(),'canvas':[1280,720],'scope':'仅本轮图片可见环境与展示角色；无战斗/敌人/任务/存档/角色控制/玩法碰撞','camera':{'fixed':[640,360],'demo_travel_px':[5,2],'edge_padding_px':24},'engine':'Godot 4.7.2.stable.official.ed1daf0bf','elements':items,'status':'scanned_pending_asset_production','scan':'九宫格+四边+遮挡层；纹理中的不可动硬壳、海绵与附着管簇静态分组，不按每个像素虚构独立节点。','source_policy':'仅本轮reference.png；不读取历史房间图片作为美术输入。隐藏补绘标推断，非画外地图。'}
(S/'elements.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8',newline='\n')
instructions=[('01_inventory','按九宫格和边缘登记背景、骨拱、顶/壁、道路、垂须、静态装饰、微动植物、光、鱼泡、前景与角色。输出elements.json，范围外维度全部NA。'),('02_assets','内置imagegen只补绘被遮挡区域和清除需独立移动的烘焙元素；原图主要结构以原生Godot遮罩抽取。生成透明PNG、保留SVG/JSON母版和生成记录。检查透明边缘再接入。'),('03_static','在现有WhalebellyRuins中建独立无玩法场景；1280×720固定机位原位合成。导出实机截图/差异图/图层独显。失败只修对应遮罩或补绘区。'),('04_motion','静态对齐后添加根部权重微摆、远鱼慢漂、分区气泡回收、低幅光变和限幅视差。角色仅独立静置；地形不变形。'),('05_acceptance','核验全部实例、无玩法节点、引用加载、零位构图、镜头四极无露边、30秒环境循环与帧时；导出实际游戏截图和动态视频，记录未完成项。')]
for name,body in instructions:(S/'instructions'/f'{name}.md').write_text('# '+name+'\n\n'+body+'\n\n输入：original/reference.png；原件不得覆盖。输出：当前源目录、assets/runtime/xumen-reference-environment 与唯一Godot工程。\n',encoding='utf8',newline='\n')
print('Registered',len(items),'elements/clusters')
