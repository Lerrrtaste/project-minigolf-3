extends Reference
class_name MapData

# MapData
#
# Contains metadata and the tile-layout and object positions of the map.

# map data
var mtiles: Array # 2d array of mtile_ids
var mobjects: Dictionary # key is vec2 pos, value is mobject_id
var mtileset_id: int # (not really used yet)

# metadata
var mname: String
var map_id: String
var creator_player_id: String
var description: String

func get_map_size() -> Vector2:
	return Vector2(mtiles.size(), mtiles[0].size())
