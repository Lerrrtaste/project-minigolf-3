extends Control

onready var panel_guest = get_node("VBoxContainer/PanelGuest")
onready var line_username_guest = get_node("VBoxContainer/PanelGuest/BoxGuest/LineUsernameGuest")
onready var btn_login_guest = get_node("VBoxContainer/PanelGuest/BoxGuest/BtnLoginGuest")

onready var lbl_or = get_node("VBoxContainer/LblOr")

onready var panel_login = get_node("VBoxContainer/PanelEmail")
onready var line_email = get_node("VBoxContainer/PanelEmail/BoxEmail/LineEmail")
onready var line_password = get_node("VBoxContainer/PanelEmail/BoxEmail/LinePassword")
onready var line_username_register = get_node("VBoxContainer/PanelEmail/BoxEmail/LineUsernameRegister")
onready var line_password_confirm = get_node("VBoxContainer/PanelEmail/BoxEmail/LinePasswordConfirm")
onready var btn_login_email = get_node("VBoxContainer/PanelEmail/BoxEmail/HSplitContainer/BtnLoginEmail")
onready var btn_register = get_node("VBoxContainer/PanelEmail/BoxEmail/HSplitContainer/BtnRegister")
onready var lbl_login = get_node("VBoxContainer/PanelEmail/BoxEmail/LblLogin")
onready var btn_cancel = get_node("VBoxContainer/PanelEmail/BoxEmail/BtnCancel")


func _ready():
	# resume previous states
	if Networker.is_logged_in():
		if Networker.is_socket_connected():
			login_complete()
		else:
			Networker.socket_connect_async()
	
	Networker.connect("socket_connected", self, "_on_Networker_socket_connected")
	Networker.connect("socket_connection_failed", self, "_on_Networker_socket_connection_failed")
	
	Networker.connect("authentication_failed", self, "_on_Networker_authentication_failed")
	
	if true: # autologin
		if not OS.get_cmdline_args().empty():
			line_username_guest.text = OS.get_cmdline_args()[0]
			_on_BtnLoginGuest_pressed() #autologin for dbg


# called when socket is connected
func login_complete():
	#Notifier.notify_info("Connected", "As %s"%Networker.get_username(true))
	get_tree().change_scene("res://scenes/menu/Menu.tscn")


func disable_inputs(disabled:bool):
	btn_login_email.disabled = disabled
	btn_login_guest.disabled = disabled
	btn_register.disabled = disabled
	line_email.editable = !disabled
	line_password.editable = !disabled
	line_password_confirm.editable = !disabled
	line_username_register.editable = !disabled
	line_username_guest.editable = !disabled

#### Event Callbacks

func _on_Networker_socket_connected():
	login_complete()

func register_mode(enabled:bool):
	panel_guest.visible = !enabled
	line_password_confirm.visible = enabled
	line_username_register.visible = enabled
	lbl_login.text = "Register" if enabled else "Login"
	btn_login_email.visible = !enabled
	lbl_or.visible = !enabled
	btn_cancel.visible = enabled 


func _on_Networker_socket_connection_failed():
	Notifier.notify_error("Connection failed", "This might be a temporary server problem\nPlease try again\n(Socket connection failed)")
	disable_inputs(false)


func _on_Networker_authentication_failed(exception):
	#Notifier.notify_error("Login failed :/",str(exception.message))
	disable_inputs(false)


func _on_BtnLoginGuest_pressed():
	if line_username_guest.text.length() < Global.USERNAME_LENGTH_MIN:
		Notifier.notify_error("Username too short", "Min %s chars"%Global.USERNAME_LENGTH_MIN)
		return
	
	if line_username_guest.text.length() > Global.USERNAME_LENGTH_MAX:
		Notifier.notify_error("Username too long", "Max %s chars"%Global.USERNAME_LENGTH_MAX)
		return
	disable_inputs(true)
	Networker.login_guest_asnyc(line_username_guest.text)
	

func _on_BtnLoginEmail_pressed():
	disable_inputs(true)
	Networker.login_email_async(line_email.text, line_password.text)
	


func _on_BtnRegister_pressed():
	if panel_guest.visible:
		register_mode(true)
		Notifier.notify_info("Enter a Username and confirm password to proceed")
		
	else:
		
		if line_password.text != line_password_confirm.text:
			Notifier.notify_error("The confirmed password is different")
			return
		
		if line_username_register.text.length() < Global.USERNAME_LENGTH_MIN:
			Notifier.notify_error("Username too short", "Min %s chars"%Global.USERNAME_LENGTH_MIN)
			return
		
		if line_username_register.text.length() > Global.USERNAME_LENGTH_MAX:
			Notifier.notify_error("Username too long", "Max %s chars"%Global.USERNAME_LENGTH_MAX)
			return
			
		disable_inputs(true)
		Networker.register_email_async(line_email.text, line_password.text, line_username_register.text)
			


func _on_BtnCancel_pressed():
	register_mode(false)
