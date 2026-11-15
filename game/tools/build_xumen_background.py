"""Source-painted water exposure and independent feathered light volumes."""
import json


def parameters(room, game):
    config=json.loads((game/'content/whalebelly/layout/atmosphere-v1.json').read_text(encoding='utf-8')).get('background',{})
    if room['id'] not in config.get('enabled_rooms',[]): return {}
    return {'water_strength':config['water_strength'],'water_phase':int(room['id'][-2:])*.91}


def build_background(sc,room,game,v):
    if not parameters(room,game): return
    config=json.loads((game/'content/whalebelly/layout/atmosphere-v1.json').read_text(encoding='utf-8'))['background']
    width,height=room['size']
    # All three volumes use one clean light bitmap, with native aspect ratio.
    for index,along in enumerate([.18,.50,.80]):
        scale=height*(1.26-index*.11)/768
        intensity=config['boss_light_strength'] if room['id']=='R1-04' else config['light_strength']
        sc.sprite('WaterLight'+str(index),'Far/Depth','res://art/whalebelly/soft_light/UNDERWATER-SOFT-LIGHT.png',
                  [width*along-256*scale,-height*.08],scale,3,
                  script=sc.ext('Script','res://content/whalebelly/environment/elements/soft_underwater_light.gd'),
                  external_clock='true',intensity=intensity*(1-index*.18),period=18+index*9,
                  phase=index*1.8+int(room['id'][-2:])*.6)
    sc.node('BackgroundCurrent','Node2D','.',script=sc.ext('Script','res://src/world/scenery/layout/background_current.gd'))
