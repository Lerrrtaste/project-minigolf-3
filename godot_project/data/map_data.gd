extends Node

onready var tileset = preload("res://assets/tiles/map_tileset.tres")

enum Tiles {
	EMPTY = -1,
	GRASS = 0,
	WALL = 1,
	SAND = 2,
	WATER = 3,
	LAVA = 4,
}
var _TDATA = {
		Tiles.EMPTY: {
				"name": "Empty",
				"tilemap_id": null, # tileset index
				"solid": true, # only used for object placement rn
				"resets_ball": true, # maybe it doesnt work
				"reset_to_start": true,
				"texture_path":null, # for editor icon
				"layer": "all",
		},
		Tiles.GRASS: {
				"name": "Grass",
				"tilemap_id": null,
				"solid": false,
				"resets_ball": false,
				"friction": 1.0, 
				"texture_path":"res://assets/tiles/grass.png",
				"layer": "ground",
				},
		Tiles.WALL: {
				"name": "Wall",
				"tilemap_id": null,
				"solid": true,
				"resets_ball": true,
				"reset_to_start": true,
				"friction": 1.0, 
				"texture_path":"res://assets/tiles/wall.png",
				"layer": "walls",
		},
		Tiles.SAND: {
				"name": "Sand",
				"tilemap_id": null,
				"solid": false,
				"resets_ball": false,
				"friction": 4.0, 
				"texture_path":"res://assets/tiles/sand.png",
				"layer": "ground",
		},
		Tiles.WATER: {
				"name": "Water",
				"tilemap_id": null,
				"solid": false,
				"resets_ball": true,
				"reset_to_start": false,
				"friction": 1.0, 
				"texture_path":"res://assets/tiles/water.png",
				"layer": "ground",
		},
		Tiles.LAVA: {
				"name": "Lava",
				"tilemap_id": null,
				"solid": false,
				"resets_ball": true,
				"reset_to_start": true,
				"friction": 1.0, 
				"texture_path":"res://assets/tiles/lava.png",
				"layer": "ground",
		},
}

enum Objects {
	NONE = -1,
	START = 0,
	FINISH = 1
}
var _ODATA = {
		Objects.START: {
				"name": "Spawn",
				"limit": 1, #only one
				"required": 1,
				"node_path":"res://objects/map_objects/start/Start.tscn",
				"texture_path":"res://objects/map_objects/start/start.png"
				},
		Objects.FINISH: {
				"name": "Finish",
				"limit": 4,
				"required": 1,
				"node_path":"res://objects/map_objects/finish/Finish.tscn",
				"texture_path":"res://objects/map_objects/finish/finish.png"
				},
}

func _ready():
	# Set tilemap_id's
	for i in _TDATA:
		var real_id = tileset.find_tile_by_name(_TDATA[i]["name"])
		_TDATA[i]["tilemap_id"] = real_id


#### Getter

# get property from tdata or null
func get_tile_property(tile_id:int, property:String):
	if not _TDATA.has(tile_id):
		Notifier.notify_error("Tile %s does not exist"%tile_id)
		return null
	
	if not _TDATA[tile_id].has(property):
		Notifier.notify_error("Tile %s does not have a %s property"%[tile_id,property])
		return null
	
	return _TDATA[tile_id][property]


# get the whole dict from tdata or null
func get_tile_dict(tile_id:int):
	if not _TDATA.has(tile_id):
		Notifier.notify_error("Tile %s does not exist"%tile_id)
		return null
		
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
