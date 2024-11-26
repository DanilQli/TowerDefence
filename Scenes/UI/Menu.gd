extends Control

var menu

func _ready():
	TranslationServer.set_locale(GameData.config.get_value("settings_game", "language"))
	DisplayServer.window_set_size(Vector2i(GameData.config.get_value("settings_game", "width"), GameData.config.get_value("settings_game", "height")))
	get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/TextureButton_1").pressed.connect(on_new_game_pressed) 
	get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/TextureButton_2").pressed.connect(settings)
	get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/TextureButton_3").pressed.connect(on_quit_pressed)
	get_node("MarginContainer2/Panel/MarginContainer/VBoxContainer/TextureButtonShop").pressed.connect(shop)
	

func on_new_game_pressed():
	menu = load("res://Scenes/SupportScenes/choose_game_mode.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(menu)

func shop():
	menu = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(menu)
	
func settings():
	get_tree().change_scene_to_file("res://Scenes/UI/MenuSettings.tscn")
	
func on_quit_pressed():
	get_tree().quit()
