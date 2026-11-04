"""Rebuild the selected mixed-source batch in a single-writer sequence.

Python dependencies and source videos must already be available. Native AI
pose sheets are versioned source inputs; this script does not call paid APIs.
It builds candidates, not approval. Run register/sync only after visual review.
"""
import argparse,os,subprocess,sys
from pathlib import Path
BASE=Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument('--models-dir',type=Path,default=BASE.parents[3]/'work/action36-models')
parser.add_argument('--threads',type=int,default=4)
args=parser.parse_args()
env=os.environ.copy();env.update(ACTION36_PROVIDER='cpu',ACTION36_THREADS=str(args.threads))

def call(script,*arguments):
    subprocess.run([sys.executable,str(BASE/script),*arguments],env=env,check=True)

for name in ['isnet-general-use.onnx','birefnet-general-lite.onnx']:
    if not (args.models_dir/name).is_file():raise SystemExit('Missing verified model: '+str(args.models_dir/name))

env.update(ACTION36_MATTE_MODEL=str(args.models_dir/'isnet-general-use.onnx'),ACTION36_MATTE_FAMILY='isnet')
call('build.py','--build','--semantic')
env.update(ACTION36_MATTE_MODEL=str(args.models_dir/'birefnet-general-lite.onnx'),ACTION36_MATTE_FAMILY='birefnet')
call('build.py','--build','--semantic','--keys','walk,strike1,dash,hurt')
# Ground-effect provenance must be captured before replacing the body source.
call('build_ground_effects.py','heavy','dive')
call('build_pure_effects.py')
call('build_sprite_sheets.py','--keys','run','parry','wall_jump','heavy','dive','--write-runtime')
call('build_anchor_sockets.py')
call('merge_sprite_sheets.py')
call('merge_final_assets.py')
call('extract_effects.py')
call('verify.py')
print('Candidate rebuild complete. Review hashes/appearance before register.py and sync-art.')
