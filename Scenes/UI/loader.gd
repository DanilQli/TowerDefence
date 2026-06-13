# Loader.gd
extends Node

func _ready():
	# Ждем первого кадра отрисовки
	await get_tree().process_frame
	await get_tree().process_frame
	
	_load_correct_menu()

func _load_correct_menu():
	var scene_path = "res://Scenes/UI/Menu.tscn"
	
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		scene_path = "res://Scenes/Mobile/Menu_mobile.tscn"
	
	# Безопасная смена сцены
	call_deferred("_change_scene_safe", scene_path)

func _change_scene_safe(path):
	get_tree().change_scene_to_file(path)
