extends Control

# UI Manager
#
# The root node for everything
# Instantiates standalone ui scenes as children
#
# Changes when
# - UiManager.change_ui_state(new_state) is called
# - networker signals like not_authenticated, authenticated, etc

enum UiStates {
	NONE,
	LOGIN,
	MAIN_MENU,
}
var _state = UiStates.NONE
var _state_scene:CanvasItem
var _loading := false

var _state_scene_paths = {
	UiStates.LOGIN: "res://ui/standalone/login/Login.tscn",
	UiStates.MAIN_MENU: "res://ui/standalone/mainmenu/MainMenu.tscn",
}


func _ready():
	Networker.connect("net_state_changed", self, "_on_Networker_net_state_changed")
	change_ui_state(UiStates.LOGIN) # later check if networker is (still) authenticated


func change_ui_state(new_state):
	Notifier.log_info("UiManager: change_ui_state: %s" % str(new_state))
	_state = new_state

	# remove old scene
	if _state_scene:
		_state_scene.queue_free()
		_state_scene.visible = false

	# load new scene
	_state_scene = load(_state_scene_paths[_state]).instance()
	add_child(_state_scene)


func _on_Networker_net_state_changed(new_state):
	match new_state:
		Networker.NetStates.NOT_AUTHENTICATED:
			change_ui_state(UiStates.LOGIN)
