extends Node2D

"""
Represents a playable and editable map

Uses map_data.gd

Tile Texture Size
32*44
"""

signal loaded
signal loading_failed

const TILE_X = 32
const TILE_Y = 16

var metadata = {
	"updated": false
}


onready var _tilemap_templates = { # dict order is node order
	"walls": get_node("TmTemplateWalls"),
	"ground": get_node("TmTemplateGround"), # default for unspecified layers
	"oneway_walls": get_node("TmTemplateOnewayWalls")
}
var tilemap_layers := {}

#var MapTileset = preload("res://objects/map/map_tileset.tres")

var spawned_objects:Dictionary


func _ready():
	# instance tilemaps
	for i in _tilemap_templates:
		var inst = _tilemap_templates[i].duplicate()
		add_child(inst)
		tilemap_layers[i] = inst

#### Editor Actions

func editor_object_place(world_pos:Vector2,object_id:int):
	var cell = world_to_map(world_pos)
	
	
	#dont spawn if cell already occupied
	if spawned_objects.keys().has(cell):
		Notifier.notify_editor("This Tile already has an object")
		return
	
	# object is in OBJECT_DATA
	if MapData.get_object_dict(object_id) == null:
		printerr("Object with id %s does not exist!"%object_id)
		return
	
	
	# check if the tile beneath is valid
	var tile_id =_get_tile(cell)
	var solid = MapData.get_tile_property(tile_id, "solid")
	var resets_ball = MapData.get_tile_property(tile_id, "resets_ball")
	var resets_ball_to_start = MapData.get_tile_property(tile_id, "resets_ball_to_start")
	if solid or resets_ball or resets_ball_to_start:
		Notifier.notify_editor("This object cant be placed on this tile")
		return
	
	#check limit
	var obj_data = MapData.get_object_dict(object_id)
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
	var cell = world_to_map(world_pos)

	if not spawned_objects.keys().has(cell):
		print("Note: cell %s has no object"%cell)
		return
	
	_remove_object(cell)


func editor_tile_change(world_pos:Vector2, id:int):
	var cell = world_to_map(world_pos)
	
	if MapData.get_tile_dict(id) == null:
		printerr("Tile with id %s does not exist!"%id)
	
	_set_tile(cell, id)
	
	if spawned_objects.keys().has(cell):
		var object_id = _get_object(cell).OBJECT_ID
		_remove_object(cell)
		editor_object_place(world_pos, object_id)



#### Match

func match_get_starting_position()->Vector2:
	for i in spawned_objects:
		if spawned_objects[i].OBJECT_ID == MapData.Objects.START:
			_get_object(i)
			return Vector2(map_to_world(i).x,map_to_world(i).y+TILE_Y/2)
	
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
	size.y = _get_used_cells().max().y - _get_used_cells().min().y + 1
	metadata["size"] = size
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
		Notifier.notify_error("A map is already loaded")
		emit_signal("loading_failed")
		return
	
	var parse := JSON.parse(jstring)
	if parse.error != OK:
		Notifier.notify_error("Could not parse mapfile")
		emit_signal("loading_failed")
		return
	
	if parse.result["game_version"] != Global.GAME_VERSION:
		Notifier.notify_error("Could not load map created with different game version")
		emit_signal("loading_failed")
		return
	
	# cells
	for i in parse.result["tiles"]:
		var coord:Vector2 = str2var(i)
		var tile_id := int(parse.result["tiles"][i])

		if MapData.get_tile_dict(tile_id) == null:
			printerr("Mapfile contains unkown tile id: %s"%tile_id)
			assert(false)
			continue
		
		_set_tile(coord, tile_id)
		

	# objects
	for i in parse.result["objects"]:
		var object_id := int(parse.result["objects"][i])
		
		if MapData.get_object_dict(object_id) == null:
			printerr("Mapfile contains unkown object id: %s"%object_id)
			assert(false)
			continue
		
		_spawn_object(str2var(i), object_id)
	
	#metadata
	metadata = parse.result["metadata"]
	metadata["updated"] = false
	Notifier.notify_game("Map \"%s\" loaded succesfully"%metadata["name"], "(ID %s)"%metadata["id"])
	emit_signal("loaded")


#### Internal Tile and Object interaction

func _set_tile(cell:Vector2, tile_id:int):
	var layer = MapData.get_tile_property(tile_id,"layer")
	var tilemap_id = MapData.get_tile_property(tile_id, "tilemap_id")
	if _get_tile(cell) != -1 and layer != "all": # clear other layers to only have one tile per coordinate across all tilemaps
		_set_tile(cell, MapData.Tiles.EMPTY)
	
	# create tilemap layer
	if not tilemap_layers.has(layer):
		Notifier.notify_error("Tile has unkown layer: "+ layer, "Using Ground Template TM")
		var inst = _tilemap_templates["ground"].duplicate()
		add_child(inst)
		tilemap_layers[layer] = inst
	
	tilemap_layers[layer].set_cell(cell.x,cell.y,tilemap_id)


func _get_tile(cell:Vector2)->int: # -> tile_id
	var tilemap_id := -1
	
	for i in tilemap_layers:
		tilemap_id = tilemap_layers[i].get_cellv(cell)
		if tilemap_id != -1:
			break
		
	for i in MapData.Tiles.values():
		if tilemap_id == MapData.get_tile_property(i, "tilemap_id"):
			return i
	
	printerr("Tile at ", cell, "could not be determined (error! investiage _get_tile)")
	return -1

# Return Tilemap node of tile at cell
# For collision blacklisting

func _get_used_cells(): # -> vector array
	var used_cells = []
	for i in tilemap_layers:
		used_cells.append_array(tilemap_layers[i]._get_used_cells())
	return used_cells


func _spawn_object(cell:Vector2, id:int):
	var path = MapData.get_object_property(id,"node_path")
	var obj = load(path).instance()
	var world_pos = map_to_world(cell)
	obj.position = world_pos
	add_child(obj)
	spawned_objects[cell] = obj


# returns object ref or null
func _get_object(cell:Vector2): # -> object ref
	if not spawned_objects.has(cell):
		return null
	return spawned_objects[cell]


func _remove_object(cell:Vector2):
	var obj = _get_object(cell)
	obj.visible = false
	obj.queue_free()
	spawned_objects.erase(cell)



#### Helper Functions

# forwards to TilemapGround
func world_to_map(world_pos:Vector2)->Vector2:
	return _tilemap_templates["ground"].world_to_map(world_pos)


# forwards to TilemapGround
func map_to_world(cell:Vector2)->Vector2:
	return _tilemap_templates["ground"].map_to_world(cell)

func get_tilemap_node_at_cell(cell:Vector2)->TileMap:
	for i in tilemap_layers:
		if tilemap_layers[i].get_cellv(cell) != -1:
			return tilemap_layers[i]
	return null

# Return object id at world_pos or -1
func get_object_id_at(world_pos:Vector2)->int:
	var obj = _get_object(world_to_map(world_pos))
	
	if obj == null or not "OBJECT_ID" in obj:
		return MapData.Objects.NONE # -1
	
	return obj.OBJECT_ID

# 
func get_cell_center(world_pos:Vector2)->Vector2:
	var cell = world_to_map(world_pos)
	var snapped_pos = map_to_world(cell)
	return snapped_pos


# Checks mobject limits (only this for now)
func is_map_valid()->bool:
	# objects
	for id in MapData.Objects.values():
		if id == MapData.Objects.NONE:
			continue
		var limit = MapData.get_object_property(id,"limit")
		var required = MapData.get_object_property(id,"required")
		
		for j in spawned_objects:
			if spawned_objects[j].OBJECT_ID == id:
				limit -= 1
				required -= 1
		
		if limit < 0:
			Notifier.notify_editor("There are too many %s objects"% MapData.get_object_property(id,"name"), "Max %s of this object are allowed" % limit)
			return false
			
		if required > 0:
			Notifier.notify_editor("There are not enough %s objects"%MapData.get_object_property(id,"name"), "At least %s of this object are required" % required)
			return false
	
	return true


#### Setget


func get_tile_property(world_pos:Vector2, property:String):
	var tile_id = _get_tile(world_to_map(world_pos))
	return MapData.get_tile_property(tile_id,property)


func get_tile_id_at(world_pos:Vector2)->int:
	return _get_tile(world_to_map(world_pos))


func get_tile_id_at_cell(cell:Vector2)->int:
	return _get_tile(cell)

