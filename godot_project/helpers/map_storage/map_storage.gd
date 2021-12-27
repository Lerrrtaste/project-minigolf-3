extends Node


signal completed

var cached_maps:=[]

# LOADING FROM CACHE IS DISABLED RN (@load_map_async)

func _ready():
	# create folder if not exists
	var dir = Directory.new()
	if not dir.dir_exists(Global.MAP_CACHE_PATH):
		dir.make_dir_recursive(Global.MAP_CACHE_PATH)


func load_map_async(map_id:String, owner_id:String=""): # -> map_jstring
#	if _is_map_cached(map_id):
#		emit_signal("completed",_load_from_cache(map_id))
#		return _load_from_cache(map_id)
		#return _load_from_cache(map_id)
	var map_jstring = yield(_load_from_server_async(map_id,owner_id), "completed")
	return map_jstring


func save_map_async(map_id:String, map_jstring:String,public:bool)->void:
	yield(_save_to_server_async(map_id, map_jstring, public), "completed")
	_save_to_cache(map_id, map_jstring)


func delete_map(map_id:String)->void:
	_delete_from_cache(map_id)
	_delete_from_server(map_id)


func list_owned_maps_async()->Dictionary: # -> {"map_id": "name", ...}
	var result = yield(Networker.collection_list_owned_objects_async(Global.MAP_COLLECTION), "completed")
	
	var owned_maps = {}
	for i in result:
		owned_maps[i.key] = JSON.parse(i.value).result["metadata"]["name"]
	
	return owned_maps


func list_public_maps_async()->Array: # ->  [{"map_id":, "creator_id":, "name":, "owner_name":},...]
	var result = yield(Networker.collection_list_public_objects_async(Global.MAP_COLLECTION), "completed")
	
	var public_maps:Array
	for i in result:
		var metadata_dict = JSON.parse(i.value).result["metadata"]
		var entry = {
			"map_id": i.key,
			"creator_id": i.user_id,
			"creator_name": metadata_dict["creator_display_name"] if metadata_dict.has("creator_display_name") else "N/A",
			"name": metadata_dict["name"], 
			}
		public_maps.append(entry)
	
	return public_maps

#ApiStorageObject Schema
#	{
#		"collection": {"name": "_collection", "type": TYPE_STRING, "required": false},
#		"create_time": {"name": "_create_time", "type": TYPE_STRING, "required": false},
#		"key": {"name": "_key", "type": TYPE_STRING, "required": false},
#		"permission_read": {"name": "_permission_read", "type": TYPE_INT, "required": false},
#		"permission_write": {"name": "_permission_write", "type": TYPE_INT, "required": false},
#		"update_time": {"name": "_update_time", "type": TYPE_STRING, "required": false},
#		"user_id": {"name": "_user_id", "type": TYPE_STRING, "required": false},
#		"value": {"name": "_value", "type": TYPE_STRING, "required": false},
#		"version": {"name": "_version", "type": TYPE_STRING, "required": false},
#	}


func _update_cached_maps():
	var map_files = []
	var dir = Directory.new()
	dir.open(Global.MAP_CACHE_PATH)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif file.ends_with(".map"):
			map_files.append(file)
	dir.list_dir_end()
	
	cached_maps.clear()
	for i in map_files:
		cached_maps.append(i.split(".map")[0])


func _is_map_cached(map_id:String)->bool:
	return cached_maps.has(map_id)


#### Server

func _load_from_server_async(map_id:String, owner_id:String="")->String: # -> map_jstring
	print("Loading from server")
	var object
	if owner_id == "":
		object = yield(Networker.collection_read_object_async(Global.MAP_COLLECTION,map_id),"completed")
	else:
		object = yield(Networker.collection_read_object_async(Global.MAP_COLLECTION,map_id, owner_id),"completed")
	 
	assert(object is NakamaAPI.ApiStorageObject)
	
	return object.value


func _save_to_server_async(map_id:String, map_jstring:String, public:bool=false): 
	yield(Networker.collection_write_object_async(Global.MAP_COLLECTION, map_id, map_jstring, public), "completed")


func _delete_from_server(map_id:String):
	Networker.collection_remove_object_asnyc(Global.MAP_COLLECTION,map_id)


#### Cache

func _save_to_cache(map_id:String, map_jstring:String)->void:
	var file = File.new()
	var path = "%s%s.map"%[Global.MAP_CACHE_PATH, map_id]
	var error = file.open(path, File.WRITE)
	if error != OK:
		printerr("Could not cache map to file!!!! %s"% error)
		return
	file.store_string(map_jstring)
	file.close()
	
	print("Map ID %s succesfully cached to %s "%[map_id,Global.MAP_CACHE_PATH])
	if not cached_maps.has(map_id):
		cached_maps.append(map_id)


func _load_from_cache(map_id:String)->String: # -> map_jstring
	if not cached_maps.has(map_id):
		printerr("Trying to load nonexistent map from cache")
		return ""

	var file = File.new()
	var error = file.open("%s%s.map"%[Global.MAP_CACHE_PATH,map_id],File.READ)
	if error != OK:
		printerr("Could not load file!!! %s"%error)
		return ""
	
	var content = file.get_as_text()
	
	file.close()
	print("Loaded from cache")
	return content


func _delete_from_cache(map_id:String):
	var dir = Directory.new()
	dir.open(Global.MAP_CACHE_PATH)
	if dir.file_exists(map_id+".map"):
		dir.remove(map_id+".map")
	else:
		printerr("Cant delete file from cache, because it does not exist")
