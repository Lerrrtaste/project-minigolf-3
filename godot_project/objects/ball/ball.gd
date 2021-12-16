extends KinematicBody2D

onready var lbl_player_name = get_node("LblPlayerName")

var connected_pc #has active player controller attached
var direction: Vector2
var speed: float
var max_speed: float = 150
var friction: float = 50


func _ready():
	if not is_instance_valid(connected_pc):
		printerr("Ball without PC entered Tree")
		return
	
	if connected_pc.LOCAL:
		lbl_player_name.text = "YOU"
	else:
		var remote_name = Networker.connected_presences[connected_pc.remote_user_id].username
		lbl_player_name.text = remote_name
	


func _process(delta):
	update()
	
	if speed > 0.0:
		var movement_step := Vector2()
		movement_step = direction
		movement_step.y /= 2
		movement_step *= speed * delta
		
		speed -= friction * delta 
		# position += movement_step
		
		_move(movement_step)
	
		


#TODO "hard set" position for sync after move ended from remote pc

func _on_PlayerController_move(_clicked_screen):
	var pos_delta:Vector2 = _clicked_screen - position
	direction = pos_delta.normalized()
	speed = max_speed
	print("Clicked at %s - current %s  --->  Delta %s"%[_clicked_screen,position,pos_delta])


func setup_playercontroller(pc_scene:PackedScene,remote_user_id=null)->void:
	if is_instance_valid(connected_pc):
		printerr("Ball is already controlled")
		return
	
	var new_pc = pc_scene.instance()
	connected_pc = new_pc
	if remote_user_id != null and new_pc.has_method("register_remote_user_id"):
		new_pc.register_remote_user_id(remote_user_id)
		
	add_child(new_pc)
	

	# connect pc signals
	new_pc.connect("move",self,"_on_PlayerController_move")


func _draw():
	draw_line(Vector2(),get_local_mouse_position(),ColorN("red"))


func _move(motion:Vector2)->void: #eig motion genannt
		
	var collision = move_and_collide(motion)
	
	# kollidiert
	if is_instance_valid(collision):
		_collide(collision)


# from last minigolf attempt
func _collide(collision:KinematicCollision2D):
	print("Collision: ",collision.remainder)
	#wall normal berechnen
	var coll_pos_delta := collision.position - position
	var collision_normal := coll_pos_delta.normalized()
	var wall_normal := Vector2()
	if coll_pos_delta.x > 0:
		if coll_pos_delta.y > 0: 
			# right down
			wall_normal = Vector2(-1,-1).normalized()
		else:
			# right up
			wall_normal = Vector2(-1,1).normalized()
	else:
		if coll_pos_delta.y > 0:
			# left down
			wall_normal = Vector2(1,-1).normalized()
		else:
			# left up
			wall_normal = Vector2(1,1).normalized()

	#set new direction
	#direction = reflect_vector(direction,wall_normal) v2 = v1 – 2(v1.n)n
	direction = reflect_vector(direction,collision.normal)
	
	#move remainder
	if !is_zero_approx(collision.remainder.length()):
		var remaining_motion := collision.remainder.normalized()
		remaining_motion *= direction
		remaining_motion.y /= 2
		_move(remaining_motion)


#### Helpers

func cartesian_to_isometric(cart:Vector2)->Vector2:
	# Cartesian to isometric:
	var iso = Vector2()
	iso.x = cart.x - cart.y
	iso.y = (cart.x + cart.y) / 2
	return iso


func reflect_vector(vector:Vector2, normal:Vector2)->Vector2:
	assert(normal.is_normalized())
	return vector - 2 * vector.dot(normal) * normal


func isometric_normalize(direction:Vector2)->Vector2:
	direction = direction.normalized()
	return direction * Vector2(1,0.6)


#### Callbacks

