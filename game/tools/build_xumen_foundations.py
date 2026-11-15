"""Native organ mass below frozen walking tops; no new road or collision."""


def build_foundations(sc, room, metrics, texture_path, top_at, segment_crosses_box):
    rid = room['id']
    for index, cap in enumerate(room['platforms']):
        if cap.get('membrane') or cap.get('one_way'):
            continue
        x,y,w = cap['x'],cap['y'],cap['w']
        # These native plates may deepen downwards, never into a lower body lane.
        available = min(220,room['size'][1]+80-y)
        for lower in room['platforms']:
            if lower['y']>y and lower['x']<x+w and lower['x']+lower['w']>x:
                available = min(available,lower['y']-145-y)
        if available<45:
            continue
        piece = 'original-ledge'
        image,alpha,box = metrics(piece)
        # A larger native bitmap is CROPPED below the top, not stretched vertically.
        scale = min(w*1.65/(box[2]-box[0]),available/(box[3]-box[1]))
        depth = (box[3]-box[1])*scale
        if depth<48:
            continue
        center = (box[0]+box[2])/2
        top = top_at(alpha,int(center),box[1],box[3])
        left = x+w/2-center*scale
        above = y+10-top*scale
        keepout = [x+8,y+28,x+w-8,y+depth+70]
        blocked = False
        for route in room['layout']['qa_routes'].values():
            previous = route.get('fixture',{}).get('spawn',room['spawn'])
            for step in route['steps']:
                if 'at' not in step:
                    continue
                point = step['at']
                if segment_crosses_box(point,point,keepout) or (step['mode'] in ('walk','drop','grapple') and segment_crosses_box(previous,point,keepout)):
                    blocked = True
                    break
                previous = point
            if blocked:
                break
        if blocked:
            continue
        lanes = 'Vector4(%s,%s,%s,%s)' % (x+8,y+12,w-16,depth+20)
        material = sc.material('res://src/world/scenery/layout/native_foundation.gdshader',{'bounds':lanes})
        sc.sprite(cap['id']+'_NativeMass','World/Art',texture_path(piece),[left,above],scale,-1,
                  material=material,modulate='Color(0.68,0.76,0.8,1)')
