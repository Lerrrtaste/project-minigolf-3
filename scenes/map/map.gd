extends Node2D

enum States {
	INVALID = -1, # not loaded
	LOADED,
	PLAYING,
	EDITING,
}
var _state:int = States.INVALID


var metadata := { #keys here are required when loading, values here are placeholders
	"title": "Not Loaded",
	"id": "#000000",#unique and collection key
	"version": "0.0.0.0"
}


func _ready():
	set_process(false)


func load_from_coursedata(coursedata:Dictionary):
	_load_from_dictionary(coursedata)
	state_change(States.LOADED)


func state_change(new_state:int)->void:
	match new_state:
		States.LOADED:
			print("Map loaded")
		States.PLAYING:
			print("Map playing")
		States.EDITING:
			print("Map editing")
	
	_state = new_state


func _load_from_dictionary(coursedata:Dictionary)->bool:
	if !coursedata.has("metadata"):
		return false
	
	if coursedata.has("map"):
		return false
	
	# metadata
	var metadata_new = coursedata["metadata"]
	for key in metadata.keys(): # validate all required keys
		if !metadata_new.has(key):
			return false
	metadata = metadata_new
	
	#map
	
	return true


func _spawn_map(map:Dictionary):
	pass
# TODOS
# load
# save
# edit 
