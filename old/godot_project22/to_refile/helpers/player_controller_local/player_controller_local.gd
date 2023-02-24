extends Node2D

## Local Player Controller
## For Networked Matches
##
## Provides UI when active
##
## When activate() waits for player input
## Then sends OpCodes.BALL_IMPACT with impact_vec and emits
## the impact signal for the ball to respond locally.
##
## The ball can call send_sync_position() at any time to
## force sync connected remote pcs position. (OpCodes.SYNC_POS)


## Ball interface (required) TODO change to not be dependent checked this
signal impact(pos) # required
signal sync_position(pos) # required
const LOCAL = true # required
var active := false # required (ball is awaiting impact)

## Owning User
var user_id:String

const MAX_SPEED_DISTANCE = 100.0  # mouse distance till full force


func _process(delta):
	update()


## Process player input
func _unhandled_input(event):
	if event is InputEventMouse:
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT and event.is_pressed():
			if active:
				var force:float = min(get_local_mouse_position().length(), MAX_SPEED_DISTANCE)
				var norm_force:float = force / MAX_SPEED_DISTANCE
				var direction := get_local_mouse_position().normalized() 
				
				var impact:Vector2 = norm_force * direction

				# Tell ball to move
				emit_signal("impact", impact)

				# Send Impact Data to server
				var send_data = {"impact_vec": var_to_str(impact)}
				Networker.match_send_state_async(Global.OpCodes.BALL_IMPACT,send_data)

				# Stop taking input
				active = false


## Set user_id
func register_user_id(_user_id):
	user_id = _user_id


## Activate to get input
func activate(): # required
	if active:
		Notifier.log_warning("Local Player Controller was already active!")
	active = true
	Notifier.log_verbose("PC activated")


func _draw():
	# Draw force line
	if active:
		var dist = min(get_local_mouse_position().length(), MAX_SPEED_DISTANCE)
		draw_line(Vector2(),get_local_mouse_position().normalized() * dist, ColorN("black"))


## Send local position to sync with remote pcs
func send_sync_position(ball_pos):
	# Called from physics process if LOCAL == true
	var op_code = Global.OpCodes.BALL_SYNC
	var data = {"synced_pos": var_to_str(ball_pos)}
	Networker.match_send_state_async(op_code,data)
