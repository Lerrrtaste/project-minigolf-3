extends Node

var loaded_maps := {}

func _ready():
	pass#_load_bultin_maps()


func get_packed_map(map_id:String) -> Dictionary:
	var packed_map:Dictionary
	
	packed_map = _load_builtin_map(map_id) # look if map is builtin first (maybe special id later)
	if !packed_map.empty():
		return packed_map
	
	# look in cached user://
	# look+get from server
	return {}


#lists all JSON Filenames in MAPFILES_BUILTIN_PATH
func list_builtin_map_ids() -> Array:
	var ids:Array
	
	var dir := Directory.new()
	if dir.open(Global.MAPFILES_PATH_BUILTIN) != OK:
		emit_signal("error","Error","Could not open builtin map dir")
		return []
	
	#append all file names without extension
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() && file_name.ends_with(".json"):
			ids.append(file_name.substr(0,file_name.length()-5)) # remove .json
		file_name = dir.get_next()
	dir.list_dir_end()
	
	return ids


# Loads specific mapfile from MAPFILES_BUILTIN_PATH
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
	file.close()
	var parseresult = JSON.parse(packed_map_jstring)
	if parseresult.error != OK:
		emit_signal("error","Error","Loaded mapfile is not a valid JSON object: %s"%parseresult.error_string)
		return {}
	
	return parseresult.result
