extends Node2D
## Scenery is independent from battle bounds and actor/collision geometry.
var scenery := preload("res://assets/stage.png")
var time := 0.0
var motion := true
var floor_y := 585.0
var rain := true
func configure(data: Dictionary) -> void:
	scenery=load(data.texture); floor_y=data.floor; rain=data.get("ambience","")=="rain"

func _process(delta: float) -> void:
	if motion: time += delta
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(scenery, Rect2(0, 0, 1280, 720), false, Color(0.82, 0.88, 0.97))
	draw_rect(Rect2(0, 0, 1280, 150), Color(0.02, 0.035, 0.055, 0.25))
	# Rain is a separate optional presentation layer, not part of collision or simulation.
	if motion and rain:
		for i in 65:
			var x: float = fmod(i * 137.31 - time * 100, 1400)
			if x < 0: x += 1400
			var y: float = fmod(i * 73.7 + time * 490, 780)
			draw_line(Vector2(x, y), Vector2(x-4, y+15), Color(0.64, 0.79, 0.91, 0.16), 1)
	draw_line(Vector2(65, floor_y+5), Vector2(1215, floor_y+5), Color(0.8, 0.89, 0.87, 0.18), 1)
