extends RefCounted
## Device-independent motion parser. Facing is sampled at each direction transition.
var history: Array[Dictionary]=[]
var clock := 0
var last_dir := 5
var last_result := ""
func clear() -> void:
	history.clear(); clock=0; last_dir=5; last_result=""
func poll(raw: Dictionary, facing: int, airborne: bool) -> Dictionary:
	clock+=1
	var axis: int=int(raw.get("move",0))*facing
	var down: bool=raw.get("crouch",false)
	var dir: int=(2 if down else 5)+axis
	if dir!=last_dir:
		history.append({"dir":dir,"time":clock}); last_dir=dir
	history=history.filter(func(h):return clock-h.time<45)
	var result=raw.duplicate()
	var button: String=raw.get("button","")
	if button!="":
		var tail: Array=[]
		for h in history:
			if h.dir!=5: tail.append(h.dir)
		var double_motion: bool=ends_with(tail,[2,3,6,2,3,6])
		var motion: bool=ends_with(tail,[2,3,6])
		if airborne: result.attack="air_"+button
		elif double_motion: result.attack="super" if button=="punch" else "awakening"
		elif motion: result.attack="special_"+button
		elif down: result.attack="crouch_"+button
		elif axis>0 and button=="kick": result.attack="command"
		else: result.attack=button
		if motion: history.clear()
	if result.get("attack","")!="": last_result=result.attack
	return result
func ends_with(array: Array, tail: Array) -> bool:
	if array.size()<tail.size(): return false
	return array.slice(array.size()-tail.size())==tail
