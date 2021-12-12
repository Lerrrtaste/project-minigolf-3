extends Node2D

"""
Tile Size
32*44
"""
const TILE_X = 32
const TILE_Y = 16

var map_objects:Dictionary

 
const TILE_DATA = { #id has to be the index in the tilemap
	"empty": {"id":-1, "texture_path":null},
	"grass": {"id":0, "texture_path":"res://objects/map/grass.png"},
	"wall": {"id":1, "texture_path":"res://objects/map/wall.png"},
	"dirt": {"id":2, "texture_path":null},
	"water": {"id":3, "texture_path":null},
}
onready var tilemap = get_node("TileMap")


func _ready():
	pass


func _process(delta):
	pass


func editor_add_object(world_pos:Vector2,object_id:int):
	pass


func editor_tile_remove(world_pos:Vector2):
	pass


func editor_cursor_show(world_pos:Vector2):
	pass


func editor_cursor_hide(world_pos:Vector2):
	pass


func _unhandled_input(event):
	if event is InputEventMouse:
		pass


#### Loading / Saving





#### Helper Functions

func snap_world_to_grid(pos:Vector2)->Vector2:
	var grid = Vector2()
	grid.x = floor(pos.x/TILE_X) * TILE_X
	grid.y = floor(pos.y/TILE_Y) * TILE_Y
	return grid

func cartesian_to_isometric(cart:Vector2)->Vector2:
	# Cartesian to isometric:
	var iso = Vector2()
	iso.x = cart.x - cart.y
	iso.y = (cart.x + cart.y) / 2
	return iso

func isometric_to_cartesion(iso:Vector2)->Vector2:
	# Isometric to Cartesian:
	var cart = Vector2()
	cart.x = (2 * iso.y + iso.x) / 2
	cart.y = (2 * iso.y - iso.x) / 2
	return cart
