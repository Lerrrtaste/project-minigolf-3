extends Control


onready var btn_matchmaking = get_node("BtnMatchmaking")
onready var btn_editor = get_node("BtnEditor")
onready var btn_practive = get_node("BtnPractice")

onready var select_map = get_node("SelectMap")
onready var lbl_display_name = get_node("PanelAccount/VBoxContainer/LblDisplayName")
onready var lbl_guest = get_node("PanelAccount/VBoxContainer/LblGuest")
onready var lbl_editor_guest_hint = get_node("BtnEditor/LblEditorGuestHint")

func _ready():
	# resume previous states
	
	if not Networker.is_logged_in():
		get_tree().change_scene("res://scenes/login/Login.tscn")
	
	if not Networker.is_socket_connected():
		btn_matchmaking.disabled = true
		Notifier.notify_error("Reconnecting...", "Server connection was interrupted")
		Networker.socket_connect()
	else:
		load_ui()
		
	
	
	Networker.connect("matchmaking_started", self,"_on_Networker_matchmaking_started")
	Networker.connect("matchmaking_ended", self, "_on_Networker_matchmaking_ended")
	Networker.connect("matchmaking_matched", self, "_on_Networker_matchmaking_matched")
	
	Networker.connect("socket_connected", self, "_on_Networker_socket_connected")


func load_ui():
	lbl_display_name.text = Networker.get_username()
	if not Networker.is_guest():
		btn_editor.disabled = false
		lbl_guest.visible = false
		lbl_editor_guest_hint.visible = false
	refresh_map_selection()


func refresh_map_selection():
	var public_maps = yield(MapStorage.list_public_maps_async(), "completed")
	for i in public_maps:
		select_map.add_item(i.name)
		select_map.set_item_metadata(select_map.get_item_count()-1, i)


#### Event Callbacks

func _on_BtnMatchmaking_pressed():
	if Networker.is_in_matchmaking():
		Networker.matchmaking_cancel_async()
	else:
		var map_id = select_map.get_selected_metadata()["map_id"]
		var owner_id = select_map.get_selected_metadata()["owner_id"]
		Networker.matchmaking_start_async(map_id,owner_id)
	
	btn_matchmaking.disabled = true
	btn_matchmaking.text = "..."


func _on_BtnEditor_pressed():
	get_tree().change_scene("res://scenes/editor_menu/EditorMenu.tscn")


func _on_BtnPractice_pressed():
	Global.set_scene_parameters({ "practice": select_map.get_selected_id() })
	get_tree().change_scene("res://scenes/match/Match.tscn")


func _on_Networker_matchmaking_started():
	btn_matchmaking.text = "Cancel"
	btn_matchmaking.disabled = false
	#btn_matchmaking.theme = load("res://assets/ui/button_red/button_red.tres")
	Notifier.notify_info("Matchmaking started")


func _on_Networker_matchmaking_ended():
	btn_matchmaking.text = "BATTLE"
	btn_matchmaking.disabled = false
	#btn_matchmaking.theme = load("res://assets/ui/button_yellow/button_yellow.tres")
	Notifier.notify_info("Matchmaking cancled")


func _on_Networker_matchmaking_matched(matched):
	Notifier.notify_info("Match found!")
	get_tree().change_scene("res://scenes/match/Match.tscn")
	

func _on_Networker_socket_connected():
	Notifier.notify_info("Connection established")
	load_ui()


func _on_Networker_socket_connection_failed():
	Notifier.notify_error("Could not connect to server")
	get_tree().change_scene("res://scenes/login/Login.tscn")


func _on_BtnLogout_pressed():
	Networker.reset()
	Notifier.notify_info("Logged out")
	get_tree().change_scene("res://scenes/login/Login.tscn")
