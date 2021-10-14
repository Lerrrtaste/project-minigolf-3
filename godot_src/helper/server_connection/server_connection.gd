extends Node

# example nakama usage https://github.com/heroiclabs/nakama-godot-demo/tree/master/godot/src/Autoload

var _client:NakamaClient
var _session:NakamaSession

func _ready():
	var log_level = NakamaLogger.LOG_LEVEL.ERROR
	if Global.DEBUGGING:
		log_level = NakamaLogger.LOG_LEVEL.DEBUG
		
	_client = Nakama.create_client(Global.NK_KEY, Global.NK_ADDRESS, Global.NK_PORT, Global.NK_PROTOCOL, Global.NK_TIMEOUT, log_level)

func authenticate_custom_async(customid:String)->bool:
	var new_session:NakamaSession
	new_session = yield(_client.authenticate_custom_async(customid),"completed")
	
	if new_session.is_exception():
		printerr("Login failed. Error code %s: %s"%[new_session.exception.status_code, new_session.exception.message])
		return false
	
	_session = new_session
	Analytics.setup(_session.user_id)
	return true
