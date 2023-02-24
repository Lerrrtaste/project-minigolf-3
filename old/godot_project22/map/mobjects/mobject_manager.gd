extends Node

# Map Object Manager
# Singleton
#
# Stores IDs, Metadata and References to the MObj Scenes
# Other than MTiles there are no Data Objects, every MObj is its own scene

# Get MObjects Properties
func get_mobject_properties(mobj_id:int) -> Dictionary:
	var filtered = _MOBJECTS_PROPERTIES[mobj_id]
	filtered.erase("scene_path")
	return filtered

# Load and Get MObjects Scene as PackedScene
func get_mobject_scene(mobj_id:int) -> PackedScene:
	return load(_MOBJECTS_PROPERTIES[mobj_id]["scene_path"]) as PackedScene

#### Data

enum MObjects {
	NONE = -1,
	START = 0,
	FINISH = 1
}

var _MOBJECTS_PROPERTIES = {
	MObjects.START: {
	"name": "Spawn",
	"limit": 1, #only one
	"required": 1,
	"scene_path":"res://map/mobjects/start/Start.tscn",
	"texture_path":"res://map/mobjects/start/start.png"
	},
	MObjects.FINISH: {
	"name": "Finish",
	"limit": 4,
	"required": 1,
	"scene_path":"res://map/mobjects/finish/Finish.tscn",
	"texture_path":"res://map/mobjects/finish/finish.png",
	},
}
