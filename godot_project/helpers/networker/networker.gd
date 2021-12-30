extends Node

"""
Networker Helper

Interface to everything Nakama related

"""


var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket 
var matchmaker_ticket : NakamaRTAPI.MatchmakerTicket

var account : NakamaAPI.ApiAccount

var joined_match:NakamaRTAPI.Match
var matched_match:NakamaRTAPI.MatchmakerMatched

signal socket_connected
signal socket_connection_failed

signal matchmaking_started
signal matchmaking_ended
signal matchmaking_matched(matched)

signal authentication_successful
signal authentication_failed(exception)

signal match_join_failed
signal match_joined(presences)
signal match_presences_updated(joined_match)
signal match_state(state)


enum ReadPermissions {
	NOONE = 0,
	OWNER = 1,
	PUBLIC = 2,
}

enum WritePermissions {
	NOONE = 0,
	OWNER = 1,
}


func _ready():
	reset()


# Recreate client and clear session, socket and ticket
func reset():
	client = Nakama.create_client(Global.NK_KEY, Global.NK_ADDRESS, Global.NK_PORT, Global.NK_PROTOCOL, Global.NK_TIMEOUT, Global.NK_LOG_LEVEL)
	session = null
	socket = null
	matchmaker_ticket = null
	Notifier.notify_debug("Networker reset")


# Call any rpc function (should not be called from outside)
func rpc_call(rpc_id:String, payload = null):
	return yield(client.rpc_async(session, rpc_id, payload), "completed")


# Check NakamaAsyncResult and notify on exception
# Returns true if no exception
func _check_result(result:NakamaAsyncResult, error_title:String="")->bool:
	if result.is_exception():
		Notifier.notify_debug(result)
		Notifier.notify_error("Error" if error_title=="" else error_title, result.message)
		return false
	return true



#### Authenticate

# Create a new guest account
func login_guest_asnyc(display_name:String)->void: # -> NakamaAsyncResult (Session or Update on error)
	# create/login account with
	# tries device uid, then random with unix time
	# metadata guest = true
	# display name = entered name
	# username = guest_display-name_random-number
	
	if is_logged_in():
		Notifier.notify_error("Error", "Already logged in")
		return session
	
	var custom_id = "guestid_os_%s" % ((OS.get_unix_time())%(randi()%19521982))
	var username = "guest_%s_%s"%[display_name,randi()%8999+1000]
	
	session = yield(client.authenticate_custom_async(custom_id, username, true, {"guest": true}), "completed")
	if session.is_exception():
		Notifier.notfy_debug(session)
		Notifier.notify_error("Account could not be created", session.message)
		emit_signal("authentication_failed",session.get_exception())
		return session
		
	var update = yield(client.update_account_async(session, null, display_name), "completed")
	if update.is_exception():
		Notifier.notfy_debug("During set Display name", update)
		Notifier.notify_error("Error during Account creation: %s" % update.message)
		emit_signal("authentication_failed",update.get_exception())
		return update
	
	emit_signal("authentication_successful")
	yield(socket_connect_async(), "completed")
	return session


# Login to email account
func login_email_async(email:String, password:String): #-> NakamaSession
	# login account with
	# mail + pw
	
	if is_logged_in():
		Notifier.notify_error("Error", "Already logged in")
		return session
	
	session = yield(client.authenticate_email_async(email,password, null, false), "completed")
	
	if session.is_exception():
		Notifier.notfy_debug("During email auth", session)
		Notifier.notify_error("Could not log in", session.message)
		emit_signal("authentication_failed", session.get_exception())
		return session
	
	#worked
	Notifier.notify_info("Login success")
	emit_signal("authentication_successful")
	yield(socket_connect_async(), "finished")
	return session


# Create email account
func register_email_async(email:String, password:String, username:String): #-> NakamaSession
	# login account with
	# mail + pw
	
	if is_logged_in():
		Notifier.notify_error("Error", "Already logged in")
		return session
	
	session = yield(client.authenticate_email_async(email, password, username, true), "completed")
	
	if session.is_exception():
		Notifier.notfy_debug("During email auth", session)
		Notifier.notify_error("Could not create account", session.message)
		emit_signal("authentication_failed",session.get_exception())
		return session
	
	#worked
	Notifier.notify_info("Account creation success")
	emit_signal("authentication_successful")
	yield(socket_connect_async(), "completed")
	return session



#### Socket

# (Re)Connect socket (called automatically after successful auth 
func socket_connect_async()->void: # -> NakamaAsyncResult
	socket = Nakama.create_socket_from(client)
	var connected : NakamaAsyncResult = yield(socket.connect_async(session), "completed")
	if connected.is_exception():
		Notifier.notfy_debug("Socket connect", connected)
		Notifier.notify_error("Could not connect", connected.message)
		emit_signal("socket_connection_failed")
		return socket
	
	account = yield(client.get_account_async(session),"completed")
	
	# register socket events
	socket.connect("received_matchmaker_matched", self, "_on_matchmaker_matched")
	socket.connect("received_match_presence", self, "_on_match_presence")
	socket.connect("received_match_state", self, "_on_match_state")
	
	emit_signal("socket_connected")
	
	return socket


func is_socket_connected()->bool:
	if !is_logged_in():
		printerr("Not even logged in")
		return false
	
	if not socket is NakamaSocket:
		return false
	
	return socket.is_connected_to_host()



#### Accounts

# Fetch an array of accounts
func fetch_accounts_async(user_ids:Array): # -> Account Array
#	Account schmea = {
#		"custom_id": {"name": "_custom_id", "type": TYPE_STRING, "required": false},
#		"devices": {"name": "_devices", "type": TYPE_ARRAY, "required": false, "content": "ApiAccountDevice"},
#		"disable_time": {"name": "_disable_time", "type": TYPE_STRING, "required": false},
#		"email": {"name": "_email", "type": TYPE_STRING, "required": false},
#		"user": {"name": "_user", "type": "ApiUser", "required": false},
#		"verify_time": {"name": "_verify_time", "type": TYPE_STRING, "required": false},
#		"wallet": {"name": "_wallet", "type": TYPE_STRING, "required": false},
#	}
	var result : NakamaAPI.ApiUsers = yield(client.get_users_async(session, user_ids), "completed")
	
	if result.is_exception():
		Notifier.notfy_debug("fetch_accounts_async", result)
		Notifier.notify_error("Error", result.message)
		return result
		
	return result.users



#### Matchmaking

# Start Matchmaking 
# Map Pool # [{map_id:, creator_id:}, ...]
func matchmaking_start_async(map_pool:Array)->void: # -> NakamaRTAPI.MatchmakerTicket
	if !is_socket_connected():
		printerr("Not connected")
		return
		
	if is_in_matchmaking():
		Notifier.notify_error("Error", "You are already in Matchmaking")
		return
	
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
	
	matchmaker_ticket = yield(
	  socket.add_matchmaker_async(query, min_count, max_count, string_properties, numeric_properties),
	  "completed"
	)
	if matchmaker_ticket.is_exception():
		Notifier.notify_debug("Error", matchmaker_ticket)
		Notifier.notify_error("Error", matchmaker_ticket.message)
		return matchmaker_ticket
	
	Notifier.notify_info("Matchmaking started")
	emit_signal("matchmaking_started")
	return matchmaker_ticket


# Cancel current Matchmaker Ticket
func matchmaking_cancel_async()->void:
	if not is_in_matchmaking():
		Notifier.notify_error("Not in matchmaking","Cant cancel")
		return
	
	var removed : NakamaAsyncResult = yield(socket.remove_matchmaker_async(matchmaker_ticket.ticket), "completed")
	if removed.is_exception():
		Notifier.notify_debug("cancel matchmaking", matchmaker_ticket)
		Notifier.notify_error("Error", matchmaker_ticket.message)
		return removed

	matchmaker_ticket = null
	emit_signal("matchmaking_ended")
	return removed



#### Matches

# Join a Match with Matchmaker Token
func match_join_async(matchmaker_token)->void: #-> AsyncResult
	joined_match = yield(socket.join_matched_async(matchmaker_token), "completed")
	if joined_match.is_exception():
		Notifier.notify_debug(joined_match)
		Notifier.notify_error("Could not join match", joined_match.message)
		joined_match = null
		return joined_match
	
	matchmaker_ticket = null
	emit_signal("match_joined",joined_match)
	return joined_match


# Send Match state
func match_send_state_async(op_code:int,new_state=""):
	if not is_in_match():
		Notifier.notify_error("Not in a match")
		return
	
	var result = yield(socket.send_match_state_async(joined_match.match_id, op_code, JSON.print(new_state)), "completed")
	_check_result(result)
	return result


# Gracefully leave the current match
func match_leave():
	if not is_in_match():
		Notifier.notify_error("Not in any match, cant leave")
		return
	
	yield(socket.leave_match_async(joined_match.match_id), "completed")
	Notifier.notify_info("Left the match")



#### Collections

# Write to collection
func collection_write_object_async(collection:String, key:String, value:String, public_read:bool): # -> ApiStorageObjectAck/s
	if not is_logged_in():
		printerr("Cant save to collection, NOT LOGGED IN")
		return
	
	var can_read =  ReadPermissions.PUBLIC if public_read else ReadPermissions.OWNER
	var can_write = WritePermissions.OWNER
	var acks : NakamaAPI.ApiStorageObjectAcks = yield(client.write_storage_objects_async(session, [
		NakamaWriteStorageObject.new(collection, key, can_read, can_write, value, "")
	]), "completed")
	
	if _check_result(acks, "Could not write to Storage"):
		return acks
	
	return acks.acks[0]


# Read single object from collection
func collection_read_object_async(collection:String, key:String, user_id:String = session.user_id): # -> ApiStorageObject
	var result : NakamaAPI.ApiStorageObjects = yield(client.read_storage_objects_async(session, [
	NakamaStorageObjectId.new(collection, key, user_id)
	]), "completed")
	
	if _check_result(result, "Could not read from Storage"):
		return result
		
	return result.objects[0]


# Remove single object from collection
func collection_remove_object_asnyc(collection:String,key:String): # -> NakamaAsyncResult
	var del : NakamaAsyncResult = yield(client.delete_storage_objects_async(session, [
		NakamaStorageObjectId.new(collection, key)
	]), "completed")
	
	_check_result(del, "Could not delete")
	return del


# List the first 100 owned objects in collection 
func collection_list_owned_objects_async(collection:String)->Array: # -> Array : ApiStorageObject
	# "objects" has cursor (for paging later)
	var limit = 100 # default is 10.
	var objects : NakamaAPI.ApiStorageObjectList = yield(client.list_storage_objects_async(session, collection, session.user_id, limit), "completed")
	
	if _check_result(objects):
		return objects
		
	return objects.objects


# List the first 100 public objects
func collection_list_public_objects_async(collection:String)->Array: # -> Array : ApiStorageObject
	# "objects" has cursor (for paging later) 
	var limit = 100 # default is 10.
	var objects : NakamaAPI.ApiStorageObjectList = yield(client.list_storage_objects_async(session, collection, "", limit), "completed")
	
	if _check_result(objects):
		return 
	
	# filter for public objects
	var public_objects:Array
	for i in objects.objects:
		if i.permission_read == ReadPermissions.PUBLIC:
			public_objects.append(i)
			
	return public_objects



#### Getset

# Get own user _id
func get_user_id()->String:
	return session.user_id


# Get own username (or display name if param)
func get_username(prefer_display_name:bool = false)->String:
	if prefer_display_name and account.user.display_name != "":
		return account.user.display_name
	return session.username


# Get own guest status
func is_guest()->bool:
	if not session.vars.has("guest"):
		return false
		
	return session.vars["guest"]


# Check if Session is valid
func is_logged_in()->bool:
	if not session is NakamaSession:
		return false
	
	if not session.is_valid():
		return false
	
	return true


# Check if a matchmaker ticket exists
func is_in_matchmaking()->bool:
	if matchmaker_ticket is NakamaRTAPI.MatchmakerTicket:
		return true
	
	return false


# Check if a match exists
func is_in_match()->bool:
	if joined_match is NakamaRTAPI.Match:
		return true
	
	return false



#### Callbacks

# Forwards to matchmaking_matched signal
func _on_matchmaker_matched(matched : NakamaRTAPI.MatchmakerMatched):
	Notifier.notify_info("Matchmaker found a Match")
	matched_match = matched
	emit_signal("matchmaking_matched", matched)


# Forwards to match_presences_updated signal
func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent): #-> NakamaRTAPI.MatchPresenceEvent
	emit_signal("match_presences_updated",p_presence)


# Forwads to match_state signal
func _on_match_state(p_state : NakamaRTAPI.MatchData):
	print(" -> Received match state with opcode %s, data %s" % [p_state.op_code, p_state.data])
	emit_signal("match_state", p_state)
