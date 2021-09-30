extends Node2D

enum States {
	INVALID = -1, # not loaded
	PLAYING,
	EDITING,
}
var state:int = States.INVALID


var metadata := { #keys here are required when loading, values here are placeholders
	"title": "Not Loaded",
	"id": "#000000",#unique and collection key
	"version": "0.0.0.0"
}


func _ready():
	set_process(false)


func setup(new_course:Dictionary):
	
	_load_from_dictionary(new_course)


func _load_from_dictionary(course:Dictionary)->bool:
	if !course.has("metadata"):
		return false
	
	if course.has("map"):
		return false
	
	# metadata
	var metadata_new = course["metadata"]
	for key in metadata.keys(): # validate all required keys
		if !metadata_new.has(key):
			return false
	metadata = metadata_new
	
	#assert()
	
	#map
	
	return true


func _spawn_map(map:Dictionary):
	pass
# TODOS
# load
# save
# edit 
