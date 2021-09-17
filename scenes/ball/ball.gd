extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	update()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			apply_central_impulse(get_local_mouse_position().rotated(rotation))
	
func _draw():
	draw_line(Vector2(), get_local_mouse_position(), ColorN("red"), 3.0, true)
