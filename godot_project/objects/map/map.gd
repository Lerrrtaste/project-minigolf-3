extends Node2D

"""
Tile Size
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
var TILE_DATA = { # TODO refactor to use tile enum as key
		Tiles.EMPTY: {
				"name": "Empty",
				"tilemap_id": null, # tileset index of
				"solid": true, # not used yet (planning to use this instead of tilemap collision shape)
				"ball_reset": true, # maybe it doesnt work (sold and reset) 
				"texture_path":null # for editor icon
		},
		Tiles.GRASS: {
				"name": "Grass",
				"tilemap_id": null,
				"solid": false,
				"ball_reset": false,
				"friction": 1.0, 
				"texture_path":"res://objects/map/grass.png"
				},
		Tiles.WALL: {
				"name": "Wall",
				"tilemap_id": null,
				"solid": true,
				"ball_reset": false,
				"friction": 1.0, 
				"texture_path":"res://objects/map/wall.png"
		},
		Tiles.SAND: {
				"name": "Sand",
				"tilemap_id": null,
				"solid": false,
				"ball_reset": false,
				"friction": 4.0, 
				"texture_path":"res://objects/map/sand.png"
		},
		Tiles.WATER: {
				"name": "Water",
				"tilemap_id": null,
				"solid": false,
				"ball_reset": true,
				"friction": 1.0, 
				"texture_path":"res://objects/map/water.png"
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
				"scene_path":"res://objects/map_objects/start/Start.tscn",
				"texture_path":"res://objects/map_objects/start/start.png"
				},
		Objects.FINISH: {
				"name": "Finish",
				"limit": 4,
				"required": 1,
				"scene_path":"res://objects/map_objects/finish/Finish.tscn",
				"texture_path":"res://objects/map_objects/finish/finish.png"
				},
}

var metadata = {
	"updated": false
}

var spawned_objects:Dictionary
onready var tilemap = get_node("TileMap")


func _ready():
	# update tileset tile ids
	for i in TILE_DATA:
		var real_id = tilemap.tile_set.find_tile_by_name(TILE_DATA[i]["name"])
		TILE_DATA[i]["tilemap_id"] = real_id

#### Editor Actions

func editor_object_place(world_pos:Vector2,object_id:int):
	var cell = tilemap.world_to_map(world_pos)
	
	# TODO check if outside of map border
	
	#dont spawn if cell already occupied
	if spawned_objects.keys().has(cell):
		Notifier.notify_editor("This Tile already has an object")
		return
	
	# object is in OBJECT_DATA
	if not OBJECT_DATA.keys().has(object_id):
		printerr("Object with id %s does not exist!"%object_id)
		return
	
	
	# check if the tile beneath is valid
	var tilemap_id = tilemap.get_cellv(cell)
	var tdata
	
	for i in TILE_DATA:
		if TILE_DATA[i]["tilemap_id"] == tilemap_id:
			tdata = TILE_DATA[i]
	
	if tdata["solid"] or tdata["ball_reset"]:
		Notifier.notify_editor("This object cant be placed on this tile")
		return
	
	# find object data
	var obj_data = OBJECT_DATA[object_id]
	var path = obj_data["scene_path"]
	
	#check limit
	if obj_data.has("limit"):
		var remaining = obj_data["limit"]
		for i in spawned_objects:
			if spawned_objects[i].OBJECT_ID == object_id:
				remaining -= 1
		if remaining <= 0:
			Notifier.notify_editor("Object limit reached")
			return
	
	var obj = load(path).instance()
	var snapped_pos = tilemap.map_to_world(cell)
	#snapped_pos.y -= TILE_Y/2 # center on cell
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
	
	if not TILE_DATA.keys().has(id):
		printerr("Tile with id %s does not exist!"%id)
		
	var tilemap_id = TILE_DATA[id]["tilemap_id"]
	tilemap.set_cell(cell.x,cell.y,tilemap_id)

	#TODO remove potential object on this tile


#### Match

func match_get_starting_position()->Vector2:
	for i in spawned_objects:
		if spawned_objects[i].OBJECT_ID == Objects.START:
			return i
	
	Notifier.notify_error("No Spawn Object found, defaulting to (0,0)")
	return Vector2()


#### Loading / Saving

func update_metadata(map_id:String, map_name:String, creator_user_id:String):
	metadata.clear()
	metadata["name"] = map_name
	metadata["id"] = map_id
	metadata["creator_user_id"] = creator_user_id
	metadata["size"] = tilemap.get_used_rect().size
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
			"size": Vector2(),
		}
	}
	
	# tile
	var cells = tilemap.get_used_cells()
	for i in cells:
		for j in TILE_DATA:
			if TILE_DATA[j]["tilemap_id"] == tilemap.get_cell(i.x,i.y):
				mapdict["tiles"][var2str(i)] = j
	
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
		
		tilemap.set_cell(coord.x,coord.y,TILE_DATA[tile_id]["tilemap_id"])
	
	# objects
	for i in parse.result["objects"]:
		var object_id := int(parse.result["objects"][i])
		var inst
		
		if not OBJECT_DATA.has(object_id):
			printerr("Mapfile contains unkown object id: %s"%object_id)
			assert(false)
			continue
		
		inst = load(OBJECT_DATA[object_id]["scene_path"]).instance()
		inst.position = str2var(i)
		add_child(inst)
		spawned_objects[str2var(i)] = inst
	
	#metadata
	metadata = parse.result["metadata"]
	metadata["updated"] = false
	Notifier.notify_game("Map \"%s\" loaded succesfully"%metadata["name"], "(ID %s)"%metadata["id"])


#### Helper Functions

func get_center_cell_position(world_pos:Vector2)->Vector2:
	var cell = tilemap.world_to_map(world_pos)
	var snapped_pos = tilemap.map_to_world(cell)
	#snapped_pos.y -= TILE_Y/2 # center on cell
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

func get_cell_position(world_pos:Vector2)->Vector2:
	return tilemap.world_to_map(world_pos)


func get_tile_friction(world_pos:Vector2)->float:
	var tilemap_id = tilemap.get_cellv(tilemap.world_to_map(world_pos))
	for i in TILE_DATA:
		if TILE_DATA[i]["tilemap_id"] == tilemap_id:
			if not TILE_DATA[i].has("friction"):
				printerr("Cell %s has no friction property"%i)
				return 0.0
			return TILE_DATA[i]["friction"]
	printerr("Cell %s not found in TILE_DATA"%tilemap_id)
	return 0.0


func get_tile_resets_ball(world_pos:Vector2)->bool:
	var tilemap_id = tilemap.get_cellv(tilemap.world_to_map(world_pos))
	for i in TILE_DATA:
		if TILE_DATA[i]["tilemap_id"] == tilemap_id:
			if not TILE_DATA[i].has("ball_reset"):
				printerr("Cell %s has no ball_reset property"%i)
				return false
			return TILE_DATA[i]["ball_reset"]
	printerr("Cell %s not found in TILE_DATA"%tilemap_id)
	return false


func get_tile_solid(world_pos:Vector2)->bool:
	var tilemap_id = tilemap.get_cellv(tilemap.world_to_map(world_pos))
	for i in TILE_DATA:
		if TILE_DATA[i]["tilemap_id"] == tilemap_id:
			if not TILE_DATA[i].has("solid"):
				printerr("Cell %s has no solid property"%i)
				return false
			return TILE_DATA[i]["solid"]
	printerr("Cell %s not found in TILE_DATA"%tilemap_id)
	return false


func get_cell_from_world(world_pos:Vector2)->Vector2:
	return tilemap.world_to_map(world_pos)


func get_tilemap_id_at(world_pos:Vector2)->int:
	return tilemap.get_cellv(tilemap.world_to_map(world_pos))


func get_tilemap_id(tile_id:int)->int:
	if not TILE_DATA.keys().has(tile_id):
		printerr("Could not find tile with id %s"%tile_id)
		return -1
	
	return TILE_DATA[tile_id]["tilemap_id"]
	
