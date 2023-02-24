

# get property from tdata or null
func get_tile_property(tile_id:int, property:String):
	if not _TDATA.has(tile_id):
		Notifier.notify_error("Tile %s does not exist"%tile_id)
		return null
	
	# use default
	if not _TDATA[tile_id].has(property):
		return _TDATA["defaults"][property]
	
	return _TDATA[tile_id][property]


# get the whole dict from tdata or null
func get_tile_dict(tile_id:int):
	if not _TDATA.has(tile_id):
		Notifier.notify_error("Tile %s does not exist"%tile_id)
		return _TDATA["defaults"]
		
	return _TDATA[tile_id]


# get property from tdata or null
func get_object_property(obj_id:int, property:String):
	if not _ODATA.has(obj_id):
		Notifier.notify_error("Object %s does not exist"%obj_id)
		return null
	
	if not _ODATA[obj_id].has(property):
		Notifier.notify_error("Object %s does not have a %s property"%[obj_id,property])
		return null
	
	return _ODATA[obj_id][property]


# get the whole dict from tdata or null
func get_object_dict(obj_id:int):
	if not _ODATA.has(obj_id):
		Notifier.notify_error("Object %s does not exist"%obj_id)
		return null
		
	return _ODATA[obj_id]
