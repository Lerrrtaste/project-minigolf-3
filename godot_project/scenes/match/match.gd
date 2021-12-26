extends Node2D

"""
Represents a single Match (in the default gamemode)

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

var presences := {} # presences (key is user_id)
var turn_order := [] # for ui only (turns are dispatched by server)
var turn_count_local := {} # userid -> shots count
var current_turn_user:String = "" # user_id

var map_id 
var map_owner_id

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
			load_map(map_id, map_owner_id)
		States.PLAYING:
			_start_match()
		States.PRACTICE:
			pass #load_map(map_id)
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
		new_ball.connect("turn_completed", self, "_on_Ball_turn_completed")
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
	for i in presences:
		spawn_ball(false,i)
		turn_count_local[i] = 0


func _start_practice():
	# TODO need to simulate the server messages (next turn etc) 
	spawn_ball(true,"me")
	turn_count_local["me"] = 0
	turn_order[0] = "me"


func player_remote_leave(user_id)->void:
	if user_id == Networker.session.user_id:
		printerr("trying to remove local ball")
		return
	remote_balls[user_id].queue_free()
	remote_balls[user_id].visible = false
	remote_balls.erase(user_id)


func load_map(map_id:String, map_owner_id:String="")->void: # todo use map storage helper some time in the futureeee
	var map_jstring = yield(MapStorage.load_map_async(map_id, map_owner_id), "completed")
	map.deserialize(map_jstring)
	Networker.match_send_state_async(Global.OpCodes.MATCH_CLIENT_READY)


func update_ui():
	var text := ""
	
	match current_state:
		States.LOADING:
			text += "[b]Waiting for Match to start...[/b]"
		States.PLAYING:
			var current_name
			if local_ball.my_turn:
				current_name = "YOUR"
			else:
				current_name = presences[current_turn_user]["username"] + "´s"
			text += "[b]%s turn[/b]\n\n"%current_name
			text += "Shots:\n"
			for i in turn_order:
				if i == current_turn_user:
					text += "->"
				text += "\t%s:\t%s\n" % [presences[i]["username"],turn_count_local[i]]
	
	text_score.bbcode_text = text


func next_turn(user_id:String):
	if current_turn_user != "":
		turn_count_local[current_turn_user] += 1
	
	
	if(user_id == Networker.get_user_id()): #copied from below only used for first turn
		local_ball.turn_ready()
	elif remote_balls.has(user_id):
		remote_balls[user_id].turn_ready()
	else:
		printerr("Could not find the server announced next user's ball")
	
	current_turn_user = user_id

#### Callbacks

func _on_Networker_match_joined(joined_match)->void:
	pass


func _on_Networker_match_state(state):
	match state.op_code:
		Global.OpCodes.MATCH_CONFIG:
			var data_dict = JSON.parse(state.data).result
			map_id = data_dict["map_id"]
			map_owner_id = data_dict["map_owner_id"]
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
			
		Global.OpCodes.REACHED_FINISH:
			print("Player %s has reached the finish"%state.presence.username)
			if state.presence.user_id == Networker.get_user_id():
				local_ball.reached_finish()
			else:
				remote_balls[state.presence.user_id].reached_finish()
			
		Global.OpCodes.MATCH_END:
			change_state(States.FINISHED)
			var params = {
				"presences": presences,
				"turn_count": JSON.parse(state.data).result["turn_count"],
				"map_metadata": map.metadata,
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
