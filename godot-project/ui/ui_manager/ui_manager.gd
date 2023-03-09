extends Control

# UI Manager
#
# The root node for everything
# Instantiates standalone ui scenes as children
#
# StandaloneScene:
# Has one standalone scene at a time
# - UiManager should handle scene switching by listing to networker signals
# - might add signals or expose function tough
#
# TODO Show blocking popup for loading states
# TODO Show fatal error / lost connection popup to reconnect
# TODO Loading state while scenes are initializeing

enum Scenes  {
	LOGIN,
	MAIN_MENU,
}
var _current_scene:CanvasItem

const SCENE_PATHS = {
	Scenes.LOGIN: "res://ui/standalone/login/Login.tscn",
	Scenes.MAIN_MENU: "res://ui/standalone/mainmenu/MainMenu.tscn",
}

@onready var lbl_loading_blocker = $LoadingBlocker
@onready var lbl_error_blocker = $ErrorBlocker

func _ready():
	Networker.socket_connect_successful.connect(_on_Networker_socket_connect_successful)
	change_scene_to(Scenes.LOGIN)


func change_scene_to(standalone_scene:Scenes):
	Notifier.log_info("UiManager: Changing scene to %s" % [standalone_scene])

	# remove old scene
	if _current_scene:
		_current_scene.queue_free()
		_current_scene.visible = false

	# load new scene
	if SCENE_PATHS.has(standalone_scene):
		var scene_path = SCENE_PATHS[standalone_scene]
		var packed_scene = load("res://ui/standalone/login/Login.tscn")
		print(scene_path)
		print(packed_scene)
		_current_scene = packed_scene.instantiate()
		add_child(_current_scene)

		# _change_state(UiStates.DEFAULT)
	else:
		# _change_state(UiStates.EMPTY)
		_current_scene = null
		Notifier.log_error("UiManager: Scene %s not found" % [standalone_scene])



#### Side Effects

func _on_Networker_socket_connect_successful():
	change_scene_to(Scenes.MAIN_MENU)


# func _change_state(new_state):
# 	if _state == new_state:
# 		print("UiManager: State already %s" % [new_state])
# 		return
# 	Notifier.log_info("UiManager: Changing state to %s" % [new_state])
# 	_state = new_state

# 	lbl_loading_blocker.visible = _state == UiStates.LOADING
# 	lbl_error_blocker.visible = _state == UiStates.ERROR
# 	# TODO disable input too

# func _on_Networker_net_state_changed(new_state):
# 	match new_state:
# 		Networker.NetStates.NOT_AUTHENTICATED:
# 			change_scene_to_file(Scenes.LOGIN)
# 		Networker.NetStates.CONNECTION_ERROR:
# 			_change_state(UiStates.ERROR)

# func _on_Networker_loading_changed(is_loading, request):
# 	print("UiManager: Loading changed to %s" % [is_loading])
# 	if is_loading:
# 		_change_state(UiStates.LOADING)
# 	else:
# 		_change_state(UiStates.DEFAULT)
