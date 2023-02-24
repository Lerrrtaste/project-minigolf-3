extends Node

# MapData Handler
# Singleton
#
# !Accesses Networker!
#
# - Only ever return maps that are present checked the server
#   (saves the headache later hopefully)
#   (no new empty maps for editor without creating collection object first!)
#
# - MapDetail Standalone ui should proabaly be the only scene that handles the mapdata by itself
#   because it would need more stats etc. (Or not? Maybe strictly here?)


#### Retrieve Maps

func get_map_data(map_id:String)->MapData:
	pass

func get_map_scene(map_id:String)->PackedScene:
	pass

func get_map_card(map_id:String)->PackedScene:
	pass


#### Modify stored Maps

func update_map_data(map_id:String, map_data:MapData):
	pass

func delete_map_data(map_id:String):
	pass


#### List stored  Maps

func list_public_map_ids()->Array:
	pass

func list_own_map_ids()->Array:
	pass


#### Helpers

func get_new_map_uuid()->String:
	pass


#### Internal

func _create_map_data_object()->MapData:
	pass

func _serialize_map_data(map_data:MapData)->Dictionary:
	pass

func _deserialize_map_data(map_data_dict:Dictionary)->MapData:
	pass

#### Internal - Networker

func _net_read_mapdata_object(map_id:String, owner_id:String)->MapData:
	pass

func _net_write_mapdata_object(map_id:String, map_data:MapData):
	pass

func _net_delete_mapdata_object(map_id:String):
	pass

func _net_list_mapdata_object_ids()->Array: # TODO userid filter
	pass

func _net_get_new_map_uuid()->String:
	pass
