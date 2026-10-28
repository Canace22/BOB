from pathlib import Path
import numpy as np,json,argparse
from PIL import Image
BASE=Path(__file__).resolve().parent
def main(name):
    files=sorted((BASE/'transparent'/name).glob('*.png'))
    seq=[]
    for p in files:
        im=Image.open(p).convert('RGBA').resize((88,88))
        a=np.asarray(im).astype(np.float32)/255
        # Premultiplied colour, alpha and lower-body weighted similarity.
        a[:,:,:3]*=a[:,:,3:4]
        a[48:]*=1.5
        seq.append(a)
    seq=np.array(seq);pairs=[]
    for start in range(len(seq)-24):
        for end in range(start+24,min(len(seq),start+75)):
            gap=float(np.mean(np.abs(seq[start]-seq[end])))
            vel=float(np.mean(np.abs((seq[start+1]-seq[start])-(seq[end]-seq[end-1]))))
            pairs.append({'start':start,'end_exclusive':end,'frames':end-start,'gap':gap,'velocity_difference':vel,'score':gap+vel*.3})
    pairs.sort(key=lambda x:x['score'])
    (BASE/'review'/f'{name}_cycle-candidates.json').write_text(json.dumps(pairs[:30],indent=2))
    print(json.dumps(pairs[:8],indent=2))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('name');a=p.parse_args();main(a.name)
