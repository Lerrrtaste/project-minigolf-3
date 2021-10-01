extends Node


var loaded_maps := {}

func _ready():
	pass#_load_bultin_maps()


func get_map(map_id:String) -> Dictionary:
	var packed_map := _load_builtin_map(map_id) # look builtin
	if !packed_map.empty():
		return packed_map
	
	# look in cached user://
	# look+get from server
	return {}


func _load_builtin_map(map_id:String)->Dictionary:
	var dir := Directory.new()
	if dir.open(Global.MAPFILES_PATH_BUILTIN) != OK:
		emit_signal("error","Error","Could not open builtin map dir")
		return {}
	
	if !dir.file_exists(map_id+".json"):
		emit_signal("error","Error","Trying to load nonexistent builtin mapfile %s"%map_id)
		return {}
	
	var file := File.new()
	file.open(Global.MAPFILES_PATH_BUILTIN+map_id+".json", File.READ)
	var packed_map_jstring := file.get_as_text()
	var check = JSON.validate_json(packed_map_jstring)
	if check != "":
		emit_signal("error","Error","Loaded mapfile is not a valid JSON object: %s"%check)
		return {}
	
	return JSON.parse_json(packed_map_jstring).result
