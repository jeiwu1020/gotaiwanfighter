extends SceneTree
func _initialize() -> void:
	if not ResourceLoader.exists("res://src/modes/progress.gd"):
		printerr("FAIL: Story progression and input parser not implemented")
		quit(1); return
	var flow=load("res://src/modes/progress.gd").new()
	flow.save_path="user://parity-test-save.json"
	flow.start_story(0)
	assert(flow.node().type=="dialogue")
	flow.advance(); assert(flow.node().type=="battle")
	flow.battle_result(false); assert(flow.node().type=="battle")
	flow.battle_result(true); assert(flow.node().type=="dialogue")
	flow.advance(); flow.battle_result(true); flow.advance()
	assert(flow.cleared.has("last_delivery") and flow.complete)
	var parser=load("res://src/core/commands.gd").new()
	parser.poll({"crouch":true},1,false)
	parser.poll({"crouch":true,"move":1},1,false)
	var command=parser.poll({"move":1,"button":"punch"},1,false)
	assert(command.attack=="special_punch")
	parser.clear()
	parser.poll({"crouch":true},-1,false)
	parser.poll({"crouch":true,"move":-1},-1,false)
	assert(parser.poll({"move":-1,"button":"kick"},-1,false).attack=="special_kick")
	print("PARITY MODES: story victory-only progression / clear / mirrored 236 passed")
	quit()
