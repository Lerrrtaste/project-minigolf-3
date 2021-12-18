extends Node

var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket 
var matchmaker_ticket : NakamaRTAPI.MatchmakerTicket

var connected_presences:Dictionary
var joined_match:NakamaRTAPI.Match
var matched_match:NakamaRTAPI.MatchmakerMatched

signal socket_connected
signal socket_connection_failed

signal matchmaking_started
signal matchmaking_ended
signal matchmaking_matched(matched)

signal authentication_successfull
signal authentication_failed

signal match_join_failed
signal match_joined(presences)
signal match_presences_updated(joined_match)
signal match_state(state)

func _ready():
	client = Nakama.create_client(Global.NK_KEY, Global.NK_ADDRESS, Global.NK_PORT, Global.NK_PROTOCOL)


func socket_connect()->void:
	socket = Nakama.create_socket_from(client)
	var connected : NakamaAsyncResult = yield(socket.connect_async(session), "completed")
	if connected.is_exception():
		print("An error occured: %s" % connected)
		emit_signal("socket_connection_failed")
		return
	print("Socket connected.")
	emit_signal("socket_connected")
	
	# register socket events
	socket.connect("received_matchmaker_matched", self, "_on_matchmaker_matched")
	socket.connect("received_match_presence", self, "_on_match_presence")
	socket.connect("received_match_state", self, "_on_match_state")


func login_async(custom_id:String)->void:
	if is_logged_in():
		return
	
	session = yield(client.authenticate_custom_async(custom_id,custom_id), "completed")
	
	if !is_logged_in(): #failed
		printerr("Could not log in with given custom ID!")
		emit_signal("authentication_failed")
		return
	
	#worked
	print("Logged in with customId %s successfully"%custom_id)
	emit_signal("authentication_successfull")
	socket_connect()
	return true


func matchmaking_start_async(map_id:int)->void:
	if !is_socket_connected():
		printerr("Not connected")
		return
		
	if is_in_matchmaking():
		printerr("Already in Matchmaking (has ticket)")
		return
		
	var query = "+properties.map_id:%s"%String(map_id)
	var min_count = 2
	var max_count = 3
	var string_properties = {
		"map_id": String(map_id)
	}
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
	
	emit_signal("match_joined",joined_match)


func match_send_state_async(op_code:int,new_state)->void:
	if not is_in_match():
		printerr("Trying to send match state while not joined in any")
		return
	
	socket.send_match_state_async(joined_match.match_id, op_code, JSON.print(new_state))


# Getset

func get_user_id()->String:
	return session.user_id


func get_username(user_id:String)->String:
	return connected_presences[user_id]["username"]


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

