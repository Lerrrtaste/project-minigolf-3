extends Control

@onready var lbl_version = get_node("LblVersion")

@onready var btn_join = get_node("BoxMenu/BtnJoin")
@onready var btn_create = get_node("BoxMenu/BtnCreate")
@onready var btn_editor = get_node("BoxMenu/BtnEditor")
@onready var btn_browser = get_node("BoxMenu/BtnBrowser")
@onready var btn_profile = get_node("BoxMenu/BtnProfile")
@onready var btn_settings = get_node("BoxMenu/BtnSettings")
@onready var btn_logout = get_node("BoxMenu/BtnLogout")

signal scene_finished(result:int)

func _ready():

	# UI
	btn_join.pressed.connect(_on_BtnJoin_pressed)
	btn_create.pressed.connect(_on_BtnCreate_pressed)
	btn_editor.pressed.connect(_on_BtnEditor_pressed)
	btn_profile.pressed.connect(_on_BtnProfile_pressed)
	btn_logout.pressed.connect(_on_BtnLogout_pressed)
	btn_browser.pressed.connect(_on_BtnBrowser_pressed)
	btn_settings.pressed.connect(_on_BtnSettings_pressed)

	lbl_version.text = "Game Version %s"%Global.GAME_VERSION


#### Event Callbacks

func _on_BtnEditor_pressed():
	emit_signal("scene_finished", UiManager.Results.MENU_EDITOR)

func _on_BtnLogout_pressed():
	Networker.logout()
	emit_signal("scene_finished", UiManager.Results.NOT_AUTHENTICATED)

func _on_BtnJoin_pressed():
	emit_signal("scene_finished", UiManager.Results.MENU_JOIN)

func _on_BtnCreate_pressed():
	emit_signal("scene_finished", UiManager.Results.MENU_CREATE)

func _on_BtnProfile_pressed():
	emit_signal("scene_finished", UiManager.Results.MENU_PROFILE)

func _on_BtnSettings_pressed():
	emit_signal("scene_finished", UiManager.Results.MENU_SETTINGS)

func _on_BtnBrowser_pressed():
	emit_signal("scene_finished", UiManager.Results.MENU_BROWSER)
