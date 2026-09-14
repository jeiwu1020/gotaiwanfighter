extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	if not g.has_method("enter_mode"):
		printerr("FAIL: production mode navigation is missing")
		g.queue_free(); await process_frame; quit(1); return
	g.enter_mode("training"); g.confirm_select()
	assert(g.screen=="vs")
	g.begin_battle()
	assert(g.model.training and g.mode=="training")
	g.reset_training()
	assert(g.model.fighters[0].hp==1000 and g.model.entities.is_empty())
	g.toggle_pause(); assert(g.paused)
	g.show_home(); assert(not g.paused and g.model.cinematic.is_empty())
	g.enter_mode("local"); g.confirm_select(); g.begin_battle()
	assert(g.mode=="local")
	g.start_story(0); assert(g.screen=="dialogue")
	for i in 3: g.advance_dialogue()
	assert(g.screen=="vs")
	g.begin_battle(); assert(g.mode=="story")
	g.show_home()
	print("PARITY SCENE: Training / local / Story / VS / pause cleanup passed")
	g.sound.shutdown()
	assert(g.sound.music.stream==null and g.sound.ambience.stream==null,"Scene cleanup releases audio streams")
	g.queue_free(); await process_frame; await create_timer(1.0).timeout
	quit()
