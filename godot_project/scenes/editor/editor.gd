extends Node2D

## The actual map editor
##
## Parameters:
## 	- load_map_id:string or created_new = true
## 	- verified:bool, optional
##
## Uses socket
##
## Exits to
## - MatchPractice with verifying = true
## - EditorMenu

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
onready var panel_tile_info = get_node("CanvasLayer/UI/ContainerMapEdit/TileInfo")
onready var lbl_tile_info = get_node("CanvasLayer/UI/ContainerMapEdit/TileInfo/LblTileInfo")
onready var spr_object_cursor = get_node("SprObjectCursor")

var selected_cell := Vector2()
var tool_dragged := false
var tool_dragged_from := Vector2()
var previous_tool

enum Tools {
	TILE_SINGLE,
	TILE_LINE,
	TILE_FILL,
	OBJECT_PLACE,
	OBJECT_REMOVE,
}
const TOOL_DATA = {
	Tools.TILE_SINGLE:
	{
		"name": "Place Tile",
		"icon_path": "res://scenes/editor/editor_tool1.png",
		"show_tilemap_cursor": true,
		"show_tile_select": true,
		"show_object_cursor": false,
		"show_object_select": false,
		"show_tile_info": true,
	},
	Tools.TILE_LINE:
	{
		"name": "Remove Tile",
		"icon_path": "res://scenes/editor/editor_tool1.png",
		"show_tilemap_cursor": true,
		"show_tile_select": true,
		"show_object_cursor": false,
		"show_object_select": false,
		"show_tile_info": true,
	},
	Tools.TILE_FILL:
	{
		"name": "Remove Tile",
		"icon_path": "res://scenes/editor/editor_tool1.png",
		"show_tilemap_cursor": true,
		"show_tile_select": true,
		"show_object_cursor": false,
		"show_object_select": false,
		"show_tile_info": true,
	},
	Tools.OBJECT_PLACE:
	{
		"name": "Place Object",
		"icon_path": "res://scenes/editor/editor_tool3.png",
		"show_tilemap_cursor": false,
		"show_tile_select": false,
		"show_object_cursor": true,
		"show_object_select": true,
		"show_tile_info": false,
	},
	Tools.OBJECT_REMOVE:
	{
		"name": "Remove Object",
		"icon_path": "res://scenes/editor/editor_tool4.png",
		"show_tilemap_cursor": false,
		"show_tile_select": false,
		"show_object_cursor": true,
		"show_object_select": false,
		"show_tile_info": false,
	},
}


func _ready():
	# center camera
	camera_editor.position = OS.window_size / 2

	load_ui()

	# LOAD OR CREATE MAP
	var params = Global.get_scene_parameter()
	if params.has("load_map_id"):
		var map_jstring = yield(MapStorage.load_map_async(params["load_map_id"]), "completed")
		map.deserialize(map_jstring)
		if map.metadata.has("name"):
			menu_edit_name.text = map.metadata["name"]

	elif params.has("created_new"):
		pass


func load_ui():
	# populate tile dropdown
	for i in MapData.Tiles.values():
		if MapData.get_tile_property(i, "texture_path") != null:
			var icon = load(MapData.get_tile_property(i, "texture_path"))
			select_tile.add_icon_item(icon)
		else:
			select_tile.add_item(MapData.get_tile_property(i, "name"))
		select_tile.set_item_metadata(select_tile.get_item_count() - 1, i)
		select_tile.set_item_tooltip(
			select_tile.get_item_count() - 1, MapData.get_tile_property(i, "name")
		)

	# populate object dropdown
	for i in MapData.Objects.values():
		if i == MapData.Objects.NONE:
			continue
		var path = MapData.get_object_property(i, "texture_path")
		var oname = MapData.get_object_property(i, "name")

		if path != null:
			var icon = load(path)
			select_object.add_item(oname, icon)
		else:
			select_object.add_item(oname)
		select_object.set_item_metadata(select_object.get_item_count() - 1, i)

	# populate tool dropdown
	for i in TOOL_DATA:
		select_tool.add_icon_item(load(TOOL_DATA[i]["icon_path"]))
		select_tool.set_item_metadata(select_tool.get_item_count() - 1, i)
		select_tool.set_item_tooltip(select_tool.get_item_count() - 1, TOOL_DATA[i]["name"])


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
	var coord = tilemap_cursor.world_to_map(get_global_mouse_position())
	if coord != selected_cell:
		# moved to new cell
		tool_draw()
		selected_cell = coord
		if Input.is_action_pressed("editor_tool_use") and tool_dragged:
			tool_use(false) #TODO get rb pressed for inverted tool while dragging


func _unhandled_input(event):
	if event is InputEventMouseButton:
#		if event.is_action_just_pressed("editor_tool_use"):

		# Remove tiles with right click
		var invert:bool
		match event.button_index:
			BUTTON_LEFT:
				invert = false
			BUTTON_RIGHT:
				invert = true
			_:
				return

		# Use tool / start dragging
		if event.pressed:
			tool_dragged = true
			var cell = tilemap_cursor.world_to_map(get_global_mouse_position())
			tool_dragged_from = tilemap_cursor.map_to_world(cell)
			tool_use(invert)

#		if event.is_action_just_released("editor_tool_use") and tool_dragged:
#		# Apply Dragged Tool
		if not event.pressed:
			tool_dragged = false
			tool_use(invert)


# Use the selected tool
# tool_dragged needs to be set before
# :param invert: invert the tool (remove tile)
func tool_use(invert) -> void:
	if select_tool.get_selected_items().size() == 0:
		return

	match select_tool.get_item_metadata(select_tool.get_selected_items()[0]):
		Tools.TILE_SINGLE:
			if not select_tile.get_selected_items().size() > 0:
				return  # tile selected

			var tile
			if invert:
				tile = MapData.Tiles.EMPTY
			else:
				var item_tile = select_tile.get_selected_items()[0]
				tile = select_tile.get_item_metadata(item_tile)
				tilemap_cursor.clear()

			var pos = get_global_mouse_position()
			map.editor_tile_change(pos, tile)

		Tools.TILE_LINE:
			if not select_tile.get_selected_items().size() > 0:
				return  # tile selected
			if tool_dragged:
				return  # line not started


			var tile
			if invert:
				tile = MapData.Tiles.EMPTY
			else:
				var item_tile = select_tile.get_selected_items()[0]
				tile = select_tile.get_item_metadata(item_tile)

			var from = tool_dragged_from
			var to = get_global_mouse_position()
			_tilemap_set_line(map, from, to, tile)
			tilemap_cursor.clear()

		Tools.TILE_FILL:
			if not select_tile.get_selected_items().size() > 0:
				return  # tile selected
			if tool_dragged:
				return

			var item_tile = select_tile.get_selected_items()[0]
			var tile = select_tile.get_item_metadata(item_tile)
			_tilemap_set_flood(map, get_global_mouse_position(), tile)
			tilemap_cursor.clear()

		Tools.OBJECT_PLACE:
			if tool_dragged:
				return
			if not select_object.get_selected_items().size() > 0:
				return
			var item = select_object.get_selected_items()[0]
			var object = select_object.get_item_metadata(item)
			var pos = get_global_mouse_position()
			map.editor_object_place(pos, object)

		Tools.OBJECT_REMOVE:
			if tool_dragged:
				return
			var pos = get_global_mouse_position()
			map.editor_object_remove(pos)


func tool_draw() -> void:
	if select_tool.get_selected_items().size() == 0:
		return
	match select_tool.get_item_metadata(select_tool.get_selected_items()[0]):
		Tools.OBJECT_PLACE:
			if select_object.get_selected_items().size() == 0:
				return

			spr_object_cursor.position = map.get_cell_center(get_global_mouse_position())

		Tools.OBJECT_REMOVE:
			var obj_id = map.get_object_id_at(get_global_mouse_position())
			if obj_id == -1:
				return  # no object under cursor

			var path = MapData.get_object_property(obj_id, "texture_path")
			if path == null:
				return  # no icon set

			var icon = load(path)
			spr_object_cursor.texture = icon

		Tools.TILE_SINGLE:
			if not select_tile.get_selected_items().size() > 0:
				return  # tile selected

			var item_tile = select_tile.get_selected_items()[0]
			var tile = select_tile.get_item_metadata(item_tile)
			var cell = map.world_to_map(get_global_mouse_position())
			if tile == -1:
				tile = map.get_tile_id_at_cell(cell)

			tilemap_cursor.clear()
			tile = MapData.get_tile_property(tile, "tilemap_id")
			tilemap_cursor.set_cellv(cell, tile)

		Tools.TILE_LINE:
			if not select_tile.get_selected_items().size() > 0:
				return  # tile selected

			var item_tile = select_tile.get_selected_items()[0]
			var tile = select_tile.get_item_metadata(item_tile)
			var cell = map.world_to_map(get_global_mouse_position())
			if tile == -1:
				tile = map.get_tile_id_at_cell(cell)

			if not tool_dragged:  # line not started
				tilemap_cursor.clear()
				tile = MapData.get_tile_property(tile, "tilemap_id")
				tilemap_cursor.set_cellv(cell, tile)
				return

			tilemap_cursor.clear()
			var from = tool_dragged_from
			var to = get_global_mouse_position()
			_tilemap_set_line(tilemap_cursor, from, to, tile)

		Tools.TILE_FILL:
			if not select_tile.get_selected_items().size() > 0:
				return  # tile selected

			var item_tile = select_tile.get_selected_items()[0]
			var tile = select_tile.get_item_metadata(item_tile)
			var cell = map.world_to_map(get_global_mouse_position())
			if tile == -1:
				tile = map.get_tile_id_at_cell(cell)

			tilemap_cursor.clear()
			tile = MapData.get_tile_property(tile, "tilemap_id")
			tilemap_cursor.set_cellv(cell, tile)


func save_map_async():
	menu_btn_save.disabled = true
	menu_btn_save.text = "Saving..."

	# update metadata
	var current_metadata = map.metadata
	var map_id: String
	var creator_id = Networker.get_user_id()
	var creator_display_name = Networker.get_username(true)
	var map_name = menu_edit_name.text
	if current_metadata.has("id"):
		map_id = current_metadata["id"]
	else:
		map_id = String(OS.get_unix_time())  # TODO replace with proper uid gen (maybe by server request)
	map.update_metadata(map_id, map_name, creator_id, creator_display_name)

	# export map
	var map_jstring = map.serialize()
	var ack = yield(MapStorage.save_map_async(map_id, map_jstring), "completed")
	if ack.is_exception():
		#Notifier.notify_error("ERROR: Map saving failed", str(ack.message))
		menu_btn_save.disabled = false
		menu_btn_save.text = "Save and exit"
	else:
		Notifier.notify_editor("Saved succesfully")
	return ack


#### Helpers


# Set cells in a line
# uses editor_tile_change if available else set_cell
func _tilemap_set_line(tilemap, start_world: Vector2, end_world: Vector2, tile: int):
	var from_cell = tilemap.world_to_map(start_world)
	var to_cell = tilemap.world_to_map(end_world)
	var line_vec = to_cell - from_cell
	for i in range(line_vec.length() + 1):
		if tilemap.has_method("editor_tile_change"):
			print(from_cell + i * (line_vec / line_vec.length()))
			var world = map.map_to_world(from_cell + i * (line_vec / line_vec.length()))
			tilemap.editor_tile_change(world, tile)
		else:
			var tm_id = MapData.get_tile_property(tile, "tilemap_id")
			tilemap.set_cellv(from_cell + i * (line_vec / line_vec.length()), tm_id)


# Set cells using a flood fill algorithm
# needs the actual Map scene
# TODO rename parameter map (shadows actual map)
func _tilemap_set_flood(map, from_world: Vector2, tile: int):
	var from_cell = map.world_to_map(from_world)
	var x = from_cell.x
	var y = from_cell.y
	var new_tile = tile
	var old_tile = map.get_tile_id_at_cell(from_cell)
	if old_tile == new_tile:
		return

	var w = 50  #max width
	var h = 50  # maxheight

	# floodFillScanlineStack Algorithm
	var x1: int
	var spanAbove: bool
	var spanBelow: bool
	var stack: Array
	stack.push_back(Vector2(x, y))

	while not stack.empty():
		var popped = stack.pop_back()
		x = popped.x
		y = popped.y

		x1 = x
		while x1 >= -w and map.get_tile_id_at_cell(Vector2(x1, y)) == old_tile:
			x1 -= 1
		x1 += 1
		spanAbove = false
		spanBelow = false

		while x1 < w and map.get_tile_id_at_cell(Vector2(x1, y)) == old_tile:
			var world = map.map_to_world(Vector2(x1, y))
			map.editor_tile_change(world, new_tile)

			if not spanAbove and y > -w and map.get_tile_id_at_cell(Vector2(x1, y - 1)) == old_tile:
				stack.push_back(Vector2(x1, y - 1))
				spanAbove = true
			elif spanAbove and y > -w and map.get_tile_id_at_cell(Vector2(x1, y - 1)) != old_tile:
				spanAbove = false

			if (
				not spanBelow
				and y < h - 1
				and map.get_tile_id_at_cell(Vector2(x1, y + 1)) == old_tile
			):
				stack.push_back(Vector2(x1, y + 1))
				spanBelow = true
			elif (
				spanBelow
				and y < h - 1
				and map.get_tile_id_at_cell(Vector2(x1, y + 1)) != old_tile
			):
				spanBelow = false

			x1 += 1


# Signal Callbacks


func _on_SelectTool_item_selected(index):
	var _tool = select_tool.get_item_metadata(index)

	if _tool == previous_tool:  #select nothing
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
	panel_tile_info.visible = TOOL_DATA[_tool]["show_tile_info"]
	previous_tool = _tool


func _on_SelectObject_item_selected(index):
	var obj_id = select_object.get_item_metadata(index)
	var path = MapData.get_object_property(obj_id, "texture_path")
	if path != null:
		spr_object_cursor.texture = load(path)


#### Menu


func _on_BtnMenu_pressed():
	menu_popup.popup_centered()


func _on_BtnSave_pressed():
	if not map.is_map_valid():
		return

	if menu_edit_name.text.length() < Global.MAP_NAME_LENGTH_MIN:
		Notifier.notify_editor("Name too short", "Min %s chars" % Global.MAP_NAME_LENGTH_MIN)
		return

	if menu_edit_name.text.length() > Global.MAP_NAME_LENGTH_MAX:
		Notifier.notify_editor("Name too long", "Max %s chars" % Global.MAP_NAME_LENGTH_MAX)
		return

	var ack = yield(save_map_async(), "completed")
	if not ack.is_exception():
		get_tree().change_scene("res://scenes/editor_menu/EditorMenu.tscn")


func _on_BtnClose_pressed():
	menu_popup.visible = false


func _on_BtnDiscard_pressed():
	btn_discard_confirm.disabled = true
	popup_discard.popup_centered()
	yield(get_tree().create_timer(1), "timeout")
	btn_discard_confirm.disabled = false


func _on_BtnDiscardConfirm_pressed():
	get_tree().change_scene("res://scenes/editor_menu/EditorMenu.tscn")


func _on_BtnDiscardCancel_pressed():
	pass  # Replace with function body.
	popup_discard.visible = false


func _on_CheckPublic_toggled(button_pressed):
	menu_btn_publish.visible = button_pressed
	menu_btn_save.visible = not button_pressed


func _on_BtnPublish_pressed():
	if not map.is_map_valid():
		return

	if menu_edit_name.text.length() < Global.MAP_NAME_LENGTH_MIN:
		Notifier.notify_editor("Name too short", "Min %s chars" % Global.MAP_NAME_LENGTH_MIN)
		return

	if menu_edit_name.text.length() > Global.MAP_NAME_LENGTH_MAX:
		Notifier.notify_editor("Name too long", "Max %s chars" % Global.MAP_NAME_LENGTH_MAX)
		return

	yield(save_map_async(), "completed")
	var params = {
		"map_id": map.metadata["id"],
		"creator_id": map.metadata["creator_user_id"],
		"verifying": true,
	}
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/match_practice/MatchPractice.tscn")


func _on_SelectTile_item_selected(index):
	var dict = MapData.get_tile_dict(select_tile.get_item_metadata(index))
	var text = ""
	text += dict["name"]

	if dict.has("resets_ball"):
		if dict["resets_ball"]:
			text += "\n\t - Resets ball"

	if dict.has("resets_ball"):
		if dict["resets_ball"]:
			text += "\n\t - Resets ball to Start"

	if dict.has("friction"):
		if dict["friction"] != 1.0:
			text += "\n\t - Friction Multiplier: %s" % dict["friction"]

	if dict.has("solid"):
		if dict["solid"]:
			text += "\n\t - Solid"

	if dict.has("force"):
		if dict["force"] > 0.0:
			text += "\n\t - Force %s" % dict["force"]

	lbl_tile_info.text = text
