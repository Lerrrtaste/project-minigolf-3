extends Control

"""
Show Results after Match is finished

Parameters:
	- gamemode ("default" / "practice")
	- map_metadata
	- turn_count: dict / int ("practice")
	- presences ("default")
	- verifying ("practice"), optional

Exits to
	- EditorMenu when published
	- Editor
		load_map_id = map_metadata.id
	- Menu

"""

var map_id:String

onready var text_result = get_node("VBoxContainer/PanelContainer/TextResult")

onready var box_publish = get_node("VBoxContainer/BoxPublish")
onready var btn_menu = get_node("VBoxContainer/BtnMenu")

func _ready():
	var params = Global.get_scene_parameter()
	if not params.has("gamemode"):
		text_result.bbcode_text = "Your match did not specify a gamemode :( Cant show any info (This is an error)"
		return
	
	var text = ""
	match params.gamemode:
		"practice":
			if not params.has_all(["turn_count", "map_metadata"]):
				text = "Error: Parameters incomplete"
				return
				
			text = "Finished Map in %s shots."%params["turn_count"]
			if params.has("verifying"):
				if params.verifying:
					btn_menu.visible = false
					box_publish.visible = true
					map_id = params.map_metadata.id
					text += "\n\n[b] -- You can now publish your map -- [/b]"
		"default":
			text += "[center][b]Match Results:[/b][/center]\n\n"
			text += ""
			var winner := []
			var winner_shots := 99999
			for i in params["presences"]:
				var username = params["presences"][i]["username"]
				if not params["turn_count"].has(i):
					continue
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
			text += "The Map was \"%s\" by %s"%[params["map_metadata"]["name"],params["map_metadata"]["creator_display_name"]]
			text += "\n(MapID %s)"%params["map_metadata"]["id"]
	
	text_result.bbcode_text = text



func _on_BtnMenu_pressed():
	get_tree().change_scene("res://scenes/menu/Menu.tscn")


func _on_BtnPublish_pressed():
	var result = yield(MapStorage.publish_map_async(map_id), "completed")
	if result.is_exception():
		Notifier.notify_error("Publishing Map failed", result.to_string())
	else:
		Notifier.notify_info("Your map is now published")
	get_tree().change_scene("res://scenes/editor_menu/EditorMenu.tscn")


func _on_BtnEditor_pressed():
	var params = {
		"load_map_id": map_id
	}
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/editor/Editor.tscn")
