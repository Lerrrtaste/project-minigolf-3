extends Node2D

onready var map = get_node("Map")
onready var select_tile = get_node("CanvasLayer/UI/SelectTile")
onready var select_tool = get_node("CanvasLayer/UI/SelectTool")
onready var select_object = get_node("CanvasLayer/UI/SelectObject")
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
	tile_change,
	object_place,
	object_remove,
}



func _ready():
	# center camera
	camera_editor.position = OS.window_size/2
	
	# populate tile dropdown
	for i in map.TILE_DATA:
		var tile_id = map.TILE_DATA[i]["id"] + 1
		if map.TILE_DATA[i]["texture_path"] != null:
			var icon = load(map.TILE_DATA[i]["texture_path"])
			select_tile.add_icon_item(icon,i,tile_id)
		else:
			select_tile.add_item(i,tile_id)
	
	# populate object dropdown
	for i in map.OBJECT_DATA:
		var object_id = map.OBJECT_DATA[i].id
		if map.OBJECT_DATA[i]["texture_path"] != null:
			var icon = load(map.OBJECT_DATA[i]["texture_path"])
			select_object.add_icon_item(icon,i,object_id)
		else:
			select_object.add_item(i,object_id)
	
	# populate tool dropdown
	select_tool.add_item("Place Tile",Tools.tile_change)
	select_tool.add_item("Place Object",Tools.object_place)
	select_tool.add_item("Remove Object",Tools.object_remove)
	_on_SelectTool_item_selected(0)
	
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
	if select_map_load.get_item_count() > 0:
		_on_SelectLoad_item_selected(0)


func _process(delta):
	
	var cam_movement := Vector2()
	var cam_speed = 10
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
		
		# move cursor
		if show_cursor:
			var coord = tilemap_cursor.world_to_map(get_global_mouse_position())
			if coord != selected_cell:
				match select_tool.selected:
					Tools.object_place:
						spr_object_cursor.position = map.get_center_cell_position(get_global_mouse_position())
					Tools.tile_change:
						tilemap_cursor.set_cell(selected_cell.x,selected_cell.y,-1)
						tilemap_cursor.set_cell(coord.x,coord.y,map.get_tilemap_id(select_tile.selected-1))
						selected_cell = coord
						if tool_dragged:
							use_tool()
	
	if event is InputEventMouseButton:
		# bisschen wonky
		if event.button_mask == BUTTON_LEFT:
			use_tool()
		tool_dragged = event.pressed


func use_tool()->void:
	match select_tool.selected:
		Tools.tile_change:
			map.editor_tile_change(get_global_mouse_position(),select_tile.selected-1)
			print("Placing tile id %s"%(select_tile.selected-1))
		Tools.object_place:
			map.editor_object_place(get_global_mouse_position(),select_object.selected)
		Tools.object_remove:
			map.editor_object_remove(get_global_mouse_position())


# Signal Callbacks

func _on_SelectTool_item_selected(index):
	match select_tool.selected:
		Tools.tile_change:
			select_tile.visible = true
			select_object.visible = false
			spr_object_cursor.visible = false
			tilemap_cursor.visible = true
		Tools.object_place:
			select_tile.visible = false
			select_object.visible = true
			tilemap_cursor.visible = false
			spr_object_cursor.visible = true
		Tools.object_remove:
			select_tile.visible = false
			select_object.visible = false
			tilemap_cursor.visible = false
			spr_object_cursor.visible = true


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
