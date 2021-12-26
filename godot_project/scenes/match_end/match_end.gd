extends Node2D

onready var text_result = get_node("VBoxContainer/PanelContainer/TextResult")

func _ready():
	var params = Global.get_scene_parameter()

	var text = ""
	text += "[center][b]Match Results:[/b][/center]\n\n"
	text += ""
	var winner := []
	var winner_shots := 99999
	for i in params["presences"]:
		var username = params["presences"][i]["username"]
		var shots = params["turn_count"][i]
		text += "%s: %s\n"%[username,shots]
		
		if shots < winner_shots:
			winner = [username]
			winner_shots = shots
		elif shots == winner_shots:
			winner.append(username)
	
	for i in winner:
		text += "\n[b]%s won[/b]"%i
	
	text += "\n\n\n"
	text += "The Map was [i]%s[/i] by %s"%[params["map_metadata"]["name"],params["map_metadata"]["creator_user_id"]] # TODO get real username (not custom_id)
	text += "\n(MapID %s)"%params["map_metadata"]["id"]
	text_result.bbcode_text = text



func _on_BtnMenu_pressed():
	get_tree().change_scene("res://scenes/menu/Menu.tscn")
