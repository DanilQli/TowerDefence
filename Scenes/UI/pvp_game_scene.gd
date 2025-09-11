# pvp_game_scene.gd — исправленная версия
extends Node2D

@onready var player2_container = $CanvasLayer/HBoxContainer/Player2Container
@onready var map_node_2 = load("res://Scenes/Maps/map_battle_0.tscn").instantiate()

var pvp_manager: Node

func _ready():
	map_node_2.name = "Map"
	player2_container.add_child(map_node_2)
	player2_container.move_child(map_node_2, 0)
	# Инициализация PvP
	pvp_manager = preload("res://Scenes/SupportScenes/pvp_manager.gd").new()
	add_child(pvp_manager)
