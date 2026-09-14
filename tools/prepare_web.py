"""Post-export local web shell and deploy manifest; standard library only."""
from pathlib import Path
import json, gzip, re, shutil
R=Path(__file__).resolve().parent.parent
root=R/'build/web';path=root/'index.html'
html=path.read_text(encoding='utf8')
html=html.replace('<html lang="en">','<html lang="zh-Hant">')
html=re.sub(r'<meta name="viewport"[^>]+>', '', html)
html=html.replace('</head>','''<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<style>
#safe {position:fixed;inset:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);pointer-events:none}
#canvas {position:absolute;touch-action:none}
#rotate {display:none;position:fixed;inset:0;z-index:10;background:#171511;color:#f3e8d2;align-items:center;justify-content:center;font:24px sans-serif;text-align:center;padding:32px}
@media (orientation:portrait) and (pointer:coarse) {#rotate{display:flex}}
</style></head>''')
html=html.replace('<canvas id="canvas"','<div id="safe"></div><div id="rotate">請將手機轉為橫向<br>武鬥台灣魂</div><canvas width="1280" height="720" id="canvas"')
html=html.replace('"canvasResizePolicy":2','"canvasResizePolicy":0')
html=html.replace('</body>','''<script>
const safe=document.getElementById('safe'), canvas=document.getElementById('canvas');
function fit(){const r=safe.getBoundingClientRect(),w=Math.min(r.width,r.height*16/9),h=w*9/16;canvas.width=Math.round(w*devicePixelRatio);canvas.height=Math.round(h*devicePixelRatio);Object.assign(canvas.style,{width:w+'px',height:h+'px',left:(r.x+(r.width-w)/2)+'px',top:(r.y+(r.height-h)/2)+'px'});}
new ResizeObserver(fit).observe(safe);window.addEventListener('resize',fit);fit();
</script></body>''')
path.write_text(html,encoding='utf8')
(root/'_headers').write_text('/*.wasm\n  Content-Type: application/wasm\n/*\n  X-Content-Type-Options: nosniff\n',encoding='utf8')
shutil.copy2(R/'art/fonts/OFL.txt',root/'FONT_LICENSE.txt')
shutil.copy2(R/'THIRD_PARTY_NOTICES.md',root/'THIRD_PARTY_NOTICES.txt')
rows=[{'file':p.name,'bytes':p.stat().st_size,'gzip_bytes':len(gzip.compress(p.read_bytes(),compresslevel=9))} for p in root.iterdir() if p.is_file()]
report={'files':rows,'total_bytes':sum(r['bytes'] for r in rows),'gzip_bytes':sum(r['gzip_bytes'] for r in rows),'note':'gzip is measured transfer estimate, server must enable compression; no remote deployment performed'}
(R/'artifacts/benchmark/web-size.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report,indent=2))
