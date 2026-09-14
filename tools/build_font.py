from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent/'pythonpackages'))
from fontTools import subset
from fontTools.ttLib import TTFont
R=Path(__file__).resolve().parent.parent
text=''.join(p.read_text(encoding='utf8') for folder in ['src','data'] for p in (R/folder).rglob('*') if p.suffix in ['.gd','.json'])
text+=''.join(chr(n) for n in range(32,127))+'∞ⅠⅡ←→✓'
font=TTFont(R/'art/fonts/NotoSansCJKtc-Regular.otf')
options=subset.Options();options.name_IDs=['*'];options.name_legacy=True;options.name_languages=['*']
sub=subset.Subsetter(options=options);sub.populate(text=text);sub.subset(font)
for record in font['name'].names:
 if record.nameID in [1,3,4,6,16,17]:
  record.string=('TaiwanUI-Regular' if record.nameID==6 else 'Taiwan UI').encode(record.getEncoding())
target=R/'assets/fonts';target.mkdir(parents=True,exist_ok=True);font.save(target/'TaiwanUI.otf')
print('Subset and renamed Taiwan UI:',(target/'TaiwanUI.otf').stat().st_size,'bytes')
