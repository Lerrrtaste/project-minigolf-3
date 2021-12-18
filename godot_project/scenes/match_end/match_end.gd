extends Node2D


func _ready():
	print(Global.get_scene_parameter())



func _on_BtnMenu_pressed():
	get_tree().change_scene("res://scenes/menu/Menu.tscn")
