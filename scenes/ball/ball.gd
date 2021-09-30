extends KinematicBody2D

# physics https://www.tutelman.com/golf/swing/index.php

var velocity := Vector2()
var friction := 0.7 #later based on ground type
const FLOAT_ROUNDING = 1


func _physics_process(delta)->void:
	if floor(velocity.length()) == 0.0:
		velocity = Vector2()
	
	_move(velocity*delta)
	_friction(delta)


func _move(movement:Vector2)->void: #eig motion genannt
	var collision = move_and_collide(movement.length()*isometric_normalize(movement))
	
	# kollidiert
	if is_instance_valid(collision):
		_collide(collision)


func _collide(collision:KinematicCollision2D):
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
	velocity = reflect_vector(velocity,wall_normal)
	
	#move remainder
	if !is_zero_approx(collision.remainder.length()):
		_move(velocity.normalized() * collision.remainder.length())


func _friction(delta:float) -> void:
	var friction_force := Vector2()
	friction_force = -velocity * friction * delta
	velocity += friction_force #apply


func impact(force:Vector2) -> void:
	velocity += force
	print(force)


func reflect_vector(vector:Vector2, normal:Vector2)->Vector2:
	assert(normal.is_normalized())
	return vector - 2 * vector.dot(normal) * normal


# Converts any Vector2 coordinates or motion from the cartesian to the isometric system
func cartesian_to_isometric(cartesian):
	return Vector2(cartesian.x - cartesian.y, (cartesian.x + cartesian.y) / 2)


# useful to convert mouse coordinates back to screen-space, and detect where the player wants to know.
# If we want to add mouse-based controls, we'll need this function
func isometric_to_cartesian(iso):
	var cart_pos = Vector2()
	cart_pos.x = (iso.x + iso.y * 2) / 2
	cart_pos.y = - iso.x + cart_pos.x
	return cart_pos


func isometric_normalize(direction:Vector2)->Vector2:
	direction = direction.normalized()
	return direction * Vector2(1,0.6)
