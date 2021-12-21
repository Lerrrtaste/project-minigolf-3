extends Node2D

"""
Tile Size
32*44
"""

const TILE_X = 32
const TILE_Y = 16

var TILE_DATA = { # TODO refactor to use tile enum as key
		"empty": {
				"name": "Empty",
				"id":-1, # "tile id" for saving/loading
				"tilemap_id": null, # tileset index of
				"solid": true, # not used yet (planning to use this instead of tilemap collision shape)
				"ball_reset": true, # maybe it doesnt work (sold and reset) 
				"texture_path":null # for editor icon
		},
		"grass": {
				"name": "Grass",
				"id":0,
				"tilemap_id": null,
				"solid": false,
				"ball_reset": false,
				"friction": 1.0, 
				"texture_path":"res://objects/map/grass.png"
				},
		"wall": {
				"name": "Wall",
				"id":1,
				"tilemap_id": null,
				"solid": true,
				"ball_reset": false,
				"friction": 1.0, 
				"texture_path":"res://objects/map/wall.png"
		},
		"sand": {
				"name": "Sand",
				"id":2,
				"tilemap_id": null,
				"solid": false,
				"ball_reset": false,
				"friction": 4.0, 
				"texture_path":"res://objects/map/sand.png"
		},
		"water": {
				"name": "Water",
				"id":3,
				"tilemap_id": null,
				"solid": false,
				"ball_reset": true,
				"friction": 1.0, 
				"texture_path":"res://objects/map/water.png"
		},
}


const OBJECT_DATA = {
		"start": {
				"name": "Spawn",
				"id": 0,
				"limit": 1, #only one
				"scene_path":"res://objects/map_objects/start/Start.tscn",
				"texture_path":"res://objects/map_objects/start/start.png"
				},
		"finish": {
				"name": "Finish",
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


func _ready():
	# update tileset tile ids
	for i in TILE_DATA:
		var real_id = tilemap.tile_set.find_tile_by_name(i)
		TILE_DATA[i]["tilemap_id"] = real_id

#### Editor Actions

func editor_object_place(world_pos:Vector2,object_id):
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


func editor_tile_change(world_pos:Vector2, id:int):
	var cell = tilemap.world_to_map(world_pos)
	for i in TILE_DATA:
		if TILE_DATA[i]["id"] == id:
			tilemap.set_cell(cell.x,cell.y,TILE_DATA[i]["tilemap_id"])

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
		for j in TILE_DATA:
			if TILE_DATA[j]["tilemap_id"] == tilemap.get_cell(i.x,i.y):
				mapdict["cells"][var2str(i)] = TILE_DATA[j]["id"]
	
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
		for j in TILE_DATA:
			if TILE_DATA[j]["id"] == parse.result["cells"][i]:
				tilemap.set_cell(coord.x,coord.y,TILE_DATA[j]["tilemap_id"])
				break
		
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


#### Setget

func get_cell_position(world_pos:Vector2)->Vector2:
	return tilemap.world_to_map(world_pos)


func get_tile_friction(world_pos:Vector2)->float:
	var cell = tilemap.get_cellv(tilemap.world_to_map(world_pos))
	for i in TILE_DATA:
		if TILE_DATA[i]["tilemap_id"] == cell:
			if not TILE_DATA[i].has("friction"):
				printerr("Cell %s has no friction property"%i)
				return 0.0
			return TILE_DATA[i]["friction"]
	printerr("Cell %s not found in TILE_DATA"%cell)
	return 0.0


func get_tile_resets_ball(world_pos:Vector2)->bool:
	var cell = tilemap.get_cellv(tilemap.world_to_map(world_pos))
	for i in TILE_DATA:
		if TILE_DATA[i]["tilemap_id"] == cell:
			if not TILE_DATA[i].has("ball_reset"):
				printerr("Cell %s has no ball_reset property"%i)
				return false
			return TILE_DATA[i]["ball_reset"]
	printerr("Cell %s not found in TILE_DATA"%cell)
	return false


func get_tile_solid(world_pos:Vector2)->bool:
	var cell = tilemap.get_cellv(tilemap.world_to_map(world_pos))
	for i in TILE_DATA:
		if TILE_DATA[i]["tilemap_id"] == cell:
			if not TILE_DATA[i].has("solid"):
				printerr("Cell %s has no solid property"%i)
				return false
			return TILE_DATA[i]["solid"]
	printerr("Cell %s not found in TILE_DATA"%cell)
	return false


func get_cell_from_world(world_pos:Vector2)->Vector2:
	return tilemap.world_to_map(world_pos)


func get_tile_id_at(world_pos:Vector2)->int:
	return tilemap.get_cellv(tilemap.world_to_map(world_pos))


func get_tilemap_id(tile_id:int)->int:
	for i in TILE_DATA:
		if TILE_DATA[i]["id"] == tile_id:
			return TILE_DATA[i]["tilemap_id"]
	printerr("Could not find tile with id %s"%tile_id)
	return -1
