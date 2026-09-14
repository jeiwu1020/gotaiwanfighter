extends SceneTree
var g: Node
var count:=0
var frames: Array=[]
var driver=preload("res://src/core/cpu.gd").new(502,"hard")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if OS.get_cmdline_user_args().has("no-vsync"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=60
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.enter_mode("cpu");g.begin_battle();g.set_physics_process(false)
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
func _physics_process(delta: float) -> bool:
	if not is_instance_valid(g): return false
	if g.model.phase=="round_end":g.continue_round()
	if g.screen=="result":g.begin_battle()
	g.model.step(driver.command(g.model,0),g.cpu.command(g.model,1))
	for e in g.model.events:g.presentation.accept(e);g.sound.play_event(e)
	count+=1
	if count%60==0 and count>120:frames.append(Engine.get_frames_per_second())
	if count==720:
		var out={"renderer":RenderingServer.get_video_adapter_name(),"viewport":"1280x720","fps_samples_after_warmup":frames,"godot_static_memory_bytes":OS.get_static_memory_usage(),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		var file=FileAccess.open("res://artifacts/benchmark/native-perf.json",FileAccess.WRITE);file.store_string(JSON.stringify(out,"  "));file.close();print(JSON.stringify(out));g.free();quit()
	return false
