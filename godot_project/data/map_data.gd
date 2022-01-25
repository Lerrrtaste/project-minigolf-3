extends Node

onready var tileset = preload("res://assets/tiles/map_tileset.tres")

enum Tiles {
	EMPTY = -1,
	GRASS = 0,
	WALL = 1,
	WALL_STICKY = 2,
	WALL_BOUNCY = 3,
	WALL_U_R = 4,
	WALL_D_R = 5,
	WALL_D_L = 6,
	WALL_U_L = 7,
	ICE = 8,
	SAND = 9,
	MUD = 10,
	WATER = 11,
	LAVA = 12,
	# TODO # CONVEYOR_U = 13,
	CONVEYOR_U_R = 14,
	# TODO # CONVEYOR_R = 15,
	CONVEYOR_D_R = 16,
	# TODO # CONEYOR_D = 17,
	CONVEYOR_D_L = 18,
	# TODO # CONEYOR_L = 19,
	CONVEYOR_U_L = 20,
	# TODO # ONEWAY_U_R = 21,
	# TODO # ONEWAY_D_R = 22,
	# TODO # ONEWAY_D_L = 23,
	# TODO # ONEWAY_U_L = 24,
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
			"allowed_direction": null, # direction in which balls ignore solid 
			"bounce": 0, # additional speed
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
				"texture_path":"res://assets/tiles/00_grass.png",
				"layer": "ground",
				},
		Tiles.WALL: {
				"name": "Wall",
				"solid": true,
				"resets_ball_to_start": true,
				"texture_path":"res://assets/tiles/01_wall.png",
				"layer": "walls",
		},
		Tiles.WALL_STICKY: {
				"name": "Sticky Wall",
				"solid": true,
				"resets_ball_to_start": true,
				"bounce": -99999,
				"texture_path":"res://assets/tiles/02_wall_sticky.png",
				"layer": "walls",
		},
		Tiles.WALL_BOUNCY: {
				"name": "Bouncy Wall",
				"solid": true,
				"resets_ball_to_start": true,
				"bounce": 100,
				"texture_path":"res://assets/tiles/03_wall_bouncy.png",
				"layer": "walls",
		},
		Tiles.WALL_U_R: {
				"name": "Oneway Wall Up Right",
				"solid": true,
				"allowed_direction": Vector2(2,-1).normalized(),
				"force_direction":Vector2(2,-1).normalized(),
				"force": 0,
				"texture_path":"res://assets/tiles/04_wall_up_right.png",
				"layer": "oneway_walls",
		},
		Tiles.WALL_D_R: {
				"name": "Oneway Wall Down Right",
				"solid": true,
				"allowed_direction": Vector2(2,1).normalized(),
				"force_direction":Vector2(2,1).normalized(),
				"force": 0,
				"texture_path":"res://assets/tiles/05_wall_down_right.png",
				"layer": "oneway_walls",
		},
		Tiles.WALL_D_L: {
				"name": "Oneway Wall Down Left",
				"solid": true,
				"allowed_direction": Vector2(-2,1).normalized(),
				"force_direction":Vector2(-2,1).normalized(),
				"force": 0,
				"texture_path":"res://assets/tiles/06_wall_down_left.png",
				"layer": "oneway_walls",
		},
		Tiles.WALL_U_L: {
				"name": "Oneway Wall Up Left",
				"solid": true,
				"allowed_direction": Vector2(-2,-1).normalized(),
				"force_direction":Vector2(-2,-1).normalized(),
				"force": 10,
				"texture_path":"res://assets/tiles/07_wall_up_left.png",
				"layer": "oneway_walls",
		},
		Tiles.ICE: {
				"name": "Ice",
				"friction": 0.3,
				"direction": null,
				"texture_path":"res://assets/tiles/08_ice.png",
				"layer": "ground",
		},
		Tiles.SAND: {
				"name": "Sand",
				"friction": 2.5, 
				"texture_path":"res://assets/tiles/09_sand.png",
				"layer": "ground",
		},
		Tiles.MUD: {
				"name": "Mud",
				"friction": 4.5, 
				"texture_path":"res://assets/tiles/10_mud.png",
				"layer": "ground",
		},
		Tiles.WATER: {
				"name": "Water",
				"resets_ball": true,
				"texture_path":"res://assets/tiles/11_water.png",
				"layer": "ground",
		},
		Tiles.LAVA: {
				"name": "Lava",
				"resets_ball_to_start": true, 
				"texture_path":"res://assets/tiles/12_lava.png",
				"layer": "ground",
		},
		Tiles.CONVEYOR_U_L: {
				"name": "Conveyor Up Left",
				"texture_path":"res://assets/tiles/20_conveyor_up_left.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(-2,-1).normalized(),
		},
		Tiles.CONVEYOR_U_R: {
				"name": "Conveyor Up Right",
				"texture_path":"res://assets/tiles/14_conveyor_up_right.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(2,-1).normalized(),
		},
		Tiles.CONVEYOR_D_L: {
				"name": "Conveyor Down Left",
				"texture_path":"res://assets/tiles/18_conveyor_down_left.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(-2,1).normalized(),
		},
		Tiles.CONVEYOR_D_R: {
				"name": "Conveyor Down Right",
				"texture_path":"res://assets/tiles/16_conveyor_down_right.png",
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
