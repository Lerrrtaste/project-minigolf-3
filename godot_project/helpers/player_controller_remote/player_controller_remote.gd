extends Node2D

"""
Remote Player Controller
For Networked Matches

Acts on behalf of a another local player controller
Provides UI when active

Recieves Match States sent by set user_id
OpCodes.BALL_IMPACT
OpCodes.SYNC_POS
"""


# expected interface by ball
signal impact(pos) # required
signal sync_position(pos) # required
const LOCAL = false # required
var active := false # required (ball is awaiting impact)

var user_id:String

const MAX_SPEED_DISTANCE = 100 # distance for max impact force



func _ready():
	Networker.connect("match_state",self,"_on_Networker_match_state")


# set user id
func register_user_id(_user_id):
	user_id = _user_id


func activate(): # required
	if active:
		printerr("Remote PC is already active")
	active = true


func _on_Networker_match_state(state:NakamaRTAPI.MatchData)->void:
	if not state.presence != null:
		return # message from server, not relevant for now
	
	
	if not state.presence.user_id == user_id:
		return #message irrelevant for this pc
	
	
	if state.op_code == Global.OpCodes.BALL_IMPACT:
		if not active:
			printerr("Remote PC was not active but recieved a BALL_IMPACT msg")
		
		var data_dict = JSON.parse(state.data).result
		var impact:Vector2 = str2var(data_dict["impact_vec"])
		active = false
		emit_signal("impact",impact)
	
	
	if state.op_code == Global.OpCodes.BALL_SYNC:
		var data_dict = JSON.parse(state.data).result
		var pos:Vector2 = str2var(data_dict["synced_pos"])
		
		emit_signal("sync_position",pos)
