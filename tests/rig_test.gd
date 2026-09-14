extends SceneTree
func _initialize() -> void:
	if not ResourceLoader.exists("res://scenes/rigs/kai.tscn"):
		printerr("FAIL: single-source rig has no replayable animation scene")
		quit(1); return
	var rig=load("res://scenes/rigs/kai.tscn").instantiate()
	root.add_child(rig)
	var player: AnimationPlayer=rig.get_node("AnimationPlayer")
	assert(player.has_animation("WALK_FORWARD") and player.has_animation("PUNCH") and player.has_animation("WAKEUP"))
	var head: Sprite2D=rig.get_node("Skeleton2D/Hip/Torso/Head/Art")
	var texture_id=head.texture.get_instance_id()
	for name in player.get_animation_list():
		player.play(name)
		for t in [0.0,0.2,0.5,0.9]:
			player.seek(t*player.get_animation(name).length,true)
			assert(head.texture.get_instance_id()==texture_id, "Face texture must not swap across poses")
	print("RIG: identity texture constant through %d clips"%player.get_animation_list().size())
	player.play("WALK_FORWARD")
	var shin: Bone2D=rig.get_node("Skeleton2D/Hip/RearThigh/RearShin")
	var anchor:=Vector2.ZERO;var drift:=0.0;var ground_error:=0.0
	for i in 24:
		var t: float=i*0.016
		player.seek(t,true)
		var foot: Vector2=(shin.global_transform*Vector2(0,100))*0.84+Vector2(201.6*t,0)
		if i==0: anchor=foot
		drift=maxf(drift,absf(foot.x-anchor.x));ground_error=maxf(ground_error,absf(foot.y))
	assert(drift<0.8 and ground_error<0.8,"Rig stance foot must remain grounded and match world travel")
	print("RIG stance foot: horizontal drift ",drift," px; ground error ",ground_error," px")
	rig.free(); quit()
