extends Node2D

var MapItem = load("res://scenes/editor_menu/map_item/MapItem.tscn")

onready var container_maps = get_node("Control/PanelContainer/ContainerMaps")
onready var lbl_placeholder = get_node("Control/PanelContainer/ContainerMaps/LblPlaceholder")

var items:Array

func _ready():
	populate_map_list()


func populate_map_list():
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
	MapStorage.delete_map(map_id)
	yield(get_tree().create_timer(0.5),"timeout")
	Notifier.notify_editor("Map deleted")
	populate_map_list()


func _on_MapItem_practice(map_id):
	pass


func _on_BtnCreate_pressed():
	var params = {
		"created_new": true
	}
	Notifier.notify_editor("Creating new map")
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/editor/Editor.tscn")
