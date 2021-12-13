extends Node2D


onready var line_customId = get_node("LoginForm/LineCustomId")
onready var lbl_loginStatus = get_node("LoginForm/LblLoginStatus")
onready var btn_matchmaking = get_node("BtnMatchmaking")


func _ready():
	lbl_loginStatus.text = "Logged in from before" if Networker.is_logged_in() else "NOT logged in!!!"
	
	Networker.connect("matchmaking_started", self,"_on_Networker_matchmaking_started")
	Networker.connect("matchmaking_ended", self, "_on_Networker_matchmaking_ended")
	Networker.connect("socket_connected", self, "_on_Networker_socket_connected")
	Networker.connect("matchmaking_matched", self, "_on_Networker_matchmaking_matched")
	
	Networker.connect("authentication_successfull", self, "_on_Networker_authentication_successfull")
	Networker.connect("authentication_failed", self, "_on_Networker_authentication_failed")
	
	_on_BtnLogin_pressed()
	

#### Event Callbacks

func _on_BtnLogin_pressed():
	Networker.login_async(line_customId.text)


func _on_BtnMatchmaking_pressed():
	if Networker.is_in_matchmaking():
		Networker.matchmaking_cancel_async()
	else:
		Networker.matchmaking_start_async()
	
	btn_matchmaking.disabled = true
	btn_matchmaking.text = "..."


func _on_Networker_matchmaking_started():
	btn_matchmaking.text = "Cancel"
	btn_matchmaking.disabled = false


func _on_Networker_matchmaking_ended():
	btn_matchmaking.text = "Battle"
	btn_matchmaking.disabled = false


func _on_Networker_socket_connected():
	btn_matchmaking.text = "Battle"
	btn_matchmaking.disabled = false


func _on_Networker_matchmaking_matched(matched):
	get_tree().change_scene("res://scenes/match/Match.tscn")


func _on_Networker_authentication_failed():
	lbl_loginStatus.text =  "Could NOT log in!!!"
	
func _on_Networker_authentication_successfull():
	lbl_loginStatus.text =  "Freshly Logged in :)"


func _on_BtnEditor_pressed():
	get_tree().change_scene("res://scenes/editor/Editor.tscn")
