extends Node


#### Game ####
const VERSION = "0.0.1"
const DEBUGGING = true


#### Maps ####
# MAP SIZE
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
enum OP_CODES {
	moved
}
