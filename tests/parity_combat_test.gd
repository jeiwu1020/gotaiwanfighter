extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + label)
func _initialize() -> void:
	if not ResourceLoader.exists("res://src/core/battle.gd"):
		check(false, "Production combat supports height, boxes and confirms")
		quit(1)
		return
	var C = load("res://src/core/battle.gd")
	var b = C.new()
	b.setup("kai", "lucy")
	b.phase = "fight"
	check(b.fighters[0].data.moves.size() >= 11, "Kai full moveset")
	check(b.fighters[1].data.moves.size() >= 11, "Lucy full moveset")
	b.step({"jump":true}, {})
	for i in 12: b.step({}, {})
	check(b.fighters[0].y < -30, "Jump changes collision elevation")
	for i in 100: b.step({}, {})
	check(b.fighters[0].y == 0, "Jump returns to ground")
	b.step({"crouch":true}, {})
	check(b.hurtboxes(0)[0].size.y < 180, "Crouch changes hurt geometry")
	b.reset_round(); b.phase="fight"
	b.fighters[0].x=500; b.fighters[1].x=640
	b.step({"attack":"crouch_kick","crouch":true}, {"guard":true})
	for i in 24: b.step({}, {"guard":true})
	check(b.fighters[1].hp<1000, "Low beats standing guard")
	check(b.fighters[1].state == "knockdown", "Sweep knocks down")
	for i in 100: b.step({}, {})
	check(b.fighters[1].state=="idle", "Wakeup returns actionable")
	b.reset_round(); b.phase="fight"
	b.fighters[0].x=500; b.fighters[1].x=640
	b.step({"attack":"crouch_kick","crouch":true}, {"guard":true,"crouch":true})
	for i in 24: b.step({}, {"guard":true,"crouch":true})
	check(b.fighters[1].hp==1000, "Crouch guard blocks low")
	b.reset_round(); b.phase="fight"
	b.step({"attack":"punch"}, {})
	for i in 8: b.step({}, {})
	check(not b.can_cancel(0,"special_punch"), "Whiff cannot confirm cancel")
	b.reset_round(); b.phase="fight"
	b.fighters[0].x=500; b.fighters[1].x=630
	b.step({"attack":"punch"}, {})
	for i in 7: b.step({}, {})
	check(b.fighters[0].confirm=="hit", "Melee produces hit confirm")
	check(b.can_cancel(0,"special_punch"), "Hit opens authored cancel")
	b.reset_round(); b.phase="fight"
	b.fighters[0].meter=200
	b.step({"attack":"awakening"}, {})
	check(not b.cinematic.is_empty(), "Awakening starts cinematic")
	var ticks = b.fighters[0].ticks
	var timer = b.remaining
	for i in 20: b.step({}, {})
	check(b.fighters[0].ticks==ticks and b.remaining==timer, "Cinematic freezes simulation timer and move")
	b.reset_round()
	check(b.cinematic.is_empty() and b.entities.is_empty(), "Reset clears cinematic and entities")
	# Same schema under an unrelated ID; no fighter-ID dispatch required.
	b.roster["third_fixture"]=b.roster.kai.duplicate(true)
	b.setup("third_fixture","lucy")
	check(b.fighters[0].data.moves.size()==11, "Third character through data only")
	print("PARITY COMBAT: %d/%d" % [checks-failures,checks])
	quit(0 if failures==0 else 1)
