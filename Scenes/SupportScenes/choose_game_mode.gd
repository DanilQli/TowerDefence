extends Control

@onready var button_1 = $Panel/MarginContainer/VBoxContainer/TextureButton_1
@onready var button_2 = $Panel/MarginContainer/VBoxContainer/TextureButton_2
@onready var button_3 = $Panel/MarginContainer/VBoxContainer/TextureButton_3
@onready var close_button = $Panel/Close
@onready var main_ui = get_parent().get_node("MarginContainer2")
var search

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
		3:
			search = preload("res://Scenes/SupportScenes/search_pvp.tscn").instantiate()
			add_child(search)
			var pvp_matchmaker = preload("res://Scenes/SupportScenes/pvp_manager.gd").new()
			add_child(pvp_matchmaker)
			
			pvp_matchmaker.match_found.connect(_on_match_found)
			pvp_matchmaker.search_failed.connect(_on_search_failed)
			
			pvp_matchmaker.start_search()

func _on_match_found(new_room_id: String, index: int):
	get_tree().change_scene_to_file("res://Scenes/UI/pvp_game_scene.tscn")

func _on_search_failed():
	search.get_node("Panel/VBoxContainer/Label").text = tr("KEY_SEARCH_PVP_NO")
	await get_tree().create_timer(1).timeout
	search.queue_free()
