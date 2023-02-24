extends RefCounted
class_name MTileData

# Data Object for one Type of MTile
#
# "tname": "N/A",  # Display Name, must be same as in tileset
# "tilemap_id": null,  # Will be set at _ready
# "solid": false,  # only used for object placement rn",
# "friction": 1.0,  # friciton multiplier
# "resets_ball": false,   # Ball will be reset to turn starting position
# "resets_ball_to_start": false, 	# Ball will be reset to map's start
# "texture_path": "res://assets/tiles/placeholder.png",  # For the editor icon
# "layer": "ground",  # Tilemap (all, ground, walls)
# "force": 0, # applied force per second
# "force_direction": Vector2(), # the direction of the force
# "allowed_direction": null, # direction in which balls ignore solid
# "bounce": 1.0, # speed multiplier (* default 0.9)

var tname
var tilemap_id
var mtile_id
var layer
var texture_path
var special_properties = {}

func _init(_mtile_id:int,data:Dictionary):
	# Requred Properties
	self.tname = data["tname"]
	self.tilemap_id = data["tilemap_id"]
	self.mtile_id = _mtile_id
	self.layer = data["layer"]
	self.texture_path = data["texture_path"]

	# Special (optional) Properties
	for key in data:
		if not key in self:
			self.special_properties[key] = data[key]
