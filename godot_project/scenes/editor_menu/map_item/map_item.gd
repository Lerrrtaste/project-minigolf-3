extends HSplitContainer

onready var lbl_name = get_node("VBoxContainer/LblName")
onready var lbl_id = get_node("VBoxContainer/LblId")
onready var btn_delete = get_node("HBoxContainer/BtnDelete")
onready var btn_edit = get_node("HBoxContainer/BtnEditMap")
onready var btn_practice = get_node("HBoxContainer/BtnPractice")

signal open_editor(map_id)
signal delete(map_id)
signal practice(map_id)

var map_id:String
var delete_confirm := false

func _ready():
	visible = false

func populate(_map_name:String,_map_id:String):
	map_id = _map_id
	lbl_name.text = _map_name
	lbl_id.text = "ID %s"%map_id
	disable_buttons(false)
	visible = true

func _on_BtnPractice_pressed():
	disable_buttons(true)
	emit_signal("practice", map_id)


func _on_BtnEditMap_pressed():
	disable_buttons(true)
	emit_signal("open_editor", map_id)


func _on_BtnDelete_pressed():
	if delete_confirm:
		disable_buttons(true)
		emit_signal("delete", map_id)
		btn_delete.text = "Deleting..."
	else:
		delete_confirm = true
		btn_delete.text = "CONFIRM DELETION"

func disable_buttons(disabled:bool):
	btn_delete.disabled = disabled
	btn_edit.disabled = disabled
	btn_practice.disabled = disabled
