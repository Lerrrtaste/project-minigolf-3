extends Node


#### Game ####
const VERSION = "0.0.1"
const DEBUGGING = true


#### Maps ####
const MAPFILES_PATH_USER = "user://maps/"
const MAPFILES_PATH_BUILTIN = "res://scenes/map/builtin_mapfiles/"


#### Nakama ####
# https://github.com/heroiclabs/nakama-godot
const NK_KEY = "defaultkey"
const NK_ADDRESS = "157.230.101.127"
const NK_PORT = 7350
const NK_PROTOCOL = "http"
const NK_TIMEOUT = 3
const NK_ADDON_VERSION = "2.1.0" # primarily note for me


#### GameAnalytics ####
# https://github.com/GameAnalytics/GA-SDK-GODOT
const GA_ADDON_VERSION = "2.0.0" # primarily note for me
const GA_ALLOWED_CURRENCIES = ["silver","gold","tickets"]
const GA_ALLOWED_ITEMTYPE = ["ball_skin","emote","ball_effect_rolling","ball_effect_win"]
const GA_ENABLE_EVENT_SUBMISSION = true
const GA_GAME_KEY = "a3ef0c8fd647bda34c2ca0db18971b94"
const GA_SECRET_KEY = "1381f94c418c5d39a14aa808e2aec5fe973bb3fe"
