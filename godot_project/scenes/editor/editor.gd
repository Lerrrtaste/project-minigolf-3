extends Node2D

onready var spr_grid_cursor = get_node("SprGridCursor")
onready var map = get_node("Map")
onready var select_tile = get_node("SelectTile")
onready var tilemap_cursor = get_node("TileMapCursor")

var show_cursor := true
var selected_cell := Vector2()

func _ready():
	for i in map.TILE_DATA:
		var tile_id = map.TILE_DATA[i]["id"] + 1
		if map.TILE_DATA[i]["texture_path"] != null:
			var icon = load(map.TILE_DATA[i]["texture_path"])
			select_tile.add_icon_item(icon,i,tile_id)
		else:
			select_tile.add_item(i,tile_id)


func _process(delta):
	var snapped = map.snap_world_to_grid(get_local_mouse_position())
	spr_grid_cursor.position = snapped
	
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
	$DebugCamera.position += cam_movement
	update()
	
	if show_cursor:
		var coord = tilemap_cursor.world_to_map(get_global_mouse_position())
		if coord != selected_cell:
			tilemap_cursor.set_cell(selected_cell.x,selected_cell.y,-1)
			tilemap_cursor.set_cell(coord.x,coord.y,select_tile.selected-1)
			selected_cell = coord


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
