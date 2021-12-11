extends Node2D

"""
Tile Size
32*44
"""
const TILE_X = 16
const TILE_Y = 16

var grid:Vector2

func _ready():
	pass

func editor_add_object(grid_coord:Vector2,object_id:int):
	pass


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
