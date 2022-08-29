extends Node


#### Game ####
const GAME_VERSION = "0.0.5"
enum LogLevel {
	DEBUG, # Everything irrelevant (includes full stack trace(not yet))
	VERBOSE, # Everything possibly relevant (includes calling scene)
	INFO, # Not an error, but something to be aware of
	WARNING, # Things that went wrong, but allow the game to continue
	ERROR, # Fatal Errors
	NONE,
}
const LOG_LEVEL = LogLevel.DEBUG
const DEBUGGING = true

#### Maps ####
# MAP SIZE
const MAPFOLDER_PATH = "user://maps/"
const MAP_NAME_LENGTH_MIN = 4
const MAP_NAME_LENGTH_MAX = 16
const MAP_CACHE_PATH = "user://map_cache/"
const MAP_COLLECTION = "maps"

#### Nakama ####
# https://github.com/heroiclabs/nakama-godot
const NK_KEY = "K&W^EDjq5%sBU4W^yCFnrMd4L9Cr%H7s"
const NK_ADDRESS = "localhost"
const NK_PORT = 7350
const NK_PROTOCOL = "http"
const NK_TIMEOUT = 3
const NK_LOG_LEVEL = NakamaLogger.LOG_LEVEL.INFO # {NONE, ERROR, WARNING, INFO, VERBOSE, DEBUG}
const NK_ADDON_VERSION = "2.1.0" # primarily note for me


const USERNAME_LENGTH_MIN = 4
const USERNAME_LENGTH_MAX = 16



#### Match State Op codes ####
# 100-199 forward to match
enum OpCodes {
	MATCH_CONFIG = 110,
	MATCH_CLIENT_READY = 111,
	MATCH_START = 112,
	MATCH_END = 115,
	
	NEXT_TURN = 120,
	TURN_COMPLETED = 125,
	
	REACHED_FINISH = 130,
	
	PLAYER_LEFT = 150,
	
	BALL_IMPACT = 201,
	BALL_SYNC = 202,
}


#### Scene Change Parameter
var _params := {}

func get_scene_parameter()->Dictionary:
	var ret = _params
	_params = {}
	return ret

func set_scene_parameters(params:Dictionary):
	_params = params
