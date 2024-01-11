extends Control

@onready var btn_mainmenu:Button = get_node("BoxMenu/BtnMainmenu")
@onready var btn_create:Button = get_node("BoxMenu/BtnCreate")

signal scene_finished(result:int)

func _ready():
	btn_mainmenu.pressed.connect(_on_BtnMainMenu_pressed)
	btn_create.pressed.connect(_on_BtnCreate_pressed)

func _on_BtnMainMenu_pressed():
	emit_signal("scene_finished", UiManager.Results.MAIN_MENU)

func _on_BtnCreate_pressed():
	emit_signal("scene_finished", UiManager.Results.EDITOR_CREATE)
