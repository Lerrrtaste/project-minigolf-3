extends Node

"""
Notifier Helper

Prints Notifications to its own CanvasLayer 

Debug notifications show when Global.DEBUG

"""

var active_notifications:Array

var TexturePanelRed = preload("res://helpers/notifier/popup/notification_panel1.png")
var TexturePanelYellow = preload("res://helpers/notifier/popup/notification_panel2.png")
var TexturePanelBlue = preload("res://helpers/notifier/popup/notification_panel3.png")
var TexturePanelGreen = preload("res://helpers/notifier/popup/notification_panel4.png")
var TexturePanelWhite = preload("res://assets/ui/panels/panel_white_small.png")

var Notification = preload("res://helpers/notifier/popup/Notification.tscn")

onready var tween = get_node("Tween")



func _ready():
	tween.connect("tween_completed", self, "_on_tween_completed")


#### Show InGame Notifications

func notify_info(title, message = ""):
	_spawn_notification(TexturePanelGreen, title, message, 4.0)


func notify_game(title, message = ""):
	_spawn_notification(TexturePanelYellow, title, message, 4.0)


func notify_error(title, message = ""):
	_spawn_notification(TexturePanelRed, title, message, 5.0)


func notify_editor(title, message = ""):
	_spawn_notification(TexturePanelBlue, title, message, 4.0)


func notify_debug(title, message = ""):
	if Global.DEBUGGING:
		_spawn_notification(null, "Dbg: "+str(title), message, 10.0)


#### Print to Console
func log_debug(message = ""):
	_log_console(Global.LogLevel.DEBUG, message)


func log_verbose(message = ""):
	_log_console(Global.LogLevel.VERBOSE, message)


func log_info(message = ""):
	_log_console(Global.LogLevel.INFO, message)


func log_warning(message = ""):
	_log_console(Global.LogLevel.WARNING, message)


func log_error(message = ""):
	_log_console(Global.LogLevel.ERROR, message)



#### Internal

func _log_console(level:int, message:String):
	if Global.LOG_LEVEL < level:
		return

    message = "["+str(level)+"] "+str(message)

	# Print Caller for Verbose and Debug Levels
	if Global.LOG_LEVEL <= Global.LogLevel.VERBOSE:
		message += "\n\t"+get_stack()[1]

	# Push to Godots Debugger if error or warning
	if level >= Global.LogLevel.ERROR:
		push_error(message)
	elif level >= Global.LogLevel.WARNING:
		push_warning(message)
	else:
		print(message)


func _spawn_notification(panel_texture:Texture, title, message, duration:float):
	title = str(title)
	message = str(message)
	
	print(title, ": ", message)
	var inst = Notification.instance()
	#inst.get_stylebox("panel").set_texture(panel_texture)
	var stylebox = inst.get_stylebox("panel").duplicate()
	if panel_texture:
		stylebox.set_texture(panel_texture)
	else:
		stylebox = StyleBoxEmpty.new()
	inst.add_stylebox_override("panel",stylebo
x)
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



#### Signal Callbacks

func _on_Notification_mouse_entered():
	pass


func _on_Notification_mouse_exited():
	pass


func _on_tween_completed(object: Object, key: NodePath):
	object.visible = false
	active_notifications.erase(object)
	object.queue_free()
	_update_positions()
