from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
qa=ROOT/'game/build/qa/r2-reference-motion-v4/current'
for id in ['R2-03','R2-04']:
 frames=[]
 for p in sorted((qa/'motion'/id).glob('*.png')):
  image=Image.open(p).convert('RGB');image.thumbnail((960,540));frames.append(image)
 if len(frames)!=160:raise RuntimeError('Expected all 160 actual renderer frames')
 frames[0].save(qa/f'{id}-motion.webp',format='WEBP',save_all=True,append_images=frames[1:],duration=50,loop=0,quality=85,method=4)
 print(id,'160 frames / 8 seconds / environment time fixture / bytes',(qa/f'{id}-motion.webp').stat().st_size)
