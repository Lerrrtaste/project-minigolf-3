extends Node2D

onready var map = $Map


func _ready():
	map.load_from_coursedata(packed_map)
	map.set_mode_editing()

