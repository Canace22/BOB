"""Native Krita animation master builder. Explicit request file only."""
from pathlib import Path
import json,traceback
from krita import Krita,Extension
from PyQt5.QtCore import QTimer
ROOT=Path('G:/鲸落万物生/BOB/assets/source/baleen-wan22')
class BaleenImporter(Extension):
    def setup(self):
        self.busy=False;self.keep=None
        self.timer=QTimer();self.timer.timeout.connect(self.poll);self.timer.start(2500)
    def createActions(self,window):pass
    def poll(self):
        request=ROOT/'metadata/krita-request.json'
        if self.busy or not request.exists():return
        self.busy=True
        jobs=json.loads(request.read_text(encoding='utf-8'))
        request.rename(ROOT/'metadata/krita-consumed.json')
        app=Krita.instance();window=app.activeWindow() or app.openWindow();records=[]
        try:
            self.keep=app.createDocument(32,32,'Baleen import workspace','RGBA','U8','',72.0);window.addView(self.keep)
            for job in jobs:
                doc=app.createDocument(job['width'],job['height'],job['id'],'RGBA','U8','',72.0)
                doc.setBatchmode(True);window.addView(doc)
                layer=doc.createNode('Wan motion - original painted texture RGBA','paintlayer')
                doc.rootNode().addChildNode(layer,None);doc.setActiveNode(layer)
                paths=sorted((ROOT/'frames'/job['id']).glob('*.png'))
                if not doc.importAnimation([str(p) for p in paths],0,1):raise RuntimeError('importAnimation failed '+job['id'])
                doc.waitForDone()
                for node in doc.rootNode().childNodes():
                    node.setVisible(node.animated())
                    if node.animated():doc.setActiveNode(node);node.setName('Wan derived animation - 12 FPS')
                correction=doc.createNode('Local paint corrections - empty','paintlayer');doc.rootNode().addChildNode(correction,None)
                doc.setFramesPerSecond(12);doc.setFullClipRangeStartTime(0);doc.setFullClipRangeEndTime(len(paths)-1);doc.setPlayBackRange(0,len(paths)-1)
                doc.setCurrentTime(0);doc.refreshProjection();doc.waitForDone()
                target=ROOT/'krita'/(job['id']+'.kra')
                if not doc.saveAs(str(target)):raise RuntimeError('saveAs failed')
                doc.waitForDone()
                preview=doc.thumbnail(job['width'],job['height']);preview.save(str(ROOT/'review'/(job['id']+'-krita.png')))
                records.append(dict(id=job['id'],status='saved',frames=len(paths),fps=doc.framesPerSecond(),version=app.version(),file=str(target),animated_layers=sum(n.animated() for n in doc.rootNode().childNodes())))
                doc.close()
        except Exception:records.append(dict(status='failed',error=traceback.format_exc()))
        (ROOT/'metadata/krita-results.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
        self.busy=False
