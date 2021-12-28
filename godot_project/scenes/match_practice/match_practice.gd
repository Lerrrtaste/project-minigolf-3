extends Node2D

"""
Represents a single Practice Match

Paramaeters: map_id, creator_id, verifying (optional)

Exits to:
	- MatchEnd
		- gamemode = "practice"
		- verifying: bool
		- turn_count: int
		- map_metadata: dict
	- EditorMenu (on cancel)
	- Editor (on cancel with verifiying == true)
		- load_map_id: String

"""

onready var map = get_node("Map")
onready var text_score = get_node("UI/PanelScore/TextScore")

var Ball = preload("res://objects/ball/Ball.tscn")
var PlayerControllerPractice = preload("res://helpers/player_controller_practice/PlayerControllerPractice.tscn")
var MatchCamera = preload("res://helpers/cameras/match_camera/MatchCamera.tscn")

var local_ball
var turn_count:int

var map_id 
var creator_id
var verifying := false
 
enum States {
	INVALID = -1,
	LOADING, # waiting for players to join
	PLAYING, # playing a match
	FINISHED, # match finished
}
var current_state = States.INVALID


func _ready():
	# read map id from scene parameters
	var params = Global.get_scene_parameter()
	if not params.has_all(["map_id", "creator_id"]):
		Notifier.notify_error("Error loading practice Match", "Could not find map ID")
	else:
		map_id = params["map_id"]
		creator_id = params["creator_id"]
		if params.has("verifying"):
			verifying = params["verifying"]
		change_state(States.LOADING)


func _process(delta):
	update_ui()


func change_state(new_state:int):
	assert(current_state != new_state)
	match new_state:
		States.LOADING:
			Notifier.notify_game("Practice Match is loading")
			load_map()
			
		States.PLAYING:
			spawn_ball()
			Notifier.notify_game("Practice Match started")
			local_ball.turn_ready()
			
			
		States.FINISHED:
			var params = {
				"gamemode": "practice",
				"verifying": verifying,
				"turn_count": turn_count,
				"map_metadata": map.metadata,
			}
			Global.set_scene_parameters(params)
			get_tree().change_scene("res://scenes/match_end/MatchEnd.tscn")
			
		_:
			printerr("Trying to change to nonexistent state")
			return
	
	current_state = new_state


func spawn_ball():
	local_ball = Ball.instance()
	add_child(local_ball)
	local_ball.position = map.match_get_starting_position()
	
	local_ball.setup_playercontroller(PlayerControllerPractice)
	local_ball.set_map(map)
	
	local_ball.connect("turn_completed", self, "_on_Ball_turn_completed")
	local_ball.connect("reached_finish", self, "_on_Ball_reached_finish")

	var cam = MatchCamera.instance()
	local_ball.add_child(cam)
	cam.make_current()


func load_map()->void:
	var map_jstring = yield(MapStorage.load_map_async(map_id, creator_id), "completed")
	map.deserialize(map_jstring)
	change_state(States.PLAYING)


func update_ui():
	var text := ""
	
	match current_state:
		States.LOADING:
			text += "[b]Loading...[/b]"
		States.PLAYING:
			text += "[b]PRACTIC MODE[/b]\n\n"
			text += "Shots: %s" % turn_count
			if verifying:
				text += "\nFinish the map to publish it"
	
	text_score.bbcode_text = text


#### Callbacks

func _on_Ball_turn_completed(local:bool):
	local_ball.turn_ready()
	turn_count += 1


func _on_Ball_reached_finish(final_pos):
	turn_count += 1
	change_state(States.FINISHED)
	


func _on_BtnLeave_pressed():
	if verifying:
		Global.set_scene_parameters({"load_map_id": map_id})
		get_tree().change_scene("res://scenes/editor/Editor.tscn")
	else:
		get_tree().change_scene("res://scenes/menu/Menu.tscn")
