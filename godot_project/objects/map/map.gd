extends Node2D

"""
Tile Size
32*44
"""

const TILE_X = 32
const TILE_Y = 16

const TILE_DATA = { #id has to be the index in the tilemap
	"empty": {"id":-1, "texture_path":null},
	"grass": {"id":0, "texture_path":"res://objects/map/grass.png"},
	"wall": {"id":1, "texture_path":"res://objects/map/wall.png"},
	"dirt": {"id":2, "texture_path":null},
	"water": {"id":3, "texture_path":null},
}

const OBJECT_DATA = {
		"start": {
				"id": 0,
				"limit": 1, #only one
				"scene_path":"res://objects/map_objects/start/Start.tscn",
				"texture_path":"res://objects/map_objects/start/start.png"
				},
		"finish": {
				"id": 1,
				"limit": 1,
				"scene_path":"res://objects/map_objects/finish/Finish.tscn",
				"texture_path":"res://objects/map_objects/finish/finish.png"
				},
}

var metadata = {
	"name": null,
	"id": null,
	"creator_id": null,
	"size": null,
}

var spawned_objects:Dictionary
onready var tilemap = get_node("TileMap")



#### Editor Actions

func editor_object_place(world_pos:Vector2,object_id:int):
	var cell = tilemap.world_to_map(world_pos)
	
	# TODO check if outside of map border
	
	#dont spawn if cell already occupied
	if spawned_objects.keys().has(cell):
		return
	
	var path
	var remaining
	
	 # find object data
	for i in OBJECT_DATA:
		if OBJECT_DATA[i]["id"] == object_id:
			path = OBJECT_DATA[i]["scene_path"]
			
			#check limit
			if OBJECT_DATA[i].has("limit"):
				remaining = OBJECT_DATA[i]["limit"]
				for j in spawned_objects:
					if spawned_objects[j].OBJECT_ID == object_id:
						remaining -= 1
			
			break
	
	#spawn if within limit
	if remaining > 0:
		var obj = load(path).instance()
		var snapped_pos = tilemap.map_to_world(cell)
		snapped_pos.y -= TILE_Y/2 # center on cell
		obj.position = snapped_pos
		add_child(obj)
		spawned_objects[snapped_pos] = obj


func editor_object_remove(world_pos:Vector2):
	var cell = tilemap.world_to_map(world_pos)
	var snapped_pos = tilemap.map_to_world(cell)
	snapped_pos.y -= TILE_Y/2 # center on cell

	if not spawned_objects.keys().has(snapped_pos):
		print("Note: %s has no object"%snapped_pos)
		return
		
	var obj = spawned_objects[snapped_pos]
	obj.visible = false
	obj.set_process(false)
	obj.queue_free()
	spawned_objects.erase(snapped_pos)


func editor_tile_change(world_pos:Vector2, tile_id:int):
	var cell = tilemap.world_to_map(world_pos)
	tilemap.set_cell(cell.x,cell.y,tile_id)
	
	#TODO remove potential object on this tile


#### Match

func match_get_starting_position()->Vector2:
	for i in spawned_objects:
		if spawned_objects[i].OBJECT_ID == OBJECT_DATA["start"]["id"]:
			return i
	
	printerr("No Startpoint found, defaulting to (0,0)")
	return Vector2()

#### Loading / Saving

func serialize()->String:
	assert(metadata["id"] != null) # should be set by editor
	
	var mapdict := {
		"game_version": "",
		"cells": {}, # vector keys are saved with var2str
		"objects": {}, # and need to be restored wit str2var
		"metadata": {
			"MapName": "",
			"MapId": "",
			"CreatorUserId": "",
			"Size": Vector2(),
		}
	}
	
	# tile
	var cells = tilemap.get_used_cells()
	for i in cells:
		mapdict["cells"][var2str(i)] = tilemap.get_cell(i.x,i.y)
	
	# objects
	for i in spawned_objects:
		mapdict["objects"][var2str(i)] = spawned_objects[i].OBJECT_ID
	
	# metadata
	mapdict["metadata"] = metadata
	mapdict["game_version"] = Global.GAME_VERSION
	
	return JSON.print(mapdict)


func deserialize(jstring:String)->void:
	if not metadata["id"] == null:
		printerr("A map is already loaded")
		return
	
	var parse := JSON.parse(jstring)
	if parse.error != OK:
		printerr("Could not parse mapfile")
		return
	
	if parse.result["game_version"] != Global.GAME_VERSION:
		printerr("Could not load map created with different game version")
		return
	
	# cells
	for i in parse.result["cells"]:
		var coord:Vector2 = str2var(i)
		tilemap.set_cell(coord.x,coord.y,parse.result["cells"][i])
		
	# objects
	for i in parse.result["objects"]:
		var object_id = parse.result["objects"][i]
		var inst
		for j in OBJECT_DATA:
			if OBJECT_DATA[j]["id"] == object_id:
				inst = load(OBJECT_DATA[j]["scene_path"]).instance()
				break
		inst.position = str2var(i)
		add_child(inst)
		spawned_objects[str2var(i)] = inst
	
	#metadata
	metadata = parse.result["metadata"]
	
	print("Map \"%s\" (ID %s) loaded succesfully"%[metadata["name"],metadata["id"]])


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

#
#func is_loaded()->bool:
#	return (not metadata["id"] == null)

#
#func get_map_size()->Vector2:
#	var size
#	size = tilemap.get_used_rect().size
#	size.x *= TILE_X
#	size.y *= TILE_Y
#	print(size)
#	return size
#
#func get_origin_cell_worldpos()->Vector2:
#	print(tilemap.get_used_rect().position)
#	return tilemap.map_to_world(tilemap.get_used_rect().position)
