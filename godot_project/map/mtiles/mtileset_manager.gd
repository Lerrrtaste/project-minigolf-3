extends Reference

# Manager for MTileSets
#
# Can list and load tilesets by id

var _mtilesets = {}

func _init():
	var dir = Directory.new()
	if dir.open("../mtilesets") != OK:
		Notifier.notify_debug("No mtilesets directory found")
		return

	dir.list_dir_begin(true, true)
	var file = dir.get_next()
	while file != "":
		if file.ends_with(".gd"):
			var mtileset = load("res://mtilesets/" + file)
			_mtilesets[mtileset.MTILESET_ID] = mtileset
		file = dir.get_next()
	dir.list_dir_end()

	if _mtilesets.size() == 0:
		Notifier.notify_debug("No mtilesets found")

func get_mtileset(id)->MTileSet:
	if _mtilesets.has(id):
		return _mtilesets[id]
	else:
		Notifier.notify_debug("No mtileset found with id: " + str(id))
		return null

func get_mtileset_ids()->Array:
	return _mtilesets.keys()
