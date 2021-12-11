extends Node

signal move(pos)
const LOCAL = false

var remote_user_id

func _ready():
	Networker.connect("match_state",self,"_on_Networker_match_state")


func register_remote_user_id(_remote_user_id):
	remote_user_id = _remote_user_id


func _on_Networker_match_state(state:NakamaRTAPI.MatchData)->void:
	if not state.presence.user_id == remote_user_id:
		return #message irrelevant for this pc
	
	if state.op_code == Global.OP_CODES.moved:
		var data_dict = parse_json(state.data)
		var moved_to = Vector2(data_dict.x,data_dict.y)
		emit_signal("move",moved_to)
