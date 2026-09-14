extends Node2D
## Raster baseline and optional single-source rig share the same simulation adapter.
var fighter: Dictionary
var manifest: Dictionary
var textures: Dictionary={}
var sprite:=Sprite2D.new()
var rig: Node2D
var use_rig := false
var frozen := false
var elapsed := 0.0
var state_name := ""
var preview := ""
var preview_time := 0.0
var floor_y := 585.0
func configure(f: Dictionary) -> void:
	fighter=f
	manifest=JSON.parse_string(FileAccess.get_file_as_string(f.data.visual))
	for key in manifest.sheets: textures[key]=load(manifest.sheets[key].texture)
	add_child(sprite)
	sprite.position.y=192-377
	if f.data.get("rig","")!="" and ResourceLoader.exists(f.data.rig):
		rig=load(f.data.rig).instantiate(); rig.z_index=10; rig.scale=Vector2(0.84,0.84); add_child(rig)
func animation_name() -> String:
	if preview!="": return preview
	if fighter.state=="attack": return fighter.move.animation
	match fighter.state:
		"walk","dash": return "WALK_BACK" if fighter.get("motion",1)*fighter.facing<0 else "WALK_FORWARD"
		"crouch": return "CROUCH"
		"guard": return "CROUCH_BLOCK" if fighter.crouch else "BLOCK"
		"block": return "CROUCH_BLOCK" if fighter.crouch else "BLOCK_HIT"
		"hurt": return "HIT"
		"jump_start": return "JUMP_START"
		"landing": return "LANDING"
		"air": return "JUMP_UP" if fighter.vy<0 else "JUMP_FALL"
		"knockdown": return "KNOCKDOWN"
		"wakeup": return "WAKEUP"
		"ko": return "KO"
	return "IDLE"
func sync(delta: float) -> void:
	position=Vector2(fighter.x,floor_y+fighter.y)
	if fighter.state in ["ko","knockdown"]: position.x=clampf(position.x,192,1088)
	scale.x=float(fighter.facing)
	var anim:=animation_name()
	if anim!=state_name: elapsed=0; state_name=anim
	var playback:=1.0
	if use_rig and anim in ["WALK_FORWARD","WALK_BACK"]:
		playback=fighter.data.speed/201.6*(fighter.data.get("back_speed_factor",0.75) if anim=="WALK_BACK" else 1.0)
	if not frozen: elapsed+=delta*playback
	var clip: Dictionary=manifest.clips.get(anim,manifest.clips.IDLE)
	var seq: Array=clip.sequence
	var at: int=int(elapsed*clip.fps)
	if fighter.state=="attack" and preview=="":
		var m: Dictionary=fighter.move
		var phase_fraction: float
		if fighter.ticks<m.startup: phase_fraction=0.28*float(fighter.ticks)/maxf(1,m.startup)
		elif fighter.ticks<m.startup+m.active: phase_fraction=0.28+0.4*float(fighter.ticks-m.startup)/maxf(1,m.active)
		else: phase_fraction=0.68+0.32*float(fighter.ticks-m.startup-m.active)/maxf(1,m.recovery)
		at=int(phase_fraction*seq.size())
	if preview!="": at=int(preview_time*clip.fps)
	at=posmod(at,seq.size()) if clip.loop else mini(at,seq.size()-1)
	var sheet: Dictionary=manifest.sheets[clip.sheet]
	sprite.texture=textures[clip.sheet]; sprite.hframes=int(sheet.cols); sprite.vframes=int(sheet.rows); sprite.frame=int(seq[at])
	sprite.visible=not use_rig or rig==null
	if rig:
		rig.visible=use_rig
		var player: AnimationPlayer=rig.get_node("AnimationPlayer")
		if player.has_animation(anim):
			if player.current_animation!=anim: player.play(anim)
			player.pause()
			var duration: float=player.get_animation(anim).length
			var t: float=preview_time if preview!="" else elapsed
			if fighter.state=="attack" and preview=="": t=float(fighter.ticks)/float(fighter.move.startup+fighter.move.active+fighter.move.recovery)*duration
			player.seek(fmod(t,duration) if clip.loop else minf(t,duration),true)
	queue_redraw()
func _draw() -> void:
	if fighter.is_empty(): return
	draw_set_transform(Vector2(0,-fighter.y),0,Vector2(1,0.16))
	draw_circle(Vector2.ZERO,65,Color(0,0,0,0.28))
	draw_set_transform(Vector2.ZERO)
