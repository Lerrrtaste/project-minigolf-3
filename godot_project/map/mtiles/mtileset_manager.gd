extends Reference

class_name MTilesManager

# Manager for MTileSets
#
# Can list and load tilesets by id

var _mtilesets = {}

func _init():
	var dir = Directory.new()
	dir.open("res://map/mtiles/mtilesets/")

	dir.list_dir_begin(true, true)
	var file = dir.get_next()
	while file != "":
		var mtileset = load("res://map/mtiles/mtilesets/" + "%s/%s.gd" % [file, file])
		_mtilesets[mtileset.MTILESET_ID] = mtileset
		file = dir.get_next()
	dir.list_dir_end()

func get_mtileset(id)->Reference:
	return _mtilesets[id]

func get_mtileset_ids()->Array:
	return _mtilesets.keys()
