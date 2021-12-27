extends Control

onready var tween = get_node("Tween")
onready var tex_dot = get_node("GridContainer/BoxPlayers/TexPlayers/TexDot")

onready var lbl_name = get_node("GridContainer/BoxInfo/LblName")
onready var lbl_creator = get_node("GridContainer/BoxInfo/LblCreator")
onready var players_root = get_node("GridContainer/BoxPlayers/TexPlayers")
onready var lbl_players = get_node("GridContainer/BoxPlayers/TexPlayers/LblPlayers")

onready var check_include = get_node("GridContainer/CheckInclude")

var map_id:String
var creator_id:String

const PLAYERS_REFRESH_INTERVAL_SEC = 15 #-1 to disable

func _ready():
	visible = false 
	
	tween.interpolate_property(tex_dot,"modulate:a",1.0,0.0,1.0,Tween.TRANS_BACK, Tween.EASE_IN, 1.0)
	tween.interpolate_property(tex_dot,"modulate:a",0.0,1.0,1.0,Tween.TRANS_BACK, Tween.EASE_OUT, 0.2)
	
	#refresh_player_count()
	
func _process(delta):
	pass

func populate(_map_name:String, _map_id:String, _creator_id:String, _creator_name:String):
	lbl_name.text = _map_name
	lbl_creator.text = _creator_name
	
	map_id = _map_id
	creator_id = _creator_id
	lbl_players.text = str(randi() % 4) # PLACEHOLDER
	
	visible = true
	
	if int(lbl_players.text) > 0:
		yield(get_tree().create_timer(randf()*2),"timeout")
		players_root.visible = true
		tween.start()


func refresh_player_count():
	# TODO implement on server
	yield(get_tree().create_timer(PLAYERS_REFRESH_INTERVAL_SEC), "timeout")
	refresh_player_count()


func is_included():
	return check_include.pressed
