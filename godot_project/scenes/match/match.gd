extends Node2D

"""
Represents a single Match / Game

Start Data: players, map
Connected to server

"""

onready var map = get_node("Map")
onready var text_score = get_node("UI/PanelScore/TextScore")

var Ball = preload("res://objects/ball/Ball.tscn")
var PlayerControllerLocal = preload("res://helpers/player_controller_local/PlayerControllerLocal.tscn")
var PlayerControllerRemote = preload("res://helpers/player_controller_remote/PlayerControllerRemote.tscn")
var MatchCamera = preload("res://helpers/cameras/match_camera/MatchCamera.tscn")

var remote_balls:Dictionary
var local_ball

var joined_players := {} # presences (key is user_id)
var turn_order := [] # list of user ids
var turn_current_idx = 0 # current player id
var turn_counter := {}

var map_id 

enum States {
	INVALID = -1,
	LOADING, # waiting for players to join
	PLAYING, # playing a match
	FINISHED, # match finished
	
	PRACTICE, # playing solo
}
var current_state = States.INVALID


func _ready():
	Networker.connect("match_joined", self,"_on_Networker_match_joined")
	Networker.connect("match_presences_updated", self, "_on_Networker_presences_updated")
	Networker.connect("match_state", self, "_on_Networker_match_state")
	
	
	var params = Global.get_scene_parameter()
	if params.has("practice"):
		map_id = params["practice"]
		change_state(States.PRACTICE)
	else:
		Networker.match_join_async(Networker.matched_match) 
	# now wait for MATCH_CONFIG data from server or practive_mode() call


func _process(delta):
	update_ui()

func change_state(new_state:int):
	assert(current_state != new_state)
	match new_state:
		States.LOADING:
			load_map(map_id)
		States.PLAYING:
			_start_match()
		States.PRACTICE:
			load_map(map_id)
			_start_practice()
		States.FINISHED:
			get_tree().change_scene("res://scenes/match_end/MatchEnd.tscn")
		_:
			printerr("Trying to change to nonexistent state")
			return
	
	current_state = new_state


func spawn_ball(local:bool, user_id:String):
	if local and local_ball != null:
		printerr("Trying to spawn a second local ball")
		return
	
	if not local and user_id == Networker.get_user_id():
		printerr("Trying to spawn remote ball for local user_id")
		return
	
	var new_ball = Ball.instance()
	
	if local:
		new_ball.setup_playercontroller(PlayerControllerLocal,user_id)
		new_ball.connect("finished_moving", self, "_on_Ball_finished_moving")
		local_ball = new_ball
	else:
		new_ball.setup_playercontroller(PlayerControllerRemote,user_id)
		remote_balls[user_id] = new_ball
	
	new_ball.set_map(map)
	add_child(new_ball)
	new_ball.position = map.match_get_starting_position()
	new_ball.connect("reached_finish", self, "_on_Ball_reached_finish")
	
	if local: # TODO add as own child and always follow current player
		# attach camera
		var cam = MatchCamera.instance()
		local_ball.add_child(cam)
		cam.make_current()


func _start_match():
	# spawn self
	spawn_ball(true,Networker.get_user_id())
	
	#spawn remote
	for i in joined_players:
		spawn_ball(false,i)
		turn_counter[i] = 0


func _start_practice():
	spawn_ball(true,"")


func player_remote_leave(user_id)->void:
	if user_id == Networker.session.user_id:
		printerr("trying to remove local ball")
		return
	remote_balls[user_id].queue_free()
	remote_balls[user_id].visible = false
	remote_balls.erase(user_id)


func load_map(map_id:int)->void: # todo use map storage helper some time in the futureeee
	var file = File.new()
	var error = file.open("%s%s.map"%[Global.MAPFOLDER_PATH,map_id],File.READ)
	if error != OK:
		printerr("Could not load file!!!")
		assert(false)
	
	map.deserialize(file.get_as_text())
	file.close()


func update_ui():
	var text := ""
	
	match current_state:
		States.LOADING:
			text += "Waiting for Match to start..."
		States.PLAYING:
			text += "%s's turn\n\n"%joined_players[turn_order[turn_current_idx]]["username"]
			text += "Shots:\n"
			for i in turn_order:
				if turn_order[turn_current_idx] == i:
					text += "->"
				text += "\t%s:\t%s\n" % [joined_players[i]["username"],turn_counter[i]]
	
	text_score.text = text


#### Callbacks

func _on_Networker_match_joined(joined_match)->void:
	pass


# Currently not sent by server at all
#func _on_Networker_presences_updated(connected_presences)->void:
#	var spawned_players = remote_balls.keys()
#
#	connected_presences.erase(Networker.session.user_id)
#
#	for _user_id in connected_presences:
#		if spawned_players.has(_user_id): #player did nothing
#			spawned_players.erase(_user_id)
#		else: #player joined
#			player_remote_spawn(_user_id)
#
#	for _user_id in spawned_players:
#		player_remote_leave(_user_id)


func _on_Networker_match_state(state):
	match state.op_code:
		Global.OpCodes.MATCH_CONFIG:
			var data_dict = JSON.parse(state.data).result
			map_id = int(data_dict["map_id"])
			
			change_state(States.LOADING)
		
		Global.OpCodes.MATCH_START:
			var data_dict = JSON.parse(state.data).result
			turn_order = data_dict["turn_order"]
			joined_players = data_dict["joined_players"]

			change_state(States.PLAYING)
			
			if(turn_order[turn_current_idx] == Networker.get_user_id()): #copied from below only used for first turn
				print("Local players turn (FIRST TURN)")
				local_ball.connected_pc.activate()
			else:
				var starting_player = joined_players[turn_order[turn_current_idx]]
				print("Other players turn: ", starting_player["username"])
				remote_balls[starting_player["user_id"]].connected_pc.activate()
		
		Global.OpCodes.NEXT_TURN:
			var data_dict = JSON.parse(state.data).result			
			var previous_player = turn_order[turn_current_idx]
			var next_turn_idx = (turn_current_idx+1)%turn_order.size()
			
			if turn_order[next_turn_idx] != data_dict["next_player"]:
				printerr("Next player is different from local turn_order")
			
			turn_current_idx = next_turn_idx
			
			if(turn_order[turn_current_idx] == Networker.get_user_id()):
				print("Local players turn")
				local_ball.connected_pc.activate()
			else:
				print("Other players turn: ", joined_players[data_dict["next_player"]]["username"])
				remote_balls[data_dict["next_player"]].connected_pc.activate()
			
			turn_counter[previous_player] += 1
		
		Global.OpCodes.REACHED_FINISH:
			#var state_dict = JSON.parse(state).result
			print("Player %s has reached the finish"%state.presence.username)
			turn_order.erase(state.presence.user_id)
			turn_current_idx = (turn_current_idx-1) % turn_order.size()
		
		Global.OpCodes.MATCH_END:
			change_state(States.FINISHED)
			Global.set_scene_parameters(JSON.parse(state.data).result)
			


func _on_Ball_finished_moving():
#	if not turn_order[turn_current_idx] == Networker.get_user_id():
#		print("Warning sending FINISHED_MOVING even though not in turn_order (only valid when finished)")
	var op_code = Global.OpCodes.TURN_FINISHED
	var data = {"reached_finish": false}
	Networker.match_send_state_async(op_code, data)


func _on_Ball_reached_finish(final_pos):
	#turn_order.erase(user_id) # happens when msg comes back
	var op_code = Global.OpCodes.TURN_FINISHED
	var data = {"reached_finish": true}
	Networker.match_send_state_async(op_code, data)
