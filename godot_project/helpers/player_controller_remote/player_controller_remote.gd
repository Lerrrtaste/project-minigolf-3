extends Node2D

signal impact(pos)
signal sync_position(pos)
const LOCAL = false

var remote_user_id
var active := false


func _ready():
	Networker.connect("match_state",self,"_on_Networker_match_state")


func register_remote_user_id(_remote_user_id):
	remote_user_id = _remote_user_id


func activate():
	if active:
		printerr("Remote PC is already active")
	active = true


func _on_Networker_match_state(state:NakamaRTAPI.MatchData)->void:
	if not state.presence != null:
		return # message from server, orobably not relevant
	
	
	if not state.presence.user_id == remote_user_id:
		return #message irrelevant for this pc
	
	
	if state.op_code == Global.OpCodes.BALL_IMPACT:
		if not active:
			printerr("Remote PC was not active but recieved a BALL_IMPACT msg")
		
		var data_dict = JSON.parse(state.data).result
		var pos:Vector2 = str2var(data_dict["target_pos"])
		active = false
		emit_signal("impact",pos)
	
	
	if state.op_code == Global.OpCodes.BALL_SYNC:
		var data_dict = JSON.parse(state.data).result
		var pos:Vector2 = str2var(data_dict["synced_pos"])
		
		emit_signal("sync_position",pos)
