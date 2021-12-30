extends Node2D

"""
Local Player Controller
For Networked Matches

Provides UI when active

Then sends OpCodes.BALL_IMPACT
Has send_sync_position() to send OpCodes.SYNC_POS
"""

# expected interface by ball
signal impact(pos) # required
signal sync_position(pos) # required
const LOCAL = true # required
var active := false # required (ball is awaiting impact)

var user_id:String

const MAX_SPEED_DISTANCE = 100.0  # mouse distance till full force


func _process(delta):
	update()


func _unhandled_input(event):
	if event is InputEventMouse:
		if event.button_mask == BUTTON_MASK_LEFT and event.is_pressed():
			if active:
				var force:float = min(get_local_mouse_position().length(), MAX_SPEED_DISTANCE)
				var norm_force:float = force / MAX_SPEED_DISTANCE
				var direction := get_local_mouse_position().normalized() 
				
				var impact:Vector2 = norm_force * direction
				
				emit_signal("impact", impact)
				var send_data = {"impact_vec": var2str(impact)}
				Networker.match_send_state_async(Global.OpCodes.BALL_IMPACT,send_data)
				active = false


# Set user_id
func register_user_id(_user_id):
	user_id = _user_id


# Activate to get input
func activate(): # required
	if active:
		printerr("Local Player Controller was already active!")
	active = true


func _draw():
	# Draw force line
	if active:
		var dist = min(get_local_mouse_position().length(), MAX_SPEED_DISTANCE)
		draw_line(Vector2(),get_local_mouse_position().normalized() * dist, ColorN("black"))


# Send local position to sync with remote pcs
func send_sync_position(ball_pos):
	# Called from physics process if LOCAL == true
	var op_code = Global.OpCodes.BALL_SYNC
	var data = {"synced_pos": var2str(ball_pos)}
	Networker.match_send_state_async(op_code,data)
