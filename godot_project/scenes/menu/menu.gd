extends Node2D


onready var line_customId = get_node("LoginForm/LineCustomId")
onready var lbl_loginStatus = get_node("LoginForm/LblLoginStatus")
onready var btn_matchmaking = get_node("BtnMatchmaking")
onready var select_map = get_node("SelectMap")
onready var btn_login = get_node("LoginForm/BtnLogin")

func _ready():
	# resume previous states
	
	if Networker.is_logged_in():
		btn_login.disabled = true
		Networker.socket_connect()
		populate_map_dropdown()
		lbl_loginStatus.text = "Logged in from before" 
	else:
		lbl_loginStatus.text = "NOT logged in!!!"
	#btn_matchmaking.disabled = not Networker.is_socket_connected()
	
	Networker.connect("matchmaking_started", self,"_on_Networker_matchmaking_started")
	Networker.connect("matchmaking_ended", self, "_on_Networker_matchmaking_ended")
	Networker.connect("socket_connected", self, "_on_Networker_socket_connected")
	Networker.connect("matchmaking_matched", self, "_on_Networker_matchmaking_matched")
	
	Networker.connect("authentication_successfull", self, "_on_Networker_authentication_successfull")
	Networker.connect("authentication_failed", self, "_on_Networker_authentication_failed")
	
	if true: # autologin
		if not OS.get_cmdline_args().empty():
			line_customId.text = OS.get_cmdline_args()[0]
			_on_BtnLogin_pressed() #autologin for dbg
			Notifier.notify_info("Autologged in because of multirun cmdline args")
	Notifier.notify_game("Press BATTLE to start a game")


func populate_map_dropdown():
	var public_maps = yield(MapStorage.list_public_maps_async(), "completed")
	for i in public_maps:
		select_map.add_item(i.name)
		select_map.set_item_metadata(select_map.get_item_count()-1, i)


#### Event Callbacks

func _on_BtnLogin_pressed():
	Networker.login_async(line_customId.text)


func _on_BtnMatchmaking_pressed():
	if Networker.is_in_matchmaking():
		Networker.matchmaking_cancel_async()
	else:
		var map_id = select_map.get_selected_metadata()["map_id"]
		var owner_id = select_map.get_selected_metadata()["owner_id"]
		Networker.matchmaking_start_async(map_id,owner_id)
	
	btn_matchmaking.disabled = true
	btn_matchmaking.text = "..."


func _on_Networker_matchmaking_started():
	btn_matchmaking.text = "Cancel"
	btn_matchmaking.disabled = false
	Notifier.notify_info("Matchmaking started")


func _on_Networker_matchmaking_ended():
	btn_matchmaking.text = "BATTLE"
	btn_matchmaking.disabled = false
	Notifier.notify_info("Matchmaking cancled")


func _on_Networker_socket_connected():
	btn_matchmaking.text = "BATTLE"
	btn_matchmaking.disabled = false


func _on_Networker_matchmaking_matched(matched):
	Notifier.notify_game("Match found!")
	get_tree().change_scene("res://scenes/match/Match.tscn")
	


func _on_Networker_authentication_failed():
	lbl_loginStatus.text =  "Could NOT log in!!!"
	Notifier.notify_error("Could not log in!")


func _on_Networker_authentication_successfull():
	lbl_loginStatus.text =  "Freshly Logged in :)"
	btn_login.disabled = true
	populate_map_dropdown()
	Notifier.notify_info("Log in successful")


func _on_BtnEditor_pressed():
	if Networker.is_socket_connected():
		get_tree().change_scene("res://scenes/editor_menu/EditorMenu.tscn")


func _on_BtnPractice_pressed():
	Global.set_scene_parameters({ "practice": select_map.get_selected_id() })
	get_tree().change_scene("res://scenes/match/Match.tscn")
