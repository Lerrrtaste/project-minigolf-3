extends Control

var MapCard = preload("res://objects/map_card/MapCard.tscn")

onready var btn_matchmaking = get_node("BtnMatchmaking")
onready var btn_editor = get_node("BtnMatchmaking/BtnEditor")
onready var btn_logout = get_node("BtnLogout")

onready var box_map_cards = get_node("ContainerMaps/BoxMapCards")
var map_cards:Array

onready var lbl_display_name = get_node("PanelAccount/VBoxContainer/LblDisplayName")
onready var lbl_guest = get_node("PanelAccount/VBoxContainer/LblGuest")
onready var lbl_editor_guest_hint = get_node("BtnMatchmaking/BtnEditor/LblEditorGuestHint")
onready var lbl_version = get_node("LblVersion")

func _ready():
	# resume previous states
	
	if not Networker.is_logged_in():
		get_tree().change_scene("res://scenes/login/Login.tscn")
	
	if not Networker.is_socket_connected():
		disable_input(true)
		Notifier.notify_error("Reconnecting...", "Server connection was interrupted")
		Networker.socket_connect_async()
	else:
		load_ui()
	
	
	Networker.connect("matchmaking_started", self,"_on_Networker_matchmaking_started")
	Networker.connect("matchmaking_ended", self, "_on_Networker_matchmaking_ended")
	Networker.connect("matchmaking_matched", self, "_on_Networker_matchmaking_matched")
	
	Networker.connect("socket_connected", self, "_on_Networker_socket_connected")
	Networker.connect("socket_connection_failed", self, "_on_Networker_socket_connection_failed")

func load_ui():
	lbl_display_name.text = Networker.get_username(true)
	if not Networker.is_guest():
		btn_editor.disabled = false
		lbl_guest.visible = false
		lbl_editor_guest_hint.visible = false
	refresh_map_selection()
	lbl_version.text = "Game Version %s"%Global.GAME_VERSION


func refresh_map_selection():
	var public_maps = yield(MapStorage.list_public_maps_async(), "completed")
	for i in public_maps:
		var map_name = i.name
		var creator_name = i.creator_name
		var map_id = i.map_id
		var creator_id = i.creator_id
		
		var inst = MapCard.instance()
		box_map_cards.add_child(inst)
		inst.populate(map_name, map_id, creator_id, creator_name)
		inst.connect("practice", self, "_on_MapCard_practice")
		
		map_cards.append(inst)

func get_maps_included()->Array:
	var map_pool:Array
	for i in map_cards:
		if i.is_included():
			map_pool.append({
				"map_id": i.map_id,
				"creator_id": i.creator_id
			})
	return map_pool


func disable_input(disabled:bool):
	btn_logout.disabled = disabled
	btn_editor.disabled = disabled
	for i in map_cards:
		i.disable_input(disabled)

#### Event Callbacks

func _on_BtnMatchmaking_pressed():
	if Networker.is_in_matchmaking():
		Networker.matchmaking_cancel_async()
		
	else:
		var map_pool = get_maps_included()
		if map_pool.size() == 0:
			Notifier.notify_error("Select at least one map", "or more")
			return
		
		Networker.matchmaking_start_async(map_pool)
		
#		var map_id = select_map.get_selected_metadata()["map_id"]
#		var owner_id = select_map.get_selected_metadata()["owner_id"]
#		Networker.matchmaking_start_async(map_id,owner_id)
	
	btn_matchmaking.disabled = true
	btn_matchmaking.text = "..."


func _on_BtnEditor_pressed():
	get_tree().change_scene("res://scenes/editor_menu/EditorMenu.tscn")


func _on_Networker_matchmaking_started():
	btn_matchmaking.text = "Cancel"
	btn_matchmaking.disabled = false
	btn_matchmaking.theme = load("res://assets/ui/buttons/big/red/button_red_big.tres")
	
	disable_input(true)
	
	Notifier.notify_info("Matchmaking started")


func _on_Networker_matchmaking_ended():
	btn_matchmaking.text = "BATTLE"
	btn_matchmaking.disabled = false
	btn_matchmaking.theme = load("res://assets/ui/buttons/big/yellow/button_yellow_big.tres")
	
	disable_input(false)
	
	Notifier.notify_info("Matchmaking cancled")


func _on_Networker_matchmaking_matched(matched):
	Notifier.notify_info("Match found!")
	get_tree().change_scene("res://scenes/match_default/MatchDefault.tscn")
	

func _on_Networker_socket_connected():
	Notifier.notify_info("Connection established")
	load_ui()
	disable_input(false)


func _on_Networker_socket_connection_failed():
	Notifier.notify_error("Could not connect to server")
	get_tree().change_scene("res://scenes/login/Login.tscn")


func _on_BtnLogout_pressed():
	Networker.reset()
	Notifier.notify_info("Logged out")
	get_tree().change_scene("res://scenes/login/Login.tscn")


func _on_MapCard_practice(map_id, creator_id):
	var params = { "map_id": map_id, "creator_id": creator_id, "verifying": false}
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/match_practice/MatchPractice.tscn")


func _on_LineEdit_text_changed(search_text):
	for i in map_cards:
		if search_text == "":
			i.visible = true
		elif i.map_id.find(search_text)!=-1:
			i.visible = true
		elif i.map_name.to_lower().find(search_text.to_lower())!=-1:
			i.visible = true
		else:
			i.visible = false
