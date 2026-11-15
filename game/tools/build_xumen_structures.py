"""New painted cliff/organ masses replace the rejected cap-and-pillar assembly."""
import json
import math


def build_structures(sc, room, game, v, poly):
    assets = json.loads((game/'content/whalebelly/layout/structure-art-v1.json').read_text(encoding='utf-8'))['assets']
    cutout = sc.material('res://src/world/scenery/layout/bitmap_cutout.gdshader')
    for wall in room['walls']:
        # User-removed structures retain their recipe record for provenance only.
        # Skip the whole assembly, including its StaticBody2D and roof joins.
        if wall.get('removed', False):
            continue
        x,y,w,h = wall['box']
        family = 'tissue' if room['id']=='R1-05' else 'bone'
        # Compact low ceilings use a quarter-turn of the same continuous ridge.
        # A wide arch has its own painting. No image is stretched to fit a box.
        name = family+'-vault' if w/h>=2.4 else family+'-ridge'
        angle = 0.0 if h>w or w/h>=2.4 else -math.pi/2
        rooted_mass = y<400 and (family=='tissue' or h>w*1.2)
        rooted_tissue = family=='tissue' and rooted_mass
        if rooted_tissue:
            name = 'tissue-ridge'
            angle = 0.0
        item = assets[name]
        core = item['core']
        def turn(point):
            return [point[1],-point[0]] if angle else point
        corners = [turn([a,b]) for a in (core[0],core[2]) for b in (core[1],core[3])]
        left,right = min(p[0] for p in corners),max(p[0] for p in corners)
        top,bottom = min(p[1] for p in corners),max(p[1] for p in corners)
        height = y+h-12 if rooted_mass else h-24
        scale = max((w-24)/(right-left),height/(bottom-top))
        pos = [x+w/2-(left+right)/2*scale,y+h-12-bottom*scale]
        sc.sprite(wall['id']+'_PaintedMass','World/Art',item['runtime'],pos,scale,2,
                  rotation=angle,material=cutout,modulate='Color(0.69,0.77,0.82,1)' if family=='bone' else 'Color(0.77,0.8,0.83,1)')
        bounds = item['bbox32']
        edge_corners = [turn([a,b]) for a in (bounds[0],bounds[2]) for b in (bounds[1],bounds[3])]
        visible_top = pos[1]+min(p[1] for p in edge_corners)*scale
        # Rooted walls merge into the existing painted roof. This is a dim rear
        # continuation of the same bitmap, not a broad cap or another collision.
        joins_roof = y<400 and (h>w*1.2 or family=='tissue' or room['id']=='R1-01')
        if joins_roof and visible_top>8:
            root = assets[family+'-ridge']
            root_core = root['core']
            root_width = w*.9
            center = x+w/2
            if room['id']=='R1-01' and w>h:
                root_width = w*.4
                center = x+w*.82
            root_scale = root_width/(root_core[2]-root_core[0])
            native_height = (root_core[3]-root_core[1])*.55
            segment = native_height*root_scale
            height = visible_top+26
            count = max(1,math.ceil(height/(segment-8)))
            for index in range(count):
                start = -18+index*(segment-8)
                length = min(segment,height-start)
                if length<=0: continue
                join=sc.material('res://src/world/scenery/layout/structure_join.gdshader',{'uv_start':root_core[1]/root['size'][1],'uv_end':(root_core[1]+length/root_scale)/root['size'][1]})
                sc.sprite(wall['id']+'_RoofJoin'+str(index),'World/Art',root['runtime'],
                          [center-(root_core[0]+root_core[2])/2*root_scale,start],root_scale,1,
                          region_enabled='true',region_rect='Rect2(0,%s,%s,%s)'%(root_core[1],root['size'][0],length/root_scale),
                          material=join,modulate='Color(0.69,0.77,0.82,1)' if family=='bone' else 'Color(0.77,0.8,0.83,1)')
        sc.node(wall['id'],'StaticBody2D','World/Terrain')
        sc.node('Contour','CollisionPolygon2D','World/Terrain/'+wall['id'],
                polygon=poly([[x+12,y+12],[x+w-12,y+12],[x+w-12,y+h-12],[x+12,y+h-12]]))
