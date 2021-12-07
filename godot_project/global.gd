extends Node


#### Game ####
const VERSION = "0.0.1"
const DEBUGGING = true


#### Maps ####
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
const NK_ADDRESS = "157.230.101.127"
const NK_PORT = 7350
const NK_PROTOCOL = "http"
const NK_TIMEOUT = 3
const NK_ADDON_VERSION = "2.1.0" # primarily note for me
