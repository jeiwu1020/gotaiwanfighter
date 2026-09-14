extends SceneTree
var stage:=Node2D.new()
var actor: Node2D
var manifest: Dictionary
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(384,432); root.content_scale_size=Vector2i(384,432)
	var b=load("res://src/core/battle.gd").new(); b.setup("kai","lucy")
	root.add_child(stage)
	var bg:=ColorRect.new(); bg.size=Vector2(384,432); bg.color=Color("37332d");stage.add_child(bg)
	actor=load("res://src/presentation/actor.gd").new(); actor.configure(b.fighters[0]); stage.add_child(actor)
	actor.use_rig=true; b.fighters[0].x=192; b.fighters[0].y=-193
	manifest=actor.manifest
	var names: Array=manifest.clips.keys()
	var sheet:=Image.create(384*7,432*4,false,Image.FORMAT_RGBA8)
	var font=load("res://assets/fonts/TaiwanUI.otf")
	var label:=Label.new();label.position=Vector2(10,402);label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",20);stage.add_child(label)
	for n in names.size():
		actor.preview=names[n]; actor.preview_time=0.5*actor.rig.get_node("AnimationPlayer").get_animation(names[n]).length
		actor.sync(0); label.text=names[n]
		await process_frame; await RenderingServer.frame_post_draw
		var img:=root.get_texture().get_image(); sheet.blit_rect(img,Rect2i(0,0,384,432),Vector2i(n%7*384,n/7*432))
	sheet.save_png("res://artifacts/benchmark/kai-rig-inventory.png")
	for i in 24:
		actor.preview="WALK_FORWARD";actor.preview_time=float(i)/24*0.8;actor.sync(0);label.text="WALK %02d"%i
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/benchmark/walk-%02d.png"%i)
	stage.free();quit()
