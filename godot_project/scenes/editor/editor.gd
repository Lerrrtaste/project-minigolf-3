extends Node2D

onready var spr_grid_cursor = get_node("SprGridCursor")
onready var map = get_node("Map")


func _ready():
	pass


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
#	#draw_circle(map.cartesian_to_isometric(map.snap_world_to_grid(get_local_mouse_position())),4,ColorN("red"))
#	var mouse = get_local_mouse_position()
#	var worldpos = (mouse.x / map.TILE_X/2 + mouse.y / map.TILE_Y/2) /2
#	draw_circle(worldpos,4,ColorN("red"))
