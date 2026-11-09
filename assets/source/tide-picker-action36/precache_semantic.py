"""Cache selected atlas source-frame masks without changing runtime assets.

Usage: python precache_semantic.py walk
Uses the explicit environment model/provider settings supported by build.py.
"""
import sys, os, json
from pathlib import Path
from build import BASE, RUNTIME, REVIEW, read_frame
from semantic_matte import SemanticMatte

config = {'threads': int(os.environ.get('ACTION36_THREADS', '4')),
          'provider': os.environ.get('ACTION36_PROVIDER', 'cpu')}
if os.environ.get('ACTION36_MATTE_MODEL'):
    config.update(model_path=Path(os.environ['ACTION36_MATTE_MODEL']),
                  model_family=os.environ.get('ACTION36_MATTE_FAMILY', 'birefnet'))
engine = SemanticMatte(**config)
actions = json.loads((RUNTIME/'animations.json').read_text(encoding='utf-8'))['actions']
for key in sys.argv[1:]:
    action = actions[key]
    for i, seconds in enumerate(action['source_seconds']):
        engine.predict(read_frame(action['source'], seconds), REVIEW/'mask-cache')
        print(key, i + 1, '/', action['frame_count'], engine.provider, flush=True)
