"""Install a request-gated local Krita plugin; preserve existing plugins/config."""
from pathlib import Path
import os,shutil,re
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/source/baleen-wan22'
resources=Path(os.environ['APPDATA'])/'krita/pykrita'
plugin=resources/'baleen_importer';plugin.mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'tools/baleen_krita_importer.py',plugin/'importer.py')
(plugin/'__init__.py').write_text('from krita import Krita\nfrom .importer import BaleenImporter\nKrita.instance().addExtension(BaleenImporter(Krita.instance()))\n',encoding='utf-8')
(resources/'baleen_importer.desktop').write_text('[Desktop Entry]\nType=Service\nServiceTypes=Krita/PythonPlugin\nX-KDE-Library=baleen_importer\nX-Python-2-Compatible=false\nName=Baleen Local Animation Master\nComment=Import explicit project frame manifest at 12 FPS\n',encoding='utf-8')
config=Path(os.environ['LOCALAPPDATA'])/'kritarc'
text=config.read_text(encoding='utf-8')
backup=ROOT/'work/wan22-production/kritarc.before-baleen'
if not backup.exists():shutil.copy2(config,backup)
if '[python]' not in text:text+='\n[python]\n'
if 'enable_baleen_importer=' not in text:text=text.replace('[python]','[python]\nenable_baleen_importer=true',1)
else:text=re.sub(r'enable_baleen_importer=[^\n]*','enable_baleen_importer=true',text)
config.write_text(text,encoding='utf-8')
print(plugin)
