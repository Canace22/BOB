"""Validate concept provenance and fixed topology, not gameplay."""
from pathlib import Path
import json, hashlib

SRC=Path(__file__).resolve().parent
ROOT=SRC.parents[2]
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def main():
    hashes=load(SRC/'input-manifest.json')+load(SRC/'art-manifest.json')['images']
    for item in hashes:
        f=SRC/item['file']
        assert hashlib.sha256(f.read_bytes()).hexdigest()==item['sha256'], f
    prompts=load(SRC/'prompts.json')['images']
    assert [p['id'] for p in prompts]==[f'A{i:02}' for i in range(8)]
    for p in prompts:
        assert (SRC/p['output']).is_file()
        for ref in p['references']:
            assert ((ROOT if ref.startswith('assets/') else SRC)/ref).is_file(), ref
    d=load(SRC/'design.json')
    ids={r['id'] for r in d['rooms']}
    expected={('R1-01','R1-02'),('R1-02','R1-03'),('R1-03','R1-04'),('R1-04','R1-05'),('R1-02','R1-06'),('R1-02','R1-07')}
    assert len(ids)==7 and len(d['edges'])==6
    assert {(b['from'],b['to']) for b in d['edges']}==expected
    cat=load(ROOT/'assets/catalog.json')
    entries=[a for a in cat['assets'] if a['id'].startswith('xumen-keyart-v2-')]
    assert len(entries)==8
    for a in entries:
        assert a['status']=='needs-review' and a['integrationStatus']=='not-integrated'
        assert not a['userArtApproval']
        assert hashlib.sha256((ROOT/a['file']).read_bytes()).hexdigest()==a['sha256']
    for item in load(SRC/'sources.json')['inputs']:
        if item['original'].startswith('assets/'):
            assert (ROOT/item['original']).is_file(), item['original']
    result={'passed':True,'hashes':len(hashes),'primaryImages':8,'rooms':7,'edges':6,'catalogEntries':8,'scope':'concept-only; no runtime validation'}
    (SRC/'review/data-results.json').write_bytes((json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    print(json.dumps(result))

if __name__=='__main__': main()
