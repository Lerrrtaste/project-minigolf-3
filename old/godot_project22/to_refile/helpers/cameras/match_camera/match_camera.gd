extends Camera2D
class_name MatchCameraClass

## The camera for matches.
##
## Intended to follow one ball at a time.
## Follow behavior can be overriden by userinput.
##
## Usage:
##     [codeblock]
##         matchcamera.follow(ball) # Transition to and then follow ball.
##         matchcamera.move_to(x, y) # Transitions and moves to cooradinate.
##     [/codeblock]


## The node to follow. Set with follow()
var _target:Node2D


## Target for temporary smooth transition.
## Disabled when set to (0,0)
var _transition_to := Vector2()


## The max speed for direct user movement.
var _manual_movement_speed := 100


func _process(delta):
	if _transition_to != Vector2():
		# Perform initial smooth transition
		if (get_camera_screen_center()-_transition_to).length() < 1:
			reset_smoothing()
			follow_smoothing_enabled = false
			_transition_to = Vector2()
	else:
		# Follow target
		if _target is Node2D:
			position = _target.position
	
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
		_target = null
		follow_smoothing_enabled = false
		position += manual_movement.normalized() * delta * _manual_movement_speed

## Move the camera to a fixed position.
##
## Makes the camera current, clears the target, and moves to the position.
##
## @param target_pos The position to move to.
## @param smooth Smooth movement
func move_to(target_pos:Vector2, smooth:bool):
	make_current()
	_target = null
	_transition_to = Vector2()
	position = target_pos
	follow_smoothing_enabled = smooth


## Makes the camera current, sets the target and starts following.
##
## @param target:Node2D The node to follow.
## @param smooth_follow:bool Whether to keep the camera smooth while following.
## @param smooth_transition:bool Wheter to smooth only the inital transition to the target. (No effect if smooth_follow is true)
func follow(target:Node2D, smooth_follow:bool, smooth_transition:bool):
	make_current()
	
	if smooth_transition and not smooth_follow:
		follow_smoothing_enabled = true
		_transition_to = _target.position
		position = _target.position
	else:
		_transition_to = Vector2()
	
	_target = target
