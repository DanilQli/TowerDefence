extends Control

@onready var button_1 = $Panel/MarginContainer/VBoxContainer/TextureButton_1
@onready var button_2 = $Panel/MarginContainer/VBoxContainer/TextureButton_2
@onready var button_3 = $Panel/MarginContainer/VBoxContainer/TextureButton_3
@onready var close_button = $Panel/Close
@onready var main_ui = get_parent().get_node("MarginContainer2")
@onready var search_screen

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
			search_screen = preload("res://Scenes/SupportScenes/search_pvp.tscn").instantiate()
			add_child(search_screen)
			
			var pvp_manager = preload("res://Scenes/SupportScenes/pvp_manager.gd").new()
			pvp_manager.name = "PvPManager" # Даём имя
			pvp_manager.add_to_group("pvp_manager") # Добавляем в группу
			add_child(pvp_manager)
			
			pvp_manager.match_found.connect(_on_match_found)
			pvp_manager.search_failed.connect(_on_search_failed)
			
			pvp_manager.start_search()

func _on_match_found(new_room_id: String, index: int, opp_id: String):
	# Сохраняем данные в глобальный PvPSession
	PvPSession.room_id = new_room_id
	PvPSession.player_index = index
	PvPSession.opponent_id = opp_id
	
	# Получаем player_id из самого менеджера, который его создал
	var pvp_manager = get_node("PvPManager")
	if pvp_manager:
		PvPSession.player_id = pvp_manager.player_id
	
	get_tree().change_scene_to_file("res://Scenes/UI/pvp_game_scene.tscn")

func _on_search_failed():
	search_screen.get_node("Panel/VBoxContainer/Label").text = tr("KEY_SEARCH_PVP_NO")
	await get_tree().create_timer(1).timeout
	search_screen.queue_free()
