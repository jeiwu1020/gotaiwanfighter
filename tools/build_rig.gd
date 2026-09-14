extends SceneTree
## Builds an editable native Skeleton2D + Bone2D + AnimationPlayer scene from fixed parts.
var rig:=Node2D.new()
var skeleton:=Skeleton2D.new()
var bones: Dictionary={}
var paths: Dictionary={}
var base: Dictionary={}
func bone(key: String, parent: Node, pos: Vector2, length_value: float, part: String, size_value: Vector2, offset: Vector2, z: int=0) -> Bone2D:
	var b:=Bone2D.new(); b.name=key; b.set_autocalculate_length_and_angle(false)
	b.position=pos; b.length=length_value; b.bone_angle=PI/2
	parent.add_child(b); b.owner=rig
	b.rest=b.transform; bones[key]=b; paths[key]=str(rig.get_path_to(b)); base[key]=0.0
	if part!="":
		var sprite:=Sprite2D.new(); sprite.name="Art"; b.add_child(sprite); sprite.owner=rig
		sprite.texture=load("res://assets/characters/kai/rig/"+part+".png")
		sprite.centered=false; sprite.position=offset; sprite.scale=size_value/sprite.texture.get_size(); sprite.z_index=z
	return b
func _initialize() -> void: call_deferred("run")
func run() -> void:
	rig.name="KaiRig"; root.add_child(rig)
	skeleton.name="Skeleton2D"; rig.add_child(skeleton); skeleton.owner=rig
	var hip=bone("Hip",skeleton,Vector2(0,-184),10,"pelvis",Vector2(79,48),Vector2(-40,-17),0)
	var torso=bone("Torso",hip,Vector2(0,-10),115,"torso",Vector2(101,139),Vector2(-50,-132),2)
	bone("Pack",torso,Vector2(-39,-85),20,"pack",Vector2(90,119),Vector2(-47,-56),-3)
	bone("Head",torso,Vector2(9,-133),50,"head",Vector2(67,89),Vector2(-29,-75),5)
	var rear=bone("RearArm",torso,Vector2(-30,-111),58,"rear_upper_arm",Vector2(38,68),Vector2(-19,-9),-1)
	bone("RearForearm",rear,Vector2(0,56),62,"rear_forearm",Vector2(32,71),Vector2(-16,-8),0)
	var front=bone("FrontArm",torso,Vector2(33,-111),58,"front_upper_arm",Vector2(40,68),Vector2(-20,-9),4)
	bone("FrontForearm",front,Vector2(0,56),62,"front_forearm",Vector2(33,71),Vector2(-16,-8),5)
	var rl=bone("RearThigh",hip,Vector2(-20,0),85,"rear_thigh",Vector2(54,99),Vector2(-27,-9),-2)
	bone("RearShin",rl,Vector2(0,84),100,"rear_shin",Vector2(61,109),Vector2(-22,-9),-2)
	var fl=bone("FrontThigh",hip,Vector2(20,0),85,"front_thigh",Vector2(57,99),Vector2(-28,-9),1)
	bone("FrontShin",fl,Vector2(0,84),100,"front_shin",Vector2(63,109),Vector2(-23,-9),1)
	var player:=AnimationPlayer.new(); player.name="AnimationPlayer"; rig.add_child(player); player.owner=rig
	var library:=AnimationLibrary.new(); player.add_animation_library("",library)
	var idle={"HipY":-174.0,"Torso":-0.08,"Head":0.08,"RearArm":0.45,"RearForearm":-2.1,"FrontArm":-0.65,"FrontForearm":-1.55,"RearThigh":0.45,"RearShin":-0.4,"FrontThigh":-0.35,"FrontShin":0.25}
	var crouch=idle.duplicate(); crouch.merge({"HipY":-105.0,"Torso":0.2,"Head":-0.2,"RearThigh":1.15,"RearShin":-1.4,"FrontThigh":-1.2,"FrontShin":1.45},true)
	var air=idle.duplicate(); air.merge({"RearThigh":0.8,"RearShin":-1.4,"FrontThigh":-1.6,"FrontShin":1.7},true)
	var punch=idle.duplicate(); punch.merge({"Torso":-0.17,"Head":0.1,"FrontArm":-1.35,"FrontForearm":-0.2,"RearArm":0.1,"RearForearm":-2.3},true)
	var kick=idle.duplicate(); kick.merge({"Torso":0.2,"Head":-0.1,"FrontThigh":-1.55,"FrontShin":0.1},true)
	var guard=idle.duplicate(); guard.merge({"FrontArm":-0.2,"FrontForearm":-2.7,"RearArm":-0.2,"RearForearm":-2.4},true)
	var hurt=idle.duplicate(); hurt.merge({"Torso":0.35,"Head":0.3,"FrontArm":-0.3,"FrontForearm":-0.2},true)
	var down=idle.duplicate(); down.merge({"HipY":-97.0,"Hip":-1.3,"Torso":-0.15,"Head":0.2,"FrontThigh":0.5,"FrontShin":-0.9,"RearThigh":0.1,"RearShin":0.4,"FrontArm":-0.5,"FrontForearm":-0.2},true)
	clip(library,"IDLE",1.2,[idle,idle],true)
	clip(library,"CROUCH",0.16,[idle,crouch])
	clip(library,"JUMP_START",0.1,[idle,crouch])
	clip(library,"JUMP_UP",0.22,[crouch,air])
	clip(library,"JUMP_FALL",0.3,[air,idle])
	clip(library,"LANDING",0.15,[crouch,idle])
	clip(library,"PUNCH",0.35,[idle,guard,punch,punch,idle])
	clip(library,"KICK",0.5,[idle,air,kick,kick,idle])
	var cp=crouch.duplicate(); cp.merge({"FrontArm":-1.45,"FrontForearm":0.0},true)
	clip(library,"CROUCH_PUNCH",0.35,[crouch,cp,cp,crouch])
	var ck=crouch.duplicate(); ck.merge({"FrontThigh":-1.55,"FrontShin":0.0},true)
	clip(library,"CROUCH_KICK",0.48,[crouch,ck,ck,crouch])
	var ap=air.duplicate(); ap.merge({"FrontArm":-1.2,"FrontForearm":0.0},true)
	clip(library,"JUMP_PUNCH",0.35,[air,ap,ap,air])
	var ak=air.duplicate(); ak.merge({"FrontThigh":-1.5,"FrontShin":0.0},true)
	clip(library,"JUMP_KICK",0.45,[air,ak,ak,air])
	clip(library,"BLOCK",0.15,[idle,guard]); clip(library,"CROUCH_BLOCK",0.15,[crouch,cp])
	clip(library,"BLOCK_HIT",0.2,[guard,hurt,guard]); clip(library,"HIT",0.3,[idle,hurt,hurt,idle]); clip(library,"HIT_ALT",0.3,[idle,hurt,idle])
	clip(library,"KNOCKDOWN",0.4,[hurt,down,down]); clip(library,"KO",0.55,[hurt,down,down]); clip(library,"WAKEUP",0.3,[down,crouch,idle])
	clip(library,"SPECIAL_PUNCH",0.6,[guard,crouch,punch,punch,idle])
	clip(library,"SPECIAL_KICK",0.7,[crouch,air,kick,kick,idle])
	clip(library,"SUPER",0.8,[crouch,punch,guard,punch,kick,idle])
	var raised=guard.duplicate(); raised.merge({"FrontArm":-2.7,"FrontForearm":0.0,"Torso":-0.1},true)
	clip(library,"AWAKENING",1.0,[crouch,raised,raised,punch,kick,idle])
	# Foot targets: stance half slides backwards with world travel, swing lifts then returns.
	# IK preserves upper/lower lengths; head, outfit and prop textures never change.
	var walk: Array=[]
	for i in 25:
		var p=idle.duplicate(); var t: float=float(i)/24; p.HipY=-169.0
		for side in ["Rear","Front"]:
			var phase: float=fmod(t+(0.5 if side=="Front" else 0),1.0)
			var x: float=lerpf(48,-48,phase*2) if phase<0.5 else lerpf(-48,48,(phase-0.5)*2)
			var y: float=169.0 if phase<0.5 else 169-sin((phase-0.5)*TAU)*27
			var length_value: float=sqrt(x*x+y*y)
			var knee: float=acos(clampf((length_value*length_value-84*84-100*100)/(2*84*100),-1,1))
			var hip_angle: float=atan2(-x,y)-atan2(100*sin(knee),84+100*cos(knee))
			p[side+"Thigh"]=hip_angle; p[side+"Shin"]=knee
		walk.append(p)
	clip(library,"WALK_FORWARD",0.8,walk,true)
	walk.reverse(); clip(library,"WALK_BACK",0.8,walk,true)
	player.play("IDLE"); player.advance(0)
	DirAccess.make_dir_recursive_absolute("res://scenes/rigs")
	var packed:=PackedScene.new(); packed.pack(rig)
	ResourceSaver.save(packed,"res://scenes/rigs/kai.tscn")
	print("Built editable rig with ",library.get_animation_list().size()," clips")
	rig.free(); quit()
func clip(library: AnimationLibrary, title: String, duration: float, poses: Array, loop: bool=false) -> void:
	var animation:=Animation.new(); animation.length=duration
	if loop: animation.loop_mode=Animation.LOOP_LINEAR
	for key in bones:
		var track:=animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track,NodePath(paths[key]+":rotation"))
		for i in poses.size(): animation.track_insert_key(track,float(i)/maxi(1,poses.size()-1)*duration,float(poses[i].get(key,0)))
	var track:=animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track,NodePath(paths.Hip+":position"))
	for i in poses.size(): animation.track_insert_key(track,float(i)/maxi(1,poses.size()-1)*duration,Vector2(0,poses[i].get("HipY",-174)))
	library.add_animation(title,animation)
