extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("run")
func shot(title: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/benchmark/"+title+".png")
func run() -> void:
	root.content_scale_size=Vector2i(1280,720); root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	game.set_physics_process(false)
	await shot("home")
	game.enter_mode("training"); await shot("select")
	game.confirm_select(); await shot("vs")
	game.begin_battle(); game.model.phase="fight"; await shot("training")
	game.rig_enabled=true; await shot("rig-idle")
	game.views[0].preview="WALK_FORWARD"; game.views[0].preview_time=0.3; await shot("rig-walk")
	game.views[0].preview="PUNCH"; game.views[0].preview_time=0.18; await shot("rig-punch")
	game.views[0].preview="KICK"; game.views[0].preview_time=0.28; await shot("rig-kick")
	game.views[0].preview=""; game.rig_enabled=false
	game.model.fighters[0].meter=300; game.model.start_move(0,"awakening"); game.model.cinematic.tick=38
	await shot("kai-awakening")
	game.reset_training(); game.model.phase="fight"; game.model.start_move(1,"awakening"); game.model.cinematic.tick=38
	await shot("lucy-awakening")
	game.reset_training(); game.touch_enabled=true; game.hud.rebuild(); await shot("touch")
	game.start_story(0); await shot("story")
	game.free(); quit()
