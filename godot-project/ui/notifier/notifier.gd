extends Node

## Notifier Helper
##
## Ingame Notifications:
## - Meant for Player relevant Messages
## - Displayed at child CanvasLayer
## - If Global.DEBUGGING also shows Console Log Messages
##
## Console Logs:
## - For me
## - Printed only with according Global.LOG_LEVEL
##

var _active_notifications:Array

# var TexturePanelRed = preload("res://ui/notifier/popup/notification_panel1.png")
# var TexturePanelYellow = preload("res://ui/notifier/popup/notification_panel2.png")
# var TexturePanelBlue = preload("res://ui/notifier/popup/notification_panel3.png")
# var TexturePanelGreen = preload("res://ui/notifier/popup/notification_panel4.png")
# var TexturePanelWhite = preload("res://ui/assets/panels/panel_white_small.png")
#
const TexturePanelRed = preload("res://ui/assets/panels/metal/panel_red_metal.tres")
const TexturePanelYellow = preload("res://ui/assets/panels/metal/panel_yellow_metal.tres")
const TexturePanelBlue = preload("res://ui/assets/panels/metal/panel_blue_metal.tres")
const TexturePanelGreen = preload("res://ui/assets/panels/metal/panel_green_metal.tres")
const TexturePanelWhite = preload("res://ui/assets/panels/panel_white_small.tres")

var Notification = preload("res://ui/notifier/popup/Notification.tscn")


#### Show InGame Notifications

## Spawn Notification with General Info
func notify_info(title, message = ""):
	_spawn_notification(TexturePanelGreen, title, message, 4.0)


## Spawn Notification with Match Info
func notify_game(title, message = ""):
	_spawn_notification(TexturePanelYellow, title, message, 4.0)


## Spawn Notification with Error
func notify_error(title, message = ""):
	_spawn_notification(TexturePanelRed, title, message, 5.0)


## Spawn Notification for Editor Info
func notify_editor(title, message = ""):
	_spawn_notification(TexturePanelBlue, title, message, 4.0)


## Spawn Notification for Debug Info (hidden if not in Debug Mode)
func notify_debug(title, message = ""):
	_spawn_notification(null, "Dbg: "+str(title), message, 10.0)



#### Print to Console

## Print probably irrelevant info
func log_debug(message = ""):
	_log_console(Global.LogLevel.DEBUG, message)


## Print possibly relevant info
func log_verbose(message = ""):
	_log_console(Global.LogLevel.VERBOSE, message)


## Print info to be aware of
func log_info(message = ""):
	_log_console(Global.LogLevel.INFO, message)


## Print non-fatal error
func log_warning(message = ""):
	_log_console(Global.LogLevel.WARNING, message)


## Print error
func log_error(message = ""):
	_log_console(Global.LogLevel.ERROR, message)



#### Internal

## Print to Console
##
## NOT (Also spawns a Notification if Global.DEBUGGING is enabled)
## and the Log Level is high enough
func _log_console(level:int, message):
	if Global.LOG_LEVEL > level:
		return

	var log_string = ""

	# Add time
#   log_string += "["+str(Time.get_ticks_msec()) +"]"

	# Add log Level
	log_string += "["+Global.LogLevel.keys()[level]+"]"

	# Add Caller Script Name
	var stack = get_stack()
	var caller_script = stack[2]["source"].split("/")[-1]
	var caller_function = stack[2]["function"]
	log_string += " ["+caller_script+":"+caller_function+"]"

	# Add Message
	log_string += ":"+str(message)

	# Push to Godots Debugger if error or warning
	if level >= Global.LogLevel.ERROR:
		push_error(log_string)
		printerr(log_string)
		return

	if level >= Global.LogLevel.WARNING:
		push_warning(log_string)

	# Print to Console
	print(log_string)

	# Show Ingame Notification if DEBUGGING (FIXME dont if console_log is called by a notification)
	# if Global.DEBUGGING:
	# 	notify_debug(log_string)


## Spawn a Ingame Notification (+ console log when debugging)
func _spawn_notification(panel_texture:StyleBoxTexture, title, message, duration:float):
	title = str(title)
	message = str(message)

	# also print to console
	log_verbose("Notification: "+title+" - "+message)

	# instantiate notification and set style
	var inst := Notification.instantiate()
	inst.add_theme_stylebox_override("panel", panel_texture)
	inst.get_node("VBox/LblTitle").text = title
	if message == "":
		inst.get_node("VBox/LblMessage").visible = false #text = ""
	else:
		inst.get_node("VBox/LblMessage").text = message
	add_child(inst)
	_active_notifications.push_front(inst)
	_update_positions()

	# setup fade tween
	var tween = get_tree().create_tween()
	tween.tween_interval(duration)
	tween.tween_property(inst, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN) #, _tween.TRANS_QUAD, _tween.EASE_IN, duration)
	tween.tween_callback(_on_tween_finished.bind(inst))
	inst.mouse_entered.connect(_on_Notification_mouse_entered.bind(inst, tween))
	tween.play()


## Update Notification Positions to account for multiple at once
func _update_positions():
	var next_offset := 0
	
	for i in _active_notifications:
		i.offset_top = next_offset
		next_offset += i.size.y
		next_offset += 8


#### Callbacks

func _on_Notification_mouse_entered(inst, tween):
	# reset fade out tween
	inst.modulate.a = 1.0
	tween.stop()
	tween.play()

func _on_tween_finished(object: Object):
	# delete instance
	object.visible = false
	_active_notifications.erase(object)
	object.queue_free()
	_update_positions()