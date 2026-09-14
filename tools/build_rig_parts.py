"""Deterministic approved normalization/cropping of generated rig parts; no generative edits."""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib
R=Path(__file__).resolve().parent.parent
p=R/'art/kai-rig/parts-source.png';im=Image.open(p).convert('RGBA')
arr=np.array(im);rgb=arr[:,:,:3].astype(float)
dominance=rgb[:,:,1]-np.maximum(rgb[:,:,0],rgb[:,:,2])
alpha=np.clip((55-dominance)/35,0,1)
arr[:,:,3]=(alpha*255).astype('uint8')
arr[:,:,1]=np.minimum(rgb[:,:,1],np.maximum(rgb[:,:,0],rgb[:,:,2])+15).astype('uint8')
clean=Image.fromarray(arr)
roles=['head','torso','pack','pelvis','rear_upper_arm','rear_forearm','front_upper_arm','front_forearm','rear_thigh','rear_shin','front_thigh','front_shin']
# Recorded per-row crop windows, not a guessed uniform 3-row cut.
rows=[(0,488),(488,918),(918,1536)]
target=R/'assets/characters/kai/rig';target.mkdir(parents=True,exist_ok=True)
reports=[]
for i,role in enumerate(roles):
 x=(i%4)*256;y0,y1=rows[i//4]
 part=clean.crop((x,y0,x+256,y1));bounds=part.getchannel('A').getbbox()
 if not bounds:raise ValueError(role)
 part=part.crop(bounds)
 # Atlas thigh illustrations contain lower trouser continuation. Clip after kneepad;
 # lower shin is supplied by the separate boot segment. Preserve relative scale in rig.
 if 'thigh' in role: part=part.crop((0,0,part.width,int(part.height*.69)))
 part.save(target/(role+'.png'))
 reports.append({'role':role,'source_window':[x,y0,256,y1-y0],'bounds':bounds,'pixels':part.size,'alpha_extrema':part.getchannel('A').getextrema(),'sha256':hashlib.sha256((target/(role+'.png')).read_bytes()).hexdigest()})
(R/'art/kai-rig/build-report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'parts':reports,'method':'green dominance alpha, deterministic individual crops; one source atlas; rig lengths independent of image bounds'},indent=2),encoding='utf8')
print('12 fixed rig parts normalized')
