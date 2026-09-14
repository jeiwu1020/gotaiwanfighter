extends SceneTree
func _initialize() -> void:
	var b=load("res://src/core/battle.gd").new();b.setup("kai","lucy");b.phase="fight"
	b.fighters[0].x=500;b.fighters[1].x=640;b.fighters[1].meter=0
	b.step({"attack":"punch"},{"guard":true})
	for i in 6: b.step({}, {"guard":true})
	assert(b.fighters[1].meter>=15,"Lucy's timed block should grant intelligence meter")
	assert(b.fighters[1].get("buff",{}).get("factor",1)>1,"Timed block grants bounded damage buff")
	var before: float=b.fighters[1].meter
	b.activate_passives(1,"perfect_block")
	assert(b.fighters[1].meter==before,"Passive cooldown prevents duplicate reward")
	b.reset_round();assert(b.fighters[1].buff.is_empty() and b.fighters[1].passive_cooldowns.is_empty())
	print("PASSIVES: timed block / meter / buff / cooldown / reset passed");quit()
