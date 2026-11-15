"""Compose library swim atlases, bubbles and marine snow without new geometry."""
import json


def build_ambience(sc, room, game, v):
    config=json.loads((game/'content/whalebelly/layout/atmosphere-v1.json').read_text(encoding='utf-8'))
    width,height=room['size']
    index=int(room['id'][-2:])-1
    fish_script=sc.ext('Script','res://src/world/scenery/chapter/fish_group.gd')
    bubble_script=sc.ext('Script','res://src/world/scenery/local_environment/elements/bubble_emitter.gd')
    if room['id'] not in config['enabled_rooms']:
        for n in range(2):
            sc.node('School'+str(n),'Node2D','Middle',script=fish_script,bounds='Rect2(%s,%s,430,130)'%(160+n*max(420,width-900),260+n*180),population=10,species=n,phase=n*2.8)
            sc.node('Bubbles'+str(n),'Node2D','Middle',script=bubble_script,bounds='Rect2(%s,%s,130,360)'%(300+n*max(500,width-800),350),population=8,external_clock='true',seed_id=index*13+n,bubble_opacity=.22)
        return
    density=config['boss_density'] if room['id']=='R1-04' else 1.0
    groups=[('DistantSchool','Far/Depth','far',0,[40,height*.14,width-80,height*.36],True,False),
            ('School0','Middle','silver',0,[60,height*.27,width-120,height*.26],True,False),
            ('School1','Middle','teal',1,[width*.48,height*.48,width*.35,height*.22],False,False),
            ('LanternSchool','Middle','lantern',2,[80,height*.58,width-160,height*.16],True,True)]
    for n,(name,parent,kind,species,box,migrate,reverse) in enumerate(groups):
        spec=config['fish'][kind]
        sc.node(name,'Node2D',parent,script=fish_script,bounds='Rect2('+','.join(str(round(x,3)) for x in box)+')',
                population=round(spec['count']*density),species=species,phase=1.5+n*1.2+index*.83,
                fish_widths=v(spec['widths']),school_tint='Color('+','.join(str(x) for x in spec['tint'])+')',
                path_seconds=spec['period'],swim_seconds=2.8+n*.25,migrate=str(migrate).lower(),reverse=str(reverse).lower(),
                formation_size=v([min(430,width*.28),height*.13]),z_index=2)
    for n in range(3):
        near=n==2
        sc.node('NearBubbles' if near else 'Bubbles'+str(n),'Node2D','World' if near else 'Middle',script=bubble_script,
                bounds='Rect2(%s,%s,%s,%s)'%(round(width*.08 if near else width*(.26+n*.43)),round(height*.12),round(width*.84 if near else width*.15),round(height*.80)),
                population=round((config['bubbles']['near_count'] if near else config['bubbles']['count_per_plume'])*density),
                external_clock='true',seed_id=index*19+n*7,size_range=v([8,16] if near else [3.5,8]),base_speed=19 if near else 13+n*3,
                bubble_opacity=.18 if near else .34,z_index=2 if near else 1)
    camera_compensation=max(1.0,width/1640)
    sc.node('MarineSnow','Node2D','Middle',script=sc.ext('Script','res://src/world/scenery/kit/kit_drift.gd'),
            texture=sc.ext('Texture2D','res://art/world-kit/fx-particle-soft.png'),
            bounds='Rect2(20,80,%s,%s)'%(width-40,height-140),population=round(config['snow']['count']*density),
            velocity=v([4.5,6.5]),sway=9.0,size_range=v([2.5*camera_compensation,6*camera_compensation]),opacity=.24,tint='Color(0.58,0.77,0.80,1)',
            seed_id=index+170,external_clock='true',z_index=3)
