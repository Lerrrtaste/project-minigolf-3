extends Node

# Networker
# Singleton
#
# Exposes lower level network stuff for certain higher level networking nodes only
# Only allowed way to interact with nakama
# Handles generic side effects, errors, loading state etc
#
# Async Request Structure:
# - "request creator" function that is being called
# - requested signal with parameters
# - failed signal with error
# - succeeded signal with cleaned data
#
# func _on_Btn_send_request():
#    Networker.send_request() # send request from somewhere, dont do anything else
#
# func _on_Networker_request_requested():
#   # show loading, disable input etc
#
# func _on_Networker_request_failed(error):
#  # show error, enable input etc
#
# func _on_Networker_request_succeeded(data):
#  # proceed
#
# TODO check for existing session first and reuse it
# TODO reauthorize if session expired
# TODO store session to stay logged in


const NK_KEY = "K&W^EDjq5%sBU4W^yCFnrMd4L9Cr%H7s"
const NK_ADDRESS = "localhost"
const NK_PORT = 7350
const NK_PROTOCOL = "http"
const NK_TIMEOUT = 3
const NK_LOG_LEVEL = NakamaLogger.LOG_LEVEL.DEBUG # {NONE, ERROR, WARNING, INFO, VERBOSE, DEBUG}
const NK_ADDON_VERSION = "3.3.1" # primarily note for me

const COLLECTION_MAPDATA = "mapdata-dev"
const COLLECTION_PLAYLISTS = "playlists-dev"

@onready var nakama = Nakama
var _nk_client: NakamaClient
var _nk_session: NakamaSession
var _nk_socket: NakamaSocket

enum NetStates {
	UNINITIALIZED, # no signal emitted
	NOT_AUTHENTICATED, # goto login
	CONNECTING,
	CONNECTION_ERROR,
	CONNECTED,
}
var _net_state = NetStates.UNINITIALIZED

signal net_state_changed(new_state)

# Auth
signal authentication_requested
signal authentication_successful
signal authentication_failed(error)

# Socket
signal socket_connect_requested
signal socket_connect_successful
signal socket_connect_failed(error)


func _ready():
	randomize()
	_nk_client = nakama.create_client(NK_KEY, NK_ADDRESS, NK_PORT, NK_PROTOCOL, NK_TIMEOUT, NK_LOG_LEVEL)
	_nk_session = null
	_nk_socket = null
	_change_net_state(NetStates.NOT_AUTHENTICATED)



#### Authentication

func auth_email(email:String, password:String, create_account := false, username := ""):
	emit_signal("authentication_requested")

	_nk_session = await _nk_client.authenticate_email_async(email, password, username, create_account)

	if _nk_session.is_exception():
		emit_signal("authentication_failed", _nk_session.get_exception())
		return

	store_session()
	emit_signal("authentication_successful")


func auth_guest(display_name:String)->void:
	emit_signal("authentication_requested")

	# create acc with metadata data
	var custom_id = "guestid_os_%s" % ((int(Time.get_unix_time_from_system())) % (randi()%19521982))
	var username = "guest_%s_%s"%[display_name,randi()%89999+10000]
	_nk_session = await _nk_client.authenticate_custom_async(custom_id, username, true, {"guest": true})

	if _nk_session.is_exception():
		emit_signal("authentication_failed", _nk_session.get_exception())
		return

	# set display name
	var update = await _nk_client.update_account_async(_nk_session, null, display_name)

	if update.is_exception():
		emit_signal("authentication_failed", update.get_exception())
		return

	store_session()
	emit_signal("authentication_successful")


func logout()->void:
	clear_session()
	await _nk_client.session_logout_async(_nk_session)
	_nk_session = null
	_nk_socket = null
	_change_net_state(NetStates.NOT_AUTHENTICATED)


#### Session Lifecycle

func check_session_async()->bool:
	# Checks if session is expired or close to expiration
	# Tries to update session
	# Returns true if everything is good
	# (Call for every standalone scene)
	if _nk_session == null:
		return false

	if _nk_session.expired:
		Notifier.log_info("Session expired, trying to restore")
		_nk_session = await _nk_client.session_refresh_async(_nk_session)

	if _nk_session.is_exception():
		Notifier.log_error("Session invalid: %s" % _nk_session.get_exception())
		return false

	return true


func restore_session()->bool:
	if not FileAccess.file_exists("user://auth_token.txt"):
		_change_net_state(NetStates.NOT_AUTHENTICATED)
		return false

	var file = FileAccess.open("user://auth_token.txt", FileAccess.READ)
	var auth_token = file.get_as_text()
	file.close()

	_nk_session = NakamaClient.restore_session(auth_token)
	if _nk_session.is_exception():
		Notifier.log_error("Session restore failed: %s" % _nk_session.get_exception())
		return false

	emit_signal("authentication_successful")
	return true

func store_session()->void:
	var file = FileAccess.open("user://auth_token.txt", FileAccess.WRITE)
	file.store_string(_nk_session.token)
	file.close()

func clear_session()->void:
	if not FileAccess.file_exists("user://auth_token.txt"):
		return

	DirAccess.open("user://").remove("auth_token.txt")


#### Socket

func socket_connect()->void:
	emit_signal("socket_connect_requested")
	_nk_socket = nakama.create_socket_from(_nk_client)
	var connected = await _nk_socket.connect_async(_nk_session)

	if connected.is_exception():
		emit_signal("socket_connect_failed", connected.get_exception())
		return

	emit_signal("socket_connect_successful")



#### Internal

func _change_net_state(new_state:NetStates)->void:
	if _net_state == new_state:
		return
	_net_state = new_state
	emit_signal("net_state_changed", new_state)




#### Side Effects / Signal Callbacks

func _on_authentication_successful()->void:
	_change_net_state(NetStates.CONNECTING)
	_nk_socket = await _nk_client.create_socket_async(_nk_session, true)
	await _nk_socket.connect_async(_nk_session)
	_change_net_state(NetStates.CONNECTED)


func _on_authentication_failed(error)->void:
	Notifier.log_error("Authentication failed: %s" % error)
	_change_net_state(NetStates.NOT_AUTHENTICATED)



#### Getters

func is_initialized()->bool:
	return _net_state != NetStates.UNINITIALIZED


func is_authenticated()->bool:
	return _net_state == NetStates.CONNECTED
