extends Node
## Four explicit buses, finite samples and stage/character overrides. No prototype pulse loop.
var muted := false
var music_enabled := true
var ambience_enabled := true
var music:=AudioStreamPlayer.new()
var ambience:=AudioStreamPlayer.new()
var voices: Array[AudioStreamPlayer]=[]
var cursor := 0
var last_stage := ""
func _ready() -> void:
	for bus in ["Music","Ambience","SFX","UI"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus),-8 if bus in ["SFX","UI"] else -20)
	music.bus="Music"; ambience.bus="Ambience"
	add_child(music); add_child(ambience)
	for i in 8:
		var p:=AudioStreamPlayer.new(); add_child(p); voices.append(p)
func stage_changed(stage: Dictionary) -> void:
	last_stage=stage.get("ambience","quiet")
	stop_all()
	if music_enabled:
		music.stream=load(stage.get("music","res://assets/audio/night-cue.wav")); music.play()
	if ambience_enabled and last_stage=="rain":
		ambience.stream=load(stage.get("ambience_audio","res://assets/audio/rain.wav")); ambience.play()
func play_event(e: Dictionary) -> void:
	if muted: return
	var key: String=e.get("sound",e.type)
	if key=="counter": key="hit"
	if not key in ["hit","block","swing","ui","release","ko","fight","cinematic"]: return
	var path: String="res://assets/audio/"+key+".wav"
	if e.get("sound_path","")!="": path=e.sound_path
	if not ResourceLoader.exists(path): return
	var p: AudioStreamPlayer=voices[cursor%voices.size()]; cursor+=1
	p.bus="UI" if key=="ui" else "SFX"; p.stream=load(path); p.play()
func stop_all() -> void:
	music.stop(); ambience.stop()
	for p in voices: p.stop()
func shutdown() -> void:
	stop_all()
	music.stream=null; ambience.stream=null
	for p in voices: p.stream=null
func toggle() -> void:
	muted=not muted
	AudioServer.set_bus_mute(0,muted)
func _exit_tree() -> void:
	shutdown()
