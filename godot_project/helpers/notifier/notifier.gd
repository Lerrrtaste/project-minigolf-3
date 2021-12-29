extends Node

var active_notifications:Array

var TexturePanelRed = preload("res://helpers/notifier/popup/notification_panel1.png")
var TexturePanelYellow = preload("res://helpers/notifier/popup/notification_panel2.png")
var TexturePanelBlue = preload("res://helpers/notifier/popup/notification_panel3.png")
var TexturePanelGreen = preload("res://helpers/notifier/popup/notification_panel4.png")
var TexturePanelWhite = preload("res://assets/ui/panels/panel_white_small.tres")

var Notification = preload("res://helpers/notifier/popup/Notification.tscn")

onready var tween = get_node("Tween")

func _ready():
	tween.connect("tween_completed", self, "_on_tween_completed")

# TODO allow non strings and do str() everywhere

func notify_info(title:String, message:String = ""):
	_spawn_notification(TexturePanelGreen, title, message, 3.0)


func notify_game(title:String, message:String = ""):
	_spawn_notification(TexturePanelYellow, title, message, 3.0)


func notify_error(title:String, message:String = ""):
	_spawn_notification(TexturePanelRed, title, message, 3.0)


func notify_editor(title:String, message:String = ""):
	_spawn_notification(TexturePanelBlue, title, message, 3.0)

func notify_debug(title, message:String = ""):
	_spawn_notification(TexturePanelWhite, "Dbg: "+str(title), message, 3.0)


func notify(color:String, message:String, title:String, duration:float):
	pass


func _spawn_notification(panel_texture:Texture, title:String, message:String, duration:float):
	print(title, ": ", message)
	var inst = Notification.instance()
	#inst.get_stylebox("panel").set_texture(panel_texture)
	var stylebox = inst.get_stylebox("panel").duplicate()
	stylebox.set_texture(panel_texture)
	inst.add_stylebox_override("panel",stylebox)
	inst.get_node("VBox/LblTitle").text = title
	if message == "":
		inst.get_node("VBox/LblMessage").visible = false #text = ""
	else:
		inst.get_node("VBox/LblMessage").text = message
	add_child(inst)
	active_notifications.push_front(inst)
	_update_positions()
	
	tween.interpolate_property(inst, "modulate:a", 1.0, 0.0, 1.0, tween.TRANS_QUAD, tween.EASE_IN, duration)
	tween.start()


func _update_positions():
	var next_offset := 0
	
	for i in active_notifications:
		i.margin_top = next_offset
		next_offset += i.rect_size.y
		next_offset += 8


func _on_Notification_mouse_entered():
	pass

func _on_Notification_mouse_exited():
	pass

func _on_tween_completed(object: Object, key: NodePath):
	object.visible = false
	active_notifications.erase(object)
	object.queue_free()
	_update_positions()
