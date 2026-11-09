"""Scoped Chaos CLI jobs for scenery-occluded bodies; resumes saved nodes/tasks."""
import sys,json,urllib.request
from pathlib import Path
BASE=Path(__file__).resolve().parent
OUT=BASE/'jobs';OUT.mkdir(exist_ok=True)
SRC=BASE.parents[3]/'outputs/拾潮者_14集参考_左右动作全集'
sys.path.insert(0,str(SRC))
from prepare import call,WF
sources={a['action']:a for a in json.loads((SRC/'selected_sources.json').read_text(encoding='utf-8'))}
prompts={
'wall_slide':'The diver holds a wall-sliding pose facing RIGHT, both palms reaching to the right and feet braced to the right, slow cape flutter, in place. Remove the wall completely, leave the hands touching an invisible vertical surface. Show all palms and toes.',
'wall_jump':'One brisk wall jump away from an invisible wall on the RIGHT. Start facing right with bent legs, push off, briefly turn the body toward LEFT, then gather legs for landing. Keep the full body in the central area, with no wall or floor drawn.',
'anchor':'The diver faces right, raises one empty hand diagonally above the head, hangs in a compact pose with knees bent, and gently swings the legs once. Keep the short fork held in the other hand. REMOVE every overhead rope and hook and ring. Only the costume red cord remains attached to the diver. The raised palm is empty and completely visible, ready for a game-engine tether.',
'slit':'The diver faces right and performs a compact low crouch followed by three low creeping steps in place, then rises. Always keep the short two-prong fork held firmly in the hand and visible in front. REMOVE the purple membrane, wall, passage, all background objects. No disappearing or becoming transparent.',
'swim':'The diver faces RIGHT, holds a horizontal swimming pose and performs a gentle repeating frog kick with both webbed feet, cape moving softly. KEEP THE WHOLE BODY and boots fully visible. REMOVE all water, surface lines, bubbles, ripples, reflections and pool. The character swims through empty space against the uniform background.',
'tram':'The diver faces RIGHT, briefly reaches forward with the empty hand to present a small ivory token, holds for a moment then withdraws it to the hip. Keep the short fork in the other hand. REMOVE the entire door, stone wall, pedestal, card reader and every environmental object; the reaching fingertips and token must be visible and complete.'}
common=' Edit {{Video 1}} into an isolated 2D game animation BODY PASS. Preserve exactly its small illustrated diver: ivory rigid helmet and dark round porthole, short dark teal cape, amber hip lamp, red costume cord, dark webbed boots, ONE short U-shaped TWO-prong fork. Replace the entire environment with a perfectly SOLID FLAT bright MAGENTA #FF00FF background, edge to edge. NO floor, horizon, cast shadow, reflection, lighting gradient, text, particles, glow or energy effects. Locked side-view camera, no zoom or pan. Stable scale, full body remains well inside frame with wide padding. Only the ONE character moves. Five seconds.'
def main():
    if sys.argv[1]=='submit':
        call(['read','--workflow-id',WF,'--summary'],OUT/'canvas_before.json')
        models=call(['models','--kind','video','--usable-only'],OUT/'models.json')
        assert any(a['modelId']=='doubao-seedance-2-5-260628' for a in models['data']['items'])
        for key,prompt in prompts.items():
            p=OUT/(key+'-submit.json')
            if p.exists():continue
            args=['i2v','--workflow-id',WF,'--source-video-node-id',sources[key]['nodeId'],'--generation-type','edit','--model','doubao-seedance-2-5-260628','--duration','5','--aspect-ratio','adaptive','--resolution','720P','--prompt',prompt+common]
            call(args,OUT/(key+'-dryrun.json'))
            r=call(args+['--apply'],p)
            print(key, r['tasks'][-1]['taskId'],flush=True)
    elif sys.argv[1]=='poll':
        for key in prompts:
            p=OUT/(key+'-submit.json')
            if not p.exists():continue
            task=json.loads(p.read_text(encoding='utf-8'))['tasks'][-1]
            r=call(['get-task','--task-id',task['taskId']],OUT/(key+'-status.json'))
            print(key,json.dumps(r,ensure_ascii=False)[0:1400],flush=True)
if __name__=='__main__':main()
