extends Node

## Networker Helper
##
## Interface to Game Server
## AutoLoad Singleton

var _client : NakamaClient
var _session : NakamaSession
var _socket : NakamaSocket
var _matchmaker_ticket : NakamaRTAPI.MatchmakerTicket

var _account : NakamaAPI.ApiAccount

var _joined_match:NakamaRTAPI.Match
var _matched_match:NakamaRTAPI.MatchmakerMatched

signal authentication_requested
signal authentication_suceeded
signal authentica
# signal socket_connected
# signal socket_connection_failed

# signal matchmaking_started
# signal matchmaking_ended
# signal matchmaking_matched(matched)

# signal authentication_successful
# signal authentication_failed(exception)

# signal match_join_failed
# signal match_joined(presences)
# signal match_presences_updated(_joined_match)
# signal match_state(state)

# signal collection_write_success
# signal collection_write_failed

enum ReadPermissions {
	NOONE = 0,
	OWNER = 1,
	PUBLIC = 2,
}

enum WritePermissions {
	NOONE = 0,
	OWNER = 1,
}


#### General

func _ready():
	randomize()
	reset()


## Reset everything
##
## Recreates _client and clear _session, _socket and _matchmaker_ticket
func reset():
	_client = Nakama.create_client(Global.NK_KEY, Global.NK_ADDRESS, Global.NK_PORT, Global.NK_PROTOCOL, Global.NK_TIMEOUT, Global.NK_LOG_LEVEL)
	_session = null
	_socket = null
	_matchmaker_ticket = null
	Notifier.log_debug("networker was reset")


## Calls any rpc function
##
## @param rpc_id string the registered id of the rpc function
## @param payload dict (optional) the payload to send to the rpc function
func _rpc_call(rpc_id:String, payload = null):
	return await _client.rpc_async(_session, rpc_id, payload).completed


## Test and Log NakamaAsyncResult error
##
## Every public networker function should call this before doing anything else!
##
## Note: Can not log_console errors here because it is unknown if it can be recovered from an exception
##       Log error in the caller function, if not!
##
## @param result NakamaAsyncResult the result to test
## @param message string (optional) Notification Title if error
## @return bool true if no exception
func _check_result(result:NakamaAsyncResult, error_title:String="")->bool:
	if result.is_exception():
		Notifier.log_debug("NakamaAsyncResult returned exception: " + str(result.get_exception()))
		Notifier.notify_error("Error" if error_title=="" else error_title, result.get_exception().message)
		return false
	return true


#### Authentication

## Create and login temporary guest account
##
## Temporary Accounts meant for onetime use by unregistered users
## - CustomID is device_uuid, if available (otherwise random+unix timestamp)
## - sets metadata "guest=true"
## - (real) username is "guest_displayname_randomnumber"
##
## @param display_name string the display name of the account
func login_guest_asnyc(display_name:String)->void: # -> NakamaAsyncResult (_Session or Update checked error)

	# Abort if already logged in
	if is_logged_in():
		if not is_socket_connected():
			_socket_connect_async()
			return
		Notifier.notify_error("Error", "Already logged in")
		return _session

	# Create account w/ metadata
	var custom_id = "guestid_os_%s" % ((Time.get_unix_time_from_system())%(randi()%19521982))
	var username = "guest_%s_%s"%[display_name,randi()%89999+10000]
	_session = await _client.authenticate_custom_async(custom_id, username, true, {"guest": true}).completed
	if not _check_result(_session,"Account could not be created"):
		emit_signal("authentication_failed",_session.get_exception())
		return _session

	# Set display name and confirm login success
	var update = await _client.update_account_async(_session, null, display_name).completed
	if not _check_result(update,"Error during Account creation"):
		emit_signal("authentication_failed",update.get_exception())
		return update

	# Login successful
	emit_signal("authentication_successful")
	await _socket_connect_async().completed
	return _session


## Login to email account
##
## @param email string the email address of the account
## @param password string the password of the account
func login_email_async(email:String, password:String): #-> Nakama_Session

	# Abort if already logged in
	if is_logged_in():
		if not is_socket_connected():
			_socket_connect_async()
			return
		Notifier.notify_error("Error", "Already logged in")
		emit_signal("authentication_successful")
		return _session

	# Login
	_session = await _client.authenticate_email_async(email,password, null, false).completed

	# Confirm login success
	if not _check_result(_session, "Could not log in"):
		emit_signal("authentication_failed", _session.get_exception())
		return _session

	# Successful
	Notifier.notify_info("Login success", "Connecting...")
	emit_signal("authentication_successful")
	await _socket_connect_async().completed
	return _session


## Register email account
##
## @param email string
## @param password string
## @param username string
func register_email_async(email:String, password:String, username:String): #-> Nakama_Session

	# Abort if already logged in
	if is_logged_in():
		if not is_socket_connected():
			_socket_connect_async()
			return
		Notifier.notify_error("Error", "Already logged in")
		return _session

	# Register
	_session = await _client.authenticate_email_async(email, password, username, true).completed

	# Confirm register success
	if not _check_result(_session,"Could not create _account"):
		emit_signal("authentication_failed",_session.get_exception())
		return _session

	# Successful
	Notifier.notify_info("_Account creation success")
	emit_signal("authentication_successful")
	await _socket_connect_async().completed
	return _session



#### _Socket

## Connect to socket from _client and connect signals
##
## Called automatically after successful authentication
func _socket_connect_async()->void: # -> NakamaAsyncResult
	# create socket
	_socket = Nakama.create_socket_from(_client)

	# abort if socket could not connect
	var connected : NakamaAsyncResult = await _socket.connect_async(_session).completed
	if not _check_result(connected,"Could not connect"):
		emit_signal("socket_connection_failed")
		return _socket

	# get account info and store in _account
	_account = await _client.get_account_async(_session).completed
	
	# register _socket events
	_socket.connect("received_matchmaker_matched",Callable(self,"_on_matchmaker_matched")) #warning-ignore:return_value_discarded
	_socket.connect("received_match_presence",Callable(self,"_on_match_presence")) #warning-ignore:return_value_discarded
	_socket.connect("received_match_state",Callable(self,"_on_match_state")) #warning-ignore:return_value_discarded
	
	emit_signal("socket_connected")
	return _socket


## Get connection status of socket
##
## @return bool true if connected
func is_socket_connected()->bool:
	if !is_logged_in():
		Notifier.log_warning("Testing socket while not even logged in")
		return false
	
	if not _socket is NakamaSocket:
		return false
	
	return _socket.is_connected_to_host()



#### Accounts

## Fetch an array of _accounts
##
##	Account Schema:
##	{
##		"custom_id": {"name": "_custom_id", "type": TYPE_STRING, "required": false},
##		"devices": {"name": "_devices", "type": TYPE_ARRAY, "required": false, "content": "Api_AccountDevice"},
##		"disable_time": {"name": "_disable_time", "type": TYPE_STRING, "required": false},
##		"email": {"name": "_email", "type": TYPE_STRING, "required": false},
##		"user": {"name": "_user", "type": "ApiUser", "required": false},
##		"verify_time": {"name": "_verify_time", "type": TYPE_STRING, "required": false},
##		"wallet": {"name": "_wallet", "type": TYPE_STRING, "required": false},
##	}
##
## @param ids array of user_ids
## @return array of accounts with above schema
func get_accounts_async(user_ids:Array): # -> Account Array
	var result : NakamaAPI.ApiUsers = await _client.get_users_async(_session, user_ids).completed
	
	if not _check_result(result):
		return result
		
	return result.users



#### Matchmaking

## Start Matchmaking
##
## Requires a map pool selection (will change soon)
##
## Map Pool # [{map_id:, creator_id:}, ...]
func matchmaking_start_async(map_pool:Array)->void: # -> NakamaRTAPI.MatchmakerTicket

	# Abort if not connected
	if !is_socket_connected():
		printerr("Not connected")
		return

	# Abort if already in matchmaking
	if is_in_matchmaking():
		Notifier.notify_error("Error", "You are already in Matchmaking")
		return

	# Build query
	var query = ""
	var min_count = 2
	var max_count = 2
	var string_properties = {}

	for i in range(map_pool.size()):
		#query += "properties./[0-9]{1,}_map_id/:%s "%str(map_pool[i].map_id)
		query += "map_%s " % str(map_pool[i].map_id)
		
		#map 2d array to 1d 
		string_properties["map_pool_%s"%(2 * i + 0)] = "map_%s"%map_pool[i].map_id
		string_properties["map_pool_%s"%(2 * i + 1)] = "creator_%s"%map_pool[i].creator_id

	var numeric_properties = { # broken atm
		
	} 

	# Send Query
	_matchmaker_ticket = yield(
	  _socket.add_matchmaker_async(query, min_count, max_count, string_properties, numeric_properties),
	  "completed"
	)

	# Confirm matchmaking start success
	if not _check_result(_matchmaker_ticket,"Could not start matchmaking"):
		Notifier.notify_debug("Error", _matchmaker_ticket)
		Notifier.notify_error("Error", _matchmaker_ticket.message)
		return _matchmaker_ticket

	# Successful
	Notifier.notify_info("Matchmaking started")
	emit_signal("matchmaking_started")
	return _matchmaker_ticket


## Cancel Matchmaking
func matchmaking_cancel_async()->void:

	# Abort if not currently in matchmaking
	if not is_in_matchmaking():
		Notifier.notify_error("Not in matchmaking","Cant cancel")
		return

	# Send query
	var removed : NakamaAsyncResult = await _socket.remove_matchmaker_async(_matchmaker_ticket.ticket).completed

	#Confirm cancel success
	if not _check_result(removed,"Could not cancel matchmaking"):
		Notifier.notify_debug("cancel matchmaking", _matchmaker_ticket)
		Notifier.notify_error("Error", _matchmaker_ticket.message)
		return removed

	# successful
	_matchmaker_ticket = null
	Notifier.notify_info("Matchmaking canceled")
	emit_signal("matchmaking_ended")
	return removed



#### Matches

## Join a Match via Matchmaker Token
##
## @param matchmaker_token
func match_join_async(matchmaker_token)->void: #-> AsyncResult
	# Abort if not connected
	if !is_socket_connected():
		Notifier.notify_error("Connection Error","Cant join match")
		return

	# send query
	_joined_match = await _socket.join_matched_async(matchmaker_token).completed

	# confirm join success
	if _joined_match.is_exception():
		Notifier.notify_debug(_joined_match)
		Notifier.notify_error("Could not join match", _joined_match.message)
		_joined_match = null
		return _joined_match

	# successful
	_matchmaker_ticket = null
	emit_signal("match_joined",_joined_match)
	return _joined_match


## Send Match state
##
## Default message for the match handler
## TODO handle exceptions (idk if necessary)
##
## @param op_code int message op code
## @param new_state string (optional)
func match_send_state_async(op_code:int,new_state=""):

	# abort if not in a match
	if not is_in_match():
		Notifier.notify_error("Not in a match")
		return

	# send query
	var result = await _socket.send_match_state_async(_joined_match.match_id, op_code, JSON.stringify(new_state)).completed

	# confirm send success
	if result.is_exception():
		Notifier.log_error(result.message)
		return result

	# successful
	return result


## Gracefully leave the current match
func match_leave():

	# abort if not in a match
	if not is_in_match():
		Notifier.notify_error("Not in any match, cant leave")
		return

	# send query
	var response = await _socket.leave_match_async(_joined_match.match_id).completed

	# confirm leave success
	if not _check_result(response,"Could not leave match"):
		Notifier.log_error(response.message)
		return response

	#successful
	Notifier.notify_info("Left the match")



#### Collections

## Write key value pair to a collection
##
## @param collection string
## @param key string
## @param value string
## @param public_read bool true to publish something
func collection_write_object_async(collection:String, key:String, value:String, public_read:bool): # -> ApiStorageObjectAck/s

	# abort if not logged in
	if not is_logged_in():
		Notifier.notify_error("Cant save to collection","NOT LOGGED IN")
		return

	# send query
	var can_read =  ReadPermissions.PUBLIC if public_read else ReadPermissions.OWNER
	var can_write = WritePermissions.OWNER
	var acks : NakamaAPI.ApiStorageObjectAcks = yield(_client.write_storage_objects_async(_session, [
		NakamaWriteStorageObject.new(collection, key, can_read, can_write, value, "")
	]), "completed")

	# handle exceptions
	if not _check_result(acks, "Could not write to Storage"):
		Notifier.log_error("Writing failed")
		emit_signal("collection_write_failed")
		return acks

	# success
	emit_signal("collection_write_success")
	return acks.acks[0]


## Read single object from collection by key
##
## @param collection string
## @param key string
## @param user_id string (optional, defaults to logged in user)
func collection_read_object_async(collection:String, key:String, user_id:String = _session.user_id): # -> ApiStorageObject

	# abort if not logged in
	if not is_logged_in():
		Notifier.notify_error("Cant read from collection","NOT LOGGED IN")
		return

	# send query
	var result : NakamaAPI.ApiStorageObjects = yield(_client.read_storage_objects_async(_session, [
	NakamaStorageObjectId.new(collection, key, user_id)
	]), "completed")

	# handle exceptions
	if not _check_result(result, "Could not read from Storage"):
		Notifier.notify_error("Could not download object", result.message)
		return result
		
	return result.objects[0]


## Remove single object from collection by key
##
## @param collection string
## @param key string
func collection_remove_object_asnyc(collection:String,key:String): # -> NakamaAsyncResult
	# abort if not logged in
	if not is_logged_in():
		Notifier.notify_error("Cant remove from collection","NOT LOGGED IN")
		return

	# send query
	var del : NakamaAsyncResult = yield(_client.delete_storage_objects_async(_session, [
		NakamaStorageObjectId.new(collection, key)
	]), "completed")

	# handle exceptions
	if not _check_result(del, "Could not remove from Storage"):
		Notifier.notify_error("Could not remove object", del.message)
		return del

	# success
	return del


## List the first 100 owned objects in collection
##
## TODO implement paging
##
## @param collection string
func collection_list_owned_objects_async(collection:String)->Array: # -> Array : ApiStorageObject
	# "objects" has cursor (for paging later)

	# abort if not logged in
	if not is_logged_in():
		Notifier.notify_error("Cant list collection","NOT LOGGED IN")
		return

	# send query
	var limit = 100 # default is 10.
	var objects : NakamaAPI.ApiStorageObjectList = await _client.list_storage_objects_async(_session, collection, _session.user_id, limit).completed

	# handle exceptions
	if not _check_result(objects):
		Notifier.log_error("Could not list collection: " + objects.message)
		return objects
		
	return objects.objects


## List the first 100 public objects
##
## TODO implement paging
##
## @param collection string
func collection_list_public_objects_async(collection:String)->Array: # -> Array : ApiStorageObject
	# "objects" has cursor (for paging later)

	# abort if not logged in
	if not is_logged_in():
		Notifier.notify_error("Cant list collection","NOT LOGGED IN")
		return

	# send query
	var limit = 100 # default is 10.
	var objects : NakamaAPI.ApiStorageObjectList = await _client.list_storage_objects_async(_session, collection, "", limit).completed

	# handle exceptions
	if not _check_result(objects):
		Notifier.log_error("Could not list collection: " + objects.message)
		return objects
	
	# filter for public objects
	var public_objects:Array
	for i in objects.objects:
		if i.permission_read == ReadPermissions.PUBLIC:
			public_objects.append(i)
			
	return public_objects



#### Getset

# Get own user _id
func get_user_id()->String:
	return _session.user_id


# Get own username (or display name if param)
func get_username(prefer_display_name:bool = false)->String:
	if prefer_display_name and _account.user.display_name != "":
		return _account.user.display_name
	return _session.username


# Get own guest status
func is_guest()->bool:
	if not _session.vars.has("guest"):
		return false
		
	return _session.vars["guest"]


# Check if _Session is valid
func is_logged_in()->bool:
	if not _session is NakamaSession:
		return false
	
	if not _session.is_valid():
		return false
	
	return true


# Check if a matchmaker ticket exists
func is_in_matchmaking()->bool:
	if _matchmaker_ticket is NakamaRTAPI.MatchmakerTicket:
		return true
	
	return false


# Check if a match exists
func is_in_match()->bool:
	if _joined_match is NakamaRTAPI.Match:
		return true
	
	return false



#### Callbacks

# Forwards to matchmaking_matched signal
func _on_matchmaker_matched(matched : NakamaRTAPI.MatchmakerMatched):
	Notifier.notify_info("Matchmaker found a Match")
	_matched_match = matched
	emit_signal("matchmaking_matched", matched)


# Forwards to match_presences_updated signal
func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent): #-> NakamaRTAPI.MatchPresenceEvent
	emit_signal("match_presences_updated",p_presence)


# Forwads to match_state signal
func _on_match_state(p_state : NakamaRTAPI.MatchData):
	print(" -> Received match state with opcode %s, data %s" % [p_state.op_code, p_state.data])
	emit_signal("match_state", p_state)
