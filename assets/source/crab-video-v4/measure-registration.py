import cv2, json, pathlib, numpy as np
root = pathlib.Path(__file__).resolve().parent
out = {}
for name in ['sweep','charge','walk','phase']:
    im = cv2.imread(str(root/'raw'/f'{name}.png'), cv2.IMREAD_UNCHANGED)
    n, labels, stats, _ = cv2.connectedComponentsWithStats((im[:,:,3] >= 32).astype(np.uint8), 8)
    bodies = [list(map(int,s[:4])) for s in stats[1:] if s[4] > 5000]
    bodies.sort(key=lambda b: b[1]+b[3]/2)
    ordered=[]
    for r in range(3): ordered.extend(sorted(bodies[r*4:r*4+4],key=lambda b:b[0]))
    assert len(ordered)==12
    x,y,w,h=ordered[0]
    tx,ty,tw,th=int(w*.48),int(h*.06),int(w*.35),int(h*.47)
    template=cv2.cvtColor(im[y+ty:y+ty+th,x+tx:x+tx+tw,:3],cv2.COLOR_BGR2GRAY)
    frames=[]
    for index,(bx,by,bw,bh) in enumerate(ordered):
        crop=im[by:by+bh,bx:bx+bw]
        match=cv2.matchTemplate(cv2.cvtColor(crop[:,:,:3],cv2.COLOR_BGR2GRAY),template,cv2.TM_CCOEFF_NORMED)
        _,score,_,location=cv2.minMaxLoc(match)
        anchor=location[0]+w*.5-tx
        assert bx>3 and by>3 and bx+bw<im.shape[1]-3 and by+bh<im.shape[0]-3, (name,index,'edge')
        frames.append({'rect':[bx-3,by-3,bw+6,bh+6], 'root':[anchor+3,bh+3], 'shell_match':round(score,4)})
    print(name, 'min match',min(f['shell_match'] for f in frames),'scale',round(447/w,4),'rootX',[round(f['root'][0]) for f in frames])
    out[name]={'size':[im.shape[1],im.shape[0]],'scale':447/w,'frames':frames}

root.joinpath('registration.json').write_text(json.dumps({'frameSize':[896,512],'pivot':[512,448],'actions':out},indent=2))
