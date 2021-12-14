extends Node2D

"""
Represents a single Match / Game

Start Data: players, map
Connected to server

"""

var Ball = preload("res://objects/ball/Ball.tscn")
var PlayerControllerLocal = preload("res://helpers/player_controller_local/PlayerControllerLocal.tscn")
var PlayerControllerRemote = preload("res://helpers/player_controller_remote/PlayerControllerRemote.tscn")

var remote_balls:Dictionary
var local_ball



func _ready():
	Networker.connect("match_joined", self,"_on_Networker_match_joined")
	Networker.connect("match_presences_updated", self, "_on_Networker_presences_updated")
	Networker.match_join_async(Networker.matched_match) 


func start_game():
	# spawn self
	var new_ball = Ball.instance()
	new_ball.setup_playercontroller(PlayerControllerLocal)
	add_child(new_ball)
	local_ball = new_ball
	
	#spawn remote
	for p in Networker.connected_presences:
		player_remote_spawn(p)


func player_remote_spawn(user_id)->void:
	if user_id == Networker.session.user_id:
		return
	var new_ball = Ball.instance()
	new_ball.setup_playercontroller(PlayerControllerRemote,user_id)
	remote_balls[user_id] = new_ball
	add_child(new_ball)


func player_remote_leave(user_id)->void:
	if user_id == Networker.session.user_id:
		return
	remote_balls[user_id].queue_free()
	remote_balls[user_id].visible = false
	remote_balls.erase(user_id)


#### Callbacks

func _on_Networker_match_joined(joined_match)->void:
	print(joined_match)
	start_game()

func _on_Networker_presences_updated(connected_presences)->void:
	var spawned_players = remote_balls.keys()
	
	connected_presences.erase(Networker.session.user_id)
	
	for _user_id in connected_presences:
		if spawned_players.has(_user_id): #player did nothing
			spawned_players.erase(_user_id)
		else: #player joined
			player_remote_spawn(_user_id)
	
	for _user_id in spawned_players:
		player_remote_leave(_user_id)
		
	
