extends CharacterBody2D

## Ball
##
## Has Physics for Ball Movement
## Needs a map reference to use tile properties
##
## To activate call turn_ready()
##
## Needs PlayerController before entering tree with setup_playercontroller
## Playercontrollers need:
## 	- signal impact(pos) # required
## 	- signal sync_position(pos) # required
## 	- const LOCAL = true # required
## 	- var active := false # required (ball is awaiting impact)
## 	- func activate()

@onready var lbl_player_name = get_node("LblPlayerName")
@onready var spr_arrow = get_node("SprArrow")
@onready var shape_body = get_node("ShapeBody")
@onready var center_pos = get_node("CenterPos")

var connected_pc #has active player controller attached
var map # set by match before entering tree (map ref)
var current_cell:Vector2 # FIXME curre
var collision_blacklist:Array # TODO maybe remove
var display_name:String

# movement
var starting_position: Vector2
var direction: Vector2 # cartesian direction
var speed: float
var max_speed: float = 300
var friction: float = 80
var bounce_count := 0
const BOUNCE_LIMIT = 3 # max bounces per turn

# tile properties
var tile_friction_modifier: float = 1.0 # changed by tile 
var tile_force: float = 0.0
var tile_force_direction:Vector2 = Vector2()

var total_distance := 0.0 #only used for collision shabe activaten for now
var collide_with_balls := false
var oneway_override_active := false

# match
var finished := false
var my_turn := false

signal turn_completed(local)
signal reached_finish(user_id)



func _ready():
	if not is_instance_valid(connected_pc):
		Notifier.log_error("Ball without PC entered Tree")
		return
	
	# name tag
	if connected_pc.LOCAL:
		lbl_player_name.text = "YOU"
	else:
		lbl_player_name.text = display_name
	
	connected_pc.position  = center_pos.position


func _physics_process(delta):
	# show arrow if at turn
	spr_arrow.visible = my_turn

	# update cell properties
	if speed > 0:
		var _cell = map.local_to_map(_get("position"))
		if _cell != current_cell: # moved to new cell
			current_cell = _cell
			update_tile_properties()
	
	# move
	if speed > 0:  # seperate because update_tile_properties can change speed (if ball resets)
		apply_tile_properties(delta)
		move_step(direction * speed, delta)

	# collision shape needs to be disabled for overlapping balls at spawn
	if shape_body.disabled and total_distance > 10:
		shape_body.disabled = false
		Notifier.log_verbose("Ball has enabled collision shape")


#### Match

## Creates and configures the given player controller (call before entering tree)
func setup_playercontroller(pc_scene:PackedScene,account=null)->void:
	if is_instance_valid(connected_pc):
		Notifier.log_warning("Cant setup palyercontroller: Ball is already controlled. Aborting")
		return
	
	# Player Controller
	var new_pc = pc_scene.instantiate()
	connected_pc = new_pc
	if new_pc.has_method("register_user_id") and account != null:
		new_pc.register_user_id(account.id)
	add_child(new_pc)
	
	# for name tag
	if account == null:
		display_name = "YOU"
	elif account.display_name != "":
		display_name = account.display_name
	else:
		display_name = account.username
	
	# pc signals
	new_pc.connect("impact",Callable(self,"_on_PlayerController_impact"))
	new_pc.connect("sync_position",Callable(self,"_on_PlayerController_sync_position"))

	Notifier.log_debug("PC has been setup: " + new_pc.get_name())


## Call if this ball is at turn
##
## Called by matches
func turn_ready():
	if my_turn:
		Notifier.log_warning("It was already this balls turn")
		return
	
	if connected_pc.active:
		Notifier.log_warning("PlayerController was already active")
	
	while speed > 0:
		await get_tree().create_timer(0.25).timeout
	
	connected_pc.activate()
	my_turn = true


## called by finished_moving callback if it was this balls turn
func turn_complete():
	assert(my_turn)
	assert(not connected_pc.active)
	my_turn = false
	Notifier.log_debug("Turn completed")
	emit_signal("turn_completed", connected_pc.LOCAL)


## Disable collision and turns for the remainder of the match
##
## called by finish map object
func reached_finish():
	finished = true
	shape_body.set_deferred("disabled", true)
	
	if connected_pc.LOCAL:
		Notifier.log_verbose("reached the finish, broadcasting")
		emit_signal("reached_finish",_get("position"))
	else:
		Notifier.log_verbose("reached finish (not broadcasting, pc is not local)")
	
	finish_moving()


func player_left():
	# The server handles skipping his turns if the player leaves
	Notifier.notify_game("Player " + lbl_player_name.text + " left the game")
	lbl_player_name.text += " (left)" 


#### Movement

## Move ball
func move_step(movement,delta):
	total_distance += movement.length() * delta
	
#	if oneway_override_active:
#		position += movement*delta
#	else:
	var collision = move_and_collide(movement*delta)
	if collision is KinematicCollision2D:
		_handle_collision(collision)
		total_distance -= collision.remainder.length()
	else:
		collision_blacklist.clear()

	speed -= (friction*tile_friction_modifier) * delta
	if speed <= 0:
		finish_moving()


## Collision occured
func _handle_collision(collision:KinematicCollision2D):
	Notifier.notify_debug("Collision: " + get_name() + " with " + collision.collider.get_name())
	
	if collision_blacklist.has(collision.collider):
		Notifier.log_debug("Collision occured but was blacklisted")
		return
		
	# ball to ball collision
	if collision.collider is CharacterBody2D: # atm only balls are kinematic bodies
		Notifier.log_debug("ball collision detected: %s colliding with %s"%[self,collision.collider])

		var coll:Vector2 = _get("position") - collision.collider.position
		var distance:float = coll.length()

		coll = coll / distance
		var aci = (speed*direction).dot(coll)
		var bci = (collision.collider.speed * collision.collider.direction).dot(coll)
		
		var acf = bci
		var bcf = aci

		var new_local_vel = (acf - aci) * coll 
		# print("NewLocalVel: %s"%new_local_vel)
		var new_collider_vel = (bcf - bci) * coll
		# print("NewRemoteVel: %s"%new_collider_vel)
		
		direction = isometric_normalize(new_local_vel)
		speed = new_local_vel.length() * 0.9
		collision.collider.collision_impact(new_collider_vel, self)

		#ollision_blacklist.append(collision.collider)
		return
	
	#wall collision
	Notifier.log_debug("wall collision detected: %s colliding with %s"%[self,collision.collider])
	var coll_pos_delta = collision.position - _get("position")
	#var collision_normal = coll_pos_delta.normalized()
	#var wall_tile_id = map.get_tile_id_at(collision.position - collision.normal*5) # approximation (could fail)
	
	
	
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
			wall_normal =  Vector2(1,1).normalized()

	#wall_normal = collision.normal * Vector2(2,1) # Test if this works
	
#	direction = isometric_normalize(reflect_vector(direction,wall_normal)).normalized()


	direction = isometric_normalize(reflect_vector(Vector2(1,2)*direction,wall_normal)).normalized()
	
	var bounce = map.get_tile_property(collision.position -wall_normal*5, "bounce")
	if bounce > 1.0:
		bounce_count += 1
	speed *=  0.9 * (bounce if bounce_count < BOUNCE_LIMIT else 1.0)


## Handle a collision with a another moving CharacterBody3D
##
## Called by colliding ball
func collision_impact(new_velocity:Vector2, sender:CharacterBody2D):
	Notifier.log_debug("Collision impact called by colliding ball: %s colliding with %s"%[self,sender])
	collision_blacklist.append(sender)
	starting_position = _get("position")
	#assert(_impact.length() <= 1.01) #length not longer than 1 (accounting for rounding error)
	speed = new_velocity.length()
	direction = new_velocity.normalized()


func finish_moving():
	Notifier.log_debug("Finished moving")
	speed = 0
	bounce_count = 0
	if connected_pc.LOCAL and connected_pc.has_method("send_sync_position"):
		connected_pc.send_sync_position(_get("position"))
		#emit_signal("finished_moving")
	
	if my_turn and not connected_pc.active:
		turn_complete()


func update_tile_properties():
	if not is_instance_valid(map):
		return
	
	if map.get_tile_property(_get("position"), "resets_ball"):
		shape_body.disabled = true
		total_distance = 0
		_set("position",starting_position)
		# TODO play respawn animation
		finish_moving()
		Notifier.notify_debug("Ball was reset because of tile property resets_ball")
		
	if map.get_tile_property(_get("position"), "resets_ball_to_start"):
		shape_body.disabled = true
		total_distance = 0
		_set("position",map.match_get_starting_position())
		# TODO play respawn animation
		finish_moving()
		Notifier.log_debug("Ball was reset to start because of tile property resets_ball_to_start")
	
	var allowed_direction = map.get_tile_property(_get("position"), "allowed_direction")
	if allowed_direction and not oneway_override_active:
		if direction.dot(allowed_direction) > 0:
			# entered oneway tile in the right direction
			set_collision_mask_value(3, false)
			oneway_override_active = true
			Notifier.log_debug("Overriding oneway collision, enterd in allowed direction")
	elif not allowed_direction and oneway_override_active:
		# exited oneway wall
		set_collision_mask_value(3, true)
		oneway_override_active = false
		Notifier.log_debug("Activating oneway collision, direction not allowed")
#
	tile_force = map.get_tile_property(_get("position"), "force")
	tile_force_direction = map.get_tile_property(_get("position"), "force_direction")
	tile_friction_modifier = map.get_tile_property(_get("position"),"friction")


func apply_tile_properties(delta):
	if tile_force > 0:
		var tile_vec = tile_force * tile_force_direction * delta
		var ball_vec = speed * direction
		var new_vec = ball_vec + tile_vec
		speed = new_vec.length()
		direction = new_vec.normalized()

#### Callbacks

# apply impact to speed and direction
func _on_PlayerController_impact(_impact):
	#Notifier.notify_debug(get_position(),str(position))
	starting_position = _get("position")
	assert(_impact.length() <= 1.01) # length not longer than 1 (accounting for rounding error)
	speed = min(_impact.length(),1.0) * max_speed
	direction = _impact.normalized()


# updates position
func _on_PlayerController_sync_position(pos):
	_set("position",pos)
	finish_moving()



#### Setget

func set_map(_map):
	map = _map


func get_pc_user_id()->String:
	if connected_pc == null:
		printerr("No pc connected")
		return ""
	
	if not "user_id" in connected_pc:
		printerr("Conncted pc does not have a user id")
		return ""
	
	return connected_pc.user_id


#### Helpers

func reflect_vector(vector:Vector2, normal:Vector2)->Vector2:
	return vector - 2 * vector.dot(normal) * normal


func isometric_normalize(_direction:Vector2)->Vector2:
	_direction = _direction.normalized()
	return _direction * Vector2(1,0.5)


# Override _get/_set to fake y position (needed for ysort)
func _get(property):
	match property:
		"position":
			return position + center_pos.position

func _set(property, value):
	match property:
		"position":
			position = value - center_pos.position
