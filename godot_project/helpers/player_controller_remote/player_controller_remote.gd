extends Node

signal impact(pos)
const LOCAL = false

var remote_user_id

func _ready():
	Networker.connect("match_state",self,"_on_Networker_match_state")


func register_remote_user_id(_remote_user_id):
	remote_user_id = _remote_user_id


func _on_Networker_match_state(state:NakamaRTAPI.MatchData)->void:
	if not state.presence != null:
		return # message from server, orobably not relevant
	
	if not state.presence.user_id == remote_user_id:
		return #message irrelevant for this pc
	
	if state.op_code == Global.OpCodes.BALL_IMPACT:
		var data_dict:Dictionary = JSON.parse(state.data).result
		var pos:Vector2 = str2var(data_dict["target_pos"])
		
		emit_signal("impact",pos)
