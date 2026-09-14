"""Godot content authoring. No Phaser code is executed or translated."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
def write(path, obj):
 p=ROOT/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf8')
def move(name, anim, stance, frames, damage, box, level='mid', kind='normal', cost=0, **extra):
 s,a,r=frames
 return dict(name=name,animation=anim,stance=stance,startup=s,active=a,recovery=r,damage=damage,level=level,kind=kind,cost=cost,stun=18,blockstun=12,push=22,hitstop=7,boxes=[dict(start=s,end=s+a-1,rect=box,group=0)],**extra)
for id,name,speed,col in [('kai','阿凱',310,'46d9ec'),('lucy','露希',280,'a9b4ff')]:
 kai=id=='kai'
 moves={
 'punch':move('巷口直拳' if kai else '諜影刺拳','PUNCH','stand',(5 if kai else 4,3,10),45,[28,-220,105,58]),
 'kick':move('急煞前踢' if kai else '特勤迴旋踢','KICK','stand',(9,4,17),68,[30,-180,157 if kai else 182,66]),
 'crouch_punch':move('低位截擊' if kai else '低姿探棍','CROUCH_PUNCH','crouch',(5,3,9),35,[25,-110,105 if kai else 138,45]),
 'crouch_kick':move('巷弄掃腿' if kai else '影步掃腿','CROUCH_KICK','crouch',(8,4,22),63,[20,-45,167,42],level='low',knockdown=38),
 'air_punch':move('躍送肘擊' if kai else '空降破勢','JUMP_PUNCH','air',(5,5,12),48,[20,-160,118,85],level='overhead'),
 'air_kick':move('跨巷飛踢' if kai else '無聲飛踢','JUMP_KICK','air',(8,7,16),67,[20,-135,175,80],level='overhead'),
 'command':move('上門破防' if kai else '斷線下劈','KICK','stand',(21,3,22),74,[20,-245,140,125],level='overhead',kind='command_normal'),
 'special_punch':move('破風急件' if kai else '影鏈突襲','SPECIAL_PUNCH','stand',(12 if kai else 10,6,22),95,[20,-215,140 if kai else 190,95],kind='special',travel=9 if kai else 6),
 'special_kick':move('路口迴旋' if kai else '蛇環裂圓','SPECIAL_KICK','stand',(16,8,26),110,[-55,-255,230 if kai else 290,160],kind='special',knockdown=32),
 'super':move('極速送達' if kai else '黑燕殲滅','SUPER','stand',(10,18,29),160,[20,-235,210 if kai else 270,150],kind='super',cost=100,cinema='super',travel=12 if kai else 5,knockdown=44),
 'awakening':move('使命必達' if kai else '終局代號：將軍','AWAKENING','stand',(14,23,36),245,[-30,-285,330 if kai else 400,230],kind='awakening',cost=200,cinema='awakening',travel=10 if kai else 2,knockdown=54)
 }
 # Different temporal shapes: two distinct contact groups for supers; same group cannot re-hit.
 for key in ['super','awakening']:
  m=moves[key];s=m['startup'];a=m['active'];rect=m['boxes'][0]['rect']
  m['boxes']=[dict(start=s,end=s+3,rect=rect,group=0),dict(start=s+a-5,end=s+a-1,rect=[rect[0],rect[1]+30,rect[2]+35,rect[3]-20],group=1)]
  m['knockdown_group']=1
  m['stun']=32
 for key in ['punch','kick','crouch_punch']:
  m=moves[key]; m['cancel']={'start':m['startup'],'end':m['startup']+m['active']+7,'confirm':'hit_or_block','targets':['special_punch','special_kick','super']}
 moves['special_punch']['cancel']={'start':moves['special_punch']['startup'],'end':moves['special_punch']['startup']+10,'confirm':'hit','targets':['super','awakening']}
 # Hurtbox keyframes are authoritative, beyond stance-only body boxes.
 moves['special_punch']['hurtboxes']=[dict(start=0,end=7,rects=[[-34,-175,85,175]])]
 moves['special_kick']['status']={'kind':'slow','frames':90,'factor':0.72} if not kai else {'kind':'none','frames':0}
 fighter=dict(id=id,name=name,english=id.upper(),speed=speed,jump_speed=690 if kai else 735,accent=col,style='疾速突進・確認連段' if kai else '武器控距・節奏制壓',preferred=125 if kai else 175,moves=moves,visual='res://data/visuals/'+id+'.json',portrait='res://assets/characters/'+id+'/portrait.webp',rig='res://scenes/rigs/kai.tscn' if kai else '',quote='再遠的巷子，也一定送到。' if kai else '目標確認。現在，結束。',hurtboxes={'stand':[[-38,-270,76,270]],'crouch':[[-43,-155,86,155]],'air':[[-36,-240,72,180]]})
 # Calibrated against raster alpha bounds and in-engine F2: include head/body/legs,
 # excluding the backpack and outstretched weapon. Crouch remains shorter than standing.
 fighter['hurtboxes']={'stand':[[-22,-315,44,62],[-35,-253,70,143],[-36,-110,72,110]],'crouch':[[-25,-205 if kai else -195,50,55],[-43,-150,86,150]],'air':[[-22,-315,44,60],[-34,-255,68,165]]}
 fighter['passives']=[] if kai else [{'id':'counter_intel','name':'反情報','trigger':'perfect_block','cooldown':300,'meter':15,'buff':{'factor':1.18,'frames':180}}]
 write('data/fighters/'+id+'.json',fighter)
write('data/roster.json',['res://data/fighters/kai.json','res://data/fighters/lucy.json'])
write('data/stages.json',{'night':{'name':'永安街口','texture':'res://assets/stage.png','floor':585,'left':90,'right':1190,'ambience':'rain'},'dawn':{'name':'收班時分','texture':'res://assets/stage.png','floor':585,'left':90,'right':1190,'ambience':'quiet'}})
write('data/stories.json',[
 {'id':'last_delivery','fighter':'kai','title':'最後一件急件','synopsis':'雨夜中，一件沒有收件人的包裹。','nodes':[
 {'type':'dialogue','lines':[['旁白','凌晨一點，永安街口。阿凱的外送袋裡，多了一件沒有地址的包裹。'],['露希','停下。那件東西，不應該出現在配送路線上。'],['阿凱','先讓我確認妳是收件人。']]},
 {'type':'battle','opponent':'lucy','stage':'night','difficulty':'easy'},
 {'type':'dialogue','lines':[['露希','封條沒破。你沒有打開它。'],['阿凱','替人送東西，就要把它完整送到。'],['露希','天亮前陪我走最後一段。我需要知道，你能不能跟上。']]},
 {'type':'battle','opponent':'lucy','stage':'dawn','difficulty':'normal'},
 {'type':'dialogue','lines':[['旁白','證物交接完成。遠處早餐店的鐵門升起。'],['露希','任務結束。這趟配送，有人會記得。'],['阿凱','那就好。下一單，兩份熱豆漿。']]}]},
 {'id':'nightfall','fighter':'lucy','title':'錯誤包裹','synopsis':'一條被改寫的路線，一個不肯放手的外送員。','nodes':[
 {'type':'dialogue','lines':[['露希','追蹤訊號停在這裡。包裹在你身上。'],['阿凱','我只送件，不賣客人的資料。'],['露希','那就讓我確認你的決心。']]},
 {'type':'battle','opponent':'kai','stage':'night','difficulty':'normal'},
 {'type':'dialogue','lines':[['露希','你守住了封條。我相信你。'],['阿凱','下次領件，記得帶證件。'],['旁白','她關閉追蹤器。雨停了，街區還有自己的生活。']]}]}
])
print('Authored 2 fighters / 22 moves / 2 story routes')
