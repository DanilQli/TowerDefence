extends Node2D

@onready var map_node = load("res://Scenes/Maps/map_battle_%d.tscn" % randi_range(0, 0)).instantiate()


# Ссылки на контроллеры
var build_controller
var wave_controller
var gift_controller
var ui_controller
var game_end_controller
var health_controller

func _ready():
	for i in range(len(ResourceManager.list_turret)):
		ResourceManager.list_turret[i] = []
	get_node("CanvasLayer/HBoxContainer/Player2Container").add_child(map_node)
	get_node("CanvasLayer/HBoxContainer/Player2Container").move_child(map_node, 0)
