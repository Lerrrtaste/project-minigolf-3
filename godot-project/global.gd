extends Node


#### Game ####
const GAME_VERSION = "0.1.0"
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


const USERNAME_LENGTH_MIN = 4
const USERNAME_LENGTH_MAX = 16

# #### Scene Change Parameter
# var _params := {}

# func get_scene_parameter()->Dictionary:
# 	var ret = _params
# 	_params = {}
# 	return ret

# func set_scene_parameters(params:Dictionary):
# 	_params = params
