extends Control

func _ready():
	print("Getting mtileset 1 from MTilesetManager")
	var mtset = MTilesetManager.get_mtileset(1)
	print("Got: ", mtset)

	print("Getting tile GRASS")
	var tiledata = mtset.get_mtile_data(mtset.MTiles.LAVA)
	Vector2(2,2)
	tiledata
	print(tiledata.tname)
	print(tiledata.mtile_id)
	print(tiledata.special_properties)

	var mobjs = MObjectManager
	print(mobjs.get_mobject_properties(mobjs.MObjects.FINISH))
	print(mobjs.get_mobject_scene(mobjs.MObjects.START))
