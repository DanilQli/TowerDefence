extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Panel/MarginContainer/VBoxContainer/TextureButton_1").pressed.connect(choose_game_mode.bind(1))
	get_node("Panel/MarginContainer/VBoxContainer/TextureButton_2").pressed.connect(choose_game_mode.bind(2))
	get_node("Panel/MarginContainer/VBoxContainer/TextureButton_3").pressed.connect(choose_game_mode.bind(3))
	get_node("Panel/Close").pressed.connect(close)

func close():
	get_node(".").queue_free()
	
func choose_game_mode(index):
	match index:
		1:
			get_tree().change_scene_to_file("res://Scenes/UI/company_world.tscn")
		2:
			get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")

	
