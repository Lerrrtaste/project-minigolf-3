extends Node2D

onready var lbl_player_name = get_node("LblPlayerName")

var connected_pc #has active player controller attached
var direction: Vector2
var speed: float
var max_speed: float = 100
var friction: float = 1


func _ready():
	if not is_instance_valid(connected_pc):
		printerr("Ball without PC entered Tree")
		return
	
	if connected_pc.LOCAL:
		lbl_player_name.text = "YOU"
	else:
		var remote_name = Networker.connected_presences[connected_pc.remote_user_id].username
		lbl_player_name.text = remote_name
	


func _process(delta):
	update()
	if speed > 0.0:
		var movement_step := Vector2()
		movement_step = direction
		movement_step.y /= 2
		movement_step *= speed * delta
		
		speed -= friction * delta
		position += movement_step
		


#TODO "hard set" position for sync after move ended from remote pc

func _on_PlayerController_move(_clicked_screen):
	var pos_delta:Vector2 =  _clicked_screen
	direction = pos_delta.normalized()
	speed = max_speed
	
	print("Clicked at %s - current %s  --->  Delta %s"%[_clicked_screen,global_position,pos_delta])


func setup_playercontroller(pc_scene:PackedScene,remote_user_id=null)->void:
	if is_instance_valid(connected_pc):
		printerr("Ball is already controlled")
		return
	
	var new_pc = pc_scene.instance()
	connected_pc = new_pc
	if remote_user_id != null and new_pc.has_method("register_remote_user_id"):
		new_pc.register_remote_user_id(remote_user_id)
		
	add_child(new_pc)
	

	# connect pc signals
	new_pc.connect("move",self,"_on_PlayerController_move")


func _draw():
	draw_line(Vector2(),get_local_mouse_position(),ColorN("red"))

