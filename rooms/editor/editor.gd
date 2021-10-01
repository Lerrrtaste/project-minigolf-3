extends Node2D

onready var map = $Map
onready var map_storage = $MapStorage
onready var list_mapfiles = $LoadingUI/ListMapfiles
onready var btn_load = $LoadingUI/BtnLoad
onready var loading_ui = $LoadingUI
onready var txt_create_id = $LoadingUI/LineCreateID
onready var txt_create_title = $LoadingUI/LineCreateTitle

onready var editing_ui = $EditingUI
onready var list_editing_blocks = $EditingUI/ListBlocks
onready var list_editing_tools = $EditingUI/ListTools
onready var btn_save = $EditingUI/BtnSave
onready var pop_save_path = $EditingUI/PopSavePath

func _ready():
	_populate_mapfiles_list()
	Signals.connect("map_loaded",self,"_on_Map_loaded")
	Signals.connect("map_started_editing",self,"_on_Map_started_editing")


func _populate_mapfiles_list() -> void:
	var mapfiles = map_storage.list_builtin_map_ids()
	
	for i in mapfiles:
		list_mapfiles.add_item(i)
	


func _on_BtnLoad_pressed():
	var selected_idx = list_mapfiles.get_selected_items()[0]
	var selected_mapid = list_mapfiles.get_item_text(selected_idx)
	var packed_map = map_storage.get_packed_map(selected_mapid)
	map.load_packed_map(packed_map)
	map.set_mode_editing()


func _on_BtnCreate_pressed():
	map.create_new(txt_create_title.text,txt_create_id.text)
	map.set_mode_editing()


func _on_Map_loaded(map_id):
	loading_ui.visible = false

func _on_Map_started_editing(map_id):
	editing_ui.visible = true

func _on_BtnSave_pressed():
	pop_save_path.popup_centered()

func _on_PopSavePath_file_selected(path):
	var packed_map = map.get_as_packed_map()
	
	var file = File.new()
	file.open(path,File.WRITE)
	file.store_string(JSON.print(packed_map))
	file.close()
