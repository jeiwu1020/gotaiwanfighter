extends Node2D
## Camera/VFX observe events. No time-scale or damage writes; reset owns all transient state.
var game: Node
var bursts: Array[Dictionary]=[]
var trauma := 0.0
var clock := 0.0
var release_effects: Array[Dictionary]=[]
func clear() -> void:
	bursts.clear(); release_effects.clear(); trauma=0; queue_redraw()
func accept(event: Dictionary) -> void:
	if event.type in ["hit","block","counter"]:
		var e=event.duplicate(); e.life=0.32; bursts.append(e)
		trauma=3 if event.type=="block" else (13 if event.get("tier","") in ["super","awakening"] else 6)
	if event.type=="release":
		trauma=15
		var f: Dictionary=game.model.fighters[event.fighter]
		release_effects.append({"point":Vector2(f.x,game.stage.floor_y-155+f.y),"facing":f.facing,"color":Color(f.data.accent),"life":0.45,"power":event.tier=="awakening"})
func _process(delta: float) -> void:
	if game.paused: return
	clock+=delta; trauma=maxf(0,trauma-delta*36)
	for e in bursts: e.life-=delta
	bursts=bursts.filter(func(e):return e.life>0)
	for e in release_effects: e.life-=delta
	release_effects=release_effects.filter(func(e):return e.life>0)
	var target:=Vector2(640,360)
	var zoom:=1.0
	if game.screen=="battle" and not game.model.cinematic.is_empty():
		var c: Dictionary=game.model.cinematic
		var f: Dictionary=game.model.fighters[c.fighter]
		var progress: float=float(c.tick)/c.duration
		var pulse: float=sin(progress*PI)
		zoom=1+0.16*pulse
		target.x=lerpf(640,clampf(f.x,400,880),pulse*0.32)
	if game.reduced_motion: zoom=1; target=Vector2(640,360)
	game.camera.zoom=Vector2.ONE*zoom
	game.camera.position=target
	game.camera.offset=Vector2(sin(clock*111),cos(clock*89))*trauma if not game.reduced_motion else Vector2.ZERO
	queue_redraw()
func _draw() -> void:
	if game.screen!="battle": return
	for e in release_effects:
		var t: float=1-e.life/0.45
		var color:=Color(e.color,0.7*(1-t))
		for j in 3:
			var radius: float=35+t*(170 if e.power else 115)+j*13
			draw_arc(e.point,radius,-1.45,1.45,32,color,6*(1-t),true)
		for j in 12:
			var y: float=-100+j*18
			var x: float=t*220+j%3*35
			draw_line(e.point+Vector2(x*e.facing,y),e.point+Vector2((x+70)*e.facing,y*1.2),color,3*(1-t),true)
	for e in bursts:
		var point: Vector2=e.position+Vector2(0,game.stage.floor_y)
		var life: float=e.life/0.32
		var color:=Color("fff2cf") if e.type!="block" else Color("b8d9ef")
		color.a=life
		if e.type=="block":
			draw_arc(point,26+(1-life)*18,-1.2,1.2,14,color,4*life,true)
		else:
			for j in 14:
				var dir:=Vector2.from_angle(j*TAU/14+0.2)
				var radius: float=(1-life)*75
				draw_line(point+dir*radius,point+dir*(radius+28*life),color,3*life,true)
			draw_colored_polygon(PackedVector2Array([point+Vector2(-8,0),point+Vector2(0,-22)*life,point+Vector2(9,0),point+Vector2(0,22)*life]),color)
	for i in 2:
		var f: Dictionary=game.model.fighters[i]
		if f.state=="attack" and f.ticks>=f.move.startup and f.ticks<f.move.startup+f.move.active:
			var color:=Color(f.data.accent,0.50)
			var center:=Vector2(f.x,585+f.y-155)
			var arc_points:=PackedVector2Array()
			var radius: float=90 if f.move.kind=="normal" else 150
			var phase: float=float(f.ticks-f.move.startup)/maxf(1,f.move.active)
			for j in 16:
				var angle: float=-1.2+float(j)/15*1.7+phase*0.5
				arc_points.append(center+Vector2(cos(angle)*f.facing,sin(angle)*0.55)*radius)
			draw_polyline(arc_points,color,5,true)
		if game.debug_boxes:
			for h in game.model.hurtboxes(i):
				h.position.y+=585; draw_rect(h,Color(0.2,1,0.5,0.18)); draw_rect(h,Color(0.2,1,0.5,0.8),false,1)
			for h in game.model.hitboxes(i):
				var rect: Rect2=h.rect; rect.position.y+=585; draw_rect(rect,Color(1,0.2,0.2,0.35))
	for entity in game.model.entities:
		var p:=Vector2(entity.x,585+entity.y)
		var color:=Color(game.model.fighters[entity.owner].data.accent)
		if entity.delay>0: color.a=0.25
		draw_arc(p,30,0,TAU,20,color,4,true)
