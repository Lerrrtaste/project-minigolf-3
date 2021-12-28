extends Node2D

# expected interface by ball
signal impact(pos) # required
signal sync_position(pos) # required
const LOCAL = true # required
var active := false # required (ball is awaiting impact)

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
				
				active = false
				emit_signal("impact", impact)


func activate(): # required
	if active:
		printerr("Local Player Controller was already active!")
	active = true


func _draw():
	if active:
		var dist = min(get_local_mouse_position().length(), MAX_SPEED_DISTANCE)
		draw_line(Vector2(),get_local_mouse_position().normalized() * dist, ColorN("black"))
