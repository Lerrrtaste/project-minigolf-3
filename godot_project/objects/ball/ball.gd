extends Node2D

var connected_pc #has active player controller attached

onready var lbl_player_name = get_node("LblPlayerName")


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


func _on_PlayerController_move(pos):
	position = pos


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
	draw_circle(Vector2(),10,ColorN("red"))
	
