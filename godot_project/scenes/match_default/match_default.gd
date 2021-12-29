extends Node2D

"""
Represents a single Match (in the default gamemode)

Start Parameters: none
Uses Networker socket

Exits to:
	- MatchEnd
		- gamemode = "default"
		- presences: Dict
		- turn_count: Dict
		- map_metadata: Dict
	- Menu (on leave)

"""

onready var map = get_node("Map")
onready var text_score = get_node("UI/PanelScore/TextScore")

onready var popup_leave = get_node("UI/PopupLeave")

var Ball = preload("res://objects/ball/Ball.tscn")
var PlayerControllerLocal = preload("res://helpers/player_controller_local/PlayerControllerLocal.tscn")
var PlayerControllerRemote = preload("res://helpers/player_controller_remote/PlayerControllerRemote.tscn")
var MatchCamera = preload("res://helpers/cameras/match_camera/MatchCamera.tscn")

var remote_balls:Dictionary
var local_ball

var expected_user_ids:Array
var presences:Dictionary # presences (key is user_id)
var accounts:Dictionary # full accounts (key userid)
var turn_order:Array# for ui only (turns are dispatched by server)
var turn_count_local:Dictionary # userid -> shots count
var current_turn_user:String = "" # user_id

var map_id 
var map_owner_id

enum States {
	INVALID = -1,
	LOADING, # waiting for players to join
	PLAYING, # playing a match
	FINISHED, # match finished
}
var current_state = States.INVALID


func _ready():
	Networker.connect("match_joined", self,"_on_Networker_match_joined")
	Networker.connect("match_state", self, "_on_Networker_match_state")
	
	Networker.match_join_async(Networker.matched_match)


func _process(delta):
	update_ui()


func change_state(new_state:int):
	assert(current_state != new_state)
	match new_state:
		States.LOADING:
			Notifier.notify_game("Game is loading")
			load_map(map_id, map_owner_id)
			var accs = yield(get_accounts_async(expected_user_ids), "completed")
			for i in accs:
				accounts[i.id] = i
			Networker.match_send_state_async(Global.OpCodes.MATCH_CLIENT_READY)
		States.PLAYING:
			Notifier.notify_game("Match started")
			_start_match()
		States.FINISHED:
			get_tree().change_scene("res://scenes/match_end/MatchEnd.tscn")
		_:
			printerr("Trying to change to nonexistent state")
			return
	
	current_state = new_state


func spawn_ball(local:bool, account):
	if local and local_ball != null:
		printerr("Trying to spawn a second local ball")
		return
	
	if not local and account.id == Networker.get_user_id():
		printerr("Trying to spawn remote ball for local user_id")
		return
	
	var new_ball = Ball.instance()
	
	if local:
		new_ball.setup_playercontroller(PlayerControllerLocal, account)
		new_ball.connect("turn_completed", self, "_on_Ball_turn_completed")
		local_ball = new_ball
	else:
		new_ball.setup_playercontroller(PlayerControllerRemote, account)
		remote_balls[account.id] = new_ball
	
	map.add_child(new_ball)
	new_ball.set_map(map)
	new_ball.position = map.match_get_starting_position()
	new_ball.connect("reached_finish", self, "_on_Ball_reached_finish")
	
	if local: # TODO add as own child and always follow current player (implement in match camera scipt
		# attach camera
		var cam = MatchCamera.instance()
		local_ball.add_child(cam)
		cam.make_current()


func _start_match():
	# spawn self
	spawn_ball(true,accounts[Networker.get_user_id()])
	
	#spawn remote
	for i in presences:
		spawn_ball(false,accounts[i])
		turn_count_local[i] = 0


func player_remote_leave(user_id)->void: # not called yet
	if user_id == Networker.session.user_id:
		printerr("trying to remove local ball")
		return
	remote_balls[user_id].queue_free()
	remote_balls[user_id].visible = false
	remote_balls.erase(user_id)


func load_map(map_id:String, map_owner_id:String="")->void:
	var map_jstring = yield(MapStorage.load_map_async(map_id, map_owner_id), "completed")
	map.deserialize(map_jstring)


func get_accounts_async(expected_user_ids:Array):
	return yield(Networker.fetch_accounts_async(expected_user_ids), "completed")


func update_ui():
	var text := ""
	
	match current_state:
		States.LOADING:
			text += "[b]Waiting for Match to start...[/b]"
		States.PLAYING:
			var current_name
			if local_ball.my_turn:
				current_name = "YOUR"
			elif remote_balls.has(current_turn_user):
				current_name = remote_balls[current_turn_user].display_name + "´s"
				
			text += "[b]%s turn[/b]\n\n"%current_name
			text += "Shots:\n"
			for i in turn_order:
				if i == current_turn_user:
					text += "->"
				var display_name = get_ball(i).display_name
				text += "\t%s:\t%s\n" % [display_name,turn_count_local[i]]
	
	text_score.bbcode_text = text


func next_turn(user_id:String):
	if current_turn_user != "": # no prev player in the first round
		turn_count_local[current_turn_user] += 1
	
	Notifier.notify_game("It is %s's turn"%get_ball(user_id).display_name)
	
	if(user_id == Networker.get_user_id()): #copied from below only used for first turn
		local_ball.turn_ready()
	elif remote_balls.has(user_id):
		remote_balls[user_id].turn_ready()
	else:
		printerr("Could not find the server announced next user's ball")
	
	current_turn_user = user_id


func get_ball(user_id:String):
	if remote_balls.has(user_id):
		return remote_balls[user_id]
	elif local_ball.get_pc_user_id() == user_id:
		return local_ball
	else:
		assert(false) # looking for non existent ball


#### Callbacks

func _on_Networker_match_joined(joined_match)->void:
	pass


func _on_Networker_match_state(state):
	match state.op_code:
		Global.OpCodes.MATCH_CONFIG:
			var data_dict = JSON.parse(state.data).result
			map_id = data_dict["map_id"]
			map_owner_id = data_dict["map_owner_id"]
			expected_user_ids = data_dict["expected_user_ids"]
			change_state(States.LOADING)
		
		
		Global.OpCodes.MATCH_START:
			var data_dict = JSON.parse(state.data).result
			turn_order = data_dict["turn_order"]
			presences = data_dict["presences"]
			change_state(States.PLAYING)
			next_turn(turn_order[0])
		
		Global.OpCodes.NEXT_TURN:
			var data_dict = JSON.parse(state.data).result
			next_turn(data_dict["next_player"])
		
		Global.OpCodes.PLAYER_LEFT:
			var data_dict = JSON.parse(state.data).result
			for i in data_dict["left_players"]:
				if current_turn_user == i.user_id:
					get_ball(i.user_id).turn_complete(true)
				
		
		Global.OpCodes.REACHED_FINISH:
			assert(false) # this is only sent by the client
#			print("Player %s has reached the finish"%state.presence.username)
#			if state.presence.user_id == Networker.get_user_id():
#				local_ball.reached_finish()
#				Notifier.notify_game("You reached the finish :)")
#			else:
#				remote_balls[state.presence.user_id].reached_finish()
#				Notifier.notify_game("%s reached the finish", remote_balls[state.presence.user_id].display_name)
#
		Global.OpCodes.MATCH_END:
			change_state(States.FINISHED)
			var params = {
				"presences": presences,
				"turn_count": JSON.parse(state.data).result["turn_count"],
				"map_metadata": map.metadata,
				"gamemode": "default"
			}
			Global.set_scene_parameters(params)


func _on_Ball_turn_completed(local:bool):
	if local:
		var op_code = Global.OpCodes.TURN_COMPLETED
		var data = {}
		Networker.match_send_state_async(op_code, data)


func _on_Ball_reached_finish(final_pos):
	#turn_order.erase(user_id) # happens when msg comes back
	var op_code = Global.OpCodes.REACHED_FINISH
	var data = {}
	Networker.match_send_state_async(op_code, data)


func _on_BtnLeave_pressed():
	popup_leave.popup_centered()


func _on_BtnLeaveConfirm_pressed():
	Networker.match_leave()
	get_tree().change_scene("res://scenes/menu/Menu.tscn")


func _on_BtnLeaveCancel_pressed():
	popup_leave.visible = false
