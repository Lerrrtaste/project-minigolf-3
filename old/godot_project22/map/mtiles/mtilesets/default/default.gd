extends RefCounted
class_name MTileset

const MTILESET_ID = 1
const TILESET_RES_PATH = "res://map/mtiles/mtilesets/default/tileset.tres"

# Tileset
#
# Has information for avaialble mtiles,
# their properties, and the actual tileset resource.
# (For the near future this system will not be used, rn there is only one tileset)

func _init():
	# Set res tilemap_ids
	var tileset = preload(TILESET_RES_PATH)
	for i in MTiles.values():
		_MTILES_PROPERTIES[i]["tilemap_id"] = tileset.find_tile_by_name(_MTILES_PROPERTIES[i]["tname"])


# Get MTileData object for given mtile id
func get_mtile_data(mtile_id:int)->MTileData:
	return MTileData.new(mtile_id, _MTILES_PROPERTIES[mtile_id])


# Get the TileSet Resource to be used in the TileMap
func get_mtileset_tilemap()->TileSet:
	return load(TILESET_RES_PATH) as TileSet


#### Data

enum MTiles {
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
	CONVEYOR_U = 13,
	CONVEYOR_U_R = 14,
	CONVEYOR_R = 15,
	CONVEYOR_D_R = 16,
	CONVEYOR_D = 17,
	CONVEYOR_D_L = 18,
	CONVEYOR_L = 19,
	CONVEYOR_U_L = 20,
}

var _DEFAULT_PROPERTIES = {
	"tname": "N/A",  # Display Name, must be same as in tileset
	"tilemap_id": null,  # Will be set at _ready
	"texture_path": "res://assets/tiles/placeholder.png",  # For the editor icon
	"layer": "ground",  # Tilemap (all, ground, walls)

	# special properties
	"solid": false,  # only used for object placement rn",
	"friction": 1.0,  # friciton multiplier
	"resets_ball": false,   # Ball will be reset to turn starting position
	"resets_ball_to_start": false, 	# Ball will be reset to map's start
	"force": 0, # applied force per second
	"force_direction": Vector2(), # the direction of the force
	"allowed_direction": null, # direction in which balls ignore solid
	"bounce": 1.0, # speed multiplier (* default 0.9)
}

var _MTILES_PROPERTIES = {
		MTiles.EMPTY: {
				"tname": "Empty",
				"solid": true, # only used for object placement rn
				"resets_ball": true, # maybe it doesnt work
				"texture_path": null, # for editor icon
				"layer": "all",
		},
		MTiles.GRASS: {
				"tname": "Grass",
				"texture_path":"res://assets/tiles/00_grass.png",
				"layer": "ground",
				},
		MTiles.WALL: {
				"tname": "Wall",
				"solid": true,
				"resets_ball_to_start": true,
				"texture_path":"res://assets/tiles/01_wall.png",
				"layer": "walls",
		},
		MTiles.WALL_STICKY: {
				"tname": "Sticky Wall",
				"solid": true,
				"resets_ball_to_start": true,
				"bounce": 0,
				"texture_path":"res://assets/tiles/02_wall_sticky.png",
				"layer": "walls",
		},
		MTiles.WALL_BOUNCY: {
				"tname": "Bouncy Wall",
				"solid": true,
				"resets_ball_to_start": true,
				"bounce": 1.7,
				"texture_path":"res://assets/tiles/03_wall_bouncy.png",
				"layer": "walls",
		},
		MTiles.WALL_U_R: {
				"tname": "Oneway Wall Up Right",
				"solid": true,
				"allowed_direction": Vector2(2,-1).normalized(),
				"force_direction":Vector2(2,-1).normalized(),
				"force": 0,
				"texture_path":"res://assets/tiles/04_wall_up_right.png",
				"layer": "oneway_walls",
		},
		MTiles.WALL_D_R: {
				"tname": "Oneway Wall Down Right",
				"solid": true,
				"allowed_direction": Vector2(2,1).normalized(),
				"force_direction":Vector2(2,1).normalized(),
				"force": 0,
				"texture_path":"res://assets/tiles/05_wall_down_right.png",
				"layer": "oneway_walls",
		},
		MTiles.WALL_D_L: {
				"tname": "Oneway Wall Down Left",
				"solid": true,
				"allowed_direction": Vector2(-2,1).normalized(),
				"force_direction":Vector2(-2,1).normalized(),
				"force": 0,
				"texture_path":"res://assets/tiles/06_wall_down_left.png",
				"layer": "oneway_walls",
		},
		MTiles.WALL_U_L: {
				"tname": "Oneway Wall Up Left",
				"solid": true,
				"allowed_direction": Vector2(-2,-1).normalized(),
				"force_direction":Vector2(-2,-1).normalized(),
				"force": 10,
				"texture_path":"res://assets/tiles/07_wall_up_left.png",
				"layer": "oneway_walls",
		},
		MTiles.ICE: {
				"tname": "Ice",
				"friction": 0.3,
				"direction": null,
				"texture_path":"res://assets/tiles/08_ice.png",
				"layer": "ground",
		},
		MTiles.SAND: {
				"tname": "Sand",
				"friction": 2.5,
				"texture_path":"res://assets/tiles/09_sand.png",
				"layer": "ground",
		},
		MTiles.MUD: {
				"tname": "Mud",
				"friction": 4.5,
				"texture_path":"res://assets/tiles/10_mud.png",
				"layer": "ground",
		},
		MTiles.WATER: {
				"tname": "Water",
				"resets_ball": true,
				"texture_path":"res://assets/tiles/11_water.png",
				"layer": "ground",
		},
		MTiles.LAVA: {
				"tname": "Lava",
				"resets_ball_to_start": true,
				"texture_path":"res://assets/tiles/12_lava.png",
				"layer": "ground",
		},
		MTiles.CONVEYOR_U: {
				"tname": "Conveyor Up",
				"texture_path":"res://assets/tiles/13_conveyor_up.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(0,-1).normalized(),
		},
		MTiles.CONVEYOR_U_R: {
				"tname": "Conveyor Up Right",
				"texture_path":"res://assets/tiles/14_conveyor_up_right.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(2,-1).normalized(),
		},
		MTiles.CONVEYOR_R: {
				"tname": "Conveyor Right",
				"texture_path":"res://assets/tiles/15_conveyor_right.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(1,0).normalized(),
		},
		MTiles.CONVEYOR_D_R: {
				"tname": "Conveyor Down Right",
				"texture_path":"res://assets/tiles/16_conveyor_down_right.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(2,1).normalized()
		},
		MTiles.CONVEYOR_D: {
				"tname": "Conveyor Down",
				"texture_path":"res://assets/tiles/17_conveyor_down.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(0,1).normalized(),
		},
		MTiles.CONVEYOR_D_L: {
				"tname": "Conveyor Down Left",
				"texture_path":"res://assets/tiles/18_conveyor_down_left.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(-2,1).normalized(),
		},
		MTiles.CONVEYOR_L: {
				"tname": "Conveyor Left",
				"texture_path":"res://assets/tiles/19_conveyor_left.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(-1,0).normalized(),
		},
		MTiles.CONVEYOR_U_L: {
				"tname": "Conveyor Up Left",
				"texture_path":"res://assets/tiles/20_conveyor_up_left.png",
				"layer": "ground",
				"force": 500,
				"force_direction": Vector2(-2,-1).normalized(),
		},
}

