"""Conservative trajectory screening, not an engine collision/playability test."""
from pathlib import Path
import json, math

SRC = Path(__file__).resolve().parent

def main():
    d = json.loads((SRC/'design.json').read_text(encoding='utf-8'))
    b = d['baseline']; g=b['gravity']; v=b['jumpSpeed']; speed=b['maxSpeed']
    height=v*v/(2*g); rows=[]
    for room in d['rooms']:
        if room['id'] in ['R1-04','R1-07']:
            continue  # Flat Boss arena / anchor traversal have a separate contract.
        for i,(a,z) in enumerate(zip(room['landings'],room['landings'][1:])):
            rise=a[2]-z[2]; gap=z[0]-a[1]
            short=room['id']=='R1-02' and i==0
            h=height*(.65 if short else 1)
            vy=math.sqrt(2*g*h)
            assert rise<h, (room['id'],i,'rise exceeds nominal apex')
            flight=vy/g+.08+math.sqrt(2*(h-rise)/(g*b['fallMultiplier']))
            dash=room['id']=='R1-05'
            reach=speed*flight+(b['dashDistance']-speed*.2 if dash else 0)
            required=gap+b['collision'][0]  # Both feet inside each ledge, no edge generosity.
            assert reach>=required, (room['id'],i,reach,required)
            assert z[1]-z[0]>=112
            rows.append({'room':room['id'],'segment':i,'mode':'jump-dash' if dash else 'short-hop' if short else 'full-jump','gap':gap,'rise':rise,'requiredWithFootMargin':required,'idealReach':round(reach,2),'margin':round(reach-required,2)})
    pts=next(r for r in d['rooms'] if r['id']=='R1-07')['special'][0]['points']
    anchors=[round(math.hypot(z[0]-a[0],z[1]-(a[1]+55)),2) for a,z in zip(pts,pts[1:])]
    assert max(anchors)<b['anchorRange']
    assert [len(r['flies']) for r in d['rooms']]==[0,2,2,0,2,1,1]
    assert d['enemy']['damage']==1 and d['enemy']['sameScreenLimit']==2 and d['enemy']['attackerLimit']==1
    report={'passed':True,'kind':'analytic screening only','runtimeTested':False,'nominalJumpHeight':height,'apexHoldAssumption':.08,'segments':rows,'anchorSearchDistancesFromAttachedPlayer':anchors,'flyInstances':sum(len(r['flies']) for r in d['rooms']),'limitations':['Ideal maximum horizontal speed; acceleration, input release timing, actual ceilings and collision not simulated.','Artwork is not a collision mesh; guide coordinates require alignment during engine production.','A2 side branch and A3 anchor chain retain original ability gates.','Enemy warning corridors/protection rules, softbed double-damage prevention and jump-dash timing require runtime tests.']}
    (SRC/'review/trajectory-screen.json').write_bytes((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    print('PASS: 18 ideal trajectory segments, 3 anchor searches, 8 proposed flies; engine playtest pending.')

if __name__=='__main__':main()
