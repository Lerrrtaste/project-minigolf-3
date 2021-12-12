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

const OBJECT_DATA = {
	"start": {"id":0, "scene_path":"res://objects/map_objects/finish/Finish.tscn", "texture_path":"res://objects/map_objects/finish/finish.png"},
	"finish": {"id":1, "scene_path":"res://objects/map_objects/start/Start.tscn", "texture_path":"res://objects/map_objects/start/start.png"},
}
var spawned_objects:Dictionary

func _ready():
	pass


func _process(delta):
	pass

func _unhandled_input(event):
	if event is InputEventMouse:
		pass


func spawn_map()->void:
	pass


#### Editor Actions

func editor_object_place(world_pos:Vector2,object_id:int):
	var cell = tilemap.world_to_map(world_pos)
	
	if spawned_objects.keys().has(cell):
		return
	
	var obj
	for i in OBJECT_DATA:
		if OBJECT_DATA[i]["id"] == object_id:
			obj = load(OBJECT_DATA[i]["scene_path"]).instance()
	var snapped_pos = tilemap.map_to_world(cell)
	snapped_pos.y -= TILE_Y/2 # center on cell
	obj.position = snapped_pos
	add_child(obj)
	spawned_objects[cell] = obj


func editor_object_remove(world_pos:Vector2):
	var cell = tilemap.world_to_map(world_pos)
	
	if not spawned_objects.keys().has(cell):
		return
		
	var obj = spawned_objects[cell]
	obj.visible = false
	obj.set_process(false)
	obj.queue_free()
	spawned_objects.erase(cell)


func editor_tile_change(world_pos:Vector2, tile_id:int):
	var cell = tilemap.world_to_map(world_pos)
	tilemap.set_cell(cell.x,cell.y,tile_id)


#### Loading / Saving

func serialize()->String:
	return ""

func deserialize()->String:
	return ""

#### Helper Functions

func get_center_cell_position(world_pos:Vector2)->Vector2:
	var cell = tilemap.world_to_map(world_pos)
	var snapped_pos = tilemap.map_to_world(cell)
	snapped_pos.y -= TILE_Y/2 # center on cell
	return snapped_pos

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
