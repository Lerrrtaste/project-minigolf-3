extends Node2D


onready var line_customId = get_node("LoginForm/LineCustomId")
onready var lbl_loginStatus = get_node("LoginForm/LblLoginStatus")
onready var btn_matchmaking = get_node("BtnMatchmaking")
onready var select_map = get_node("SelectMap")
onready var btn_login = get_node("LoginForm/BtnLogin")

func _ready():
	# resume previous states
	lbl_loginStatus.text = "Logged in from before" if Networker.is_logged_in() else "NOT logged in!!!"
	if Networker.is_logged_in():
		btn_login.disabled = true
		Networker.socket_connect()
	#btn_matchmaking.disabled = not Networker.is_socket_connected()
	
	Networker.connect("matchmaking_started", self,"_on_Networker_matchmaking_started")
	Networker.connect("matchmaking_ended", self, "_on_Networker_matchmaking_ended")
	Networker.connect("socket_connected", self, "_on_Networker_socket_connected")
	Networker.connect("matchmaking_matched", self, "_on_Networker_matchmaking_matched")
	
	Networker.connect("authentication_successfull", self, "_on_Networker_authentication_successfull")
	Networker.connect("authentication_failed", self, "_on_Networker_authentication_failed")
	
	
	
	# ONLY TEMPORARY, later random map dictated by server
	# populate load dropdown
	var map_files = []
	var dir = Directory.new()
	dir.open(Global.MAPFOLDER_PATH)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif file.ends_with(".map"):
			map_files.append(file)
	dir.list_dir_end()
	
	for i in map_files:
		var file = File.new()
		file.open(Global.MAPFOLDER_PATH + i, File.READ)
		var map_jstring = file.get_as_text()
		file.close()

		var parse = JSON.parse(map_jstring)
		if parse.error != OK:
			printerr("Could not parse map jstring to offer in load drop down")
			continue
		var map_name = parse.result["metadata"]["name"] 
		var map_id = parse.result["metadata"]["id"] 
		
		select_map.add_item(map_name,map_id)
		
	
	
	if true: # autologin
		if not OS.get_cmdline_args().empty():
			line_customId.text = OS.get_cmdline_args()[0]
			#_on_BtnLogin_pressed() #autologin for dbg


#### Event Callbacks

func _on_BtnLogin_pressed():
	Networker.login_async(line_customId.text)


func _on_BtnMatchmaking_pressed():
	if Networker.is_in_matchmaking():
		Networker.matchmaking_cancel_async()
	else:
		Networker.matchmaking_start_async(select_map.get_selected_id())
	
	btn_matchmaking.disabled = true
	btn_matchmaking.text = "..."


func _on_Networker_matchmaking_started():
	btn_matchmaking.text = "Cancel"
	btn_matchmaking.disabled = false


func _on_Networker_matchmaking_ended():
	btn_matchmaking.text = "BATTLE"
	btn_matchmaking.disabled = false


func _on_Networker_socket_connected():
	btn_matchmaking.text = "BATTLE"
	btn_matchmaking.disabled = false


func _on_Networker_matchmaking_matched(matched):
	get_tree().change_scene("res://scenes/match/Match.tscn")


func _on_Networker_authentication_failed():
	lbl_loginStatus.text =  "Could NOT log in!!!"


func _on_Networker_authentication_successfull():
	lbl_loginStatus.text =  "Freshly Logged in :)"
	btn_login.disabled = true


func _on_BtnEditor_pressed():
	if Networker.is_socket_connected():
		get_tree().change_scene("res://scenes/editor/Editor.tscn")


func _on_BtnPractice_pressed():
	Global.set_scene_parameters({ "practice": select_map.get_selected_id() })
	get_tree().change_scene("res://scenes/match/Match.tscn")
