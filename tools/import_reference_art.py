"""Read-only raster/data extraction, not Phaser runtime translation. Output owned by Godot."""
import json,re,hashlib,shutil
from pathlib import Path
from PIL import Image
R=Path(__file__).resolve().parent.parent
REF=R/'reference/phaser-benchmark/taiwanfighter-phaser-reference-for-astra/PHASER_REFERENCE'
report=[]
for id,source in [('kai','fighter_a'),('lucy','fighter_lucy')]:
 target=R/'assets/characters'/id;target.mkdir(parents=True,exist_ok=True)
 folder=REF/'public/assets/characters'/source
 sheets={}
 for path in (folder/'sprites').glob('*.webp'):
  key=path.stem.removeprefix(source+'_').removeprefix('lucy_')
  dest=target/(key+'.webp');shutil.copy2(path,dest)
  im=Image.open(path).convert('RGBA');w,h=im.size
  sheets[key]={'texture':'res://assets/characters/'+id+'/'+key+'.webp','cols':w//384,'rows':h//384,'frame':384}
  report.append({'source':str(path.relative_to(R)),'output':str(dest.relative_to(R)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'size':[w,h],'alpha_extrema':im.getchannel('A').getextrema()})
 src=(REF/'src/data/characters'/(source+'_animations.ts')).read_text(encoding='utf8')
 clips={}
 for match in re.finditer(r'\[AnimationState\.(\w+)\]:\s*\{(.*?)\n  \},',src,re.S):
  name,body=match.groups()
  asset=re.search(r"assetKey:\s*'[^']*_sheet_(\w+)'",body)
  seq=re.search(r'frameSequence:\s*\[([^\]]+)\]',body)
  fps=re.search(r'fps:\s*(\d+)',body)
  if asset and seq:
   clips[name]={'sheet':asset[1],'sequence':[int(v) for v in re.findall(r'\d+',seq[1])],'fps':int(fps[1]) if fps else 12,'loop':'loop: true' in body}
 portraits=folder/'portraits'
 portrait=portraits/(('fighter_a_select_1p' if id=='kai' else 'lucy_select_1p')+'.webp')
 shutil.copy2(portrait,target/'portrait.webp')
 out=R/'data/visuals';out.mkdir(parents=True,exist_ok=True)
 (out/(id+'.json')).write_text(json.dumps({'sheets':sheets,'clips':clips,'scale':1.0,'baseline':377,'provenance':'User-provided Phaser raster baseline; separate Godot runtime adapter'},ensure_ascii=False,indent=2),encoding='utf8')
 # A clean rendered contact sheet excludes invisible RGB hidden under alpha.
 preview=Image.new('RGB',(8*192,5*220),'#282725')
 from PIL import ImageDraw
 d=ImageDraw.Draw(preview)
 for n,(name,clip) in enumerate(clips.items()):
  if n>=40:break
  sheet=Image.open(target/(clip['sheet']+'.webp')).convert('RGBA')
  index=clip['sequence'][len(clip['sequence'])//2];cols=sheet.width//384
  frame=sheet.crop(((index%cols)*384,(index//cols)*384,(index%cols+1)*384,(index//cols+1)*384)).resize((192,192))
  pos=((n%8)*192,(n//8)*220);preview.paste(frame,pos,frame);d.text((pos[0]+4,pos[1]+194),name,fill='white')
 preview.save(R/'artifacts/benchmark'/(id+'-reference-inventory.png'))
(R/'artifacts/benchmark/art-import.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('Copied 20 immutable raster atlases and 2 portraits; extracted semantic clip data')
