"""Explicit task-local manifest importer executed inside real Krita."""
from pathlib import Path
import json, traceback, sys
from krita import Krita, Extension
try:
    from PyQt6.QtCore import QTimer
except ImportError:
    from PyQt5.QtCore import QTimer

ROOT=Path('G:/鲸落万物生/BOB/assets/source/baleen-keyart-v2')

class BaleenKeyartImporter(Extension):
    def setup(self):
        self.busy=False
        self.timer=QTimer();self.timer.timeout.connect(self.poll);self.timer.start(2500)
        (ROOT/'metadata/krita-ready.json').write_text(json.dumps({'version':Krita.instance().version()}),encoding='utf-8')
        if '--export' in sys.argv:
            self.poll()

    def createActions(self,window):
        pass

    def poll(self):
        req=ROOT/'metadata/krita-request.json'
        if self.busy or not req.exists():return
        self.busy=True
        jobs=json.loads(req.read_text(encoding='utf-8'))
        req.replace(ROOT/'metadata/krita-consumed.json')
        app=Krita.instance();window=app.activeWindow() or app.openWindow()
        records=[]
        try:
            self.keep=app.createDocument(32,32,'Baleen V2 import workspace','RGBA','U8','',72.0)
            window.addView(self.keep)
            for job in jobs:
                doc=app.createDocument(job['size'],job['size'],job['title'],'RGBA','U8','',72.0)
                doc.setBatchmode(True);window.addView(doc)
                initial=doc.createNode(job['layer'],'paintlayer');doc.rootNode().addChildNode(initial,None);doc.setActiveNode(initial)
                paths=sorted((ROOT/job['folder']).glob('*.png'))
                if not paths:raise RuntimeError('No input frames')
                if not doc.importAnimation([str(p) for p in paths],0,1):raise RuntimeError('importAnimation failed')
                doc.waitForDone()
                for node in doc.rootNode().childNodes():
                    node.setVisible(node.animated())
                    if node.animated():node.setName(job['layer']);doc.setActiveNode(node)
                correction=doc.createNode('Editable paint corrections - empty','paintlayer');doc.rootNode().addChildNode(correction,None)
                doc.setFramesPerSecond(12);doc.setFullClipRangeStartTime(0);doc.setFullClipRangeEndTime(len(paths)-1);doc.setPlayBackRange(0,len(paths)-1);doc.setCurrentTime(0)
                doc.refreshProjection();doc.waitForDone()
                target=ROOT/'krita'/job['file']
                if not doc.saveAs(str(target)):raise RuntimeError('saveAs failed')
                doc.waitForDone()
                doc.thumbnail(job['size'],job['size']).save(str(ROOT/'review'/(job['file']+'.png')))
                records.append({'file':str(target),'frames':len(paths),'fps':doc.framesPerSecond(),'version':app.version(),'status':'saved','animated_layers':sum(n.animated() for n in doc.rootNode().childNodes())})
                doc.close()
        except Exception:records.append({'status':'failed','error':traceback.format_exc()})
        (ROOT/'metadata/krita-results.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
        self.busy=False
