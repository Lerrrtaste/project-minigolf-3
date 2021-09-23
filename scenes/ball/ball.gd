extends KinematicBody2D

var velocity := Vector2()

func _ready():
	pass # Replace with function body.

func _process(delta):
	update()
	
	var collision = move_and_collide(velocity)
	print(collision)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if velocity == Vector2():
				velocity = get_local_mouse_position()
			#apply_central_impulse(get_local_mouse_position().rotated(rotation))
	
func _draw():
	if velocity == Vector2():
		draw_line(Vector2(), get_local_mouse_position(), ColorN("red"), 3.0, true)
