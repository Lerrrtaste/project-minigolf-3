extends Node2D

## Simple scrolling background
##
## Just works out of the box.

## Speed of x-speed per second
const SCROLL_SPEED = 3

@onready var _bg1 = get_node("Bg1")
@onready var _bg2 = get_node("Bg2")

var _scroll_progress := 0


func _ready():
	_bg1.position.x -= _bg1.texture.get_width()


func _process(delta):
	_scroll_progress += SCROLL_SPEED * delta
	_bg1.position.x += SCROLL_SPEED * delta
	_bg2.position.x += SCROLL_SPEED * delta
	
	if _bg1.position.x >= _bg1.texture.get_width():
		_bg1.position.x = _bg2.position.x-_bg1.texture.get_width()
		
	if _bg2.position.x >= _bg2.texture.get_width():
		_bg2.position.x = _bg1.position.x-_bg2.texture.get_width()
