extends SceneTree
var g: Node
var failures:=0
var report: Array=[]
var output_root := "res://artifacts/benchmark"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="): output_root=arg.substr(4)
	DirAccess.make_dir_recursive_absolute(output_root)
	call_deferred("run")
func check(ok: bool, title: String) -> void:
	report.append({"check":title,"passed":ok})
	if not ok: failures+=1; printerr("FAIL: "+title)
func key(code: int, pressed: bool=true) -> void:
	var e:=InputEventKey.new(); e.keycode=code; e.pressed=pressed; Input.parse_input_event(e)
	Input.flush_buffered_events()
func tick(n: int) -> void:
	for i in n:
		g._physics_process(1.0/60)
		await process_frame
func shot(title: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_root+"/play-"+title+".png")
func run() -> void:
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	if not is_instance_valid(g.hud): printerr("FAIL: UI failed to initialize");g.free();quit(1);return
	g.enter_mode("training");g.begin_battle();g.model.recover_health=false;g.reset_training()
	key(KEY_D);await tick(50);key(KEY_D,false)
	check(g.model.fighters[0].x>610,"Keyboard movement reaches attack range")
	key(KEY_J);key(KEY_J,false);await tick(12)
	check(g.model.fighters[1].hp<1000,"Keyboard punch produces real collision damage")
	g.dummy="guard";await tick(35);var hp: int=g.model.fighters[1].hp
	key(KEY_K);key(KEY_K,false);await tick(35)
	check(g.model.fighters[1].hp==hp and g.model.fighters[1].last_contact=="block","Training guard blocks keyboard kick")
	await shot("block")
	g.dummy="idle";key(KEY_S);await tick(1);key(KEY_K);key(KEY_K,false);await tick(18);key(KEY_S,false)
	check(g.model.fighters[1].state=="knockdown","Keyboard crouch kick causes knockdown")
	await shot("knockdown");await tick(90)
	key(KEY_W);key(KEY_W,false);await tick(10);key(KEY_K);key(KEY_K,false);await tick(8)
	check(g.model.fighters[0].y<0,"Keyboard air attack is airborne")
	await shot("air");await tick(90)
	g.reset_training();key(KEY_L);key(KEY_L,false);await tick(28);await shot("anticipation")
	var cine_tick: int=g.model.cinematic.tick; key(KEY_ESCAPE);key(KEY_ESCAPE,false);await tick(20)
	check(g.model.cinematic.tick==cine_tick and g.paused,"Pause freezes cinematic clock")
	print("Pause observation ",cine_tick," -> ",g.model.cinematic.get("tick",-1)," paused=",g.paused)
	key(KEY_ESCAPE);key(KEY_ESCAPE,false);await tick(20);await shot("cutin")
	await tick(52);await shot("release");await tick(90)
	check(g.model.cinematic.is_empty() and g.camera.zoom.is_equal_approx(Vector2.ONE),"Awakening returns camera and simulation")
	g.enter_mode("local");g.begin_battle();await tick(80)
	var x: float=g.model.fighters[1].x;key(KEY_LEFT);await tick(20);key(KEY_LEFT,false)
	check(g.model.fighters[1].x<x-50,"Local P2 independent keyboard direction")
	key(KEY_KP_4);key(KEY_KP_4,false);await tick(1)
	check(g.model.fighters[1].move_id=="special_punch","Local P2 special input")
	print("P2 observation ",g.model.fighters[1].move_id," pending=",g.pending[1]," buffer=",g.model.fighters[1].buffer)
	await shot("local")
	# Full Story route uses the same CPU commands and collision model, no HP/winner writes.
	g.flow.save_path="user://gpu-story-test.json";g.start_story(0)
	var driver=load("res://src/core/cpu.gd").new(991,"hard")
	var rounds:=0;var attempts:=0;var losses:=0;var budget:=45000
	while g.screen!="clear" and budget>0:
		budget-=1
		match g.screen:
			"dialogue": g.advance_dialogue()
			"vs": g.begin_battle();attempts+=1
			"result":
				if g.model.winner!=0: attempts+=1;losses+=1
				g.continue_result()
			"battle":
				if g.model.phase=="round_end":
					rounds+=1; await shot("story-round-%d"%rounds);g.continue_round()
				else:
					g.model.step(driver.command(g.model,0),g.cpu.command(g.model,1))
					for event in g.model.events: g.presentation.accept(event);g.sound.play_event(event)
		if budget%8==0: await process_frame
	check(g.screen=="clear","Real combat advances two-battle Story route through clear")
	await shot("story-clear")
	var saved=load("res://src/modes/progress.gd").new();saved.save_path=g.flow.save_path;saved.load_save()
	check(saved.cleared.has("last_delivery"),"Story clear persisted and loaded")
	var out=FileAccess.open(output_root+"/gpu-play.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":report,"rounds":rounds,"matches":attempts,"losses_retried":losses,"remaining_budget":budget},"  "));out.close()
	print("GPU PLAY: ",report.size()-failures,"/",report.size(),"; Story matches ",attempts," rounds ",rounds)
	g.free();quit(1 if failures else 0)
