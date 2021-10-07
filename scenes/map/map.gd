extends Node2D

class_name Map

enum States {
	INVALID = -1, # not loaded
	LOADED,
	PLAYING,
	EDITING,
	COMPLETED,
}
var _state:int = States.INVALID

var mapdata:Dictionary #contains blocks (key=vec2, val=block_id) 
var metadata := {
	"title": "Not Loaded",
	"id": "#000000",#unique and collection key
	"version": "0.0.0.0",
}#keys here are required when loading, values here are placeholders


var block_scenes:Dictionary
onready var blocks = $Blocks


func _ready():
	for i in Global.BLOCK_SCENE_PATHS:
		var scene = load(i)
		block_scenes[i.replace] = scene
	set_process(false)


func load_packed_map(packed_map:Dictionary):
	assert(_state == States.INVALID) #not yet loaded
	_load_from_dictionary(packed_map)
	_spawn_map()
	_change_state(States.LOADED)


func create_new(title:String,id:String)->void:
	assert(_state == States.INVALID) #not yet loaded
	metadata = {
		"title": title,
		"id": id,
		"version": Global.VERSION
	}
	_change_state(States.LOADED)


func set_mode_editing()->void:
	_change_state(States.EDITING)


func set_mode_playing()->void:
	_change_state(States.PLAYING)


func _change_state(new_state:int)->void:
	match new_state:
		States.LOADED:
			Signals.emit_signal("map_loaded",metadata.id)
			print("Map loaded")
		
		_:
			if _state == States.INVALID:
				Signals.emit_signal("error","Error","Map has not been loaded")
				assert(false)
			
			continue
		
		States.PLAYING:
			Signals.emit_signal("map_started_playing",metadata.id)
			print("Map playing")
			
		States.EDITING:
			Signals.emit_signal("map_started_editing",metadata.id)
			print("Map editing")
			
		States.COMPLETED:
			Signals.emit_signal("map_started_completed",metadata.id)
	_state = new_state


func get_as_packed_map()->Dictionary:
	var ret = {
			"mapdata": mapdata,
			"metadata": metadata,
			}
	return ret


# Converts any Vector2 coordinates or motion from the cartesian to the isometric system
func cartesian_to_isometric(cartesian):
	return Vector2(cartesian.x - cartesian.y, (cartesian.x + cartesian.y) / 2)


# useful to convert mouse coordinates back to screen-space, and detect where the player wants to know.
# If we want to add mouse-based controls, we'll need this function
func isometric_to_cartesian(iso):
	var cart_pos = Vector2()
	cart_pos.x = (iso.x + iso.y * 2) / 2
	cart_pos.y = - iso.x + cart_pos.x
	return cart_pos


func _load_from_dictionary(packed_map:Dictionary)->bool:
	if !packed_map.has("metadata"):
		Signals.emit_signal("error","Error","Trying to load mapdata")
		return false
	
	# metadata
	var metadata_new = packed_map["metadata"]
	for key in metadata.keys(): # validate all required keys
		if !metadata_new.has(key):
			Signals.emit_signal("error","Error","PackedMap missing required key %s"%key)
	metadata = metadata_new
	mapdata.erase("metadata")
	
	#map
	for key in packed_map.keys():
		if !block_scenes.has(packed_map[key]):
			Signals.emit_signal("error","Error","Mapdata contains unknown blocks")
			return false
	
	mapdata = packed_map
	return true


func _spawn_map()->void:
	for i in mapdata.keys():
		var inst = block_scenes[mapdata[i]].instance()
		inst.position = cartesian_to_isometric(i)
		blocks.add_child(inst)





# TODOS
# load
# save
# edit 
