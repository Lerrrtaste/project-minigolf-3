extends Node2D

var MapItem = load("res://scenes/editor_menu/map_item/MapItem.tscn")

onready var container_maps = get_node("Control/PanelContainer/ContainerMaps")
onready var lbl_placeholder = get_node("Control/PanelContainer/ContainerMaps/LblPlaceholder")
onready var popup_delete = get_node("Control/PopupDelete")
onready var btn_delete_confirm = get_node("Control/PopupDelete/VBoxContainer/HBoxContainer/BtnDeleteConfirm")
onready var btn_delete_cancel = get_node("Control/PopupDelete/VBoxContainer/HBoxContainer/BtnDeleteCancel")
var deleting_map_id:String
var items:Array

func _ready():
	populate_map_list()


func populate_map_list():
	lbl_placeholder.visible = true
	lbl_placeholder.text = "Loading..."
	
	for i in items:
		i.queue_free()
		i.visible = false
	items.clear()
	
	var owned_maps = yield(MapStorage.list_owned_maps_async(), "completed")
	
	for map_id in owned_maps:
		var inst = MapItem.instance()
		container_maps.add_child(inst)
		inst.populate(owned_maps[map_id],map_id)
		inst.connect("open_editor", self, "_on_MapItem_open_editor")
		inst.connect("delete", self, "_on_MapItem_delete")
		inst.connect("practice", self, "_on_MapItem_practice")
		items.append(inst)
		lbl_placeholder.visible = false
	
	lbl_placeholder.text = "You have no maps. Press create new to start."


func _on_MapItem_open_editor(map_id, map_name):
	var params = {
		"load_map_id": map_id
	}
	Notifier.notify_editor("Opening map %s"%map_name)
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/editor/Editor.tscn")


func _on_MapItem_delete(map_id):
	deleting_map_id = map_id
	btn_delete_confirm.disabled = true
	btn_delete_cancel.disabled = false
	popup_delete.popup_centered()
	yield(get_tree().create_timer(1), "timeout")
	btn_delete_confirm.disabled = false
	


func _on_MapItem_practice(map_id):
	var params = {
		"map_id": map_id,
		"creator_id": Networker.get_user_id(),
		"verifying": false,
	}
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/match_practice/MatchPractice.tscn")


func _on_BtnCreate_pressed():
	var params = {
		"created_new": true
	}
	Notifier.notify_editor("Creating new map")
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/editor/Editor.tscn")


func _on_BtnBack_pressed():
	get_tree().change_scene("res://scenes/menu/Menu.tscn")


func _on_BtnDeleteConfirm_pressed():
	btn_delete_confirm.disabled = true
	btn_delete_cancel.disabled = true
	MapStorage.delete_map(deleting_map_id)
	yield(get_tree().create_timer(0.5),"timeout")
	Notifier.notify_editor("Map deleted")
	populate_map_list()

	deleting_map_id = ""
	popup_delete.visible = false


func _on_BtnDeleteCancel_pressed():
	for i in items:
		if i.map_id == deleting_map_id:
			i.cancle_delete()
			break
	deleting_map_id = ""
	popup_delete.visible = false

