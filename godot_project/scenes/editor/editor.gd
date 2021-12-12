extends Node2D

onready var map = get_node("Map")
onready var select_tile = get_node("CanvasLayer/UI/SelectTile")
onready var select_tool = get_node("CanvasLayer/UI/SelectTool")
onready var select_object = get_node("CanvasLayer/UI/SelectObject")
onready var tilemap_cursor = get_node("Map/TileMapCursor")
onready var camera_editor = get_node("CameraEditor")
var show_cursor := true
onready var spr_object_cursor = get_node("SprObjectCursor")
var selected_cell := Vector2()

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
	
	#populate tool dropdown
	select_tool.add_item("Place Tile",Tools.tile_change)
	select_tool.add_item("Place Object",Tools.object_place)
	select_tool.add_item("Remove Object",Tools.object_remove)
	_on_SelectTool_item_selected(0)


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
	if event is InputEventMouse:
		
		# move cursor
		if show_cursor:
			var coord = tilemap_cursor.world_to_map(get_global_mouse_position())
			if coord != selected_cell:
				match select_tool.selected:
					Tools.object_place:
						spr_object_cursor.position = map.get_center_cell_position(get_global_mouse_position())
					Tools.tile_change:
						tilemap_cursor.set_cell(selected_cell.x,selected_cell.y,-1)
						tilemap_cursor.set_cell(coord.x,coord.y,select_tile.selected-1)
						selected_cell = coord
		
		if event.is_pressed():
			if event.button_mask == BUTTON_LEFT:
				use_tool()


func _draw():
	var draw_limit = 1000
#	# Grid
#	for y in range(0, draw_limit, 16):
#		var start = map.cartesian_to_isometric(map.snap_world_to_grid(Vector2(0,y)))
#		var end = map.cartesian_to_isometric(map.snap_world_to_grid(Vector2(draw_limit,y)))
#		draw_line(start,end,ColorN("grey"))
#
#	for x in range(0, draw_limit, 16):
#		var start = map.cartesian_to_isometric(map.snap_world_to_grid(Vector2(x,0)))
#		var end = map.cartesian_to_isometric(map.snap_world_to_grid(Vector2(x,draw_limit)))
#		draw_line(start,end,ColorN("grey"))
#
	#draw_circle(map.cartesian_to_isometric(map.snap_world_to_grid(get_local_mouse_position())),4,ColorN("red"))
#	var mouse = get_local_mouse_position()
#	var worldpos:Vector2 = (mouse.x / map.TILE_X/2 + mouse.y / map.TILE_Y/2) /2
#	draw_circle(worldpos,4,ColorN("red"))


func use_tool()->void:
	match select_tool.selected:
		Tools.tile_change:
			map.editor_tile_change(get_global_mouse_position(),select_tile.selected-1)
		Tools.object_place:
			map.editor_object_place(get_global_mouse_position(),select_object.selected)


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
