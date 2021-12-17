extends Node2D

signal impact(pos)
signal sync_position(pos)
const LOCAL = true

var active := false



func _ready():
	pass	


func _unhandled_input(event):
	if event is InputEventMouse:
		if event.button_mask == BUTTON_MASK_LEFT and event.is_pressed():
			if active:
				emit_signal("impact", get_local_mouse_position())
				var send_data = {"target_pos": var2str(get_local_mouse_position())}
				Networker.match_send_state_async(Global.OpCodes.BALL_IMPACT,send_data)
				active = false


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
