extends Control

@onready var panel_guest = get_node("VBoxContainer/PanelGuest")
@onready var panel_login = get_node("VBoxContainer/PanelEmail")

@onready var lbl_or = get_node("VBoxContainer/LblOr")
@onready var lbl_login = get_node("VBoxContainer/PanelEmail/BoxEmail/LblLogin")

@onready var line_email = get_node("VBoxContainer/PanelEmail/BoxEmail/LineEmail")
@onready var line_password = get_node("VBoxContainer/PanelEmail/BoxEmail/LinePassword")
@onready var line_username_register = get_node("VBoxContainer/PanelEmail/BoxEmail/LineUsernameRegister")
@onready var line_password_confirm = get_node("VBoxContainer/PanelEmail/BoxEmail/LinePasswordConfirm")
@onready var line_username_guest = get_node("VBoxContainer/PanelGuest/BoxGuest/LineUsernameGuest")

@onready var btn_login_email = get_node("VBoxContainer/PanelEmail/BoxEmail/HSplitContainer/BtnLoginEmail")
@onready var btn_login_guest = get_node("VBoxContainer/PanelGuest/BoxGuest/BtnLoginGuest")
@onready var btn_register = get_node("VBoxContainer/PanelEmail/BoxEmail/HSplitContainer/BtnRegister")
@onready var btn_cancel = get_node("VBoxContainer/PanelEmail/BoxEmail/BtnCancel")

signal scene_finished(result:int)


# Results:
# OK: Authenticated and Connected


func _ready():
	# UI
	btn_cancel.pressed.connect(_on_BtnCancel_pressed)
	btn_login_guest.pressed.connect(_on_BtnLoginGuest_pressed)
	btn_login_email.pressed.connect(_on_BtnLoginEmail_pressed)
	btn_register.pressed.connect(_on_BtnRegister_pressed)

	# Networker
	Networker.authentication_requested.connect(_on_Networker_authentication_requested)
	Networker.authentication_successful.connect(_on_Networker_authentication_successful)
	Networker.authentication_failed.connect(_on_Networker_authentication_failed)

	Networker.socket_connect_requested.connect(_on_Networker_socket_connect_requested)
	Networker.socket_connect_successful.connect(_on_Networker_socket_connect_successful)
	Networker.socket_connect_failed.connect(_on_Networker_socket_connect_failed)

	# Try to restore session
	disable_inputs(true)
	if not Networker.restore_session():
		disable_inputs(false)

	# if true: # autologin
	# 	if not OS.get_cmdline_args().is_empty():
	# 		line_username_guest.text = OS.get_cmdline_args()[0]
	# 		_on_BtnLoginGuest_pressed() #autologin for dbg




#### UI Signals

func _on_BtnCancel_pressed():
	register_mode(false)

func _on_BtnLoginGuest_pressed():
	if line_username_guest.text.length() < Global.USERNAME_LENGTH_MIN:
		Notifier.notify_error("Username too short", "Min %s chars"%Global.USERNAME_LENGTH_MIN)
		return

	if line_username_guest.text.length() > Global.USERNAME_LENGTH_MAX:
		Notifier.notify_error("Username too long", "Max %s chars"%Global.USERNAME_LENGTH_MAX)
		return

	Networker.auth_guest(line_username_guest.text)


func _on_BtnLoginEmail_pressed():
	Networker.auth_email(line_email.text, line_password.text, false)


func _on_BtnRegister_pressed():
	if panel_guest.visible:
		register_mode(true)
		Notifier.notify_info("Enter a Username and confirm password to procceed")
		return

	if line_password.text != line_password_confirm.text:
		Notifier.notify_error("The confirmed password is different")
		return

	if line_username_register.text.length() < Global.USERNAME_LENGTH_MIN:
		Notifier.notify_error("Username too short", "Min %s chars"%Global.USERNAME_LENGTH_MIN)
		return

	if line_username_register.text.length() > Global.USERNAME_LENGTH_MAX:
		Notifier.notify_error("Username too long", "Max %s chars"%Global.USERNAME_LENGTH_MAX)
		return

	Networker.auth_email(line_email.text, line_password.text, true, line_username_register.text)



#### Networker Signals

func _on_Networker_authentication_requested():
	Notifier.notify_info("Authenticating...")
	disable_inputs(true)

func _on_Networker_authentication_successful():
	Notifier.notify_info("Authentication successful")
	disable_inputs(true)
	Networker.socket_connect()

func _on_Networker_authentication_failed(error):
	Notifier.notify_error("Authentication failed", error.message)
	disable_inputs(false)


func _on_Networker_socket_connect_requested():
	Notifier.notify_info("Connecting to server...")
	disable_inputs(true)

func _on_Networker_socket_connect_successful():
	Notifier.notify_info("Connected to server")
	disable_inputs(true)
	emit_signal("scene_finished", UiManager.Results.LOGIN_OK)

func _on_Networker_socket_connect_failed(error):
	Notifier.notify_error("Connection failed", error.message)
	disable_inputs(false)



#### Helpers

func disable_inputs(disabled:bool):
	btn_login_email.disabled = disabled
	btn_login_guest.disabled = disabled
	btn_register.disabled = disabled
	line_email.editable = !disabled
	line_password.editable = !disabled
	line_password_confirm.editable = !disabled
	line_username_register.editable = !disabled
	line_username_guest.editable = !disabled

func register_mode(enabled:bool):
	panel_guest.visible = !enabled
	line_password_confirm.visible = enabled
	line_username_register.visible = enabled
	lbl_login.text = "Register" if enabled else "Login"
	btn_login_email.visible = !enabled
	lbl_or.visible = !enabled
	btn_cancel.visible = enabled
