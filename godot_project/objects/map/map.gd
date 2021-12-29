extends Node2D

"""
Represents a playable and editable map

Contains TILE_DATA and OBJECT_DATA

Tile Texture Size
32*44
"""

const TILE_X = 32
const TILE_Y = 16

enum Tiles { # these are saved in files
	EMPTY = -1,
	GRASS = 0,
	WALL = 1,
	SAND = 2,
	WATER = 3,
}
var TILE_DATA = {
		Tiles.EMPTY: {
				"name": "Empty",
				"tilemap_id": null, # tileset index of
				"solid": true, # not used yet (planning to use this instead of tilemap collision shape)
				"resets_ball": true, # maybe it doesnt work (sold and reset) 
				"texture_path":null, # for editor icon
				"layer": "all",
		},
		Tiles.GRASS: {
				"name": "Grass",
				"tilemap_id": null,
				"solid": false,
				"resets_ball": false,
				"friction": 1.0, 
				"texture_path":"res://objects/map/grass.png",
				"layer": "ground",
				},
		Tiles.WALL: {
				"name": "Wall",
				"tilemap_id": null,
				"solid": true,
				"resets_ball": false,
				"friction": 1.0, 
				"texture_path":"res://objects/map/wall.png",
				"layer": "walls",
		},
		Tiles.SAND: {
				"name": "Sand",
				"tilemap_id": null,
				"solid": false,
				"resets_ball": false,
				"friction": 4.0, 
				"texture_path":"res://objects/map/sand.png",
				"layer": "ground",
		},
		Tiles.WATER: {
				"name": "Water",
				"tilemap_id": null,
				"solid": false,
				"resets_ball": true,
				"friction": 1.0, 
				"texture_path":"res://objects/map/water.png",
				"layer": "ground",
		},
}

enum Objects {
	START = 0,
	FINISH = 1
}
const OBJECT_DATA = {
		Objects.START: {
				"name": "Spawn",
				"limit": 1, #only one
				"required": 1,
				"node_path":"res://objects/map_objects/start/Start.tscn",
				"texture_path":"res://objects/map_objects/start/start.png"
				},
		Objects.FINISH: {
				"name": "Finish",
				"limit": 4,
				"required": 1,
				"node_path":"res://objects/map_objects/finish/Finish.tscn",
				"texture_path":"res://objects/map_objects/finish/finish.png"
				},
}

var metadata = {
	"updated": false
}

onready var _tilemap_ground = get_node("TileMapGround")
onready var _tilemap_walls = get_node("TileMapWalls")
var MapTileset = preload("res://objects/map/map_tileset.tres")

var spawned_objects:Dictionary



func _ready():
	# Set tilemap_id's
	for i in TILE_DATA:
		var real_id = MapTileset.find_tile_by_name(TILE_DATA[i]["name"])
		TILE_DATA[i]["tilemap_id"] = real_id


#### Editor Actions

func editor_object_place(world_pos:Vector2,object_id:int):
	var cell = _world_to_map(world_pos)
	
	
	#dont spawn if cell already occupied
	if spawned_objects.keys().has(cell):
		Notifier.notify_editor("This Tile already has an object")
		return
	
	# object is in OBJECT_DATA
	if not OBJECT_DATA.keys().has(object_id):
		printerr("Object with id %s does not exist!"%object_id)
		return
	
	
	# check if the tile beneath is valid
	var tdata = TILE_DATA[_get_tile(cell)]
	
	if tdata["solid"] or tdata["resets_ball"]:
		Notifier.notify_editor("This object cant be placed on this tile")
		return
	
	#check limit
	var obj_data = OBJECT_DATA[object_id]
	if obj_data.has("limit"):
		var remaining = obj_data["limit"]
		for i in spawned_objects:
			if spawned_objects[i].OBJECT_ID == object_id:
				remaining -= 1
		if remaining <= 0:
			Notifier.notify_editor("Object limit reached")
			return
	
	_spawn_object(cell, object_id)


func editor_object_remove(world_pos:Vector2):
	var cell = _world_to_map(world_pos)

	if not spawned_objects.keys().has(cell):
		print("Note: cell %s has no object"%cell)
		return
	
	_remove_object(cell)


func editor_tile_change(world_pos:Vector2, id:int):
	var cell = _world_to_map(world_pos)
	
	if not TILE_DATA.keys().has(id):
		printerr("Tile with id %s does not exist!"%id)
	
	_set_tile(cell, id)
	
	if spawned_objects.keys().has(cell):
		var object_id = _get_object(cell).OBJECT_ID
		_remove_object(cell)
		editor_object_place(world_pos, object_id)
	


#### Match

func match_get_starting_position()->Vector2:
	for i in spawned_objects:
		if spawned_objects[i].OBJECT_ID == Objects.START:
			_get_object(i)
			return Vector2(_map_to_world(i).x,_map_to_world(i).y+TILE_Y/2)
	
	Notifier.notify_error("No Spawn Object found, defaulting to (0,0)")
	return Vector2()


#### Loading / Saving

func update_metadata(map_id:String, map_name:String, creator_user_id:String, creator_display_name:String):
	metadata.clear()
	metadata["name"] = map_name
	metadata["id"] = map_id
	metadata["creator_user_id"] = creator_user_id
	metadata["creator_display_name"] = creator_display_name
	var size = Vector2()
	size.x = _get_used_cells().max().x - _get_used_cells().min().x + 1
	size.y = _get_used_cells().max().y - _get_used_cells().min().y
	metadata["size"] = size
	Notifier.notify_debug("Calculated size is %s"%size, "Is this correct?")
	metadata["updated"] = true


func serialize()->String:
	assert(metadata["updated"]) # call update_metadata(...) before

	var mapdict := {
		"game_version": "",
		"tiles": {}, # vector keys are saved with var2str
		"objects": {}, # and need to be restored wit str2var
		"metadata": {
			"name": "",
			"id": "",
			"creator_user_id": "",
			"create_display_name": "",
			"size": Vector2(),
		}
	}
	
	var cells = _get_used_cells()
	for i in cells:
		mapdict["tiles"][var2str(i)] = _get_tile(i)
	
	# objects
	for i in spawned_objects:
		mapdict["objects"][var2str(i)] = spawned_objects[i].OBJECT_ID
	
	# metadata
	mapdict["metadata"] = metadata
	mapdict["metadata"].erase("updated")
	mapdict["game_version"] = Global.GAME_VERSION
	
	return JSON.print(mapdict)


func deserialize(jstring:String)->void:
	if metadata.has("id"):
		printerr("A map is already loaded")
		return
	
	var parse := JSON.parse(jstring)
	if parse.error != OK:
		Notifier.notify_error("Could not parse mapfile")
		return
	
	if parse.result["game_version"] != Global.GAME_VERSION:
		Notifier.notify_error("Could not load map created with different game version")
		return
	
	# cells
	for i in parse.result["tiles"]:
		var coord:Vector2 = str2var(i)
		var tile_id := int(parse.result["tiles"][i])

		if not TILE_DATA.has(tile_id):
			printerr("Mapfile contains unkown tile id: %s"%tile_id)
			assert(false)
			continue
		
		_set_tile(coord, tile_id)
		

	# objects
	for i in parse.result["objects"]:
		var object_id := int(parse.result["objects"][i])
		
		if not OBJECT_DATA.has(object_id):
			printerr("Mapfile contains unkown object id: %s"%object_id)
			assert(false)
			continue
		
		_spawn_object(str2var(i), object_id)
	
	#metadata
	metadata = parse.result["metadata"]
	metadata["updated"] = false
	Notifier.notify_game("Map \"%s\" loaded succesfully"%metadata["name"], "(ID %s)"%metadata["id"])


#### Internal Tile and Object interaction

func _set_tile(cell:Vector2, tile_id:int):
	if _get_tile(cell) != -1 and TILE_DATA[tile_id]["layer"] != "all": # clear other layers to only have one tile per coordinate across all tilemaps
		_set_tile(cell, Tiles.EMPTY)
		
	match TILE_DATA[tile_id]["layer"]:
			"ground":
				_tilemap_ground.set_cell(cell.x,cell.y,TILE_DATA[tile_id]["tilemap_id"])
			"walls":
				_tilemap_walls.set_cell(cell.x,cell.y,TILE_DATA[tile_id]["tilemap_id"])
			"all":
				_tilemap_walls.set_cell(cell.x,cell.y,TILE_DATA[tile_id]["tilemap_id"])
				_tilemap_ground.set_cell(cell.x,cell.y,TILE_DATA[tile_id]["tilemap_id"])
			_:
				printerr("TILE_DATA has unkown layer ", TILE_DATA[tile_id]["layer"])


func _get_tile(cell:Vector2)->int: # -> tile_id
	var tilemap_id := -1
	
	if _tilemap_ground.get_cellv(cell) != -1:
		tilemap_id = _tilemap_ground.get_cellv(cell)
	elif _tilemap_walls.get_cellv(cell) != -1:
		tilemap_id = _tilemap_walls.get_cellv(cell)
		
	for i in TILE_DATA:
		if TILE_DATA[i]["tilemap_id"] == tilemap_id:
			return i
	
	printerr("Tile at ", cell, "could not be determined (error! investiage _get_tile)")
	return -1


func _get_used_cells(): # -> vector array
	var used_cells = []
	used_cells.append_array(_tilemap_ground.get_used_cells())
	used_cells.append_array(_tilemap_walls.get_used_cells())
	return used_cells



func _spawn_object(cell:Vector2, id:int):
	var path = OBJECT_DATA[id]["node_path"]
	var obj = load(path).instance()
	var world_pos = _map_to_world(cell)
	obj.position = world_pos
	add_child(obj)
	spawned_objects[cell] = obj


func _get_object(cell:Vector2): # -> object ref
	return spawned_objects[cell]


func _remove_object(cell:Vector2):
	var obj = _get_object(cell)
	obj.visible = false
	obj.queue_free()
	spawned_objects.erase(cell)



func _world_to_map(world_pos:Vector2)->Vector2:
	return _tilemap_ground.world_to_map(world_pos)


func _map_to_world(cell:Vector2)->Vector2:
	return _tilemap_ground.map_to_world(cell)


#### Helper Functions

func get_cell_center(world_pos:Vector2)->Vector2:
	var cell = _world_to_map(world_pos)
	var snapped_pos = _map_to_world(cell)
	#snapped_pos.y -= TILE_Y/2 # center on cell
	return snapped_pos


func is_map_valid()->bool:
	# objects
	for id in OBJECT_DATA.keys():
		var limit = OBJECT_DATA[id]["limit"]
		var required = OBJECT_DATA[id]["required"]
		
		for j in spawned_objects:
			if spawned_objects[j].OBJECT_ID == id:
				limit -= 1
				required -= 1
		
		if limit < 0:
			Notifier.notify_editor("There are too many %s objects"%OBJECT_DATA[id]["name"], "Max %s of this object are allowed" %OBJECT_DATA[id]["limit"])
			return false
			
		if required > 0:
			Notifier.notify_editor("There are not enough %s objects"%OBJECT_DATA[id]["name"], "At least %s of this object are required" %OBJECT_DATA[id]["required"])
			return false
	
	return true


#### Setget


func get_tile_property(world_pos:Vector2, property:String):
	var tile_id = _get_tile(_world_to_map(world_pos))
	
	if not TILE_DATA[tile_id].has(property):
		printerr("Cell %s has no \"%s\" property"%[tile_id,property])
		return
	
	return TILE_DATA[tile_id][property]


func get_tile_id_at(world_pos:Vector2)->int:
	return _get_tile(_world_to_map(world_pos))


func get_tilemap_id(tile_id:int)->int:
	if not TILE_DATA.keys().has(tile_id):
		printerr("Could not find tile with id %s"%tile_id)
		return -1
	
	return TILE_DATA[tile_id]["tilemap_id"]
	
