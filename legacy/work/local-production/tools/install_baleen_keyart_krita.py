from pathlib import Path
import os, shutil, re
ROOT=Path(__file__).resolve().parents[1]
resources=Path(os.environ['APPDATA'])/'krita/pykrita'
plugin=resources/'baleen_keyart_v2';plugin.mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'tools/baleen_keyart_krita.py',plugin/'importer.py')
(plugin/'__init__.py').write_text('from krita import Krita\nfrom .importer import BaleenKeyartImporter\nKrita.instance().addExtension(BaleenKeyartImporter(Krita.instance()))\n',encoding='utf-8')
(resources/'baleen_keyart_v2.desktop').write_text('[Desktop Entry]\nType=Service\nServiceTypes=Krita/PythonPlugin\nX-KDE-Library=baleen_keyart_v2\nX-Python-2-Compatible=false\nName=Baleen Key Art V2\nComment=Import only the explicit baleen key-art manifest\n',encoding='utf-8')
config=Path(os.environ['LOCALAPPDATA'])/'kritarc'
backup=ROOT/'assets/source/baleen-keyart-v2/metadata/kritarc-before'
if not backup.exists():shutil.copy2(config,backup)
text=config.read_text(encoding='utf-8')
if '[python]' not in text:text+='\n[python]\n'
if 'enable_baleen_keyart_v2=' not in text:text=text.replace('[python]','[python]\nenable_baleen_keyart_v2=true',1)
else:text=re.sub(r'enable_baleen_keyart_v2=[^\n]*','enable_baleen_keyart_v2=true',text)
config.write_text(text,encoding='utf-8')
print(plugin)
