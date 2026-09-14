extends RefCounted
## Authoritative 60 Hz world. Rectangles are feet-relative, +x toward facing, -y upward.
var roster: Dictionary = {}
var fighters: Array[Dictionary] = []
var events: Array[Dictionary] = []
var entities: Array[Dictionary] = []
var cinematic: Dictionary = {}
var wins := [0,0]
var phase := "intro"
var phase_ticks := 75
var frame := 0
var remaining := 3600
var round_number := 1
var winner := -1
var hitstop := 0
var training := false
var infinite_meter := true
var recover_health := true
var bounds := Vector2(90,1190)
var serial := 0

func _init() -> void:
	var paths = JSON.parse_string(FileAccess.get_file_as_string("res://data/roster.json"))
	for path in paths:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		roster[d.id] = d

func setup(a: String, b: String) -> void:
	assert(roster.has(a) and roster.has(b))
	fighters.clear()
	for id in [a,b]:
		fighters.append({"id":id,"data":roster[id]})
	wins=[0,0]; round_number=1
	reset_round()

func reset_round() -> void:
	for i in 2:
		fighters[i].merge({"x":430.0 if i==0 else 850.0,"y":0.0,"vx":0.0,"vy":0.0,"hp":1000,"meter":100.0,"guard":100.0,"state":"idle","ticks":0,"stun":0,"down":0,"wake":0,"landing":0,"jump_start":0,"air_used":false,"facing":1 if i==0 else -1,"move":{},"move_id":"","connected":[],"confirm":"miss","buffer":"","buffer_time":0,"crouch":false,"guarding":false,"dash":0,"dash_cd":0,"guard_delay":0,"combo":0,"combo_damage":0,"status":{},"attack_serial":0,"last_contact":"","last_damage":0},true)
	phase="fight" if training else "intro"; phase_ticks=75
	for f in fighters: f.guard_ticks=0; f.buff={}; f.passive_cooldowns={}
	remaining=3600; winner=-1; hitstop=0; frame=0
	entities.clear(); cinematic.clear(); events.clear()

func next_round() -> void:
	if phase!="round_end": return
	if wins.max()>=2: phase="match_end"
	else:
		round_number+=1
		reset_round()

func rect_world(raw: Array, f: Dictionary) -> Rect2:
	return Rect2(f.x+(raw[0] if f.facing==1 else -raw[0]-raw[2]),f.y+raw[1],raw[2],raw[3])

func hurtboxes(i: int) -> Array[Rect2]:
	var f=fighters[i]
	if f.state in ["knockdown","wakeup","ko"]: return []
	var stance: String = "air" if f.y<0 else ("crouch" if f.crouch else "stand")
	var raw: Array=f.data.hurtboxes[stance]
	if f.state=="attack":
		for key in f.move.get("hurtboxes",[]):
			if f.ticks>=key.start and f.ticks<=key.end: raw=key.rects
	var result: Array[Rect2]=[]
	for box in raw: result.append(rect_world(box,f))
	return result

func hitboxes(i: int) -> Array[Dictionary]:
	var f=fighters[i]
	var result: Array[Dictionary]=[]
	if f.state!="attack": return result
	for key in f.move.get("boxes",[]):
		if f.ticks>=key.start and f.ticks<=key.end and not f.connected.has(key.group):
			result.append({"rect":rect_world(key.rect,f),"group":key.group})
	return result

func can_cancel(i: int, target: String) -> bool:
	var f=fighters[i]
	var c: Dictionary=f.move.get("cancel",{})
	if f.state!="attack" or c.is_empty() or not c.targets.has(target): return false
	return f.ticks>=c.start and f.ticks<=c.end and (c.confirm=="always" or f.confirm=="hit" or (c.confirm=="hit_or_block" and f.confirm=="block"))

func legal_move(f: Dictionary, id: String) -> bool:
	if not f.data.moves.has(id): return false
	var m: Dictionary=f.data.moves[id]
	if f.meter<m.cost: return false
	if m.stance=="air": return f.y<0 and not f.air_used
	return f.y==0 and f.jump_start==0

func start_move(i: int, id: String) -> void:
	var f=fighters[i]
	var m: Dictionary=f.data.moves[id]
	serial+=1; f.attack_serial=serial
	f.move=m; f.move_id=id; f.ticks=0; f.state="attack"
	f.confirm="miss"; f.connected=[]; f.buffer=""; f.buffer_time=0; f.dash=0
	f.meter-=m.cost
	f.crouch=m.stance=="crouch"
	if m.stance=="air": f.air_used=true
	events.append({"type":"swing","fighter":i,"move":id,"tier":m.kind})
	if m.has("cinema") and cinematic.is_empty():
		cinematic={"fighter":i,"kind":m.cinema,"tick":0,"duration":90 if m.cinema=="awakening" else 48,"move":id}
		events.append({"type":"cinematic","fighter":i,"tier":m.kind})

func step(a: Dictionary, b: Dictionary) -> void:
	events.clear()
	if not cinematic.is_empty():
		cinematic.tick+=1
		if cinematic.tick>=cinematic.duration:
			events.append({"type":"release","fighter":cinematic.fighter,"tier":cinematic.kind})
			cinematic.clear()
		return
	if phase=="intro":
		phase_ticks-=1
		if phase_ticks<=0: phase="fight"; events.append({"type":"fight"})
		return
	if phase!="fight": return
	var commands=[a,b]
	for i in 2:
		if commands[i].get("attack","")!="":
			fighters[i].buffer=commands[i].attack; fighters[i].buffer_time=10
	if hitstop>0: hitstop-=1; return
	frame+=1
	if not training: remaining-=1
	for i in 2: update_fighter(i,commands[i])
	# Simultaneous activation: both moves are committed; first presentation owns the freeze.
	if not cinematic.is_empty(): return
	pushboxes()
	var contacts: Array[Dictionary]=[]
	for i in 2:
		for box in hitboxes(i):
			for hurt in hurtboxes(1-i):
				if box.rect.intersects(hurt):
					contacts.append({"source":i,"move":fighters[i].move,"group":box.group,"position":box.rect.intersection(hurt).get_center(),"facing":fighters[i].facing,"serial":fighters[i].attack_serial})
					break
	# Snapshot contacts before resolution preserves trades without stale move reads.
	for c in contacts:
		if not fighters[c.source].connected.has(c.group):
			fighters[c.source].connected.append(c.group)
			contact(c)
	update_entities()
	pushboxes()
	if training:
		for f in fighters:
			if infinite_meter: f.meter=300
			if recover_health and f.state in ["idle","walk","crouch","guard"]: f.hp=1000
			if f.hp<=0: f.hp=1000
		return
	if fighters[0].hp<=0 or fighters[1].hp<=0 or remaining<=0:
		winner=-1 if fighters[0].hp==fighters[1].hp else (0 if fighters[0].hp>fighters[1].hp else 1)
		if winner>=0: wins[winner]+=1
		phase="round_end"; entities.clear(); cinematic.clear()
		for f in fighters:
			if f.hp<=0: f.state="ko"; f.ticks=0
		events.append({"type":"ko","winner":winner})

func update_fighter(i: int, cmd: Dictionary) -> void:
	var f=fighters[i]
	if cmd.get("guard",false): f.guard_ticks+=1
	else: f.guard_ticks=0
	for key in f.passive_cooldowns: f.passive_cooldowns[key]=maxi(0,f.passive_cooldowns[key]-1)
	if not f.buff.is_empty():
		f.buff.frames-=1
		if f.buff.frames<=0: f.buff.clear()
	var old_state: String=f.state
	f.dash_cd=maxi(0,f.dash_cd-1); f.guard_delay=maxi(0,f.guard_delay-1)
	f.buffer_time=maxi(0,f.buffer_time-1)
	if f.buffer_time==0: f.buffer=""
	if not f.status.is_empty():
		f.status.frames-=1
		if f.status.frames<=0: f.status.clear()
	f.meter=minf(300,f.meter+0.015)
	if f.y<0:
		f.vy+=27.0; f.y=minf(0,f.y+f.vy/60.0); f.x+=f.vx/60.0
		if f.y==0:
			f.air_used=false; f.landing=5; f.vy=0; f.vx=0
			if f.state=="attack" and f.move.stance=="air": f.state="landing"; f.move={}
	if f.down>0:
		f.down-=1; f.state="knockdown"; f.ticks+=1
		if f.down==0: f.wake=18; f.state="wakeup"; f.ticks=0
		return
	if f.wake>0:
		f.wake-=1; f.state="wakeup"; f.ticks+=1
		if f.wake==0: f.state="idle"
		return
	if f.stun>0:
		f.stun-=1; f.ticks+=1
		if f.stun==0: f.state="idle"; f.combo=0; f.combo_damage=0
		return
	if f.landing>0:
		f.landing-=1; f.state="landing"; return
	if f.jump_start>0:
		f.jump_start-=1; f.state="jump_start"
		if f.jump_start==0: f.y=-1.0; f.vy=-float(f.data.jump_speed); f.state="air"
		return
	if f.state=="attack":
		if f.buffer!="" and can_cancel(i,f.buffer) and legal_move(f,f.buffer): start_move(i,f.buffer); return
		f.ticks+=1
		if f.ticks>=f.move.startup-5 and f.ticks<f.move.startup+f.move.active:
			f.x+=f.facing*f.move.get("travel",0)
		if f.ticks==f.move.startup:
			for payload in f.move.get("spawns",[]): spawn_entity(i,payload,f.move)
		if f.ticks<f.move.startup+f.move.active+f.move.recovery: return
		f.state="idle"; f.move={}; f.move_id=""
	f.crouch=bool(cmd.get("crouch",false)) and f.y==0
	f.guarding=bool(cmd.get("guard",false)) and f.y==0
	if f.y==0: f.facing=1 if fighters[1-i].x>f.x else -1
	if f.guard_delay==0 and not f.guarding: f.guard=minf(100,f.guard+0.4)
	if f.guarding: f.state="guard"; f.buffer=""; return
	if f.buffer!="" and legal_move(f,f.buffer): start_move(i,f.buffer); return
	var axis: float=clampf(float(cmd.get("move",0)),-1,1)
	f.motion=axis
	if bool(cmd.get("jump",false)) and f.y==0 and not f.crouch:
		f.jump_start=4; f.vx=axis*f.data.speed; f.state="jump_start"; return
	if f.y<0: f.state="air"; return
	if f.dash>0:
		f.x+=f.vx/60.0; f.dash-=1; f.state="dash"; return
	if bool(cmd.get("dash",false)) and f.dash_cd==0 and not f.crouch:
		f.dash=9; f.dash_cd=35; f.vx=(axis if axis!=0 else f.facing)*690; f.state="dash"; return
	var slow: float=f.status.get("factor",1.0) if f.status.get("kind","")=="slow" else 1.0
	if not f.crouch: f.x+=axis*f.data.speed*(f.data.get("back_speed_factor",0.75) if axis*f.facing<0 else 1.0)*slow/60.0
	f.state="crouch" if f.crouch else ("walk" if axis!=0 else "idle")
	if old_state!=f.state: f.ticks=0
	else: f.ticks+=1

func pushboxes() -> void:
	for f in fighters: f.x=clampf(f.x,bounds.x,bounds.y)
	var a=fighters[0]; var b=fighters[1]
	if absf(a.y-b.y)>150: return
	var dx: float=b.x-a.x
	if absf(dx)<88:
		var sign_x: float=1 if dx>=0 else -1
		var center: float=clampf((a.x+b.x)/2,bounds.x+44,bounds.y-44)
		a.x=center-sign_x*44; b.x=center+sign_x*44

func contact(c: Dictionary) -> void:
	var a=fighters[c.source]; var d=fighters[1-c.source]; var m: Dictionary=c.move
	var counter_profile: Dictionary=d.move.get("counter",{}) if d.state=="attack" else {}
	if not c.get("entity",false) and not counter_profile.is_empty() and d.ticks>=counter_profile.start and d.ticks<=counter_profile.end and m.kind in ["normal","special","command_normal"]:
		a.stun=20; a.state="hurt"; a.move={}; d.state="idle"
		start_move(1-c.source,counter_profile.response)
		events.append({"type":"counter","fighter":1-c.source,"position":c.position})
		return
	var blocked: bool=(d.guarding or d.state=="block") and d.y==0 and (m.level!="low" or d.crouch) and (m.level!="overhead" or not d.crouch)
	var broken := false
	if blocked:
		d.guard=maxf(0,d.guard-(12 if m.kind=="normal" else 25)); d.guard_delay=80
		broken=d.guard<=0
	var damage:=0
	if blocked and not broken:
		d.state="block"; d.stun=int(m.blockstun); d.x+=c.facing*m.push*0.4
		if d.guard_ticks>0 and d.guard_ticks<=6: activate_passives(1-c.source,"perfect_block")
		if not c.get("entity",false): a.confirm="block"
		hitstop=4
	else:
		var counter: bool=d.state=="attack" and d.ticks<d.move.startup
		damage=maxi(1,int(m.damage*a.buff.get("factor",1.0)*(1.2 if counter else 1.0)*maxf(0.45,1-d.combo*0.1)))
		d.hp=maxi(0,d.hp-damage); d.combo+=1; d.combo_damage+=damage
		d.stun=48 if broken else int(m.stun); d.state="hurt"; d.ticks=0
		d.buffer=""; d.dash=0; d.x+=c.facing*m.push
		if not c.get("entity",false): a.confirm="hit"
		var final_contact: bool=c.get("entity",false) or int(c.get("group",0))==int(m.get("knockdown_group",0))
		if m.get("knockdown",0)>0 and final_contact:
			d.down=int(m.knockdown); d.state="knockdown"; d.stun=0; d.y=0; d.vy=0
		if m.has("status") and m.status.kind!="none": d.status=m.status.duplicate(true)
		d.meter=minf(300,d.meter+9)
		hitstop=int(m.hitstop)+(6 if m.kind in ["super","awakening"] else 0)
	d.move={}; d.move_id=""
	a.meter=minf(300,a.meter+(5 if blocked else 12))
	d.last_contact="block" if blocked and not broken else "hit"; d.last_damage=damage
	events.append({"type":d.last_contact,"fighter":1-c.source,"attacker":c.source,"position":c.position,"damage":damage,"break":broken,"combo":d.combo,"tier":m.kind})

func activate_passives(i: int, trigger: String) -> void:
	var f=fighters[i]
	for p in f.data.get("passives",[]):
		if p.trigger!=trigger or f.passive_cooldowns.get(p.id,0)>0: continue
		f.passive_cooldowns[p.id]=int(p.cooldown)
		f.meter=minf(300,f.meter+p.get("meter",0))
		if p.has("buff"): f.buff=p.buff.duplicate(true); f.buff.label=p.name
		events.append({"type":"passive","fighter":i,"name":p.name})

func spawn_entity(i: int, p: Dictionary, move: Dictionary) -> void:
	var f=fighters[i]
	entities.append({"owner":i,"kind":p.kind,"x":f.x+f.facing*p.get("offset_x",40),"y":f.y+p.get("offset_y",-120),"facing":f.facing,"speed":p.get("speed",0),"delay":p.get("delay",0),"life":p.get("life",80),"rect":p.get("rect",[-25,-25,50,50]),"move":move.duplicate(true),"connected":false})

func update_entities() -> void:
	for e in entities:
		e.life-=1
		if e.delay>0: e.delay-=1; continue
		e.x+=e.facing*e.speed/60.0
		if e.connected: continue
		for hurt in hurtboxes(1-e.owner):
			var box:=rect_world(e.rect,e)
			if box.intersects(hurt):
				contact({"source":e.owner,"move":e.move,"facing":e.facing,"position":box.intersection(hurt).get_center(),"entity":true})
				e.connected=true
				if e.kind=="projectile": e.life=0
				break
	# Opposed projectiles clash; zones expire independently of actor attack recovery.
	for i in entities.size():
		for j in range(i+1,entities.size()):
			var a=entities[i]; var b=entities[j]
			if a.owner!=b.owner and a.kind=="projectile" and b.kind=="projectile" and rect_world(a.rect,a).intersects(rect_world(b.rect,b)): a.life=0; b.life=0
	entities=entities.filter(func(e):return e.life>0 and e.x>bounds.x-100 and e.x<bounds.y+100)
