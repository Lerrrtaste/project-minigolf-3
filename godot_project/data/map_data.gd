extends Node

onready var tileset = preload("res://assets/tiles/map_tileset.tres")

enum Tiles {
	EMPTY = -1,
	GRASS = 0,
	WALL = 1,
	SAND = 2,
	WATER = 3,
	LAVA = 4,
	ICE = 5,
	CONVEYOR_U_L = 6,
	CONVEYOR_U_R = 7,
	CONVEYOR_D_L = 8,
	CONVEYOR_D_R = 9,
}
var _TDATA = {
		"defaults": {
			"name": "N/A",  # Display Name, must be same as in tileset
			"tilemap_id": null,  # Will be set at _ready
			"solid": false,  # only used for object placement rn",
			"friction": 1.0,  # friciton multiplier
			"resets_ball": false,   # Ball will be reset to turn starting position
			"resets_ball_to_start": false, 	# Ball will be reset to map's start
			"texture_path": "res://assets/tiles/placeholder.png",  # For the editor icon
			"layer": "ground",  # Tilemap (all, ground, walls)
			"force": 0, # applied force per second
			"force_direction": Vector2(), # the direction of the force
		},
		Tiles.EMPTY: {
				"name": "Empty",
				"solid": true, # only used for object placement rn
				"resets_ball": true, # maybe it doesnt work
				"texture_path": null, # for editor icon
				"layer": "all",
		},
		Tiles.GRASS: {
				"name": "Grass",
				"texture_path":"res://assets/tiles/grass.png",
				"layer": "ground",
				},
		Tiles.WALL: {
				"name": "Wall",
				"solid": true,
				"resets_ball_to_start": true,
				"texture_path":"res://assets/tiles/wall.png",
				"layer": "walls",
		},
		Tiles.SAND: {
				"name": "Sand",
				"friction": 3.0, 
				"texture_path":"res://assets/tiles/sand.png",
				"layer": "ground",
		},
		Tiles.WATER: {
				"name": "Water",
				"resets_ball": true,
				"texture_path":"res://assets/tiles/water.png",
				"layer": "ground",
		},
		Tiles.LAVA: {
				"name": "Lava",
				"resets_ball_to_start": true, 
				"texture_path":"res://assets/tiles/lava.png",
				"layer": "ground",
		},
		Tiles.ICE: {
				"name": "Ice",
				"friction": 0.3,
				"direction": null,
				"texture_path":"res://assets/tiles/ice.png",
				"layer": "ground",
		},
		Tiles.CONVEYOR_U_L: {
				"name": "Conveyor Up Left",
				"texture_path":"res://assets/tiles/conveyor_up_left.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(-2,-1).normalized(),
		},
		Tiles.CONVEYOR_U_R: {
				"name": "Conveyor Up Right",
				"texture_path":"res://assets/tiles/conveyor_up_right.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(2,-1).normalized(),
		},
		Tiles.CONVEYOR_D_L: {
				"name": "Conveyor Down Left",
				"texture_path":"res://assets/tiles/conveyor_down_left.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(-2,1).normalized(),
		},
		Tiles.CONVEYOR_D_R: {
				"name": "Conveyor Down Right",
				"texture_path":"res://assets/tiles/conveyor_down_right.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(2,1).normalized()
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
	for i in Tiles.values():
		var real_id = tileset.find_tile_by_name(_TDATA[i]["name"])
		_TDATA[i]["tilemap_id"] = real_id


#### Getter

# get property from tdata or null
func get_tile_property(tile_id:int, property:String):
	if not _TDATA.has(tile_id):
		Notifier.notify_error("Tile %s does not exist"%tile_id)
		return null
	
	if not _TDATA[tile_id].has(property):
		#Notifier.notify_error("Tile %s does not have a %s property"%[tile_id,property], "Defaulting to %s"%_TDATA["defaults"][property])
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
