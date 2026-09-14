extends SceneTree
func _initialize() -> void:
	var rows: Array=[]
	for difficulty in ["easy","normal","hard"]:
		var wins=[0,0,0]
		for seed_value in 12:
			var b=load("res://src/core/battle.gd").new();b.setup("kai","lucy")
			var a=load("res://src/core/cpu.gd").new(seed_value*31+9,difficulty)
			var z=load("res://src/core/cpu.gd").new(seed_value*73+5,difficulty)
			for tick in 18000:
				if b.phase=="round_end": b.next_round()
				if b.phase=="match_end": break
				b.step(a.command(b,0),z.command(b,1))
			wins[b.winner if b.winner>=0 else 2]+=1
		rows.append({"difficulty":difficulty,"kai":wins[0],"lucy":wins[1],"draw":wins[2]})
	var file=FileAccess.open("res://artifacts/benchmark/cpu-balance.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close()
	print("CPU BALANCE ",JSON.stringify(rows));quit()
