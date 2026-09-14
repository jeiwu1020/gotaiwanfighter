extends SceneTree

func _initialize() -> void:
	var output := FileAccess.open("res://GODOT_COPYRIGHT.txt", FileAccess.WRITE)
	output.store_string("Godot " + Engine.get_version_info().string + "\n\n")
	output.store_string(Engine.get_license_text() + "\n\n")
	output.store_string(JSON.stringify(Engine.get_copyright_info(), "\t") + "\n\n")
	var licenses := Engine.get_license_info()
	for name in licenses:
		output.store_string(str(name) + "\n" + str(licenses[name]) + "\n\n")
	output.close()
	quit()
