extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.enter_mode("training");g.begin_battle();g.touch_enabled=true;g.hud.rebuild()
	g.hud.set_finger(0,Vector2(195,650),true);g.hud.set_finger(1,Vector2(345,535),true)
	assert(g.human(0).move==1 and g.touch_held.guard)
	g.hud.set_finger(2,Vector2(345,535),true);g.hud.set_finger(1,Vector2.ZERO,false)
	assert(g.touch_held.guard,"One finger release must preserve second finger")
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(700,350);g.hud._input(drag)
	assert(not g.touch_held.right,"Dragging out of controls releases movement")
	g.toggle_pause();assert(g.touch_held.is_empty() and g.pending[0].is_empty())
	g.toggle_pause();g.model.fighters[0].meter=300
	var trigger:=InputEventJoypadMotion.new();trigger.device=0;trigger.axis=JOY_AXIS_TRIGGER_RIGHT;trigger.axis_value=1
	g._input(trigger);g._physics_process(1.0/60)
	assert(g.model.fighters[0].move_id=="awakening")
	g._input(trigger);assert(g.pending[0].is_empty(),"Held trigger does not repeatedly issue awakening")
	g.clean_presentation();assert(g.model.cinematic.is_empty() and g.camera.zoom==Vector2.ONE)
	g.sound.shutdown()
	assert(g.sound.music.stream==null and g.sound.ambience.stream==null,"Audio shutdown releases stream resources before scene disposal")
	print("DEVICES: independent fingers / drag release / pause cleanup / trigger edge passed")
	# Headless Windows audio releases its playback resources on later mix cycles.
	# Wait through several cycles after shutdown before asserting process cleanup.
	g.queue_free(); await process_frame; await create_timer(1.0).timeout
	quit()
