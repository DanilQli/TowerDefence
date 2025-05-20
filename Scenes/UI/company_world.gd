extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(len(get_node("Panel").get_children())):
		get_node("Panel").get_child(i).pressed.connect(game_start.bind(i + 1))
		
func game_start(level):
	GameData.currrent_level = level
	GameData.current_wave = 0
	GameData.FLAG_GAME_COMPANY = true
	get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")


func back() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
