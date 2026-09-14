extends RefCounted
## Content-driven route state; no battle simulation or UI ownership.
var routes: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/stories.json"))
var route: Dictionary={}
var node_index := 0
var line_index := 0
var complete := false
var cleared: Array=[]
var save_path := "user://progress-v1.json"
func load_save() -> void:
	if not FileAccess.file_exists(save_path): return
	var data=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary and data.get("version",0)==1 and data.get("cleared",null) is Array:
		cleared=data.cleared.filter(func(id):return id is String)
func start_story(index: int) -> void:
	route=routes[index]; node_index=0; line_index=0; complete=false
func node() -> Dictionary:
	return {} if complete or route.is_empty() else route.nodes[node_index]
func advance() -> void:
	node_index+=1; line_index=0
	if node_index>=route.nodes.size():
		complete=true
		if not cleared.has(route.id): cleared.append(route.id)
		var file=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify({"version":1,"cleared":cleared}))
			file.close()
			DirAccess.rename_absolute(save_path+".tmp",save_path)
func battle_result(won: bool) -> void:
	if won: advance()
