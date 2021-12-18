extends KinematicBody2D

onready var lbl_player_name = get_node("LblPlayerName")

var connected_pc #has active player controller attached
var direction: Vector2 # cartesian direction
var speed: float
var max_speed: float = 150
var friction: float = 50
var turn_ready: = false
var finished := false

var dbg_line_start := Vector2()
var dbg_line_end := Vector2()

signal finished_moving()
signal reached_finish(user_id)

func _ready():
	if not is_instance_valid(connected_pc):
		printerr("Ball without PC entered Tree")
		return
	
	if connected_pc.LOCAL:
		lbl_player_name.text = "YOU"
	else:
		lbl_player_name.text = Networker.get_username(connected_pc.user_id)


func _process(delta):
	update()


func _physics_process(delta):
	if speed > 0:
		move_step(delta)
	

func setup_playercontroller(pc_scene:PackedScene,user_id)->void:
	if is_instance_valid(connected_pc):
		printerr("Ball is already controlled")
		return
	
	var new_pc = pc_scene.instance()
	connected_pc = new_pc
	if new_pc.has_method("register_user_id"):
		new_pc.register_user_id(user_id)
		
	add_child(new_pc)
	
	# connect pc signals
	new_pc.connect("impact",self,"_on_PlayerController_impact")
	new_pc.connect("sync_position", self, "_on_PlayerController_sync_position")
	

func reached_finish():
	finished = true
	speed = 0
	if connected_pc.LOCAL:
		emit_signal("reached_finish",position)

#### Movement

func move_step(delta:float):
	var movement = direction * speed
	
	move_and_slide(movement)
	
	if get_slide_count() > 0:
		#wall normal berechnen
		var collision = get_slide_collision(0)
		
		var coll_pos_delta = collision.position - position
		var collision_normal = coll_pos_delta.normalized()
		
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
		
		
		direction = isometric_normalize(reflect_vector(direction,wall_normal))
		dbg_line_start = Vector2()
		dbg_line_end = isometric_normalize(wall_normal) * 50
	
	speed -= friction * delta
	
	if not finished and speed <= 0 and connected_pc.LOCAL:
		connected_pc.send_sync_position(position)
		emit_signal("finished_moving")
	

#### Helpers

func cartesian_to_isometric(cart:Vector2)->Vector2:
	# Cartesian to isometric:
	var iso = Vector2()
	iso.x = cart.x - cart.y
	iso.y = (cart.x + cart.y) / 2
	return iso


func reflect_vector(vector:Vector2, normal:Vector2)->Vector2:
	return vector - 2 * vector.dot(normal) * normal


func isometric_normalize(direction:Vector2)->Vector2:
	direction = direction.normalized()
	return direction * Vector2(1,0.5)


#### Callbacks

func _on_PlayerController_impact(_clicked_screen):
	direction = _clicked_screen.normalized()
	speed = max_speed


func _on_PlayerController_sync_position(pos):
	position = pos
