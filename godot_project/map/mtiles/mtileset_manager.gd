extends Node

# Manager for MTileSets
# Singleton
#
# Can list and load tilesets by id

var _mtilesets = {}

func _init():
	var dir = Directory.new()
	dir.open("res://map/mtiles/mtilesets/")

	dir.list_dir_begin(true, true)
	var file = dir.get_next()
	while file != "":
		var mtileset = load("res://map/mtiles/mtilesets/" + "%s/%s.gd" % [file, file]).new()
		_mtilesets[mtileset.MTILESET_ID] = mtileset
		file = dir.get_next()
	dir.list_dir_end()
	

func get_mtileset(id)->MTileset:
	return _mtilesets[id] as MTileset

func get_mtileset_ids()->Array:
	return _mtilesets.keys()
