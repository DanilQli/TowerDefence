extends Control

@onready var button_1 = $Panel/MarginContainer/VBoxContainer/TextureButton_1
@onready var button_2 = $Panel/MarginContainer/VBoxContainer/TextureButton_2
@onready var button_3 = $Panel/MarginContainer/VBoxContainer/TextureButton_3
@onready var close_button = $Panel/Close
@onready var main_ui = get_parent().get_node("MarginContainer2")

func _ready():
	button_1.pressed.connect(_on_mode_selected.bind(1))
	button_2.pressed.connect(_on_mode_selected.bind(2))
	button_3.pressed.connect(_on_mode_selected.bind(3))
	close_button.pressed.connect(_on_close)

func _on_close():
	get_parent().get_node("MarginContainer2").visible = true
	get_parent().get_node("Reward").visible = true
	get_node(".").queue_free()
	
func _on_mode_selected(index):
	match index:
		1:
			get_tree().change_scene_to_file("res://Scenes/UI/company_world.tscn")
		2:
			GameSession.current_level = 0
			GameSession.current_wave = 0
			GameSession.game_mode = GameConstants.GameMode.SANDBOX
			get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")
