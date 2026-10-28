from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import threading

ROOT=Path(__file__).resolve().parent/'public'
class Handler(SimpleHTTPRequestHandler):
    def __init__(self,*args,**kwargs): super().__init__(*args,directory=str(ROOT),**kwargs)
    def list_directory(self,path): self.send_error(404); return None
    def end_headers(self):
        self.send_header('X-Content-Type-Options','nosniff')
        super().end_headers()
local=ThreadingHTTPServer(('127.0.0.1',8876),Handler)
lan=ThreadingHTTPServer(('10.11.140.20',8876),Handler)
threading.Thread(target=local.serve_forever,daemon=True).start()
lan.serve_forever()
