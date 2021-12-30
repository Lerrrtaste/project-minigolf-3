extends Node2D

const SCROLL_SPEED = 3

onready var bg1 = get_node("Bg1")
onready var bg2 = get_node("Bg2")

var scroll_progress := 0


func _ready():
	bg1.position.x -= bg1.texture.get_width()


func _process(delta):
	scroll_progress += SCROLL_SPEED * delta
	bg1.position.x += SCROLL_SPEED * delta
	bg2.position.x += SCROLL_SPEED * delta
	
	if bg1.position.x >= bg1.texture.get_width():
		bg1.position.x = bg2.position.x-bg1.texture.get_width()
		
	if bg2.position.x >= bg2.texture.get_width():
		bg2.position.x = bg1.position.x-bg2.texture.get_width()
