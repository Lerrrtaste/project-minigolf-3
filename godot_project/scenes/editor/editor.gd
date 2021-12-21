extends Node2D

onready var map = get_node("Map")

onready var select_tile = get_node("CanvasLayer/UI/ContainerMapEdit/SelectTile")
onready var select_tool = get_node("CanvasLayer/UI/ContainerMapEdit/SelectTool")
onready var select_object = get_node("CanvasLayer/UI/ContainerMapEdit/SelectObject")

onready var tilemap_cursor = get_node("Map/TileMapCursor")
onready var camera_editor = get_node("CameraEditor")
onready var line_border = get_node("Map/LineBorder")
onready var edit_map_name_save = get_node("CanvasLayer/UI/BtnSave/EditMapName")
onready var select_map_load = get_node("CanvasLayer/UI/BtnLoad/SelectLoad")
onready var btn_save = get_node("CanvasLayer/UI/BtnSave")
onready var btn_load = get_node("CanvasLayer/UI/BtnLoad")
var show_cursor := true
onready var spr_object_cursor = get_node("SprObjectCursor")
var selected_cell := Vector2()
var tool_dragged := false

enum Tools {
	tile_place,
	tile_remove
	object_place,
	object_remove,
}

const TOOL_DATA = {
	Tools.tile_place: {
		"name": "Place Tile",
		"icon_path": "res://scenes/editor/editor_tool1.png",
		"show_tilemap_cursor": true,
		"show_tile_select": true,
		"show_object_cursor": false,
		"show_object_select": false,
	},
	Tools.tile_remove: {
		"name": "Remove Tile",
		"icon_path": "res://scenes/editor/editor_tool2.png",
		"show_tilemap_cursor": true,
		"show_tile_select": false,
		"show_object_cursor": false,
		"show_object_select": false,
	},
	Tools.object_place: {
		"name": "Place Object",
		"icon_path": "res://scenes/editor/editor_tool3.png",
		"show_tilemap_cursor": false,
		"show_tile_select": false,
		"show_object_cursor": true,
		"show_object_select": true,
	},
	Tools.object_remove: {
		"name": "Remove Object",
		"icon_path": "res://scenes/editor/editor_tool4.png",
		"show_tilemap_cursor": false,
		"show_tile_select": false,
		"show_object_cursor": false,
		"show_object_select": false,
	},
}


func _ready():
	# center camera
	camera_editor.position = OS.window_size/2
	
	# populate tile dropdown
	for i in map.TILE_DATA:
		var tile_id = map.TILE_DATA[i]["id"]
		if map.TILE_DATA[i]["texture_path"] != null:
			var icon = load(map.TILE_DATA[i]["texture_path"])
			select_tile.add_icon_item(icon)
		else:
			select_tile.add_item(map.TILE_DATA[i]["name"])
		select_tile.set_item_metadata(select_tile.get_item_count()-1, tile_id)
		select_tile.set_item_tooltip(select_tile.get_item_count()-1, map.TILE_DATA[i]["name"])
	
	# populate object dropdown
	for i in map.OBJECT_DATA:
		var object_id = map.OBJECT_DATA[i].id
		if map.OBJECT_DATA[i]["texture_path"] != null:
			var icon = load(map.OBJECT_DATA[i]["texture_path"])
			select_object.add_icon_item(icon)
		else:
			select_object.add_item(map.OBJECT_DATA[i]["name"])
		select_object.set_item_metadata(select_object.get_item_count()-1,object_id)
	
	# populate tool dropdown
	for i in TOOL_DATA:
		select_tool.add_icon_item(load(TOOL_DATA[i]["icon_path"]))
		select_tool.set_item_metadata(select_tool.get_item_count()-1,i)
		select_tool.set_item_tooltip(select_tool.get_item_count()-1,TOOL_DATA[i]["name"])

	
	# populate load dropdown
	var map_files = []
	var dir = Directory.new()
	dir.open(Global.MAPFOLDER_PATH)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif file.ends_with(".map"):
			map_files.append(file)
	dir.list_dir_end()
	
	for i in map_files:
		var file = File.new()
		file.open(Global.MAPFOLDER_PATH + i, File.READ)
		var map_jstring = file.get_as_text()
		file.close()

		var parse = JSON.parse(map_jstring)
		if parse.error != OK:
			printerr("Could not parse map jstring to offer in load drop down")
			continue
		var map_name = parse.result["metadata"]["name"] 
		var map_id = parse.result["metadata"]["id"] 
		
		select_map_load.add_item(map_name,map_id)
	
	#enable load button
#	if select_map_load.get_item_count() > 0:
#		select_tool.select(0)


func _process(delta):
	
	var cam_movement := Vector2()
	var cam_speed = 5
	if Input.is_key_pressed(KEY_W):
		cam_movement.y -= cam_speed
	if Input.is_key_pressed(KEY_S):
		cam_movement.y += cam_speed 
	if Input.is_key_pressed(KEY_A):
		cam_movement.x -= cam_speed 
	if Input.is_key_pressed(KEY_D):
		cam_movement.x += cam_speed
	camera_editor.position += cam_movement
	update()


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# moved cursor
		if show_cursor:
			var coord = tilemap_cursor.world_to_map(get_global_mouse_position())
			if coord != selected_cell:
				# moved to new cell
				tool_draw(coord)
				selected_cell = coord
				if tool_dragged:
					tool_use()# still using (mb held)
	if event is InputEventMouseButton:
		# bisschen wonky
		if event.button_mask == BUTTON_LEFT:
			tool_use()
		tool_dragged = event.pressed


func tool_use()->void:
	if select_tool.get_selected_items().size() == 0:
		return
	match select_tool.get_item_metadata(select_tool.get_selected_items()[0]):
		Tools.tile_place:
			map.editor_tile_change(get_global_mouse_position(),select_tile.get_item_metadata(select_tile.get_selected_items()[0]))
		Tools.tile_remove:
			map.editor_tile_change(get_global_mouse_position(),-1)
			tool_draw(selected_cell) # hide shadow of removed tile
		Tools.object_place:
			map.editor_object_place(get_global_mouse_position(),select_object.get_item_metadata(select_object.get_selected_items()[0]))
		Tools.object_remove:
			map.editor_object_remove(get_global_mouse_position())


func tool_draw(coord:Vector2)->void:
	if select_tool.get_selected_items().size() == 0:
		return
	match select_tool.get_item_metadata(select_tool.get_selected_items()[0]):
		Tools.object_place:
			if select_object.get_selected_items().size() == 0:
				return
			spr_object_cursor.position = map.get_center_cell_position(get_global_mouse_position())
			var obj_id = select_object.get_item_metadata(select_object.get_selected_items()[0])
			var path
			for i in map.OBJECT_DATA:
				if map.OBJECT_DATA[i]["id"] == obj_id:
					path = map.OBJECT_DATA[i]["texture_path"]
					break
			var icon = load(path)
			spr_object_cursor.texture = icon
		Tools.tile_place:
			if select_tile.get_selected_items().size() == 0:
				return
			tilemap_cursor.set_cell(selected_cell.x,selected_cell.y,-1)
			tilemap_cursor.set_cell(coord.x,coord.y,map.get_tilemap_id(select_tile.get_item_metadata(select_tile.get_selected_items()[0])))
		Tools.tile_remove:
			tilemap_cursor.set_cell(selected_cell.x,selected_cell.y,-1)
			tilemap_cursor.set_cell(coord.x,coord.y,map.get_tile_id_at(get_global_mouse_position()))


# Signal Callbacks

func _on_SelectTool_item_selected(index):
	var _tool = select_tool.get_item_metadata(index)
	select_tile.visible = TOOL_DATA[_tool]["show_tile_select"]
	select_object.visible = TOOL_DATA[_tool]["show_object_select"]
	spr_object_cursor.visible = TOOL_DATA[_tool]["show_object_cursor"]
	tilemap_cursor.visible = TOOL_DATA[_tool]["show_tilemap_cursor"]


func _on_SelectObject_item_selected(index):
	for i in map.OBJECT_DATA:
		if map.OBJECT_DATA[i]["id"] == index:
			spr_object_cursor.texture = load(map.OBJECT_DATA[i]["texture_path"])


func _on_BtnSave_pressed():
	# update metadata
	map.metadata["name"] = edit_map_name_save.text
	if map.metadata["id"] == null:
		map.metadata["id"] = OS.get_unix_time()
	if map.metadata["creator_id"] == null:
		map.metadata["creator_id"] = Networker.session.user_id # TODO prevent crash if not logged in
	
	# export map
	var map_jstring = map.serialize()
	
	# create mapfolder
	var dir = Directory.new()
	if not dir.dir_exists(Global.MAPFOLDER_PATH):
		dir.make_dir_recursive(Global.MAPFOLDER_PATH)
	
	#save to file
	var file = File.new()
	var path = "%s%s.map"%[Global.MAPFOLDER_PATH,map.metadata["id"]]
	var error = file.open(path, File.WRITE)
	if error != OK:
		printerr("Could not save to file!!!! %s"% error)
		return
	file.store_string(map_jstring)
	file.close()
	
	print("Map \"%s\" (ID %s) succesfully saved to %s "%[map.metadata["name"],map.metadata["id"],path])
	get_tree().change_scene("res://scenes/menu/Menu.tscn")


func _on_EditMapName_text_changed(new_text):
	btn_save.disabled = (new_text.length() < 4) # at least 4 char length 


func _on_SelectLoad_item_selected(index):
	btn_load.disabled = (index < 0)  # something is selected


func _on_BtnLoad_pressed():
	var map_id = select_map_load.get_selected_id()
	
	var file = File.new()
	var error = file.open("%s%s.map"%[Global.MAPFOLDER_PATH,map_id],File.READ)
	if error != OK:
		printerr("Could not load file!!!")
		return
	
	map.deserialize(file.get_as_text())
	file.close()
	btn_load.disabled = true
	select_map_load.disabled = true
	edit_map_name_save.text = map.metadata["name"]
