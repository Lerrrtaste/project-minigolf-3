extends Node2D

var stroke_ready := true
var stroke_force_max := 400
var stroke_distance_max := 150

onready var ball = $Ball2


func _ready():
	pass # Replace with function body.


func _process(delta):
	update()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if stroke_ready:
				var strength = min(get_local_mouse_position().distance_to(ball.position),stroke_distance_max) / stroke_distance_max
				var force = stroke_force_max * strength * (get_local_mouse_position()-ball.position).normalized()
				ball.impact(force)


func _draw():
	# draw stroke as line
	if stroke_ready:
		var c = "black"
		if get_local_mouse_position().distance_to(ball.position) >= stroke_distance_max:
			c = "red"
		draw_line(ball.position, get_local_mouse_position(), ColorN(c), 3.0, true)
