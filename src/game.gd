extends Node2D
## Composition root: owns mode transitions, devices and lifetimes. Simulation owns combat.
const Battle=preload("res://src/core/battle.gd")
const Commands=preload("res://src/core/commands.gd")
const Cpu=preload("res://src/core/cpu.gd")
const Actor=preload("res://src/presentation/actor.gd")
const Flow=preload("res://src/modes/progress.gd")
var model=Battle.new()
var flow=Flow.new()
var parsers=[Commands.new(),Commands.new()]
var cpu=Cpu.new()
var screen := "home"
var mode := "cpu"
var selected := "kai"
var opponent := "lucy"
var difficulty := "normal"
var stage_id := "night"
var stages: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/stages.json"))
var paused := false
var help_open := false
var help_page := "controls"
var reduced_motion := false
var debug_boxes := false
var rig_enabled := false
var touch_enabled := OS.has_feature("web") or OS.has_feature("mobile")
var dummy := "idle"
var world:=Node2D.new()
var stage=preload("res://src/stage.gd").new()
var camera:=Camera2D.new()
var views: Array=[]
var hud: Control
var presentation: Node2D
var sound: Node
var pending: Array=[{},{}]
var held: Dictionary={}
var touch_held: Dictionary={}
var trigger_held: Dictionary={}
var seconds := 0.0
var keys: Array=[
	{"left":KEY_A,"right":KEY_D,"down":KEY_S,"up":KEY_W,"guard":KEY_SPACE,"punch":KEY_J,"kick":KEY_K,"special_punch":KEY_U,"special_kick":KEY_I,"super":KEY_O,"awakening":KEY_L,"dash":KEY_SHIFT},
	{"left":KEY_LEFT,"right":KEY_RIGHT,"down":KEY_DOWN,"up":KEY_UP,"guard":KEY_KP_0,"punch":KEY_KP_1,"kick":KEY_KP_2,"special_punch":KEY_KP_4,"special_kick":KEY_KP_5,"super":KEY_KP_6,"awakening":KEY_KP_3,"dash":KEY_KP_7}]

func _ready() -> void:
	add_child(world); world.add_child(stage)
	camera.position=Vector2(640,360); camera.position_smoothing_enabled=false
	world.add_child(camera)
	presentation=load("res://src/presentation/effects.gd").new(); presentation.game=self; world.add_child(presentation)
	sound=load("res://src/presentation/audio.gd").new(); add_child(sound)
	var canvas:=CanvasLayer.new(); canvas.layer=10; add_child(canvas)
	hud=load("res://src/presentation/interface.gd").new(); hud.game=self; canvas.add_child(hud)
	flow.load_save(); show_home()

func clean_input() -> void:
	pending=[{},{}]; held.clear(); touch_held.clear()
	trigger_held.clear()
	for p in parsers: p.clear()

func clean_presentation() -> void:
	model.cinematic.clear(); model.entities.clear()
	if presentation: presentation.clear()
	camera.position=Vector2(640,360); camera.zoom=Vector2.ONE; camera.offset=Vector2.ZERO
	clean_input()

func rebuild_actors() -> void:
	for view in views: view.queue_free()
	views.clear()
	for f in model.fighters:
		var v=Actor.new(); v.configure(f); v.floor_y=stages[stage_id].floor; world.add_child(v); views.append(v)
	world.move_child(presentation,world.get_child_count()-1)

func show_home() -> void:
	clean_presentation(); paused=false; help_open=false; screen="home"
	model.training=false; model.setup("kai","lucy")
	model.fighters[0].x=800; model.fighters[1].x=1070
	rebuild_actors(); hud.rebuild()

func enter_mode(new_mode: String) -> void:
	clean_presentation(); mode=new_mode; paused=false; help_open=false
	screen="story_menu" if mode=="story" else "select"
	hud.rebuild()

func confirm_select() -> void:
	screen="vs"; clean_input(); hud.rebuild()

func begin_battle() -> void:
	clean_presentation(); model.training=mode=="training"
	model.setup(selected,opponent)
	model.bounds=Vector2(stages[stage_id].left,stages[stage_id].right)
	cpu=Cpu.new(731,difficulty)
	stage.modulate=Color(1.1,0.95,0.82) if stage_id=="dawn" else Color.WHITE
	stage.configure(stages[stage_id])
	screen="battle"; paused=false; help_open=false
	rebuild_actors(); hud.rebuild(); sound.stage_changed(stages[stage_id])

func start_story(index: int) -> void:
	mode="story"; flow.start_story(index); selected=flow.route.fighter
	story_node()

func story_node() -> void:
	clean_presentation(); paused=false
	if flow.complete: screen="clear"
	elif flow.node().type=="dialogue": screen="dialogue"
	else:
		var n: Dictionary=flow.node()
		opponent=n.opponent; stage_id=n.stage; difficulty=n.get("difficulty","normal"); screen="vs"
	model.setup(selected,opponent); rebuild_actors()
	hud.rebuild()

func advance_dialogue() -> void:
	flow.line_index+=1
	if flow.line_index>=flow.node().lines.size(): flow.advance(); story_node()
	else: hud.rebuild()

func continue_round() -> void:
	model.next_round(); clean_input()
	if model.phase=="match_end": screen="result"
	hud.rebuild()

func continue_result() -> void:
	if mode=="story" and model.winner==0: flow.battle_result(true); story_node()
	else: begin_battle()

func reset_training() -> void:
	clean_presentation(); model.reset_round(); model.fighters[0].meter=300; model.fighters[1].meter=300
	hud.rebuild()

func toggle_pause() -> void:
	if screen!="battle": return
	paused=not paused; help_open=false; clean_input(); hud.rebuild()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		clean_input()
		if screen=="battle" and not paused: toggle_pause()

func primary_action() -> void:
	match screen:
		"home": enter_mode("cpu")
		"select": confirm_select()
		"vs": begin_battle()
		"dialogue": advance_dialogue()
		"result": continue_result()
		"clear": enter_mode("story")
		"battle":
			if paused: toggle_pause()
			elif model.phase=="round_end": continue_round()

func action_pressed(action: String, i: int=0) -> void:
	if screen!="battle" or paused: return
	if action in ["punch","kick"]: pending[i].button=action
	elif action in ["jump","dash"]: pending[i][action]=true
	else: pending[i].attack=action

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: int=event.keycode if event.keycode!=0 else event.physical_keycode
		held[key]=event.pressed
		if not event.pressed or event.echo: return
		if key==KEY_ENTER: primary_action(); get_viewport().set_input_as_handled(); return
		if key==KEY_ESCAPE:
			if screen=="battle": toggle_pause()
			else: show_home()
			return
		if key==KEY_F1:
			help_page="controls"
			help_open=not help_open
			if screen=="battle": paused=help_open
			clean_input(); hud.rebuild(); return
		if key==KEY_TAB and screen=="battle":
			help_page="moves"; help_open=not help_open; paused=help_open; clean_input(); hud.rebuild(); return
		if key==KEY_F2: debug_boxes=not debug_boxes
		if key==KEY_F3: reduced_motion=not reduced_motion; stage.motion=not reduced_motion
		if key==KEY_F4: touch_enabled=not touch_enabled; hud.rebuild()
		if key==KEY_F5 and mode=="training": dummy="guard" if dummy=="idle" else "idle"; hud.rebuild()
		if key==KEY_F6 and mode=="training": model.infinite_meter=not model.infinite_meter; hud.rebuild()
		if key==KEY_F7 and mode=="training": rig_enabled=not rig_enabled; hud.rebuild()
		if key==KEY_M: sound.toggle()
		if key==KEY_R and screen=="battle":
			if mode=="training": reset_training()
			else: begin_battle()
		for i in 2:
			for action in keys[i]:
				if key==keys[i][action]:
					if action=="up": action_pressed("jump",i)
					elif action not in ["left","right","down","guard"]: action_pressed(action,i)
	if event is InputEventJoypadButton and event.pressed:
		var i: int=mini(event.device,1) if mode=="local" else 0
		if event.button_index==JOY_BUTTON_START: primary_action() if screen!="battle" else toggle_pause()
		var map={JOY_BUTTON_A:"punch",JOY_BUTTON_X:"kick",JOY_BUTTON_Y:"special_punch",JOY_BUTTON_RIGHT_SHOULDER:"dash",JOY_BUTTON_DPAD_UP:"jump",JOY_BUTTON_LEFT_SHOULDER:"super"}
		if map.has(event.button_index): action_pressed(map[event.button_index],i)
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
		var trigger: String="%d:%d"%[event.device,event.axis]
		var pressed: bool=event.axis_value>0.6
		if pressed and not trigger_held.get(trigger,false):
			action_pressed("special_kick" if event.axis==JOY_AXIS_TRIGGER_LEFT else "awakening",mini(event.device,1) if mode=="local" else 0)
		trigger_held[trigger]=pressed

func human(i: int) -> Dictionary:
	var k: Dictionary=keys[i]
	var result: Dictionary=pending[i].duplicate(); pending[i].clear()
	result.move=int(held.get(k.right,false))-int(held.get(k.left,false))
	result.crouch=held.get(k.down,false); result.guard=held.get(k.guard,false)
	if i==0:
		if touch_held.get("left",false) or touch_held.get("right",false): result.move=int(touch_held.get("right",false))-int(touch_held.get("left",false))
		result.crouch=result.crouch or touch_held.get("down",false)
		result.guard=result.guard or touch_held.get("guard",false)
	if Input.get_connected_joypads().has(i):
		var axis: float=Input.get_joy_axis(i,JOY_AXIS_LEFT_X)
		if absf(axis)>0.25: result.move=signf(axis)
		result.crouch=result.crouch or Input.get_joy_axis(i,JOY_AXIS_LEFT_Y)>0.5 or Input.is_joy_button_pressed(i,JOY_BUTTON_DPAD_DOWN)
		result.guard=result.guard or Input.is_joy_button_pressed(i,JOY_BUTTON_B)
		if Input.is_joy_button_pressed(i,JOY_BUTTON_DPAD_LEFT): result.move=-1
		if Input.is_joy_button_pressed(i,JOY_BUTTON_DPAD_RIGHT): result.move=1
	return parsers[i].poll(result,model.fighters[i].facing,model.fighters[i].y<0)

func _physics_process(_delta: float) -> void:
	if screen!="battle" or paused: return
	var before: String=model.phase
	var other: Dictionary
	if mode=="local": other=human(1)
	elif mode=="training":
		other={"guard":dummy=="guard","crouch":dummy=="guard" and model.fighters[0].get("move",{}).get("level","")=="low"}
	else: other=cpu.command(model,1)
	model.step(human(0),other)
	for e in model.events:
		presentation.accept(e)
		if e.has("fighter"): e.sound_path=model.fighters[e.fighter].data.get("audio",{}).get(e.type,"")
		sound.play_event(e)
	if before!=model.phase: hud.rebuild()

func _process(delta: float) -> void:
	seconds+=delta
	for v in views:
		v.frozen=paused or model.hitstop>0 or not model.cinematic.is_empty()
		v.use_rig=rig_enabled
		v.sync(delta)
	hud.queue_redraw()
