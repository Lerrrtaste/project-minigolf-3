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

class_name UiManager

enum Scenes  {
	LOGIN,
	MAIN_MENU,

	MATCH_JOIN,
	MATCH_CREATE,

	MATCH_LOBBY,
	MATCH,
	MATCH_END,

	EDITOR_MENU,
	EDITOR,

	MAP_BROWSER,
	MAP_DETAIL,
	PLAYLIST,

	SETTINGS,
	PROFILE,
}
var _current_scene:CanvasItem

const SCENE_PATHS = {
	Scenes.LOGIN: "res://ui/standalone/login/Login.tscn",
	Scenes.MAIN_MENU: "res://ui/standalone/mainmenu/MainMenu.tscn",
	Scenes.EDITOR_MENU: "res://ui/standalone/editormenu/EditorMenu.tscn",
}

enum Results {
	LOGIN_OK,
	NOT_AUTHENTICATED,

	MENU_EDITOR,
	MENU_BROWSER,
	MENU_JOIN,
	MENU_CREATE,
	MENU_PROFILE,
	MENU_SETTINGS,

	EDITOR_CREATE,
	EDITOR_EDIT,

	MAIN_MENU,

	# NOT_AUTHENTICATED,
	# NOT_CONNECTED,
	}

@onready var lbl_loading_blocker = $LoadingBlocker
@onready var lbl_error_blocker = $ErrorBlocker

func _ready():
	change_scene_to(Scenes.LOGIN)


func change_scene_to(standalone_scene:Scenes):
	Notifier.log_info("UiManager: Changing scene to %s" % [standalone_scene])

	# remove old scene
	if _current_scene:
		_current_scene.queue_free()
		_current_scene.visible = false

	# Check Session
	if (standalone_scene != Scenes.LOGIN) and (not await Networker.check_session_async()):
		Networker.logout()
		change_scene_to(Scenes.LOGIN)
		Notifier.log_error("UiManager: Session expired")
		return

	# load new scene
	if SCENE_PATHS.has(standalone_scene):
		var scene_path = SCENE_PATHS[standalone_scene]
		var packed_scene = load(scene_path)
		print(scene_path)
		print(packed_scene)
		_current_scene = packed_scene.instantiate()
		_current_scene.scene_finished.connect(_on_scene_finished)
		add_child(_current_scene)

	else:
		_current_scene = null
		Notifier.log_error("UiManager: Scene %s not found" % [standalone_scene])



#### Side Effects

# func _on_Networker_socket_connect_successful():
# 	change_scene_to(Scenes.MAIN_MENU)

func _on_scene_finished(result:Results):
	match result:
		Results.LOGIN_OK:
			change_scene_to(Scenes.MAIN_MENU)

		Results.MENU_JOIN:
			change_scene_to(Scenes.MAP_BROWSER)
		Results.MENU_CREATE:
			change_scene_to(Scenes.MATCH_CREATE)

		Results.MENU_EDITOR:
			change_scene_to(Scenes.EDITOR_MENU)
		Results.MENU_BROWSER:
			change_scene_to(Scenes.MAP_BROWSER)

		Results.MENU_PROFILE:
			change_scene_to(Scenes.PROFILE)
		Results.MENU_SETTINGS:
			change_scene_to(Scenes.SETTINGS)
		Results.NOT_AUTHENTICATED:
			change_scene_to(Scenes.LOGIN)

		Results.MAIN_MENU:
			change_scene_to(Scenes.MAIN_MENU)

		_:
			Notifier.log_error("UiManager: scene finished with invalid result %s" % [result])
