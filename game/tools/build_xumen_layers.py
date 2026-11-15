"""Register existing painted layers; never export an old walking road."""
import json
from PIL import Image


def build_layers(sc, room, game, v, water_params=None):
    water_params=water_params or {}
    rid = room['id']
    width, height = room['size']
    middle = 'res://art/r1-chapter-scenes/' + rid + '/'
    motion = sc.ext('Script', 'res://src/world/scenery/chapter/pinned_bitmap.gd')
    layer_script = sc.ext('Script', 'res://src/world/scenery/layout/painted_layer.gd')
    # Tiny bounded displacement preserves the registered roof/root composition.
    for name, gain, limit in [('Middle', .025, [8, 5]), ('Foreground', -.04, [12, 7])]:
        for index, text in enumerate(sc.nodes):
            if text.startswith('[node name="' + name + '" '):
                sc.nodes[index] += '\nscript = ' + layer_script + '\nroom_center = ' + v([width/2,height/2]) + '\nresponse = ' + str(gain) + '\nlimit = ' + v(limit)
                break
    if rid == 'R1-01':
        opening_layers(sc, room, game, v, motion, water_params)
        return
    image = Image.open(game / middle.removeprefix('res://') / 'Middle.png')
    frame_width = width+350
    k = frame_width / (image.width - 32)
    left = -175
    top = -200 if rid=='R1-04' else -60
    origin = [left-16*k, top-16*k]
    feather = sc.material('res://src/world/scenery/layout/painted_edges.gdshader',{'feather_pixels':14.0,**water_params})
    chamber_edge = sc.material('res://src/world/scenery/layout/painted_edges.gdshader',{'feather_pixels':14.0,'fade_lower':'true'})
    sc.sprite('OriginalChamber', 'Middle', middle+'Middle.png', origin, k,
              material=chamber_edge,modulate='Color(0.88,0.91,0.94,1)')
    # Far retains its original cutout and a complete painted underpaint beneath.
    bg = Image.open(game / middle.removeprefix('res://') / 'underpaint.png')
    bk = max(width/bg.width,height/bg.height)*1.08
    sc.sprite('OriginalFar', 'Far/Depth', middle+'Far.png',
              [(width-bg.width*bk)/2,(height-bg.height*bk)/2],bk,
              material=feather,modulate='Color(0.76,0.84,0.88,0.35)')
    export = json.loads((game/'content/whalebelly/layout/painted-layers-v1.json').read_text(encoding='utf-8'))['rooms'][rid]
    hanging = [e for e in export['elements'] if ('BALEEN' in e['id'] or 'VINE' in e['id']) and e['origin'][1] < 420]
    if rid in ('R1-05','R1-06'):
        # These vines originally grew on the old ROAD; attach to actual new ledges.
        hanging = [e for e in export['elements'] if 'VINE' in e['id']]
    for n, element in enumerate(hanging):
        point = [left+element['origin'][0]*k,top+element['origin'][1]*k]
        if rid in ('R1-05','R1-06'):
            cap = room['platforms'][1+n % (len(room['platforms'])-1)]
            point = [cap['x']+cap['w']*.4,cap['y']+12]
        profile = 'PackedFloat32Array('+','.join(str(x) for x in element.get('root_profile',[0.0]*13))+')'
        sc.node('Fringe'+str(n),'MeshInstance2D','Middle',script=motion,
                texture=sc.ext('Texture2D',middle+element['id']+'.png'),
                position=v(point),scale=v([k,k]),root_profile=profile,
                amplitude=2.5,period=9.0+n,phase=n*1.3,
                modulate='Color(0.88,0.91,0.94,1)')
    front_image = Image.open(game / middle.removeprefix('res://') / 'Foreground.png')
    fk = frame_width / (front_image.width-32)
    front_material = foreground_material(sc, room)
    sc.sprite('OriginalNearBone','Foreground',middle+'Foreground.png',
              [left-16*fk,height+(180 if rid=='R1-04' else 75)-(front_image.height-16)*fk],fk,material=front_material,
              modulate='Color(0.88,0.91,0.94,1)')


def foreground_material(sc, room):
    # Feather only where the original near silhouette crosses a real landing.
    # The native frame stays visible elsewhere. No physics or player state changes.
    zones = [[p['x']-40,p['y']-140,p['w']+80,210] for p in room['platforms']]
    zones += [[d['pos'][0]-90,d['pos'][1]-210,180,280] for d in room['doors']]
    values = 'PackedVector4Array('+','.join(str(x) for zone in zones for x in zone)+')'
    return sc.material('res://src/world/scenery/layout/foreground_clearance.gdshader',
                       {'zone_count':len(zones),'clear_zones':values})


def opening_layers(sc, room, game, v, motion, water_params=None):
    width,height=room['size'];k=(width+350)/1280
    left,top=-175,-60
    base='res://art/whalebelly/'
    # The native jaw/arch underpaint has no old walking road or actors.
    distant=base+'foreground_edges/CLEAN-ENV-UNDERPAINT.png'
    im=Image.open(game/distant.removeprefix('res://'))
    far_scale=max(width/im.width,height/im.height)*1.08
    soft=sc.material('res://src/world/scenery/layout/painted_edges.gdshader',{'feather_pixels':18.0,**(water_params or {})})
    sc.sprite('OriginalOralFar','Far/Depth',distant,[(width-im.width*far_scale)/2,(height-im.height*far_scale)/2],far_scale,material=soft,modulate='Color(0.76,0.84,0.88,0.84)')
    edge=sc.material('res://src/world/scenery/layout/painted_edges.gdshader',{'fade_lower':'true','fade_from':.3,'fade_to':.88})
    sc.sprite('OriginalChamber','Middle',base+'baleen_loop_v3/CLEAN-ROOF.png',[left,top],k)
    for side,at in [('L',[0,0]),('R',[1164,0])]:
        sc.sprite('OriginalWall'+side,'Middle',base+'foreground_edges/CLEAN-WALL-'+side+'.png',[left+at[0]*k,top+at[1]*k],k,
                  material=edge,modulate='Color(0.88,0.91,0.94,1)')
    # Preserve the reference's actual clean root positions and authored frame atlas.
    for n,x in enumerate([90,255,422,575,722,880]):
        material={}
        if n==0:
            material['material']=sc.material('res://content/whalebelly/environment/elements/extraction_alpha.gdshader',{'clean_from_y':115.0,'cut_after_y':235.0})
        sc.sprite('Root'+str(n),'Middle',base+f'baleen_loop_v3/CLEAN-BALEEN-{n+1:02}-ROOT.png',[left+x*k,top],k,**material)
    for n,(x,y,scale,rotation,phase) in enumerate([(215.532,-152.28,1.29246,.001436,0),(644.489,-168.195,.83103,.29594,13),(870.899,-111.934,1.07856,.16903,27)]):
        sc.node('OriginalBaleen'+str(n),'Sprite2D','Middle',
                script=sc.ext('Script','res://content/whalebelly/environment/elements/baleen_frames.gd'),
                texture=sc.ext('Texture2D',base+'baleen_loop_v3/baleen-sway-atlas.png'),
                centered='false',position=v([left+x*k,top+y*k]),scale=v([scale*k,scale*k]),rotation=rotation,
                hframes=8,vframes=6,external_clock='true',frame_count=48,playback_fps=12.0,phase_offset_frames=phase,z_index=-1)
    # Two original vines attach below actual caps, rather than borrowing R1-02.
    for n,cap in enumerate(room['platforms'][:2]):
        path=base+f'motion_elements/VINE-{n+1:02}.png'
        sc.node('Fringe'+str(n),'MeshInstance2D','Middle',script=motion,
                texture=sc.ext('Texture2D',path),position=v([cap['x']+cap['w']*.5,cap['y']+18]),
                amplitude=1.8,period=9.0+n)
    material=foreground_material(sc,room)
    sc.sprite('OriginalNearBone','Foreground',base+'foreground_edges/FRONT-BOTTOM-PAD.png',
              [left-32*k,height+75-752*k],k,material=material)
    sc.sprite('OriginalNearCorner','Foreground',base+'foreground_edges/FRONT-TOP-LEFT.png',[left-32*k,top-32*k],k)
