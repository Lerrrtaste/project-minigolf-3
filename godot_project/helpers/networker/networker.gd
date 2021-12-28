extends Node

var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket 
var matchmaker_ticket : NakamaRTAPI.MatchmakerTicket

var account : NakamaAPI.ApiAccount

var connected_presences:Dictionary
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

#signal completed

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


func socket_connect()->void:
	socket = Nakama.create_socket_from(client)
	var connected : NakamaAsyncResult = yield(socket.connect_async(session), "completed")
	if connected.is_exception():
		print("An error occured: %s" % connected)
		emit_signal("socket_connection_failed")
		return
	print("Socket connected.")
	
	account = yield(client.get_account_async(session),"completed")
	
	# register socket events
	socket.connect("received_matchmaker_matched", self, "_on_matchmaker_matched")
	socket.connect("received_match_presence", self, "_on_match_presence")
	socket.connect("received_match_state", self, "_on_match_state")
	
	emit_signal("socket_connected")
	

func login_guest_asnyc(display_name:String)->void:
	# create/login account with
	# tries device uid, then random with unix time
	# TODO metadata guest = true
	# display name = entered name
	# username = guest_display-name_random-number
	
	if is_logged_in():
		printerr("Already logged in")
		return
	
	var custom_id = OS.get_unique_id()
	
	# deviceID disabled for now
	if true:# custom_id == "":
		randomize()
		custom_id = "guestid_os_%s" % ((OS.get_unix_time() * OS.get_system_time_msecs())%(randi()%19521982))
	else:
		custom_id = "guestid_rand_%s" % custom_id
	
	var username = "guest_%s_%s"%[display_name,randi()%8999+1000]
	
	session = yield(client.authenticate_custom_async(custom_id, username, true, {"guest": true}), "completed")
	
	var update : NakamaAsyncResult = yield(client.update_account_async(session, null, display_name, null, null, null), "completed")
	if update.is_exception():
		print("An error occured: %s" % update)
		return
	print("Guest display name set")
	
	if !is_logged_in(): #failed
		printerr("Could not log in with given custom ID!")
		emit_signal("authentication_failed",session.get_exception())
		return
	
	#worked
	emit_signal("authentication_successful")
	socket_connect()
	return


func login_email_async(email:String, password:String):
	# login account with
	# mail + pw
	
	if is_logged_in():
		printerr("Already logged in")
		return
	
	session = yield(client.authenticate_email_async(email,password, null, false), "completed")
	
	if !is_logged_in(): #failed
		printerr("Could not log in with given email password!")
		emit_signal("authentication_failed", session.get_exception())
		return
	
	#worked
	print("Logged in with email %s successfully"%email)
	emit_signal("authentication_successfull")
	socket_connect()
	return


func register_email_async(email:String, password:String, username:String):
	# login account with
	# mail + pw
	
	if is_logged_in():
		printerr("Already logged in")
		return
	
	session = yield(client.authenticate_email_async(email, password, username, true), "completed")
	
	if !is_logged_in(): #failed
		printerr("Could not register in with given email password!")
		emit_signal("authentication_failed",session.get_exception())
		return
	
	#worked
	print("Registered and Logged in with mail %s successfully"%email)
	emit_signal("authentication_successfull")
	socket_connect()
	return


func fetch_accounts_async(user_ids:Array):
	var result : NakamaAPI.ApiUsers = yield(client.get_users_async(session, user_ids), "completed")
	
	if result.is_exception():
		Notifier.notify_error("An error occured:",result.to_string())
		return
		
	return result.users


func reset():
	client = Nakama.create_client(Global.NK_KEY, Global.NK_ADDRESS, Global.NK_PORT, Global.NK_PROTOCOL)
	session = null
	socket = null
	matchmaker_ticket = null


func rpc_call(rpc_id:String, payload = null):
	return yield(client.rpc_async(session, rpc_id, payload), "completed")

#### Matches

func matchmaking_start_async(map_pool:Array)->void: # [{map_id:, creator_id:}, ...]
	if !is_socket_connected():
		printerr("Not connected")
		return
		
	if is_in_matchmaking():
		printerr("Already in Matchmaking (has ticket)")
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
	  printerr("An error occured: %s" % matchmaker_ticket)
	  return
	#print("Got ticket for matchmaking: %s" % [matchmaker_ticket])
	emit_signal("matchmaking_started")


func matchmaking_cancel_async()->void:
	if not is_in_matchmaking():
		printerr("Not in matchmaking, cant cancel")
		return
	
	var removed : NakamaAsyncResult = yield(socket.remove_matchmaker_async(matchmaker_ticket.ticket), "completed")
	if removed.is_exception():
	  printerr("An error occured: %s" % removed)
	  return
	#print("Removed from matchmaking %s" % [matchmaker_ticket.ticket])
	matchmaker_ticket = null
	emit_signal("matchmaking_ended")


func match_join_async(matchmaker_token)->void:
	# TODO make matchmaker parameter optional to use this for normal matches too
	joined_match = yield(socket.join_matched_async(matchmaker_token), "completed")
	if joined_match.is_exception():
		printerr("An error occured: %s" % joined_match)
		joined_match = null
		return
		
	#print("Joined match: %s" % [joined_match])

	# collect already connected presences
	for presence in joined_match.presences:
		#print("User id %s name %s'." % [presence.user_id, presence.username])
		connected_presences[presence.user_id] = presence
	
	matchmaker_ticket = null
	emit_signal("match_joined",joined_match)


func match_send_state_async(op_code:int,new_state="")->void:
	if not is_in_match():
		printerr("Trying to send match state while not joined in any")
		return
	
	socket.send_match_state_async(joined_match.match_id, op_code, JSON.print(new_state))


#### Collections

func collection_write_object_async(collection:String, key:String, value:String, public_read:bool): # -> ApiStorageObjectAck/s
	if not is_logged_in():
		printerr("Cant save to collection, NOT LOGGED IN")
		return
	
	var can_read =  ReadPermissions.PUBLIC if public_read else ReadPermissions.OWNER
	var can_write = WritePermissions.OWNER
	var acks : NakamaAPI.ApiStorageObjectAcks = yield(client.write_storage_objects_async(session, [
		NakamaWriteStorageObject.new(collection, key, can_read, can_write, value, "")
	]), "completed")
	
	if acks.is_exception():
		printerr("An error occured while writing to collection: %s" % acks)
		return acks
		
	print("Successfully stored objects:")
	for a in acks.acks:
		print("%s" % a)
	
	return acks.acks[0]


func collection_read_object_async(collection:String, key:String, user_id:String = session.user_id): # -> ApiStorageObject
	var result : NakamaAPI.ApiStorageObjects = yield(client.read_storage_objects_async(session, [
	NakamaStorageObjectId.new(collection, key, user_id)
	]), "completed")
	
	if result.is_exception():
		printerr("An error occured: %s" % result)
		return
		
	print("Read objects:")
	for o in result.objects:
		print("%s" % o)
	
	return result.objects[0]


func collection_remove_object_asnyc(collection:String,key:String): # -> NakamaAsyncResult
	var del : NakamaAsyncResult = yield(client.delete_storage_objects_async(session, [
		NakamaStorageObjectId.new(collection, key)
	]), "completed")
	
	if del.is_exception():
		printerr("An error occured: %s" % del)
		return
		
	print("Deleted objects.")
	return del


func collection_list_owned_objects_async(collection:String)->Array: # -> Array : ApiStorageObject
	# "objects" has cursor (for paging later)
	var limit = 100 # default is 10.
	var objects : NakamaAPI.ApiStorageObjectList = yield(client.list_storage_objects_async(session, collection, session.user_id, limit), "completed")
	if objects.is_exception():
		print("An error occured: %s" % objects)
		return
	return objects.objects


func collection_list_public_objects_async(collection:String)->Array: # -> Array : ApiStorageObject
	# "objects" has cursor (for paging later) 
	var limit = 100 # default is 10.
	var objects : NakamaAPI.ApiStorageObjectList = yield(client.list_storage_objects_async(session, collection, "", limit), "completed")
	if objects.is_exception():
		print("An error occured: %s" % objects)
		return
	# filter for public objects
	var public_objects:Array
	for i in objects.objects:
		if i.permission_read == ReadPermissions.PUBLIC:
			public_objects.append(i)
	return public_objects


#### Getset

func get_user_id()->String:
	return session.user_id


func get_username(prefer_display_name:bool = false)->String:
	if prefer_display_name and account.user.display_name != "":
		return account.user.display_name
	return session.username


func is_guest()->bool:
	if not session.vars.has("guest"):
		return false
		
	return session.vars["guest"]


func is_socket_connected()->bool:
	if !is_logged_in():
		printerr("Not even logged in")
		return false
	
	if not socket is NakamaSocket:
		return false
	
	return socket.is_connected_to_host()


func is_logged_in()->bool:
	if not session is NakamaSession:
		return false
	
	if not session.is_valid() or session.is_expired():
		return false
	
	return true


func is_in_matchmaking()->bool:
	if matchmaker_ticket is NakamaRTAPI.MatchmakerTicket:
		return true
	
	return false


func is_in_match()->bool:
	if joined_match is NakamaRTAPI.Match:
		return true
	
	return false


#### Callbacks

func _on_matchmaker_matched(matched : NakamaRTAPI.MatchmakerMatched):
	#print("Received MatchmakerMatched message: %s" % [matched])
	#print("Matched opponents: %s" % [matched.users])
	matched_match = matched
	emit_signal("matchmaking_matched", matched)


func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		connected_presences[p.user_id] = p
	for p in p_presence.leaves:
		connected_presences.erase(p.user_id)
	#print("Connected opponents: %s" % [connected_presences])
	emit_signal("match_presences_updated",connected_presences)


func _on_match_state(p_state : NakamaRTAPI.MatchData):

	print(" -> Received match state with opcode %s, data %s" % [p_state.op_code, p_state.data])
	emit_signal("match_state", p_state)

