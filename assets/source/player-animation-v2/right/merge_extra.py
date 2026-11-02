"""Merge the separately reviewed RIGHT hurt/dash/heal package without regenerating art."""
from pathlib import Path
import json,shutil
P=Path(__file__).resolve().parent;D=P/'delivery'
m=json.loads((D/'manifest.json').read_text());m['clips'].update(json.loads((P/'extra/delivery/clips.json').read_text()))
for f in (P/'extra/delivery').glob('*.png'):shutil.copyfile(f,D/f.name)
(D/'manifest.json').write_text(json.dumps(m,indent=2)+'\n')
