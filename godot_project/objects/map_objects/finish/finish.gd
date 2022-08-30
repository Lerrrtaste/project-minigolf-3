extends Node2D

const OBJECT_ID = 1

func _ready():
	pass

func _on_Area2D_body_entered(body:Node):
	if body.has_method("reached_finish"):
		body.reached_finish()
