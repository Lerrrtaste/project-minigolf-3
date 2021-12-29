extends Node2D

"""
The actual map editor

Parameters:
	- load_map_id:string or created_new = true
	- verified:bool, optional

Uses socket

Exits to
- MatchPractice with verifying = true
- EditorMenu

"""

onready var map = get_node("Map")

onready var tilemap_cursor = get_node("TileMapCursor")
onready var camera_editor = get_node("CameraEditor")

# ui
onready var menu_edit_name = get_node("CanvasLayer/UI/SaveMenu/VBoxContainer/GridContainer/EditName")
onready var menu_check_public = get_node("CanvasLayer/UI/SaveMenu/VBoxContainer/GridContainer/CheckPublic")
onready var menu_btn_save = get_node("CanvasLayer/UI/SaveMenu/VBoxContainer/HBoxContainer/BtnSave")
onready var menu_btn_publish = get_node("CanvasLayer/UI/SaveMenu/VBoxContainer/HBoxContainer/BtnPublish")
onready var menu_btn_discard = get_node("CanvasLayer/UI/SaveMenu/VBoxContainer/HBoxContainer/BtnDiscard")
onready var menu_popup = get_node("CanvasLayer/UI/SaveMenu")
onready var select_tile = get_node("CanvasLayer/UI/ContainerMapEdit/SelectTile")
onready var select_tool = get_node("CanvasLayer/UI/ContainerMapEdit/SelectTool")
onready var select_object = get_node("CanvasLayer/UI/ContainerMapEdit/SelectObject")

onready var popup_discard = get_node("CanvasLayer/UI/PopupDiscard")
onready var btn_discard_confirm = get_node("CanvasLayer/UI/PopupDiscard/VBoxContainer/HBoxContainer/BtnDiscardConfirm")

var show_cursor := true
onready var spr_object_cursor = get_node("SprObjectCursor")
var selected_cell := Vector2()
var tool_dragged := false
var previous_tool

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
		if i == map.Tiles.EMPTY:
			continue
		if map.TILE_DATA[i]["texture_path"] != null:
			var icon = load(map.TILE_DATA[i]["texture_path"])
			select_tile.add_icon_item(icon)
		else:
			select_tile.add_item(map.TILE_DATA[i]["name"])
		select_tile.set_item_metadata(select_tile.get_item_count()-1, i)
		select_tile.set_item_tooltip(select_tile.get_item_count()-1, map.TILE_DATA[i]["name"])
	
	# populate object dropdown
	for i in map.OBJECT_DATA:
		if map.OBJECT_DATA[i]["texture_path"] != null:
			var icon = load(map.OBJECT_DATA[i]["texture_path"])
			select_object.add_item(map.OBJECT_DATA[i]["name"], icon)
		else:
			select_object.add_item(map.OBJECT_DATA[i]["name"])
		select_object.set_item_metadata(select_object.get_item_count()-1,i)
	
	# populate tool dropdown
	for i in TOOL_DATA:
		select_tool.add_icon_item(load(TOOL_DATA[i]["icon_path"]))
		select_tool.set_item_metadata(select_tool.get_item_count()-1,i)
		select_tool.set_item_tooltip(select_tool.get_item_count()-1,TOOL_DATA[i]["name"])
	
	
	# LOAD OR CREATE MAP
	var params = Global.get_scene_parameter()
	if params.has("load_map_id"):
		var map_jstring = yield(MapStorage.load_map_async(params["load_map_id"]),"completed")
		map.deserialize(map_jstring)
		if map.metadata.has("name"):
			menu_edit_name.text = map.metadata["name"]
	
		
	elif params.has("created_new"):
		pass


func _process(delta):
	
	if not menu_popup.visible:
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
			if select_tile.get_selected_items().size() > 0:
				map.editor_tile_change(get_global_mouse_position(),select_tile.get_item_metadata(select_tile.get_selected_items()[0]))
		Tools.tile_remove:
			map.editor_tile_change(get_global_mouse_position(),-1)
			tool_draw(selected_cell) # hide shadow of removed tile
		Tools.object_place:
			if select_object.get_selected_items().size() > 0:
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
			spr_object_cursor.position = map.get_cell_center(get_global_mouse_position())
			var obj_id = select_object.get_item_metadata(select_object.get_selected_items()[0])
			var path = map.OBJECT_DATA[obj_id]["texture_path"]
			var icon = load(path)
			spr_object_cursor.texture = icon
		Tools.tile_place:
			if select_tile.get_selected_items().size() == 0:
				return
			tilemap_cursor.set_cell(selected_cell.x,selected_cell.y,-1)
			tilemap_cursor.set_cell(coord.x,coord.y,map.get_tilemap_id(select_tile.get_item_metadata(select_tile.get_selected_items()[0])))
		Tools.tile_remove:
			tilemap_cursor.set_cell(selected_cell.x,selected_cell.y,-1)
			tilemap_cursor.set_cell(coord.x,coord.y,map.get_tilemap_id(map.get_tile_id_at(get_global_mouse_position())))


func save_map_async():
	menu_btn_save.disabled = true
	menu_btn_save.text = "Saving..."
	
	# update metadata
	var current_metadata = map.metadata
	var map_id:String
	var creator_id = Networker.session.user_id
	var creator_display_name = Networker.get_username(true)
	var map_name = menu_edit_name.text
	if current_metadata.has("id"):
		map_id = current_metadata["id"]
	else:
		map_id = String(OS.get_unix_time()) # TODO replace with proper uid gen (maybe by server request)
	map.update_metadata(map_id, map_name, creator_id, creator_display_name)
	
	# export map
	var map_jstring = map.serialize()
	var public = false # menu_check_public.pressed
	var ack = yield(MapStorage.save_map_async(map_id, map_jstring,public), "completed")
	if ack.is_exception():
		Notifier.notify_error("ERROR: Map saving failed", str(ack))
	else:
		Notifier.notify_editor("Saved succesfully")
	return ack

# Signal Callbacks

func _on_SelectTool_item_selected(index):
	var _tool = select_tool.get_item_metadata(index)
	
	if _tool == previous_tool: 
		select_tool.unselect_all()
		
		select_tile.visible = false
		select_object.visible = false
		spr_object_cursor.visible = false
		tilemap_cursor.visible = false
		
		previous_tool = null
		return
	
	select_tile.visible = TOOL_DATA[_tool]["show_tile_select"]
	select_object.visible = TOOL_DATA[_tool]["show_object_select"]
	spr_object_cursor.visible = TOOL_DATA[_tool]["show_object_cursor"]
	tilemap_cursor.visible = TOOL_DATA[_tool]["show_tilemap_cursor"]
	
	previous_tool = _tool


func _on_SelectObject_item_selected(index):
	var obj_id = select_object.get_item_metadata(index)
	spr_object_cursor.texture = load(map.OBJECT_DATA[obj_id]["texture_path"])


#### Menu

func _on_BtnMenu_pressed():
	menu_popup.popup_centered()


func _on_BtnSave_pressed():
	if not map.is_map_valid():
		return
		
	if menu_edit_name.text.length() < Global.MAP_NAME_LENGTH_MIN:
		Notifier.notify_editor("Name too short", "Min %s chars"%Global.MAP_NAME_LENGTH_MIN)
		return
		
	if menu_edit_name.text.length() > Global.MAP_NAME_LENGTH_MAX:
		Notifier.notify_editor("Name too long", "Max %s chars"%Global.MAP_NAME_LENGTH_MAX)
		return
		
	var ack = yield(save_map_async(), "completed")
	if not ack.is_exception():
		get_tree().change_scene("res://scenes/editor_menu/EditorMenu.tscn")


func _on_BtnClose_pressed():
	menu_popup.visible=false


func _on_BtnDiscard_pressed():
	btn_discard_confirm.disabled = true
	popup_discard.popup_centered()
	yield(get_tree().create_timer(1), "timeout")
	btn_discard_confirm.disabled = false


func _on_BtnDiscardConfirm_pressed():
	get_tree().change_scene("res://scenes/editor_menu/EditorMenu.tscn")


func _on_BtnDiscardCancel_pressed():
	pass # Replace with function body.
	popup_discard.visible = false


func _on_CheckPublic_toggled(button_pressed):
	menu_btn_publish.visible = button_pressed
	menu_btn_save.visible = not button_pressed
	

func _on_BtnPublish_pressed():
	if not map.is_map_valid():
		return
		
	if menu_edit_name.text.length() < Global.MAP_NAME_LENGTH_MIN:
		Notifier.notify_editor("Name too short", "Min %s chars"%Global.MAP_NAME_LENGTH_MIN)
		return
		
	if menu_edit_name.text.length() > Global.MAP_NAME_LENGTH_MAX:
		Notifier.notify_editor("Name too long", "Max %s chars"%Global.MAP_NAME_LENGTH_MAX)
		return
	
	yield(save_map_async(), "completed")
	var params = {
		"map_id": map.metadata["id"],
		"creator_id": map.metadata["creator_user_id"],
		"verifying": true,
	}
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/match_practice/MatchPractice.tscn")
