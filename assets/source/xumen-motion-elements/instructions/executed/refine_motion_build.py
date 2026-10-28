from pathlib import Path
p=Path('BOB/tools/build_motion_elements.py');s=p.read_text(encoding='utf-8');s=s.replace("pos=a['source_rect'][:2]; z=a['layer']","pos=a['source_rect'][:2]; z=a['layer']\n  if id.startswith('BALEEN'):pos[0]-=16")
s=s.replace('phase=0.0,intensity=0.18','phase=0.0,intensity=0.32').replace('phase=2.1,intensity=0.10','phase=2.1,intensity=0.16')
p.write_text(s,encoding='utf-8',newline='\n')
