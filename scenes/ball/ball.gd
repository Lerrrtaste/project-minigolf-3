extends KinematicBody2D


# physics https://www.tutelman.com/golf/swing/index.php

var velocity := Vector2()
var stroke_force_max := 20
var friction := 0.98 #later based on ground type
var stroke_ready := true

var current_collision:KinematicCollision2D

func _ready():
	pass # Replace with function body.

func _process(delta):
	update()
	
	stroke_ready = velocity.length() < 1.0

func _physics_process(delta)->void:
	move(velocity*delta)
	velocity.x *= friction
	velocity.y *= friction


func move(movement:Vector2)->void:
	var collision = move_and_collide(velocity)
	
	# kollidiert nicht
	if !is_instance_valid(collision):
		return
	
	_collide(collision)


func _collide(collision:KinematicCollision2D):
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
	if collision.remainder.length() != 0:
		move(collision.remainder)


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if stroke_ready:
				velocity = get_local_mouse_position().clamped(stroke_force_max)
			#apply_central_impulse(get_local_mouse_position().rotated(rotation))

func reflect_vector(vector:Vector2, normal:Vector2)->Vector2:
	assert(normal.is_normalized())
	return vector - 2 * vector.dot(normal) * normal

func _draw():
	if stroke_ready:
		draw_line(Vector2(), get_local_mouse_position(), ColorN("red"), 3.0, true)
