extends Camera2D
class_name MatchCameraClass

"""
A camera to be used during matches

Intended to follow() balls
Can be taken over by user input

"""

var target:Node2D
var transition_to := Vector2() # for temporary smooth
var manual_movement_speed := 100
 
func _ready():
	pass


func _process(delta):
	if transition_to != Vector2():
		if (get_camera_screen_center()-transition_to).length() < 1:
			reset_smoothing()
			smoothing_enabled = false
			transition_to = Vector2()
	else:
		if target is Node2D:
			position = target.position
	
	# user takeover
	var manual_movement := Vector2()
	if Input.is_action_pressed("camera_down"):
		manual_movement.y += 1
	if Input.is_action_pressed("camera_up"):
		manual_movement.y -= 1
	if Input.is_action_pressed("camera_right"):
		manual_movement.x += 1
	if Input.is_action_pressed("camera_left"):
		manual_movement.x -= 1
	if manual_movement.length() > 0:
		target = null
		smoothing_enabled = false
		position += manual_movement.normalized() * delta * manual_movement_speed

# focus a position
func move_to(target_pos:Vector2, smooth:bool):
	make_current()
	target = null
	transition_to = Vector2()
	position = target_pos
	smoothing_enabled = smooth


# follow a node's position
func follow(_target:Node2D, smooth_follow:bool, smooth_transition:bool):
	make_current()
	
	if smooth_transition and not smooth_follow:
		smoothing_enabled = true
		transition_to = _target.position
		position = _target.position
	else:
		transition_to = Vector2()
	
	target = _target
