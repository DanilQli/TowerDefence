extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(len(get_node("Panel").get_children())):
		get_node("Panel").get_child(i).pressed.connect(game_start.bind(i + 1))
		
func game_start(level):
	GameSession.current_level = level
	GameSession.current_wave = 0
	GameSession.game_mode = GameConstants.GameMode.CAMPAIGN
	get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")


func back() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		get_tree().change_scene_to_file("res://Scenes/Mobile/Menu_mobile.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
