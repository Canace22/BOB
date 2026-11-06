"""Snapshot user references without altering any pixels."""
from pathlib import Path
import json,hashlib,shutil
from PIL import Image
SRC=Path(__file__).resolve().parent
ROOT=SRC.parents[2]
ATTACH=Path('C:/Users/Kingsoft/AppData/Local/Temp')
MAPPING=[('01-entry-alt','b00a1145-62cb-4a2f-9492-40a123a2c176','R1-01'),('02-memory','06c2272c-52e7-4a9a-b6b9-540d818824d9','R1-07'),('03-entry','b362e4e8-af09-4c85-bb42-ce63703ad7f1','R1-01'),('04-filter','9232a6a0-f752-4469-b2a1-50709f244ed3','R1-02'),('05-tongue','9af81cb0-052b-4eab-82f7-54ad2118a9f8','R1-03'),('06-boss','ae73008a-4be5-4d2c-a7de-f5c3c2d123b0','R1-04'),('07-nursery','fc75cfba-b5b9-4e93-95e9-c84ac5e1bebf','R1-05'),('08-upper','ab65c899-a59b-443b-b9e9-b1f33b33637f','R1-06')]
def main():
    (SRC/'inputs').mkdir(parents=True,exist_ok=True)
    records=[]
    for name,uid,rid in MAPPING:
        original=ATTACH/f'codex-clipboard-{uid}.png';dst=SRC/'inputs'/f'{name}.png'
        if not dst.exists():shutil.copyfile(original,dst)
        digest=hashlib.sha256(dst.read_bytes()).hexdigest()
        assert digest==hashlib.sha256(original.read_bytes()).hexdigest()
        with Image.open(dst) as im:w,h=im.size
        records.append({'file':str(dst.relative_to(SRC)).replace('\\','/'),'original':str(original),'room':rid,'width':w,'height':h,'sha256':digest,'role':'alternate reference' if name.endswith('alt') else 'locked room reference'})
    (SRC/'inputs.json').write_bytes((json.dumps(records,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    print(json.dumps({'references':len(records),'rooms':len({r['room'] for r in records}),'allByteIdentical':True}))
if __name__=='__main__':main()
