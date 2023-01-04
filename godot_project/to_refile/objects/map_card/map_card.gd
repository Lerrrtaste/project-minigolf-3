extends Control

onready var tween = get_node("Tween")
onready var tex_dot = get_node("GridContainer/BoxPlayers/TexPlayers/TexDot")

onready var lbl_name = get_node("GridContainer/BoxInfo/LblName")
onready var lbl_creator = get_node("GridContainer/BoxInfo/LblCreator")
onready var players_root = get_node("GridContainer/BoxPlayers/TexPlayers")
onready var lbl_players = get_node("GridContainer/BoxPlayers/TexPlayers/LblPlayers")

onready var check_include = get_node("GridContainer/CheckInclude")
onready var btn_practice = get_node("BtnPractice")

var map_id:String
var creator_id:String
var map_name:String
var _version_mismatch:bool

signal practice(map_id, creator_id)

const PLAYERS_REFRESH_INTERVAL_SEC = -1#15 #-1 to disable

## A Card with basic map info
##
## Supposed for selecting maps and exploring
## Can start practice match and add to map pool


func _ready():
	#visible = false 
	
	tween.interpolate_property(tex_dot,"modulate:a",1.0,0.0,1.0,Tween.TRANS_BACK, Tween.EASE_IN, 1.0)
	tween.interpolate_property(tex_dot,"modulate:a",0.0,1.0,1.0,Tween.TRANS_BACK, Tween.EASE_OUT, 0.2)
	
	#refresh_player_count()


func populate(_map_name:String, _map_id:String, _creator_id:String, _creator_name:String, _game_version:String):
	# Disable input if game version does not match
	if _game_version != Global.GAME_VERSION:
		_version_mismatch = true
		check_include.disabled = true
		check_include.hint_tooltip = "Game version mismatch"
		btn_practice.disabled = true
		btn_practice.hint_tooltip = "Game version mismatch"
		lbl_creator.text = "[v%s required]"%[_game_version]
	else:
		lbl_creator.text = _creator_name

	lbl_name.text = _map_name

	map_id = _map_id
	creator_id = _creator_id
	map_name = _map_name
	lbl_players.text = str(randi() % 64) #PLACEHOLDER
	
	hint_tooltip = "Map ID: %s"%map_id


	#visible = true
	
	if int(lbl_players.text) > 0:
		yield(get_tree().create_timer(randf()*4),"timeout")
		players_root.visible = true
		tween.start()


func refresh_player_count():
	# TODO implement on server
	yield(get_tree().create_timer(PLAYERS_REFRESH_INTERVAL_SEC), "timeout")
	refresh_player_count()


func is_included():
	if _version_mismatch:
		return false
	return check_include.pressed


func disable_input(disabled:bool):
	if _version_mismatch:
		disabled = true
	btn_practice.disabled = disabled
	check_include.disabled = disabled

func _on_BtnPractice_pressed():
	if _version_mismatch:
		return
	emit_signal("practice",map_id,creator_id)
