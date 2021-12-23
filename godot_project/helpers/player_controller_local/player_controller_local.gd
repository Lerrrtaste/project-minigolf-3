extends Node2D

signal impact(pos)
signal sync_position(pos)
const LOCAL = true

var active := false
var user_id:String

const MAX_SPEED_DISTANCE = 100.0  # mouse distance till full force



func _ready():
	pass	


func _unhandled_input(event):
	if event is InputEventMouse:
		if event.button_mask == BUTTON_MASK_LEFT and event.is_pressed():
			if active:
				var force:float = min(get_local_mouse_position().length(), MAX_SPEED_DISTANCE)
				var norm_force:float = force / MAX_SPEED_DISTANCE
				assert(norm_force <= 1.0)
				
				var direction := get_local_mouse_position().normalized() 
				var impact:Vector2 = norm_force * direction
				
				emit_signal("impact", impact)
				var send_data = {"impact_vec": var2str(impact)}
				Networker.match_send_state_async(Global.OpCodes.BALL_IMPACT,send_data)
				active = false


func register_user_id(_user_id):
	user_id = _user_id


func activate():
	if active:
		printerr("Local Player Controller was already active!")
	active = true


# Called from physics process if LOCAL == true
func send_sync_position(ball_pos):
	var op_code = Global.OpCodes.BALL_SYNC
	var data = {"synced_pos": var2str(ball_pos)}
	Networker.match_send_state_async(op_code,data)



#maybe support position rcv sync once server supports authorative position
