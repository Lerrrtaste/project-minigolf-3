extends Node


#### General ####
signal error(severity,message) #Debug,Info,Warning,Error,Critical


#### Match ####
signal match_created()
signal match_started()
signal match_ended()


#### Player ####
signal player_turn_available()
signal player_turn_completed()


#### Maps ####
signal map_loaded(map_id)
signal map_started_playing(map_id)
signal map_started_editing(map_id)
signal map_completed(map_id)

