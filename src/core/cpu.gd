extends RefCounted
var rng:=RandomNumberGenerator.new()
var difficulty := "normal"
var decision := 0
var threat_serial := -1
var react_at := 0
var defend := false
var last_move := ""
var repeat_count := 0
func _init(seed_value: int=431, level: String="normal") -> void:
	rng.seed=seed_value; difficulty=level
func command(b, i: int) -> Dictionary:
	if b.phase!="fight" or not b.cinematic.is_empty() or b.hitstop>0: return {}
	var f: Dictionary=b.fighters[i]; var o: Dictionary=b.fighters[1-i]
	var distance: float=absf(f.x-o.x)
	var dir: int=1 if o.x>f.x else -1
	var settings: Array={"easy":[20,0.28,30],"normal":[12,0.58,18],"hard":[7,0.8,11]}[difficulty]
	if o.state=="attack" and o.attack_serial!=threat_serial:
		threat_serial=o.attack_serial; react_at=b.frame+settings[0]
		if o.move_id==last_move: repeat_count+=1
		else: last_move=o.move_id; repeat_count=0
		defend=rng.randf()<minf(0.92,settings[1]+(repeat_count*0.035 if difficulty=="hard" else 0))
	if o.state=="attack" and b.frame>=react_at and defend and distance<310:
		return {"guard":true,"crouch":o.move.level=="low"}
	decision-=1
	if f.state=="attack":
		if f.confirm=="hit" and difficulty!="easy" and b.can_cancel(i,"super") and f.meter>=100: return {"attack":"super"}
		return {}
	if f.y<0: return {"attack":"air_kick"} if distance<220 and not f.air_used else {}
	if decision>0: return {"move":dir if distance>f.data.preferred+30 else 0}
	decision=int(settings[2])+rng.randi_range(0,10)
	if o.y<-45 and distance<210: return {"attack":"special_kick"}
	if distance>280:
		if rng.randf()<0.23: return {"jump":true,"move":dir}
		return {"move":dir,"dash":rng.randf()<0.5}
	var choices: Array=["punch","kick","crouch_kick","special_punch","special_kick"]
	if f.meter>=100 and difficulty!="easy": choices.append("super")
	if f.meter>=200 and difficulty=="hard": choices.append("awakening")
	if distance>200: return {"attack":"special_punch"}
	var attack: String=choices[rng.randi_range(0,choices.size()-1)]
	return {"attack":attack,"crouch":attack.begins_with("crouch")}
