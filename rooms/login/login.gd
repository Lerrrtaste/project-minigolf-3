extends Control

onready var server_connection = $ServerConnection
onready var edit_login_name = $LoginName
onready var btn_login = $LoginName/Button


func _ready():
	pass#_on_Button_pressed()


func _on_Button_pressed():
	btn_login.disabled = true
	var custom_id = edit_login_name.text
	var result = yield(server_connection.authenticate_custom_async(custom_id),"completed")
	
	if result:
		print("User authenticated successfully. %s"%custom_id)
	else:
		printerr("User authentication failed! Error %s (%s)"%[result,custom_id])
