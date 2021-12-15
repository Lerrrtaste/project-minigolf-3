extends Node2D

signal move(pos)
const LOCAL = true


func _ready():
	pass	

func _unhandled_input(event):
	if event is InputEventMouse:
		if event.button_mask == BUTTON_MASK_LEFT:
			emit_signal("move", event.position)
#			var data = {"x": event.position.x, "y":event.position.y}
#			Networker.match_send_state_async(Global.OP_CODES.moved, data)
