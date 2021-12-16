extends Node2D

signal impact(pos)
const LOCAL = true


func _ready():
	pass	

func _unhandled_input(event):
	if event is InputEventMouse:
		if event.button_mask == BUTTON_MASK_LEFT:
			emit_signal("impact", get_local_mouse_position())
			var send_data = JSON.print({"target_pos": var2str(get_local_mouse_position())})
			Networker.match_send_state_async(Global.OpCodes.BALL_IMPACT,send_data)
