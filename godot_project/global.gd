extends Node


#### Game ####
const GAME_VERSION = "0.0.2"
const DEBUGGING = true


#### Maps ####
# MAP SIZE
const MAPFOLDER_PATH = "user://maps/"
#const MAPFILES_PATH_USER = "user://maps/"
#const MAPFILES_PATH_BUILTIN = "res://scenes/map/builtin_mapfiles/"
#const BLOCK_SCENE_PATHS = [
#	"res://scenes/building_blocks/error/BlockError.tscn",
#	"res://scenes/building_blocks/wall/BlockWall.tscn",
#	"res://scenes/building_blocks/grass/BlockGrass.tscn",
#]


#### Nakama ####
# https://github.com/heroiclabs/nakama-godot
const NK_KEY = "defaultkey"
const NK_ADDRESS = "127.0.0.1"
const NK_PORT = 7350
const NK_PROTOCOL = "http"
const NK_ADDON_VERSION = "2.1.0" # primarily note for me


#### Match State Op codes ####
# 100-199 forward to match
enum OpCodes {
	BALL_IMPACT = 201,
	BALL_SYNC = 202,
	MATCH_CONFIG = 101,
	MATCH_START = 102,
	NEXT_TURN = 103,
	TURN_FINISHED = 104,
	# when match starts
	# contains map_id, tuŕn_order
	
}


#### Scene Change Parameter
var _params := {}

func get_scene_parameter()->Dictionary:
	var ret = _params
	_params = {}
	return ret

func set_scene_parameters(params:Dictionary):
	_params = params
