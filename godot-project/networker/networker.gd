extends Node

# Networker
# Singleton
#
# Exposes lower level network stuff for certain higher level networking nodes only
# Only allowed way to interact with nakama
# Handles generic side effects, errors, loading state etc

const NK_KEY = "K&W^EDjq5%sBU4W^yCFnrMd4L9Cr%H7s"
const NK_ADDRESS = "localhost"
const NK_PORT = 7350
const NK_PROTOCOL = "http"
const NK_TIMEOUT = 3
const NK_LOG_LEVEL = NakamaLogger.LOG_LEVEL.DEBUG # {NONE, ERROR, WARNING, INFO, VERBOSE, DEBUG}
const NK_ADDON_VERSION = "3.3.0" # primarily note for me

const COLLECTION_MAPDATA = "mapdata-dev"
const COLLECTION_PLAYLISTS = "playlists-dev"

@onready var nakama = $Nakama
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

signal authentication_requested
signal authentication_successful
signal authentication_failed(error_msg)

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
		emit_signal("authentication_failed", _nk_session.get_exception().get_message())
		return

	emit_signal("authentication_successful")


func auth_guest(display_name:String)->void:
	emit_signal("authentication_requested")

	# create acc with metadata data
	var custom_id = "guestid_os_%s" % ((int(Time.get_unix_time_from_system())) % (randi()%19521982))
	var username = "guest_%s_%s"%[display_name,randi()%89999+10000]
	_nk_session = await _nk_client.authenticate_custom_async(custom_id, username, true, {"guest": true})

	if _nk_session.is_exception():
		emit_signal("authentication_failed", _nk_session.get_exception().get_message())
		return

	# set display name
	var update = await _nk_client.update_account_async(_nk_session, null, display_name)

	if update.is_exception():
		emit_signal("authentication_failed", update.get_exception().get_message())
		return

	emit_signal("authentication_successful")



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


func _on_authentication_failed(error_msg)->void:
	Notifier.log_error("Authentication failed: %s" % error_msg)
	_change_net_state(NetStates.NOT_AUTHENTICATED)


#### Getters

func is_initialized()->bool:
	return _net_state != NetStates.UNINITIALIZED

func is_authenticated()->bool:
	return _net_state == NetStates.CONNECTED
