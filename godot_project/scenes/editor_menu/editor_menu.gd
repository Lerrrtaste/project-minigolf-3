extends Node2D

var MapItem = load("res://scenes/editor_menu/map_item/MapItem.tscn")

onready var container_maps = get_node("Control/PanelContainer/ContainerMaps")

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
		


func _on_MapItem_open_editor(map_id):
	var params = {
		"load_map_id": map_id
	}
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/editor/Editor.tscn")


func _on_MapItem_delete(map_id):
	MapStorage.delete_map(map_id)
	yield(get_tree().create_timer(0.5),"timeout")
	populate_map_list()


func _on_MapItem_practice(map_id):
	pass


func _on_BtnCreate_pressed():
	var params = {
		"created_new": true
	}
	Global.set_scene_parameters(params)
	get_tree().change_scene("res://scenes/editor/Editor.tscn")
