extends SceneTree
const Battle=preload("res://src/core/battle.gd")
var checks:=0
var failures:=0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+label)
func arena():
	var b=Battle.new(); b.setup("kai","lucy"); b.phase="fight"
	b.fighters[0].x=500; b.fighters[1].x=640
	b.fighters[0].meter=300; b.fighters[1].meter=300
	return b
func _initialize() -> void:
	var b=arena()
	b.step({"attack":"super"},{})
	var hits:=0
	for i in 150:
		b.step({},{})
		for e in b.events:
			if e.type=="hit": hits+=1
	check(hits==2,"Two Super contact groups both land before final knockdown")
	b=arena(); b.step({"attack":"super"},{"attack":"awakening"})
	check(b.cinematic.fighter==0,"First simultaneous cinematic owns presentation")
	check(b.fighters[1].move_id=="awakening","Simultaneous opponent move still committed")
	b=arena(); b.fighters[0].x=300; b.fighters[1].x=800
	var payload={"kind":"projectile","speed":600,"life":90}
	var attack: Dictionary=b.roster.kai.moves.punch.duplicate(true)
	b.spawn_entity(0,payload,attack)
	for i in 70: b.step({},{})
	check(b.fighters[1].hp<1000 and b.entities.is_empty(),"Projectile persists independently, hits then despawns")
	check(b.fighters[0].confirm=="miss","Old projectile cannot grant a new melee cancel confirm")
	b=arena(); b.spawn_entity(0,{"kind":"zone","offset_x":140,"delay":12,"life":40},attack)
	for i in 10: b.step({},{})
	check(b.fighters[1].hp==1000,"Area telegraph delays damage")
	for i in 30: b.step({},{})
	check(b.fighters[1].hp<1000,"Area effect becomes active")
	b=arena(); b.step({}, {"attack":"special_kick"})
	for i in 26: b.step({},{})
	check(b.fighters[0].status.get("kind","")=="slow","Lucy applies authored slow status")
	b=arena(); b.roster.lucy.moves.command.counter={"start":0,"end":20,"response":"special_kick"}
	b.step({"attack":"punch"},{"attack":"command"})
	for i in 6: b.step({},{})
	check(b.fighters[1].move_id=="special_kick" and b.fighters[1].hp==1000,"Generic counter window deflects and responds")
	print("PARITY DEPTH: %d/%d"%[checks-failures,checks]); quit(1 if failures else 0)
