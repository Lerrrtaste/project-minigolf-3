extends KinematicBody2D

onready var lbl_player_name = get_node("LblPlayerName")
onready var spr_arrow = get_node("SprArrow")
onready var shape_body = get_node("ShapeBody")

var connected_pc #has active player controller attached
var map # set by match before entering tree (map ref)
var current_cell:Vector2
var collision_blacklist:Array # TODO maybe remove

# movement
var starting_position: Vector2
var direction: Vector2 # cartesian direction
var speed: float
var max_speed: float = 150
var friction_modifier: float = 1.0 # changed by tile 
var friction: float = 50

var total_distance := 0.0 #only used for collision shabe activaten for now

# match
var finished := false
var my_turn := false

signal turn_completed(local)
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
	spr_arrow.visible = my_turn


func _physics_process(delta):
	if total_distance >= 10:
		shape_body.set_deferred("disabled", finished) # TODO cleanup
	
	if speed > 0:
		var _cell = map.get_cell_position(position)
		if _cell != current_cell: # moved to new cell
			current_cell = _cell
			update_tile_properties()
	
	if speed > 0:  # seperate because update_tile_properties can change speed (if ball resets)
		move_step(direction * speed, delta)


func _draw():
	if connected_pc.active and connected_pc.LOCAL:
		var dist = min(get_local_mouse_position().length(), connected_pc.MAX_SPEED_DISTANCE)
		draw_line(Vector2(),get_local_mouse_position().normalized() * dist, ColorN("black"))


# called before entering tree
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


# called by match when this balls turn
func turn_ready():
	if my_turn:
		printerr("Ball was already at turn!!!!")
		return
	
	if connected_pc.active:
		printerr("The playercontroller was already active!!!!")
	
	while speed > 0:
		yield(get_tree().create_timer(0.25),"timeout")
	
	connected_pc.activate()
	my_turn = true


# called by finished_moving callback if it was this balls turn
func turn_complete():
	assert(my_turn)
	assert(not connected_pc.active) #he ball finished moving because of a previous collision, player took no turn yet
	my_turn = false
	emit_signal("turn_completed", connected_pc.LOCAL)


# called by finish map object
func reached_finish():
	finished = true
	shape_body.set_deferred("disabled", true)
	
	if connected_pc.LOCAL:
		emit_signal("reached_finish",position)
	
	finish_moving()


#### Movement

func move_step(movement,delta):
	#var movement = direction * speed
	
	#move_and_slide(movement)
	var collision = move_and_collide(movement*delta)
	total_distance += movement.length() * delta
	if collision is KinematicCollision2D:
		_handle_collision(collision)
		total_distance -= collision.remainder.length()
	else:
		collision_blacklist.clear()

	speed -= (friction*friction_modifier) * delta
	
	if speed <= 0:
		finish_moving()
		print("Sent because of physics")


func _handle_collision(collision:KinematicCollision2D):
	# ball to ball collision
	if collision_blacklist.has(collision.collider):
		return
		 
	if collision.collider is KinematicBody2D: # atm only balls are kinematic bodies
		print("ball %s colliding with %s"%[self,collision.collider])
		#You can get the collision components by creating a unit vector pointing in the direction
		#from one ball to the other, then taking the dot product with the velocity vectors of the balls. 
		var coll:Vector2 = position - collision.collider.position
		var distance:float = coll.length()

		coll = coll / distance
		var aci = (speed*direction).dot(coll)
		var bci = (collision.collider.speed * collision.collider.direction).dot(coll)
		
		var acf = bci
		var bcf = aci

		var new_local_vel = (acf - aci) * coll
		print("NewLocalVel: %s"%new_local_vel)
		var new_collider_vel = (bcf - bci) * coll
		print("NewRemoteVel: %s"%new_collider_vel)
		
		direction = isometric_normalize(new_local_vel)
		speed = new_local_vel.length()
		collision.collider.collision_impact(new_collider_vel, self)

		#ollision_blacklist.append(collision.collider)
		return
	
	#wall collision
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


func collision_impact(new_velocity:Vector2, sender:KinematicBody2D):
	# called by colliding ball
	collision_blacklist.append(sender)
	starting_position = position
	#assert(_impact.length() <= 1.01) #length not longer than 1 (accounting for rounding error)
	speed = new_velocity.length()
	direction = new_velocity.normalized()


func finish_moving():
	speed = 0
	
	if connected_pc.LOCAL:
		connected_pc.send_sync_position(position)
		#emit_signal("finished_moving")
	
	if my_turn and not connected_pc.active:
		turn_complete()


func update_tile_properties():
	if not is_instance_valid(map):
		return
		
	if map.get_tile_resets_ball(position):
		position = starting_position
		finish_moving()
		# TODO play respawn animation
		#print("Sent because of tile property")
	friction_modifier = map.get_tile_friction(position)


#### Callbacks

func _on_PlayerController_impact(_impact):
	starting_position = position
	assert(_impact.length() <= 1.01) # length not longer than 1 (accounting for rounding error)
	speed = min(_impact.length(),1.0) * max_speed
	direction = _impact.normalized()


func _on_PlayerController_sync_position(pos):
	position = pos
	finish_moving()


#### Setget

func set_map(_map):
	map = _map

func get_pc_user_id()->String:
	if connected_pc == null:
		printerr("No pc connected")
		return""
	
	return connected_pc.user_id


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

