"""Validate content contracts and read-only references; generate factual inventories."""
from pathlib import Path
import json,hashlib,wave
from PIL import Image
R=Path(__file__).resolve().parent.parent
def path(s):return R/s.removeprefix('res://')
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
inventory=[];lines=['# Moves and animation inventory — Godot 0.2','', 'Frame values use 60 Hz. Super/Awakening damage is per hit before combo scaling. Raster art is the user-provided Phaser baseline, not newly generated Godot animation.','']
for fpath in read(R/'data/roster.json'):
 f=read(path(fpath));v=read(path(f['visual']));unique=0
 for sheet in v['sheets'].values():
  im=Image.open(path(sheet['texture'])).convert('RGBA')
  assert im.size==(sheet['cols']*384,sheet['rows']*384)
  assert im.getchannel('A').getextrema()==(0,255)
  unique+=sheet['cols']*sheet['rows']
 lines += [f"## {f['name']} / {f['id']}",'',f"Speed {f['speed']} px/s; jump {f['jump_speed']} px/s; preferred range {f['preferred']} px. {f['style']}.",'', '| Move ID | Name | Startup / active / recovery | Damage | Meter | Level | Animation |','|---|---|---|---|---|---|---|']
 for key,m in f['moves'].items():
  assert m['animation'] in v['clips'],(f['id'],key)
  assert m['cost']>=0 and m['startup']>0 and m['active']>0 and m['recovery']>0
  for box in m['boxes']:
   assert m['startup']<=box['start']<=box['end']<m['startup']+m['active']
   assert box['rect'][2]>0 and box['rect'][3]>0
  if 'cancel' in m:
   assert all(k in f['moves'] for k in m['cancel']['targets'])
   assert m['cancel']['end']<m['startup']+m['active']+m['recovery']
  lines.append(f"| {key} | {m['name']} | {m['startup']} / {m['active']} / {m['recovery']} | {m['damage']} | {m['cost']} | {m['level']} | {m['animation']} |")
 lines+=['','| Clip | Sheet | Frame sequence | FPS | Loop |','|---|---|---|---|---|']
 for key,clip in v['clips'].items():
  s=v['sheets'][clip['sheet']]
  assert all(0<=i<s['cols']*s['rows'] for i in clip['sequence'])
  lines.append(f"| {key} | {clip['sheet']} | {clip['sequence']} | {clip['fps']} | {clip['loop']} |")
 lines+=['', 'Command normal reuses KICK presentation; other attack IDs resolve to their named semantic clip. Several transitional clips share source frames. A semantic state count is not a count of independently authored drawings.','']
 inventory.append({'id':f['id'],'moves':len(f['moves']),'clips':len(v['clips']),'atlas_cells_including_padding':unique,'sheets':len(v['sheets'])})
changed=[]
hashes=read(R/'artifacts/phaser-reference-hashes.json')
for item in hashes:
 p=Path(item['Path'])
 if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest().upper()!=item['Hash']:changed.append(str(p))
assert not changed,changed
audio=[]
for p in (R/'assets/audio').glob('*.wav'):
 with wave.open(str(p)) as w:audio.append({'file':p.name,'seconds':w.getnframes()/w.getframerate(),'channels':w.getnchannels()})
(R/'docs/MOVE_ANIMATION_INVENTORY.md').write_text('\n'.join(lines),encoding='utf8')
report={'fighters':inventory,'unchanged_reference_files':len(hashes),'audio':audio}
(R/'artifacts/benchmark/content-audit.json').write_text(json.dumps(report,indent=2),encoding='utf8')
frames=[Image.open(R/f'artifacts/benchmark/walk-{i:02d}.png').convert('RGB') for i in range(24)]
frames[0].save(R/'artifacts/benchmark/kai-rig-walk.gif',save_all=True,append_images=frames[1:],duration=33,loop=0)
print(json.dumps(report,indent=2))
