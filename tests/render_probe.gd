extends SceneTree
var ticks:=0
func _initialize() -> void:
	if OS.get_cmdline_user_args().has("no-vsync"): DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	print("PROBE adapter=",RenderingServer.get_video_adapter_name()," vsync=",DisplayServer.window_get_vsync_mode())
func _process(_delta: float) -> bool:
	ticks+=1
	if ticks%20==0: print("PROBE fps=",Engine.get_frames_per_second()," process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000," physics_ms=",Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
	if ticks>=80:quit()
	return false
