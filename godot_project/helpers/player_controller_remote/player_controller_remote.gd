extends Node2D

## Remote Player Controller
## For Networked Matches
##
## Acts on behalf of a another local player controller
## Provides UI when active
##
## Recieves Match States sent by set user_id
## OpCodes.BALL_IMPACT
## OpCodes.SYNC_POS

## Ball interface (required) TODO change to not be dependent on this
signal impact(pos) # required
signal sync_position(pos) # required
const LOCAL = false # required
var active := false # required (ball is awaiting impact)

var user_id:String

const MAX_SPEED_DISTANCE = 100 # distance for max impact force



func _ready():
	Networker.connect("match_state",self,"_on_Networker_match_state") #warning-ignore:return_value_discarded


## set user id
func register_user_id(_user_id):
	user_id = _user_id


## Called when awaiting input from owning player
func activate(): # required
	if active:
		Notifier.log_warning("Remote PC is already active")
	active = true
	Notifier.log_verbose("PC activated")


## handle match states
func _on_Networker_match_state(state:NakamaRTAPI.MatchData)->void:
	# message from server, not relevant for now
	if not state.presence != null:
		Notifier.log_debug("Discarding irrelevant match_state (sent by server)")
		return
	
	# message irrelevant for this pc
	if not state.presence.user_id == user_id:
		Notifier.log_debug("Discarding irrelevant match_state (presence does not match)")
		return
	

	# handle BALL_IMPACT
	if state.op_code == Global.OpCodes.BALL_IMPACT:
		if not active:
			Notifier.log_warning("Remote PC was not active but recieved a BALL_IMPACT msg")
		
		var data_dict = JSON.parse(state.data).result
		var impact:Vector2 = str2var(data_dict["impact_vec"])
		active = false
		Notifier.log_debug("Recieved BALL_IMPACT: "+str(impact))
		emit_signal("impact",impact)
	

	# handle BALL_SYNC
	if state.op_code == Global.OpCodes.BALL_SYNC:
		var data_dict = JSON.parse(state.data).result
		var pos:Vector2 = str2var(data_dict["synced_pos"])

		Notifier.log_debug("Recieved BALL_SYNC "+str(pos))
		emit_signal("sync_position",pos)
