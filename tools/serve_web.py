"""Local-only static test server, no remote publication."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from functools import partial
from pathlib import Path
root=Path(__file__).resolve().parent.parent/'build/web'
SimpleHTTPRequestHandler.extensions_map['.wasm']='application/wasm'
print('http://127.0.0.1:8060',flush=True)
ThreadingHTTPServer(('127.0.0.1',8060),partial(SimpleHTTPRequestHandler,directory=str(root))).serve_forever()
