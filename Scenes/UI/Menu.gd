extends Control



func _ready():
	TranslationServer.set_locale(GameData.data.get("SettingsGame", {}).get("language", "en"))
	DisplayServer.window_set_size(Vector2i(GameData.data.get("SettingsGame", {}).get("width", 1600), GameData.data.get("SettingsGame", {}).get("height", 900)))
	get_node("Panel/HBoxContainer/Label").text = str(GameData.resources_money)

func on_new_game_pressed():
	GameData.menu_object = load("res://Scenes/SupportScenes/choose_game_mode.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(GameData.menu_object)

func shop():
	GameData.menu_object = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	get_node("MarginContainer2").visible = false
	get_node(".").add_child(GameData.menu_object)
	
func settings():
	get_tree().change_scene_to_file("res://Scenes/UI/MenuSettings.tscn")
	
func on_quit_pressed():
	get_tree().quit()
